$SwsRepo   = 'PaladinXV/SimpleWindows11'
$SwsBranch = 'main'

& {
    $ErrorActionPreference = 'Stop'
    $global:ProgressPreference = 'SilentlyContinue'

    $tick  = '--'
    $cross = [string][char]0x2717
    $frames = @(0x280B,0x2819,0x2839,0x2838,0x283C,0x2834,0x2826,0x2827,0x2807,0x280F) | ForEach-Object { [string][char]$_ }

    function Show-Banner {
        try { Clear-Host } catch { }
        $h = [string][char]0x2550; $v = [string][char]0x2551
        $tl = [string][char]0x2554; $tr = [string][char]0x2557
        $bl = [string][char]0x255A; $br = [string][char]0x255D
        $w = 50
        $title = 'Simple Windows 11 Tool'
        $sub   = 'By PaladinXV'
        $padT = [int](($w - $title.Length) / 2)
        $padS = [int](($w - $sub.Length) / 2)
        Write-Host ""
        Write-Host ("   " + $tl + ($h * $w) + $tr) -ForegroundColor DarkGray
        Write-Host ("   " + $v + (' ' * $w) + $v) -ForegroundColor DarkGray
        Write-Host ("   " + $v) -NoNewline -ForegroundColor DarkGray
        Write-Host ((' ' * $padT) + $title + (' ' * ($w - $padT - $title.Length))) -NoNewline -ForegroundColor Gray
        Write-Host $v -ForegroundColor DarkGray
        Write-Host ("   " + $v) -NoNewline -ForegroundColor DarkGray
        Write-Host ((' ' * $padS) + $sub + (' ' * ($w - $padS - $sub.Length))) -NoNewline -ForegroundColor DarkGray
        Write-Host $v -ForegroundColor DarkGray
        Write-Host ("   " + $v + (' ' * $w) + $v) -ForegroundColor DarkGray
        Write-Host ("   " + $bl + ($h * $w) + $br) -ForegroundColor DarkGray
        Write-Host ""
    }

    function Show-Status([string]$text, [string]$state = 'run', [string]$frame = '') {
        if ($state -eq 'ok')        { $icon = $tick;  $color = 'Gray' }
        elseif ($state -eq 'fail')  { $icon = $cross; $color = 'Red' }
        else                        { $icon = $frame; $color = 'Gray' }
        $line = "   $($icon.PadRight(2)) $($text.PadRight(30))"
        try {
            [Console]::CursorVisible = $false
            Write-Host "`r$line" -NoNewline -ForegroundColor $color
        } catch { Write-Host $line -ForegroundColor $color }
    }

    function Invoke-Step([string]$text, [scriptblock]$work) {
        Show-Status $text 'run' $frames[0]
        try {
            $null = & $work
        } catch {
            Show-Status $text 'fail'
            Write-Host ""
            throw
        }
        Show-Status $text 'ok'
        Write-Host ""
    }

    function Get-FileWithSpinner([string]$uri, [string]$path, [string]$text) {
        $req = [Net.HttpWebRequest]::Create($uri)
        $req.UserAgent = 'SimpleWindowsTool'
        $resp = $req.GetResponse()
        $in = $resp.GetResponseStream()
        $out = [IO.File]::Create($path)
        try {
            $buf = New-Object byte[] 65536
            $i = 0
            $watch = [Diagnostics.Stopwatch]::StartNew()
            while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) {
                $out.Write($buf, 0, $n)
                if ($watch.ElapsedMilliseconds -ge 70) {
                    $watch.Restart()
                    Show-Status $text 'run' $frames[$i % $frames.Count]
                    $i++
                }
            }
        } finally {
            $out.Dispose(); $in.Dispose(); $resp.Close()
        }
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        Show-Banner

        $temp = [IO.Path]::GetTempPath()
        $zip  = Join-Path $temp 'SimpleWindowsSetup.zip'
        $dest = Join-Path $temp 'SimpleWindowsSetup'
        $uri  = "https://github.com/$SwsRepo/archive/refs/heads/$SwsBranch.zip"

        $text1 = 'Downloading...'
        Show-Status $text1 'run' $frames[0]
        try {
            Get-FileWithSpinner $uri $zip $text1
        } catch {
            Show-Status $text1 'fail'
            Write-Host ""
            throw
        }
        Show-Status $text1 'ok'
        Write-Host ""

        Invoke-Step 'Extracting...' {
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force
            Remove-Item -LiteralPath $zip -Force
        }

        $script:main = $null
        Invoke-Step 'Preparing...' {
            $script:main = Get-ChildItem -LiteralPath $dest -Recurse -Filter 'Main.ps1' | Select-Object -First 1
            if (-not $script:main) { throw "Main.ps1 was not found in the download." }
            Get-ChildItem -LiteralPath $dest -Recurse -File | Unblock-File
        }
        $main = $script:main

        Invoke-Step 'Launching...' {
            $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
            $script:proc = Start-Process -FilePath $windowsPowerShell -WindowStyle Hidden -PassThru -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($main.FullName)`""
            Start-Sleep -Milliseconds 400
        }

        $text2 = 'Detecting System Configuration...'
        $ready = $false
        $deadline = (Get-Date).AddMinutes(3)
        for ($i = 0; -not $ready -and (Get-Date) -lt $deadline; $i++) {
            Show-Status $text2 'run' $frames[$i % $frames.Count]
            $ready = [bool](Get-Process -Name powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq 'Simple Windows 11 Tool' })
            if ($ready) { break }
            if ($i % 20 -eq 19 -and $script:proc.HasExited) {
                $alive = $false
                try {
                    $alive = [bool](Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction Stop | Where-Object { $_.CommandLine -like '*Main.ps1*' })
                } catch { $alive = $true }
                if (-not $alive) { break }
            }
            Start-Sleep -Milliseconds 100
        }
        Show-Status $text2 $(if ($ready) { 'ok' } else { 'fail' })
        Write-Host ""

        if ($script:proc) { try { $script:proc | Wait-Process } catch { } }

        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $deadline = (Get-Date).AddSeconds($(if ($isAdmin) { 15 } else { 90 }))
        $found = $false
        while ($true) {
            $running = $false
            try {
                $running = [bool](Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction Stop |
                    Where-Object { $_.CommandLine -like '*Main.ps1*' -and $_.CommandLine -like '*NoConhostRelaunch*' })
            } catch { }
            if ($running) { $found = $true }
            elseif ($found) { break }
            elseif ((Get-Date) -gt $deadline) { while ($true) { Start-Sleep -Seconds 3600 } }
            Start-Sleep -Seconds 1
        }

    } catch {
        Write-Host ""
        Write-Host "   $cross Simple Windows 11 Tool could not be started" -ForegroundColor Red
        Write-Host "     $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ""
    } finally {
        try { [Console]::CursorVisible = $true } catch { }
    }
}
