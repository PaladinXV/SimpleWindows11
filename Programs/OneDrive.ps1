$OneDriveRemoval = @{
    Name            = "OneDrive"
    Category        = "System Apps"
    SafetyLevel     = "Safe"
    ReinstallId     = 'Microsoft.OneDrive'
    ReinstallSource = 'winget'
    Detect          = {
        $regPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
        )
        return [bool]($regPaths | Where-Object { Test-Path $_ } | Select-Object -First 1)
    }
    Apply           = {
        if (-not (Invoke-RemovalScript -FileName "Remove-OneDrive.ps1")) {
            throw "OneDriveSetup ran but OneDrive is still present. Close OneDrive from the system tray and try again."
        }
    }
}
