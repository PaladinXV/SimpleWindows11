$NotificationsTweaks = @(
    @{
        Name        = 'Disable "Notifications"'
        SubCategory = "System"
        Category    = "Notifications"
        Description = "Turns off Windows notifications entirely."
        SafetyLevel = "Advanced"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Notifications`" `"Notifications`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0 }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 1 }
    }
    @{
        Name        = 'Disable "Windows Tips & Suggestions"'
        SubCategory = "System"
        Category    = "Notifications"
        Description = "Disables 'Get tips and suggestions when using Windows'."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Notifications`" -> `"Additional settings`" `"Get tips and suggestions when using Windows`""
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0 }
        Revert      = { Remove-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" }
    }
    @{
        Name        = 'Disable "Finish setting up this device"'
        SubCategory = "System"
        Category    = "Notifications"
        Description = "Disables 'Suggest ways to get the most out of Windows and finish setting up this device'."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Notifications`" -> `"Additional settings`" `"Suggest ways to finish setting up my device to get the most out of Windows`""
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" }
    }
    @{
        Name        = 'Disable "Show account-related notifications"'
        Category    = "Notifications"
        SubCategory = "System"
        Description = "Stops Windows putting a notification badge on your account in Start, with prompts such as OneDrive backup and Microsoft account reminders."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "Personalization" -> "Start" "Show account-related notifications"'
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_AccountNotifications" 0
        }
        Revert      = {
            Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_AccountNotifications"
        }
        Detect      = { (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_AccountNotifications" 0) }
    }
    @{
        Name        = 'Disable "Notification Sounds"'
        SubCategory = "System"
        Category    = "Notifications"
        Description = "Mutes the sound that plays with notifications."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Notifications`" `"Allow notifications to play sounds`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" }
    }
    @{
        Name        = 'Disable "Notifications on the lock screen"'
        SubCategory = "Lock screen"
        Category    = "Notifications"
        Description = "Hides notification content on the lock screen."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Notifications`" `"Show notifications on the lock screen`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" }
    }
    @{
        Name        = 'Disable "VOIP/Reminders on the lock screen"'
        SubCategory = "Lock screen"
        Category    = "Notifications"
        Description = "Hides reminders and incoming VOIP calls on the lock screen."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Notifications`" `"Show reminders and incoming VoIP calls on the lock screen`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" }
    }
    @{
        Name        = 'Disable "Show Notifications in Settings"'
        Category    = "Notifications"
        SubCategory = "Privacy & security"
        Description = "Stops account reminders and suggestion notifications appearing inside the Settings app."
        SafetyLevel = "Safe"
        Location    = "Located in Settings -> Privacy & security -> Recommendations & offers -> `"Show notifications in Settings`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" "EnableAccountNotifications" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" "EnableAccountNotifications" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" "EnableAccountNotifications" }
    }
)
