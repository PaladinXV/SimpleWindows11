$EdgeRemoval = @{
    Name            = "Microsoft Edge"
    Category        = "System Apps"
    SafetyLevel     = "Not Recommended"
    ReinstallId     = 'Microsoft.Edge'
    ReinstallSource = 'winget'
    Detect          = {
        $exePaths = @(
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
            "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
            "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
        )
        $regPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
        )
        return [bool](@($exePaths + $regPaths) | Where-Object { Test-Path $_ } | Select-Object -First 1)
    }
    Apply           = {
        if (-not (Invoke-RemovalScript -FileName "Remove-Edge.ps1")) {
            throw "Edge removal ran but msedge.exe is still present"
        }
    }
}
