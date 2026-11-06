function Update-UI {
    try {
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        $callback = [System.Windows.Threading.DispatcherOperationCallback] {
            param($f)
            $f.Continue = $false
            return $null
        }
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background, $callback, $frame) | Out-Null
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    } catch { }
}

function Wait-UI {
    param([int]$Milliseconds = 50)
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds($Milliseconds)
    $timer.Add_Tick({ $timer.Stop(); $frame.Continue = $false }.GetNewClosure())
    $timer.Start()
    try { [System.Windows.Threading.Dispatcher]::PushFrame($frame) } catch { $timer.Stop() }
}

$script:AppxSnapshot = $null

function Get-AppxSnapshot {
    param([switch]$Refresh)
    if ($Refresh -or $null -eq $script:AppxSnapshot) {
        $map = @{}
        foreach ($p in (Get-AppxPackage -ErrorAction SilentlyContinue)) {
            if (-not $map.ContainsKey($p.Name)) {
                $map[$p.Name] = New-Object System.Collections.Generic.List[object]
            }
            $map[$p.Name].Add($p)
        }
        $script:AppxSnapshot = $map
    }
    return $script:AppxSnapshot
}

function Test-AppxInstalled {
    param([string]$PackageId)
    $snap = Get-AppxSnapshot
    if ($snap.ContainsKey($PackageId)) { return $true }
    foreach ($k in $snap.Keys) {
        if ($k -like "*$PackageId*") { return $true }
    }
    return $false
}

