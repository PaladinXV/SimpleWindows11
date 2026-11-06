function Find-OneDriveSetup {
    $oneDriveBase = "$env:LOCALAPPDATA\Microsoft\OneDrive"
    if (Test-Path $oneDriveBase) {
        $versionFolder = Get-ChildItem -Path $oneDriveBase -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d+(\.\d+)+$' } |
            Sort-Object { [version]$_.Name } -Descending |
            Select-Object -First 1
        if ($versionFolder) {
            $candidate = Join-Path $versionFolder.FullName "OneDriveSetup.exe"
            if (Test-Path $candidate) { return $candidate }
        }
    }
    $legacyPaths = @(
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe",
        "$env:ProgramFiles\Microsoft OneDrive\OneDriveSetup.exe"
    )
    return ($legacyPaths | Where-Object { Test-Path $_ } | Select-Object -First 1)
}

Get-Process -Name 'OneDrive' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$oneDriveInstaller = Find-OneDriveSetup
if ($oneDriveInstaller) {
    try { Start-Process -FilePath $oneDriveInstaller -ArgumentList "/uninstall /quiet" -Wait -WindowStyle Hidden -ErrorAction Stop } catch { }
}
Start-Sleep -Milliseconds 750

return -not (@(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
) | Where-Object { Test-Path $_ })
