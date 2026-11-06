function Install-Chocolatey {
    if (Test-CommandExists choco) { return [PSCustomObject]@{ Success = $true; Stopped = $false; Error = "" } }
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript({
        $ProgressPreference = 'SilentlyContinue'
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }.ToString()) | Out-Null
    $handle = $ps.BeginInvoke()
    while (-not $handle.IsCompleted) {
        if ($CancelToken -and $CancelToken.Requested) {
            try { $ps.BeginStop($null, $null) | Out-Null } catch { }
            return [PSCustomObject]@{ Success = $false; Stopped = $true; Error = "Stopped" }
        }
        Wait-UI -Milliseconds 50
    }
    $err = ""
    try { $ps.EndInvoke($handle) | Out-Null } catch { $err = $_.Exception.Message }
    if (-not $err -and $ps.Streams.Error.Count -gt 0) { $err = "$($ps.Streams.Error[0])" }
    try { $ps.Dispose(); $rs.Dispose() } catch { }
    Update-SessionPath
    $ok = [bool](Test-CommandExists choco)
    return [PSCustomObject]@{ Success = $ok; Stopped = $false; Error = $(if ($ok) { "" } elseif ($err) { $err } else { "choco was not found after installing." }) }
}

function Uninstall-Chocolatey {
    $root = [Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine')
    if (-not $root) { $root = $env:ChocolateyInstall }
    if (-not $root) { $root = Join-Path $env:ProgramData 'chocolatey' }
    $targets = @(
        @{ Key = [Microsoft.Win32.Registry]::LocalMachine; Path = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment' }
        @{ Key = [Microsoft.Win32.Registry]::CurrentUser;  Path = 'Environment' }
    )
    foreach ($t in $targets) {
        $envKey = $t.Key.OpenSubKey($t.Path, $true)
        if (-not $envKey) { continue }
        $raw = $envKey.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($raw) {
            $kept = @($raw -split ';' | Where-Object { $_ -and ($_ -notlike "$root*") -and ($_ -notlike '*%ChocolateyInstall%*') })
            $newPath = $kept -join ';'
            if ($newPath -ne $raw) { $envKey.SetValue('Path', $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString) }
        }
        foreach ($name in 'ChocolateyInstall', 'ChocolateyLastPathUpdate', 'ChocolateyToolsLocation') {
            if ($null -ne $envKey.GetValue($name)) { $envKey.DeleteValue($name) }
        }
        $envKey.Close()
    }
    [Environment]::SetEnvironmentVariable('ChocolateyInstall', $null, 'User')
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction Stop }
    $env:ChocolateyInstall = $null
    Update-SessionPath
}

function Install-ChocoApp {
    param([Parameter(Mandatory)][string]$Id, $CancelToken = $null)
    Update-SessionPath
    if (-not (Test-CommandExists choco)) {
        return @{ Success = $false; ExitCode = -1; Output = 'Chocolatey is not installed' }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "choco"
    $psi.Arguments = "install $Id -y --no-progress"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
    } catch {
        return @{ Success = $false; ExitCode = -1; Output = $_.Exception.Message }
    }
    try { $proc.StandardInput.Close() } catch { }
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()

    $cancelled = $false
    $skipped = $false
    while (-not $proc.WaitForExit(0)) {
        if ($CancelToken -and $CancelToken.Requested) {
            Stop-ProcessTree -Process $proc
            $cancelled = $true
            break
        }
        if ($SkipToken -and $SkipToken.Requested) {
            Stop-ProcessTree -Process $proc
            $skipped = $true
            break
        }
        Wait-UI -Milliseconds 50
    }
    $exitWait = if ($cancelled -or $skipped) { 1000 } else { 5000 }
    $readWait = if ($cancelled -or $skipped) { 300 } else { 3000 }
    try { $proc.WaitForExit($exitWait) | Out-Null } catch { }

    $raw = ''
    try { if ($outTask.Wait($readWait)) { $raw += $outTask.Result } } catch { }
    try { if ($errTask.Wait($readWait)) { $raw += "`n" + $errTask.Result } } catch { }
    $lines = @($raw -split "[\r\n]+" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -notmatch '^Progress:' })
    $tail = ($lines | Select-Object -Last 3) -join ' | '

    if ($skipped) {
        return @{ Success = $false; Skipped = $true; ExitCode = $null; Output = $tail }
    }
    if ($cancelled) {
        return @{ Success = $false; Cancelled = $true; ExitCode = $null; Output = $tail }
    }
    $code = $proc.ExitCode
    $ok = $code -in @(0, 1641, 3010)
    $already = $ok -and ($raw -match 'already installed')
    return @{ Success = $ok; AlreadyInstalled = $already; ExitCode = $code; Output = $tail }
}

