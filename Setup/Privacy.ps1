$PrivacyTweaks = @(
    @{
        Name        = 'Disable "Personalized offers"'
        Category    = "Privacy & Security"
        SubCategory = "Recommendations & offers"
        Description = "Stops Microsoft using your diagnostic data to show you personalized tips, ads and recommendations."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Recommendations & offers -> `"Personalized offers`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0 }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 1 }
    }
    @{
        Name        = 'Disable "Allow websites to access my language list"'
        Category    = "Privacy & Security"
        SubCategory = "Recommendations & offers"
        Description = "Stops websites reading your Windows language list to decide what content to show you."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Recommendations & offers -> `"Allow websites to access my language list`""
        Apply       = { Set-Reg "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" 1 }
        Detect      = { Test-RegValue "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" 1 }
        Revert      = { Remove-Reg "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" }
    }
    @{
        Name        = 'Disable "Improve Start and search results"'
        Category    = "Privacy & Security"
        SubCategory = "Recommendations & offers"
        Description = "Stops Windows tracking which apps you open to personalize Start and search results. This also greys out `"Show most used apps`" in Start settings, as that list depends on this tracking."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Recommendations & offers -> `"Improve Start and search results`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" }
    }
    @{
        Name        = 'Disable "Recommendations and offers in Settings"'
        Category    = "Privacy & Security"
        SubCategory = "Recommendations & offers"
        Description = "Stops suggested content and offers appearing in the Settings app."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Recommendations & offers -> `"Recommendations and offers in Settings`""
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled" 0
        }
        Revert      = {
            Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled"
            Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled"
            Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled"
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" 0) -and
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" 0) -and
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled" 0)
        }
    }
    @{
        Name        = 'Disable "Advertising ID"'
        Category    = "Privacy & Security"
        SubCategory = "Recommendations & offers"
        Description = "Turns off your advertising ID, which apps use to show you personalized ads. Your existing ID is cleared too."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Recommendations & offers -> `"Advertising ID`""
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
            Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "ID"
        }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 1 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 }
    }
    @{
        Name        = 'Disable "Custom inking and typing dictionary"'
        Category    = "Privacy & Security"
        SubCategory = "Inking & typing personalization"
        Description = "Stops Windows building a personal dictionary from your handwriting and typing to improve suggestions."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Inking & typing personalization -> `"Custom inking and typing dictionary`""
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization" "Value" 0
            Set-Reg "HKCU:\Software\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" 0
            Set-Reg "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
            Set-Reg "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
            Set-Reg "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0
        }
        Revert      = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization" "Value" 1
            Set-Reg "HKCU:\Software\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" 1
            Set-Reg "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 0
            Set-Reg "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 0
            Set-Reg "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 1
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization" "Value" 0) -and
            (Test-RegValue "HKCU:\Software\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" 0) -and
            (Test-RegValue "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1) -and
            (Test-RegValue "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1) -and
            (Test-RegValue "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0)
        }
    }
    @{
        Name        = 'Disable "Send optional diagnostic data" (Telemetry)'
        Category    = "Privacy & Security"
        SubCategory = "Diagnostics & feedback"
        Description = "Limits the diagnostic data sent to Microsoft to the required minimum."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Diagnostics & feedback -> `"Diagnostic data`" -> `"Send optional diagnostic data`""
        Apply       = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 1
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "MaxTelemetryAllowed" 1
        }
        Revert      = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 3
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "MaxTelemetryAllowed" 3
        }
        Detect      = {
            (Test-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 1) -and
            (Test-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "MaxTelemetryAllowed" 1)
        }
    }
    @{
        Name        = 'Disable "Improve inking and typing"'
        Category    = "Privacy & Security"
        SubCategory = "Diagnostics & feedback"
        Description = "Stops Windows sending your inking and typing data to Microsoft to improve recognition and suggestions."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Diagnostics & feedback -> `"Improve inking and typing`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Input\TIPC" "Enabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Input\TIPC" "Enabled" 0 }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Input\TIPC" "Enabled" 1 }
    }
    @{
        Name        = "Feedback Frequency"
        Category    = "Privacy & Security"
        SubCategory = "Diagnostics & feedback"
        Type        = "Option"
        Description = "How often Windows asks for your feedback. Never stops the feedback prompts."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Diagnostics & feedback -> `"Feedback`" -> `"Feedback frequency`""
        Options     = @(
            @{ Label = "Automatically (Default)"; Apply = { Remove-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" } }
            @{ Label = "Never (Recommended)"; Apply = {
                Set-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
                Remove-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "PeriodInNanoSeconds"
            } }
        )
        DefaultIndex = 1
        DetectIndex = {
            if (Test-RegValue "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0) { return 2 }
            return 1
        }
    }
    @{
        Name        = 'Disable "Search history"'
        Category    = "Privacy & Security"
        SubCategory = "Search"
        Description = "Stops Windows Search keeping a history of your searches on this device."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Search -> `"Search history`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" }
    }
    @{
        Name        = 'Disable "Show search highlights"'
        Category    = "Privacy & Security"
        SubCategory = "Search"
        Description = "Removes the Trend/Theme in the search bar."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Search -> `"Show search highlights`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDynamicSearchBoxEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDynamicSearchBoxEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDynamicSearchBoxEnabled" }
    }
    @{
        Name        = 'Disable "Search my accounts - Microsoft account"'
        Category    = "Privacy & Security"
        SubCategory = "Search"
        Description = "Stops Windows Search including results from your personal Microsoft account, such as OneDrive and Outlook.com."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Search -> `"Search my accounts`" -> `"Microsoft account`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsMSACloudSearchEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsMSACloudSearchEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsMSACloudSearchEnabled" }
    }
    @{
        Name        = 'Disable "Search my accounts - Work or School account"'
        Category    = "Privacy & Security"
        SubCategory = "Search"
        Description = "Stops Windows Search including results from a work or school account, such as OneDrive for Business, SharePoint and Outlook."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Search -> `"Search my accounts`" -> `"Work or School account`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsAADCloudSearchEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsAADCloudSearchEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsAADCloudSearchEnabled" }
    }
    @{
        Name        = "Find my files"
        Category    = "Privacy & Security"
        SubCategory = "Search"
        Type        = "Option"
        Description = "Enhanced will search a larger amount of files and folders. This will increase CPU power draw and disk usage."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Searching Windows -> `"Find my files`""
        Options     = @(
            @{ Label = "Classic (Default)"; Apply = { Remove-Reg "HKLM:\SOFTWARE\Microsoft\Windows Search" "EnableFindMyFiles" } }
            @{ Label = "Enhanced";              Apply = { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows Search" "EnableFindMyFiles" 1 } }
        )
        DefaultIndex = 1
        DetectIndex = {
            if (Test-RegValue "HKLM:\SOFTWARE\Microsoft\Windows Search" "EnableFindMyFiles" 1) { return 2 }
            return 1
        }
    }
    @{
        Name        = 'Disable "Share across devices"'
        Category    = "Privacy & Security"
        SubCategory = "Other"
        Description = "Stops apps on other devices signed in to your Microsoft account opening apps and sending messages on this PC."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Apps`" -> `"Advanced app settings`" `"Share across devices`""
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "RomeSdkChannelUserAuthzPolicy" 0
        }
        Revert      = {
            Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy"
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "RomeSdkChannelUserAuthzPolicy" 1
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 0) -and
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "RomeSdkChannelUserAuthzPolicy" 0)
        }
    }
    @{
        Name        = 'Disable "Cross-device resume"'
        Category    = "Privacy & Security"
        SubCategory = "Other"
        Description = "Stops Windows from offering to continue on this PC what you were doing on your phone."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Apps`" -> `"Resume`" `"Resume`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" "IsResumeAllowed" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" "IsResumeAllowed" 0 }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" "IsResumeAllowed" 1 }
    }
)