function Stop-AppxBlockingProcess {
    param([string[]]$ProcessNames = @())
    $names = @($ProcessNames | Where-Object { $_ })
    if ($names.Count -eq 0) { return }
    Get-Process -Name $names -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

function Block-OobeReinstall {
    param([ValidateSet('Outlook', 'DevHome')][string]$App)
    $oobe = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe'
    Remove-Item -Path "$oobe\$($App)Update" -Recurse -Force -ErrorAction SilentlyContinue
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\$($App)Update" 'workCompleted' 1
    if ($App -eq 'Outlook') { Set-Reg $oobe 'BlockedOobeUpdaters' '["MS_Outlook"]' 'String' }
}

function Invoke-RemovalScript {
    param([Parameter(Mandatory)][string]$FileName, [string]$Folder = "Programs")
    $path = Join-Path $script:ToolRoot (Join-Path $Folder $FileName)
    if (-not (Test-Path $path)) { throw "Could not find $FileName at $path" }

    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript('param($ScriptPath) $ProgressPreference = ''SilentlyContinue''; $r = & $ScriptPath; @($r)[-1]').AddArgument($path) | Out-Null
    $handle = $ps.BeginInvoke()
    $started = Get-Date

    while (-not $handle.IsCompleted) {
        if ($SkipToken -and $SkipToken.Requested) {
            try { $ps.BeginStop($null, $null) | Out-Null } catch { }
            Stop-ChildProcessesSince -Since $started
            throw [System.OperationCanceledException]::new("Skipped")
        }
        Wait-UI -Milliseconds 50
    }

    $output = @()
    try { $output = @($ps.EndInvoke($handle)) } catch { }
    try { $ps.Dispose(); $rs.Dispose() } catch { }
    if ($output.Count -eq 0) { return $false }
    return [bool]$output[-1]
}

function Invoke-AppxRemovalBatch {
    param(
        [array]$Items,
        [scriptblock]$OnProgress,
        [int]$IndexOffset = 0,
        [int]$GrandTotal = 0,
        $CancelToken = $null
    )

    $results = @{}
    foreach ($it in $Items) { $results[$it.Name] = @{ Success = $false; Error = "Not processed" } }
    if (-not $Items -or $Items.Count -eq 0) { return $results }

    $reportTotal = $Items.Count
    if ($GrandTotal -le 0) { $GrandTotal = $reportTotal }

    function Report {
        param([string]$Message, [int]$Done, [switch]$NoCount)
        if (-not $OnProgress) { return }
        $text = if ($NoCount) { $Message } else { "$Message ($($IndexOffset + $Done) of $GrandTotal)" }
        & $OnProgress $text $Done $reportTotal
    }

    Report "Closing running apps..." 0 -NoCount
    $procNames = New-Object System.Collections.Generic.List[string]
    foreach ($it in $Items) {
        if ($it.ContainsKey('StopProcesses') -and $it.StopProcesses) {
            foreach ($n in @($it.StopProcesses)) { if (-not $procNames.Contains($n)) { $procNames.Add($n) } }
        }
    }
    Stop-AppxBlockingProcess -ProcessNames $procNames
    Update-UI

    $state = [hashtable]::Synchronized(@{
        Current        = ""
        CurrentStarted = Get-Date
        Abandoned      = $false
        Done           = 0
        Stage          = "removing"
        Finished       = $false
        Results        = [hashtable]::Synchronized(@{})
    })

    $worker = {
        param($WorkItems, $State, $Cancel)

        $ProgressPreference = 'SilentlyContinue'
        Import-Module Appx -ErrorAction SilentlyContinue

        $byName = @{}
        foreach ($p in (Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue)) {
            if (-not $byName.ContainsKey($p.Name)) { $byName[$p.Name] = New-Object System.Collections.Generic.List[object] }
            $byName[$p.Name].Add($p)
        }

        $done = 0
        $provCache = $null
        foreach ($it in $WorkItems) {
            if ($Cancel -and $Cancel.Requested) { break }
            if ($State.Abandoned) { break }
            $State.Current = $it.Name
            $started = Get-Date
            $State.CurrentStarted = $started
            $errors = New-Object System.Collections.Generic.List[string]
            $usedAllUsers = $false
            $cheapError = $null

            foreach ($id in @($it.AppxIds)) {
                $matchedKeys = @()
                if ($byName.ContainsKey($id)) { $matchedKeys = @($id) }
                else { $matchedKeys = @($byName.Keys | Where-Object { $_ -like "*$id*" }) }
                if ($matchedKeys.Count -eq 0) { continue }

                foreach ($pkg in @($matchedKeys | ForEach-Object { $byName[$_] })) {
                    $removed = $false
                    try {
                        Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                        $removed = $true
                    } catch {
                        $cheapError = $_.Exception.Message
                    }

                    if (-not $removed) {
                        $usedAllUsers = $true
                        try {
                            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                            $removed = $true
                        } catch {
                            if (-not $removed) { $errors.Add($_.Exception.Message) }
                        }
                    }
                }
            }

            $provFound = $null; $provCmdlet = $null; $provError = $null
            if ($it.RemoveProvisioned) {
                if ($null -eq $provCache) {
                    $fastGet    = [bool](Get-Command Get-ProvisionedAppxPackage -ErrorAction SilentlyContinue)
                    $fastRemove = [bool](Get-Command Remove-ProvisionedAppxPackage -ErrorAction SilentlyContinue)
                    if (-not $fastGet -or -not $fastRemove) { Import-Module Dism -ErrorAction SilentlyContinue }
                    try {
                        $provCache = if ($fastGet) { @(Get-ProvisionedAppxPackage -Online -ErrorAction SilentlyContinue) }
                                     else          { @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue) }
                    } catch {
                        $provCache = @()
                        $provError = "enumeration failed: $($_.Exception.Message)"
                    }
                }
                $provMatches = @()
                foreach ($id in @($it.AppxIds)) {
                    $provMatches += @($provCache | Where-Object {
                        $_.DisplayName -eq $id -or $_.DisplayName -like "*$id*" -or $_.PackageName -like "*$id*"
                    })
                }
                $provFound  = $provMatches.Count
                $provCmdlet = if ($fastRemove) { 'Remove-ProvisionedAppxPackage' } else { 'Remove-AppxProvisionedPackage (Dism)' }
                foreach ($pp in $provMatches) {
                    try {
                        if ($fastRemove) { Remove-ProvisionedAppxPackage -Online -PackageName $pp.PackageName -ErrorAction Stop | Out-Null }
                        else             { Remove-AppxProvisionedPackage -Online -PackageName $pp.PackageName -ErrorAction Stop | Out-Null }
                    } catch {
                        $provError = $_.Exception.Message
                    }
                }
            }

            $State.Results[$it.Name] = @{
                Success    = ($errors.Count -eq 0)
                Error      = ($errors -join '; ')
                Seconds    = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
                Path       = $(if ($usedAllUsers) { 'all-users (SLOW)' } else { 'current-user (fast)' })
                CheapError = $cheapError
                ProvFound  = $provFound
                ProvCmdlet = $provCmdlet
                ProvError  = $provError
            }
            $done++
            $State.Done = $done
        }

        if ($Cancel -and $Cancel.Requested) { $State.Finished = $true; return }
        if ($State.Abandoned) { $State.Finished = $true; return }
        $State.Stage = "retry"
        $State.Current = ""

        Start-Sleep -Milliseconds 1500

        $stillPresent = @{}
        foreach ($p in (Get-AppxPackage -ErrorAction SilentlyContinue)) {
            if (-not $stillPresent.ContainsKey($p.Name)) { $stillPresent[$p.Name] = $p }
        }
        foreach ($it in $WorkItems) {
            foreach ($id in @($it.AppxIds)) {
                $key = $null
                if ($stillPresent.ContainsKey($id)) { $key = $id }
                else { $key = @($stillPresent.Keys | Where-Object { $_ -like "*$id*" })[0] }
                if (-not $key) { continue }
                $id = $key
                $State.Current = $it.Name
                $retryStart = Get-Date
                $retryErr = $null
                try { Remove-AppxPackage -Package $stillPresent[$id].PackageFullName -ErrorAction Stop }
                catch {
                    $retryErr = $_.Exception.Message
                    try { Remove-AppxPackage -Package $stillPresent[$id].PackageFullName -AllUsers -ErrorAction Stop; $retryErr = $null }
                    catch { }
                }
                $prev = $State.Results[$it.Name]
                $prevSecs = if ($prev -and $prev.Seconds) { $prev.Seconds } else { 0 }
                $State.Results[$it.Name] = @{
                    Success    = ($null -eq $retryErr)
                    Error      = $retryErr
                    Seconds    = [math]::Round($prevSecs + ((Get-Date) - $retryStart).TotalSeconds, 1)
                    Path       = 'current-user (needed a retry)'
                    CheapError = $(if ($prev) { $prev.CheapError } else { $null })
                    ProvFound  = $(if ($prev) { $prev.ProvFound } else { $null })
                    ProvCmdlet = $(if ($prev) { $prev.ProvCmdlet } else { $null })
                    ProvError  = $(if ($prev) { $prev.ProvError } else { $null })
                }
            }
        }
        $State.Current = ""

        $State.Finished = $true
    }

    $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $runspace
    $ps.AddScript($worker.ToString()).AddArgument($Items).AddArgument($state).AddArgument($CancelToken) | Out-Null
    $handle = $ps.BeginInvoke()

    $lastKey = ""
    $lastElapsedShown = -1
    $skippedApp = $null
    while (-not $handle.IsCompleted) {
        $cur = [string]$state.Current
        if ($SkipToken -and $SkipToken.Requested -and $cur) {
            $skippedApp = $cur
            break
        }
        $doneCount = [int]$state.Done
        $key = "$($state.Stage)|$cur|$doneCount"

        if ($key -ne $lastKey) {
            $lastKey = $key
            $lastElapsedShown = -1
        }

        if ($state.Stage -eq "retry") {
            if ($lastElapsedShown -lt 0 -and $cur) {
                Report "Retrying $cur..." $reportTotal -NoCount
                $lastElapsedShown = 0
            }
        } elseif ($cur) {
            $elapsed = [int]((Get-Date) - [datetime]$state.CurrentStarted).TotalSeconds
            $tick = if ($elapsed -ge 10) { [math]::Floor($elapsed / 5) } else { 0 }
            if ($tick -ne $lastElapsedShown) {
                $lastElapsedShown = $tick
                $suffix = ""
                if ($elapsed -ge 10) { $suffix = " - $elapsed seconds" }
                Report "Uninstalling $cur$suffix" ([Math]::Min($doneCount + 1, $reportTotal))
            }
        }
        Wait-UI -Milliseconds 50
    }

    if ($skippedApp) {
        $state.Abandoned = $true
        $SkipToken.Requested = $false
        foreach ($k in @($state.Results.Keys)) { $results[$k] = $state.Results[$k] }
        $results[$skippedApp] = @{ Success = $false; Skipped = $true; Error = "Skipped" }
        $remaining = @($Items | Where-Object { $_.Name -ne $skippedApp -and $results[$_.Name].Error -eq "Not processed" })
        if ($remaining.Count -gt 0 -and -not ($CancelToken -and $CancelToken.Requested)) {
            $rest = Invoke-AppxRemovalBatch -Items $remaining -OnProgress $OnProgress -IndexOffset ($IndexOffset + $Items.Count - $remaining.Count) `
                -GrandTotal $GrandTotal -CancelToken $CancelToken
            foreach ($k in $rest.Keys) { $results[$k] = $rest[$k] }
        }
        return $results
    }

    try { $ps.EndInvoke($handle) | Out-Null } catch { }
    foreach ($k in $state.Results.Keys) { $results[$k] = $state.Results[$k] }
    if ($CancelToken -and $CancelToken.Requested) {
        foreach ($it in $Items) {
            if ($results[$it.Name].Error -eq "Not processed") {
                $results[$it.Name] = @{ Success = $false; Error = "Cancelled"; Cancelled = $true }
            }
        }
    }
    try { $ps.Dispose(); $runspace.Dispose() } catch { }

    Get-AppxSnapshot -Refresh | Out-Null
    foreach ($it in $Items) {
        if (-not $results[$it.Name].Success) { continue }
        foreach ($id in @($it.AppxIds)) {
            if (Test-AppxInstalled $id) {
                $results[$it.Name].Success = $false
                $results[$it.Name].Error = "Still installed after removal (package '$id' did not unregister)"
                break
            }
        }
    }

    return $results
}

function Stop-ProcessTree {
    param($Process)
    if (-not $Process) { return }
    try { & "$env:SystemRoot\System32\taskkill.exe" /PID $Process.Id /T /F 2>$null | Out-Null } catch { }
    try { if (-not $Process.HasExited) { $Process.Kill() } } catch { }
}

function Stop-ChildProcessesSince {
    param([datetime]$Since)
    $kids = @()
    try { $kids = @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $PID" -ErrorAction Stop | Where-Object { $_.CreationDate -ge $Since }) } catch { return }
    foreach ($k in $kids) {
        try { Stop-ProcessTree -Process (Get-Process -Id $k.ProcessId -ErrorAction Stop) } catch { }
    }
}

function Invoke-DeepClean {
    param([string]$Name, [string[]]$AppxIds)
    $scriptPath = Join-Path $script:ToolRoot "Programs\Deep-Clean.ps1"
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Ids `"$((@($AppxIds) -join ';'))`""
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $start = Get-Date
    $proc = [System.Diagnostics.Process]::Start($psi)
    $script:DeepCleanProcess = $proc
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()
    $stopped = $null
    while (-not $proc.WaitForExit(0)) {
        if ($CancelToken -and $CancelToken.Requested) { $stopped = "Cancelled"; break }
        if ($SkipToken -and $SkipToken.Requested) { $stopped = "Skipped"; break }
        Wait-UI -Milliseconds 50
    }
    $secs = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
    if ($stopped) {
        Stop-ProcessTree -Process $proc
        $script:DeepCleanProcess = $null
        return @{ Success = $false; Seconds = $secs; $stopped = $true; Error = $stopped }
    }
    $script:DeepCleanProcess = $null
    $out = ""
    try { if ($outTask.Wait(3000)) { $out = $outTask.Result } } catch { }
    try { if ($errTask.Wait(1000)) { $out += "`n" + $errTask.Result } } catch { }
    $lastLine = @($out -split "[\r\n]+" | ForEach-Object { $_.Trim() } | Where-Object { $_ }) | Select-Object -First 1
    if ($proc.ExitCode -eq 0) { return @{ Success = $true; Seconds = $secs; Error = "" } }
    return @{ Success = $false; Seconds = $secs; Error = $(if ($lastLine) { $lastLine } else { "exit code $($proc.ExitCode)" }) }
}

function Start-ProcessWithTimeout {
    param([string]$FilePath, [string[]]$ArgumentList, [int]$TimeoutSeconds = 30)
    try {
        $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -WindowStyle Hidden -PassThru
    } catch {
        return @{ TimedOut = $false; ExitCode = -1 }
    }
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while (-not $proc.HasExited -and (Get-Date) -lt $deadline) {
        Wait-UI -Milliseconds 50
    }
    if (-not $proc.HasExited) {
        Stop-ProcessTree -Process $proc
        return @{ TimedOut = $true; ExitCode = $null }
    }
    return @{ TimedOut = $false; ExitCode = $proc.ExitCode }
}

function Test-RegValue {
    param([string]$Path, [string]$Name, $ExpectedValue)
    if (-not (Test-Path $Path)) { return $false }
    $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $prop) { return $false }
    return $prop.$Name -eq $ExpectedValue
}

function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Remove-Reg {
    param([string]$Path, [string]$Name)
    if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
}

function Test-CommandExists { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ";"
}

function New-SystemRestorePoint {
    $body = {
        $newest = { (@(Get-ComputerRestorePoint -ErrorAction SilentlyContinue) | Measure-Object -Property SequenceNumber -Maximum).Maximum }
        try {
            Enable-ComputerRestore -Drive "$($env:SystemDrive)\" -ErrorAction SilentlyContinue
            $before = & $newest
            Checkpoint-Computer -Description "Restore Point - Simple Windows 11 Tool" -RestorePointType "MODIFY_SETTINGS" -WarningAction SilentlyContinue -ErrorAction Stop
            if ((& $newest) -gt $before) { @{ Success = $true; LimitHit = $false; Error = "" } }
            else { @{ Success = $false; LimitHit = $true; Error = "" } }
        } catch {
            @{ Success = $false; LimitHit = $false; Error = $_.Exception.Message }
        }
    }
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript($body.ToString()) | Out-Null
    $handle = $ps.BeginInvoke()
    while (-not $handle.IsCompleted) { Wait-UI -Milliseconds 50 }
    $result = $null
    try { $result = @($ps.EndInvoke($handle))[-1] } catch { }
    try { $ps.Dispose(); $rs.Dispose() } catch { }
    if (-not $result) { return @{ Success = $false; LimitHit = $false; Error = "No result was returned." } }
    return $result
}

function Test-InternetConnection {
    try {
        $r = Invoke-WebRequest -Uri 'http://www.msftconnecttest.com/connecttest.txt' -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop
        if ($r.Content -match 'Microsoft Connect Test') { return $true }
    } catch { }
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ok = $tcp.ConnectAsync('storeedgefd.dsx.mp.microsoft.com', 443).Wait(5000)
        $tcp.Close()
        return [bool]$ok
    } catch {
        return $false
    }
}