$ChocoApps = @(
    @{ Name = 'Brave';                       ChocoId = 'brave' }
    @{ Name = 'Chrome';                      ChocoId = 'googlechrome' }
    @{ Name = 'FireFox';                     ChocoId = 'firefox' }
    @{ Name = 'FireFox ESR';                 ChocoId = 'firefoxesr' }
    @{ Name = 'Floorp';                      ChocoId = 'floorp' }
    @{ Name = 'Helium';                      ChocoId = 'helium' }
    @{ Name = 'Librewolf';                   ChocoId = 'librewolf' }
    @{ Name = 'Tor Browser';                 ChocoId = 'tor-browser' }
    @{ Name = 'Vivaldi';                     ChocoId = 'vivaldi' }
    @{ Name = 'Waterfox';                    ChocoId = 'waterfox' }
    @{ Name = 'Zen Browser';                 ChocoId = 'zen-browser' }
    @{ Name = 'Discord';                     ChocoId = 'discord' }
    @{ Name = 'Signal';                      ChocoId = 'signal' }
    @{ Name = 'TeamSpeak';                   ChocoId = 'teamspeak' }
    @{ Name = 'Telegram';                    ChocoId = 'telegram' }
    @{ Name = 'Adobe Acrobat Reader';        ChocoId = 'adobereader' }
    @{ Name = 'LibreOffice';                 ChocoId = 'libreoffice-fresh' }
    @{ Name = 'Notepad++';                   ChocoId = 'notepadplusplus' }
    @{ Name = 'OpenOffice';                  ChocoId = 'openoffice' }
    @{ Name = 'EA App';                      ChocoId = 'ea-app' }
    @{ Name = 'Epic Games Launcher';         ChocoId = 'epicgameslauncher' }
    @{ Name = 'GOG Launcher';                ChocoId = 'goggalaxy' }
    @{ Name = 'Steam';                       ChocoId = 'steam' }
    @{ Name = 'Ubisoft Connect';             ChocoId = 'ubisoft-connect' }
    @{ Name = 'Audacity';                    ChocoId = 'audacity' }
    @{ Name = 'Foobar2000';                  ChocoId = 'foobar2000' }
    @{ Name = 'Handbrake';                   ChocoId = 'handbrake' }
    @{ Name = 'IrfanView';                   ChocoId = 'irfanview' }
    @{ Name = 'iTunes';                      ChocoId = 'itunes' }
    @{ Name = 'K-Lite Codec Standard';       ChocoId = 'k-litecodecpackstandard' }
    @{ Name = 'OBS Studio';                  ChocoId = 'obs-studio' }
    @{ Name = 'ShareX';                      ChocoId = 'sharex' }
    @{ Name = 'VLC Media Player';            ChocoId = 'vlc' }
    @{ Name = '7Zip';                        ChocoId = '7zip' }
    @{ Name = 'AutoHotkey';                  ChocoId = 'autohotkey' }
    @{ Name = 'Bitwarden';                   ChocoId = 'bitwarden' }
    @{ Name = 'CPU-Z';                       ChocoId = 'cpu-z' }
    @{ Name = 'Crystal Disk Info';           ChocoId = 'crystaldiskinfo' }
    @{ Name = 'Crystal Disk Mark';           ChocoId = 'crystaldiskmark' }
    @{ Name = 'Display Driver Uninstaller';  ChocoId = 'ddu' }
    @{ Name = 'Dropbox';                     ChocoId = 'dropbox' }
    @{ Name = 'Everything';                  ChocoId = 'everything' }
    @{ Name = 'GPU-Z';                       ChocoId = 'gpu-z' }
    @{ Name = 'HWInfo';                      ChocoId = 'hwinfo' }
    @{ Name = 'HWMonitor';                   ChocoId = 'hwmonitor' }
    @{ Name = 'MSI Afterburner';             ChocoId = 'msiafterburner' }
    @{ Name = 'Nanazip';                     ChocoId = 'nanazip' }
    @{ Name = 'PowerToys';                   ChocoId = 'powertoys' }
    @{ Name = 'Process Lasso';               ChocoId = 'plasso' }
    @{ Name = 'qBitTorrent';                 ChocoId = 'qbittorrent' }
    @{ Name = 'Mullvad VPN';                 ChocoId = 'mullvad-app' }
    @{ Name = 'Proton VPN';                  ChocoId = 'protonvpn' }
)

foreach ($chocoApp in $ChocoApps) {
    $wingetApp = $WingetApps | Where-Object { $_.Name -eq $chocoApp.Name } | Select-Object -First 1
    $chocoApp.Category = $wingetApp.Category
    $chocoApp.Description = $wingetApp.Description
    if ($wingetApp.Warning) { $chocoApp.Warning = $wingetApp.Warning }
}
