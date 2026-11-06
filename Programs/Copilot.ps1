$CopilotRemoval = @{
    Name              = "Copilot"
    Category          = "System Apps"
    SafetyLevel       = "Safe"
    ReinstallId       = 'XP9CXNGPPJ97XX'
    ReinstallSource   = 'msstore'
    CloseAfterInstall = '*Copilot*'
    Detect            = {
        if (Test-AppxInstalled 'Microsoft.Copilot') { return $true }
        $keys = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
        return [bool](Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '^(Microsoft )?Copilot$' })
    }
    Apply             = {
        if (-not (Invoke-RemovalScript -FileName "Remove-Copilot.ps1")) { throw "Copilot is still installed after its uninstaller ran" }
    }
}
