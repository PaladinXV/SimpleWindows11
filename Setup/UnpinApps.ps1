$UnpinTweaks = @(
    @{
        Name        = "Clear Start Menu Apps"
        Category    = "Unpin apps"
        SafetyLevel = "Safe"
        RunLast     = $true
        Apply       = {
            if (-not (Invoke-RemovalScript -FileName "Clear-StartMenuPins.ps1" -Folder "Setup")) { throw "Could not clear Start menu pins." }
        }
    }
    @{
        Name        = "Clear Task Bar Apps"
        Category    = "Unpin apps"
        SafetyLevel = "Safe"
        RunLast     = $true
        Apply       = {
            if (-not (Invoke-RemovalScript -FileName "Clear-TaskbarPins.ps1" -Folder "Setup")) { throw "Could not clear taskbar pins." }
        }
    }
)
