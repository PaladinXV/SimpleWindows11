function Write-EdgeLog {
    param([string]$Message)
    try { Add-Content -Path "$env:TEMP\SimpleWindowsTool-log.txt" -Value ((" " * 30) + "Edge: $Message") -Encoding UTF8 } catch { }
}

function Start-AndWait {
    param([string]$FilePath, [string]$Arguments)
    $proc = Start-Process -FilePath $FilePath -ArgumentList $Arguments -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
    if ($proc) { $proc.WaitForExit() }
}

function Test-EdgePresent {
    foreach ($exe in @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
    )) {
        if ($exe -and (Test-Path $exe)) { return $exe }
    }
    return $null
}

function Get-EdgeUninstallString {
    foreach ($v in @(
        @{ Hive = [Microsoft.Win32.RegistryHive]::LocalMachine; View = [Microsoft.Win32.RegistryView]::Registry32 },
        @{ Hive = [Microsoft.Win32.RegistryHive]::LocalMachine; View = [Microsoft.Win32.RegistryView]::Registry64 },
        @{ Hive = [Microsoft.Win32.RegistryHive]::CurrentUser;  View = [Microsoft.Win32.RegistryView]::Default }
    )) {
        try {
            $k = [Microsoft.Win32.RegistryKey]::OpenBaseKey($v.Hive, $v.View).OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge")
            if ($k) {
                $u = $k.GetValue("UninstallString")
                if ($u) { return $u }
            }
        } catch { }
    }
    return $null
}

$regionKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\DeviceRegion'
$originalRegion = $null
try { $originalRegion = Get-ItemPropertyValue -Path $regionKey -Name 'DeviceRegion' -ErrorAction SilentlyContinue } catch { }
try { Set-ItemProperty -Path $regionKey -Name 'DeviceRegion' -Value 244 -Type DWord -Force -ErrorAction SilentlyContinue } catch { }

try {
    $baseKey = 'HKLM:\SOFTWARE' + $(if ([Environment]::Is64BitOperatingSystem) { '\WOW6432Node' }) + '\Microsoft'
    $devKeyPath = "$baseKey\EdgeUpdateDev"
    if (-not (Test-Path $devKeyPath)) { New-Item -Path $devKeyPath -Force | Out-Null }
    Set-ItemProperty -Path $devKeyPath -Name 'AllowUninstall' -Value '' -Type String -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "$baseKey\EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" -Name 'experiment_control_labels' -Force -ErrorAction SilentlyContinue
} catch { }

$stopNames = "backgroundTaskHost", "Copilot", "CrossDeviceResume", "GameBar", "MicrosoftEdgeUpdate",
    "msedge", "msedgewebview2", "RuntimeBroker", "WidgetService", "Widgets"
$stopNames | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -like "*edge*" -or $_.Path -like "*\Microsoft\Edge\*" } |
    Stop-Process -Force -ErrorAction SilentlyContinue

$uninstallKeyPath = 'Microsoft\Windows\CurrentVersion\Uninstall'
$uninstallKeys = (Get-ChildItem -Path @(
        "HKLM:\SOFTWARE\$uninstallKeyPath",
        "HKLM:\SOFTWARE\WOW6432Node\$uninstallKeyPath",
        "HKCU:\SOFTWARE\$uninstallKeyPath",
        "HKCU:\SOFTWARE\WOW6432Node\$uninstallKeyPath"
    ) -ErrorAction SilentlyContinue) -match '\{\b[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}\b\}'
foreach ($key in $uninstallKeys.PSPath) {
    $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
    if ($props.DisplayName -like "*Microsoft Edge*" -and $props.UninstallString -like '*MsiExec.exe*') {
        $guid = Split-Path -Path $key -Leaf
        Start-AndWait -FilePath 'msiexec.exe' -Arguments "/qn /X$guid REBOOT=ReallySuppress /norestart"
    }
}

