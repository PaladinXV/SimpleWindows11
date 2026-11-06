$MouseTweaks = @(
    @{
        Name        = 'Disable "Mouse acceleration"'
        SubCategory = "Mouse"
        Category    = "Miscellaneous"
        Description = "Disables `"Enhanced Pointer Precision`", also known as mouse acceleration."
        SafetyLevel = "Safe"
        Location    = "Located in `"Control Panel`" -> `"Mouse`" -> `"Pointer Options`" `"Enhance pointer precision`""
        Apply       = {
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"
        }
        Revert      = {
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed" "1" "String"
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" "6" "String"
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" "10" "String"
        }
        Detect      = {
            (Test-RegValue "HKCU:\Control Panel\Mouse" "MouseSpeed" "0") -and
            (Test-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0") -and
            (Test-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0")
        }
    }
)
