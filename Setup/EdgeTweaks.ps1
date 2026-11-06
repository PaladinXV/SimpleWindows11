$EdgeTweaks = @(
    @{
        Name        = 'Disable "Background Mode"'
        Category    = "Microsoft Edge"
        Description = "Stops Edge from running in the background, even when closed. If Edge is uninstalled, these keys are still applied if you reinstall."
        SafetyLevel = "Safe"
        Location    = "Located in `"Microsoft Edge`" -> `"Settings`" -> `"System and performance`" `"Continue running background extensions and apps when Microsoft Edge is closed`""
        Apply       = { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" 0 }
        Revert      = { Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" }
        Detect      = { Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" 0 }
    }
    @{
        Name        = 'Disable "Startup Boost"'
        Category    = "Microsoft Edge"
        Description = "Stops Edge from pre-loading itself at Windows startup for faster launch times. If Edge is uninstalled, these keys are still applied if you reinstall."
        SafetyLevel = "Safe"
        Location    = "Located in `"Microsoft Edge`" -> `"Settings`" -> `"System and performance`" `"Startup boost`""
        Apply       = { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" 0 }
        Revert      = { Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" }
        Detect      = { Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" 0 }
    }
    @{
        Name        = 'Hide "Edge first run experience"'
        Category    = "Microsoft Edge"
        Description = "Skips Edge's first-run welcome/setup screen. If Edge is uninstalled, these keys are still applied if you reinstall."
        SafetyLevel = "Safe"
        Apply       = { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "HideFirstRunExperience" 1 }
        Revert      = { Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "HideFirstRunExperience" }
        Detect      = { Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "HideFirstRunExperience" 1 }
    }
)