$edgeUpdatePaths = @()
"LocalApplicationData", "ProgramFilesX86", "ProgramFiles" | ForEach-Object {
    $folder = [Environment]::GetFolderPath($_)
    $edgeUpdatePaths += Get-ChildItem "$folder\Microsoft\EdgeUpdate\*.*.*.*\MicrosoftEdgeUpdate.exe" -Recurse -ErrorAction SilentlyContinue
}

$regLocations = "HKCU:\SOFTWARE", "HKLM:\SOFTWARE", "HKCU:\SOFTWARE\Policies", "HKLM:\SOFTWARE\Policies",
    "HKCU:\SOFTWARE\WOW6432Node", "HKLM:\SOFTWARE\WOW6432Node",
    "HKCU:\SOFTWARE\WOW6432Node\Policies", "HKLM:\SOFTWARE\WOW6432Node\Policies"
foreach ($location in $regLocations) {
    Remove-Item "$location\Microsoft\EdgeUpdate" -Recurse -Force -ErrorAction SilentlyContinue
}

foreach ($path in $edgeUpdatePaths) {
    if (-not (Test-Path $path.FullName)) { continue }
    foreach ($arg in "/unregsvc", "/uninstall") {
        Start-AndWait -FilePath $path.FullName -Arguments $arg
        $waitCount = 0
        while ((Get-Process -Name "setup", "MicrosoftEdge*" -ErrorAction SilentlyContinue).Path -like "*\Microsoft\Edge\*" -and $waitCount -lt 10) {
            Start-Sleep -Seconds 3
            $waitCount++
        }
    }
}

$edgeUwpPath = "$env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
$createdStub = $false
if (-not (Test-Path "$edgeUwpPath\MicrosoftEdge.exe")) {
    New-Item -Path $edgeUwpPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path "$edgeUwpPath\MicrosoftEdge.exe" -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
    $createdStub = $true
}

$uninstallString = Get-EdgeUninstallString
if (-not $uninstallString) { Write-EdgeLog "no uninstall entry found in any registry location" }

for ($attempt = 1; $attempt -le 2 -and $uninstallString -and (Test-EdgePresent); $attempt++) {
    Get-Process -Name msedge -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    try {
        Start-AndWait -FilePath "cmd.exe" -Arguments "/c $uninstallString --force-uninstall"
    } catch {
        Write-EdgeLog "attempt ${attempt}: could not start the uninstaller - $($_.Exception.Message)"
    }
    $w = 0
    while ((Get-Process -Name setup -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*\Microsoft\Edge\*' }) -and $w -lt 20) {
        Start-Sleep -Seconds 1
        $w++
    }
    $uninstallString = Get-EdgeUninstallString
}

if ($createdStub) {
    Remove-Item -Path $edgeUwpPath -Recurse -Force -ErrorAction SilentlyContinue
}

cmd /c "reg delete `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView`" /f >nul 2>&1"

@(
    "$([Environment]::GetFolderPath('Desktop'))\Microsoft Edge.lnk",
    "$([Environment]::GetFolderPath('CommonStartMenu'))\Microsoft Edge.lnk",
    "$env:SystemDrive\Windows\System32\config\systemprofile\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk"
) | ForEach-Object { Remove-Item -Path $_ -Force -ErrorAction SilentlyContinue }

Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(edgeupdate|edgeupdatem|MicrosoftEdgeElevationService)$' } | ForEach-Object {
    cmd /c "sc stop `"$($_.Name)`" >nul 2>&1"
    cmd /c "sc delete `"$($_.Name)`" >nul 2>&1"
}

if ($null -ne $originalRegion) {
    Set-ItemProperty -Path $regionKey -Name 'DeviceRegion' -Value $originalRegion -Type DWord -Force -ErrorAction SilentlyContinue
}

$remaining = Test-EdgePresent
if ($remaining) { Write-EdgeLog "finished, but msedge.exe is still at $remaining" }
return (-not $remaining)