function Restore-StagedAppx {
    param([string[]]$AppxIds)
    $body = {
        param($Ids)
        $ProgressPreference = 'SilentlyContinue'
        Import-Module Appx -ErrorAction SilentlyContinue
        $restored = $false; $err = ''
        foreach ($id in $Ids) {
            $pkgs = @(Get-AppxPackage -AllUsers -Name "*$id*" -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -eq $id -or $_.Name -like "*$id*" } |
                      Sort-Object Version -Descending)
            foreach ($p in $pkgs) {
                if (-not $p.InstallLocation) { continue }
                $manifest = Join-Path $p.InstallLocation 'AppxManifest.xml'
                if (-not (Test-Path $manifest)) { continue }
                try {
                    Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop
                    $restored = $true
                    break
                } catch {
                    $err = $_.Exception.Message
                    if ($err -match '0x80073D02') {
                        foreach ($proc in @(Get-Process -ErrorAction SilentlyContinue)) {
                            try {
                                if ($proc.Path -and $proc.Path.StartsWith($p.InstallLocation, [System.StringComparison]::OrdinalIgnoreCase)) {
                                    $proc.Kill()
                                }
                            } catch { }
                        }
                        Start-Sleep -Milliseconds 800
                        try {
                            Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop
                            $restored = $true
                            $err = ''
                            break
                        } catch { $err = $_.Exception.Message }
                    }
                }
            }
            if ($restored) { break }
        }
        [PSCustomObject]@{ Restored = $restored; Error = $err }
    }
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript($body.ToString()).AddArgument([string[]]$AppxIds) | Out-Null
    $h = $ps.BeginInvoke()
    while (-not $h.IsCompleted) {
        if ($SkipToken -and $SkipToken.Requested) {
            try { $ps.BeginStop($null, $null) | Out-Null } catch { }
            return [PSCustomObject]@{ Restored = $false; Skipped = $true }
        }
        Wait-UI -Milliseconds 50
    }
    $out = $null
    try { $out = @($ps.EndInvoke($h))[-1] } catch { }
    try { $ps.Dispose(); $rs.Dispose() } catch { }
    if (-not $out) { return [PSCustomObject]@{ Restored = $false; Error = 'no result' } }
    return $out
}

