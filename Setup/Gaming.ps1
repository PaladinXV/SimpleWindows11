$GamingTweaks = @(
    @{
        Name        = 'Disable "Xbox Mode"'
        SubCategory = "Other"
        Category    = "Gaming"
        Description = "Disables Xbox Full Screen Experience mode."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Gaming`" -> `"Full screen experience`" `"Choose home app`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\GamingConfiguration" "GamingHomeApp" "" "String" }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\GamingConfiguration" "GamingHomeApp" "Microsoft.GamingApp_8wekyb3d8bbwe!Microsoft.Xbox.App" "String" }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\GamingConfiguration" "GamingHomeApp" "" }
    }
    @{
        Name        = 'Disable "Controller guide button"'
        SubCategory = "Game Bar"
        Category    = "Gaming"
        Description = "Disables using View+Menu as Guide buttons in games without native controller support."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Gaming`" -> `"Game Bar`" `"Allow your controller to open Game Bar`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\GameBar" "GamepadNexusChordEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\GameBar" "GamepadNexusChordEnabled" }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\GameBar" "GamepadNexusChordEnabled" 0 }
    }
    @{
        Name        = 'Disable "Controller opening Game Bar"'
        SubCategory = "Game Bar"
        Category    = "Gaming"
        Description = "Disables `"Allow your controller to open Game Bar`"."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Gaming`" -> `"Game Bar`" `"Allow your controller to open Game Bar`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\GameBar" "UseNexusForGameBarEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\GameBar" "UseNexusForGameBarEnabled" }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\GameBar" "UseNexusForGameBarEnabled" 0 }
    }
    @{
        Name        = 'Disable "Game Mode"'
        SubCategory = "Game Mode"
        Category    = "Gaming"
        Description = "Disables Windows Game Mode. Not recommended as it has various optimizations for gaming, such as higher CPU/GPU resource priority, limiting Windows background activity, OBS optimizations."
        SafetyLevel = "Not Recommended"
        Location    = "Located in `"Settings`" -> `"Gaming`" -> `"Game Mode`" `"Game Mode`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0 }
    }
)
