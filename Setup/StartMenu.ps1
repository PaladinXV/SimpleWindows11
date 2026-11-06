$StartMenuTweaks = @(
    @{
        Name        = 'Disable "Show recently added apps in Start"'
        SubCategory = "Start"
        Category    = "Start Menu"
        Description = "Prevents the Start Menu from showing recently added/installed apps"
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Start`" `"Show recently added apps`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" "ShowRecentList" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" "ShowRecentList" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" "ShowRecentList" }
    }
    @{
        Name        = 'Disable "Show recently used files in the Start Menu"'
        SubCategory = "Start"
        Category    = "Start Menu"
        Description = "Disables recommended/recent files shown in Start, File Explorer, and Jump Lists"
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Start`" `"Show recommended files in Start, recent files in File Explorer, and items in Jump Lists`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" }
    }
    @{
        Name        = 'Disable "Recommended section"'
        SubCategory = "Start"
        Category    = "Start Menu"
        Description = "Disables 'Show recommendations for tips, shortcuts, new apps, and more' in Start"
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Start`" `"Show recommendations for tips, shortcuts, new apps, and more`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" }
    }
    @{
        Name        = "All Apps View"
        SubCategory = "All apps"
        Category    = "Start Menu"
        Type        = "Option"
        Description = "Select which apps view is used in the Start Menu."
        SafetyLevel = "Safe"
        Location    = "Located in the Start Menu -> `"All`" -> `"View`""
        Options     = @(
            @{ Label = "Category (Default)"; Apply = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" "AllAppsViewMode" 0 } }
            @{ Label = "Grid";     Apply = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" "AllAppsViewMode" 1 } }
            @{ Label = "List";     Apply = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" "AllAppsViewMode" 2 } }
        )
        DetectIndex = {
            $prop = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name "AllAppsViewMode" -ErrorAction SilentlyContinue
            if (-not $prop) { return 1 }
            switch ($prop.AllAppsViewMode) {
                0 { return 1 }; 1 { return 2 }; 2 { return 3 }
                default { return 0 }
            }
        }
    }
    @{
        Name        = 'Disable "Bing Search in the Start Menu"'
        Category    = "Start Menu"
        SubCategory = "Search"
        Description = "Stops the start menu search from searching with Bing."
        SafetyLevel = "Safe"
        Apply       = {
            Set-Reg "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "CortanaConsent" 0
        }
        Revert      = {
            Set-Reg "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 0
            Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"
            Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "CortanaConsent"
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1) -and
            (Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0) -and
            (Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "CortanaConsent" 0)
        }
    }
)
