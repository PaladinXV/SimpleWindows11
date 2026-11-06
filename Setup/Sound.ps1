$SoundTweaks = @(
    @{
        Name        = 'Set "Communication Volume - Do Nothing"'
        SubCategory = "Sound"
        Category    = "Miscellaneous"
        Description = "Stops Windows from lowering sound in apps during phone calls."
        SafetyLevel = "Safe"
        Location    = "Located in `"Control Panel`" -> `"Sound`" -> `"Communications`" `"Do nothing`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Multimedia\Audio" "UserDuckingPreference" 3 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Multimedia\Audio" "UserDuckingPreference" }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Multimedia\Audio" "UserDuckingPreference" 3 }
    }
)