function Close-AppsLaunchedSince {
    param([string]$NamePattern, [datetime]$Since)
    if (-not $NamePattern) { return }
    foreach ($proc in @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $NamePattern })) {
        try { if ($proc.StartTime -ge $Since) { $proc.Kill() } } catch { }
    }
}

function Install-WingetApp {
    param([string]$Id, [string]$Source = "", [scriptblock]$OnProgress, $CancelToken = $null)
    $sourceArg = if ($Source) { " -s $Source" } else { "" }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "winget"
    $psi.Arguments = "install --id $Id -e --silent --disable-interactivity --accept-source-agreements --accept-package-agreements$sourceArg"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
    } catch {
        return @{ Success = $false; ExitCode = -1; Hex = ''; Output = '' }
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
    $lines = @($raw -split "[\r\n]+" | ForEach-Object { $_.Trim() } | Where-Object {
        $_ -and
        $_ -notmatch '^[\-\\|/]+$' -and
        $_ -notmatch '[\u2580-\u259F]' -and
        $_ -notmatch '^\d+(\.\d+)?\s*(B|KB|MB|GB)\s*/' -and
        $_ -notmatch '\d+\s*%$'
    })
    $tail = ($lines | Select-Object -Last 3) -join ' | '

    if ($skipped) {
        return @{ Success = $false; Skipped = $true; ExitCode = $null; Hex = ''; Output = $tail }
    }
    if ($cancelled) {
        return @{ Success = $false; Cancelled = $true; ExitCode = $null; Hex = ''; Output = $tail }
    }
    $code = $proc.ExitCode
    $hex = '0x{0:X8}' -f ($code -band 0xFFFFFFFF)
    if ($code -eq -1978335189) {
        return @{ Success = $true; AlreadyInstalled = $true; ExitCode = $code; Hex = $hex; Output = $tail }
    }
    return @{ Success = ($code -eq 0); ExitCode = $code; Hex = $hex; Output = $tail }
}
