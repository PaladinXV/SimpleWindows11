$MiscellaneousTweaks = @(
    @{
        Name        = 'Disable "Apps running in the background"'
        SubCategory = "Apps"
        Category    = "Miscellaneous"
        Description = "Prevents apps from running in the background. Can affect notifications/updates for some apps. This was changed in Windows 11 to individual toggles rather than a single one."
        SafetyLevel = "Advanced"
        Apply       = { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2 }
        Detect      = { Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2 }
        Revert      = { Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" }
    }
    @{
        Name        = 'Enable "Right-click classic context menu"'
        SubCategory = "Other"
        Category    = "Miscellaneous"
        Description = "Restores the old Windows right-click menu."
        SafetyLevel = "Safe"
        Apply       = {
            $keyPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
            if (-not (Test-Path $keyPath)) { New-Item -Path $keyPath -Force | Out-Null }
            Set-Item -Path $keyPath -Value "" -Force
        }
        Revert      = {
            Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Detect      = { Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" }
    }
    @{
        Name        = 'Enable "Clipboard History"'
        SubCategory = "Clipboard"
        Category    = "Miscellaneous"
        Description = "Enables Windows clipboard history."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Clipboard`" `"Clipboard history`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" 1 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" 1 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" }
    }
    @{
        Name        = 'Allow "Unsigned local PowerShell Scripts"'
        SubCategory = "Developer options"
        Category    = "Miscellaneous"
        Description = "Sets PowerShell execution policy to RemoteSigned. Local scripts run without signing. Remote scripts will still need signing."
        SafetyLevel = "Not Recommended"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Advanced`" `"PowerShell`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" "ExecutionPolicy" "RemoteSigned" "String" }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" "ExecutionPolicy" }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" "ExecutionPolicy" "RemoteSigned" }
    }
    @{
        Name        = 'Enable "End Task" in the Task bar'
        SubCategory = "Developer options"
        Category    = "Miscellaneous"
        Description = "Adds the `"End Task`" option to the taskbar right-click option."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Advanced`" `"End task`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" "TaskbarEndTask" 1 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" "TaskbarEndTask" 1 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" "TaskbarEndTask" }
    }
    @{
        Name        = 'Disable "Storage Sense"'
        SubCategory = "Storage"
        Category    = "Miscellaneous"
        Description = "Disable Storage Sense automatic disk cleanup."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Storage`" `"Storage Sense`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 0 }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 1 }
    }
    @{
        Name        = 'Disable "Snap Suggestions"'
        SubCategory = "Multitasking"
        Category    = "Miscellaneous"
        Description = "Disables 'When I snap a window, suggest what I can snap next to it'."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Multitasking`" -> `"Snap windows`" `"Show what I can snap next to it`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "SnapAssist" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "SnapAssist" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "SnapAssist" }
    }
    @{
        Name        = 'Disable "Snap Layouts Flyout"'
        SubCategory = "Multitasking"
        Category    = "Miscellaneous"
        Description = "Disables the layout picker that appears when hovering a window's maximize button."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Multitasking`" -> `"Snap windows`" `"Show snap layouts when I hover over a window's maximize button`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "EnableSnapAssistFlyout" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "EnableSnapAssistFlyout" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "EnableSnapAssistFlyout" }
    }
    @{
        Name        = 'Hide "App tabs when snapping/alt+tab"'
        SubCategory = "Multitasking"
        Category    = "Miscellaneous"
        Description = "Stops browser tabs from appearing individually when snapping windows or pressing Alt+Tab."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Multitasking`" `"Show tabs from apps when snapping or pressing Alt+Tab`""
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "MultiTaskingAltTabFilter" 3 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "MultiTaskingAltTabFilter" 3 }
        Revert      = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "MultiTaskingAltTabFilter" 2 }
    }
    @{
        Name        = 'Disable "Autoplay"'
        SubCategory = "AutoPlay"
        Category    = "Miscellaneous"
        Description = "Disables Autoplay for removable drives and media."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Bluetooth & devices`" -> `"AutoPlay`" `"Use AutoPlay for all media and devices`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" "DisableAutoplay" 1 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" "DisableAutoplay" 1 }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" "DisableAutoplay" 0 }
    }
    @{
        Name        = 'Disable "Resume"'
        SubCategory = "Apps"
        Category    = "Miscellaneous"
        Description = "Disables whether Windows can automatically resume apps and activities from your other devices."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Apps`" -> `"Resume`" `"Resume`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "IsEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "IsEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "IsEnabled" }
    }
    @{
        Name        = 'Hide "Security/Defender icon from startup/task bar"'
        SubCategory = "Startup apps"
        Category    = "Miscellaneous"
        Description = "Hides the Windows Security notification icon from appearing at startup (Security still runs, just no tray icon)."
        SafetyLevel = "Advanced"
        Location    = "Located in `"Settings`" -> `"Apps`" -> `"Startup`" `"Windows Security notification icon`""
        Apply       = { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" "SecurityHealth" ([byte[]](0x07,0x00,0x00,0x00,0x00,0xF8,0x77,0xD1,0xBF,0x8D,0xD8,0x01)) "Binary" }
        Revert      = { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" "SecurityHealth" ([byte[]](0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)) "Binary" }
        Detect      = {
            $prop = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "SecurityHealth" -ErrorAction SilentlyContinue
            if (-not $prop -or $prop.SecurityHealth.Count -eq 0) { return $false }
            ($prop.SecurityHealth[0] -band 1) -eq 1
        }
    }
    @{
        Name        = 'Enable "Old Windows Photo Viewer"'
        SubCategory = "Other"
        Description = "Enables the old Windows 7-style photo viewer. Some newer file types might not be supported."
        Location    = "After applying: right-click an image -> `"Open with`" -> `"Windows Photo Viewer`""
        Category    = "Miscellaneous"
        SafetyLevel = "Safe"
        Detect      = {
            Test-Path "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\command"
        }
        Apply       = {
            $app = "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll"
            $open = "$app\shell\open"
            New-Item -Path "$open\command" -Force | Out-Null
            New-Item -Path "$open\DropTarget" -Force | Out-Null
            Set-Reg $open "MuiVerb" "@photoviewer.dll,-3043" "String"
            New-ItemProperty -Path "$open\command" -Name "(Default)" `
                -Value "%SystemRoot%\System32\rundll32.exe `"%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll`", ImageView_Fullscreen %1" `
                -PropertyType ExpandString -Force | Out-Null
            Set-Reg "$open\DropTarget" "Clsid" "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" "String"

            $types = "$app\SupportedTypes"
            New-Item -Path $types -Force | Out-Null
            foreach ($ext in @(".jpg", ".jpeg", ".jpe", ".jfif", ".png", ".bmp", ".dib", ".gif", ".tif", ".tiff", ".wdp", ".jxr")) {
                Set-Reg $types $ext "" "String"
            }
        }
        Revert      = {
            Remove-Item -Path "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    @{
        Name        = 'Disable "Autocorrect misspelled words"'
        Category    = "Miscellaneous"
        SubCategory = "Typing"
        Description = "Stops Windows automatically correcting misspelled words as you type."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "Time & language" -> "Typing" "Autocorrect misspelled words"'
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\TabletTip\1.7" "EnableAutocorrection" 0
        }
        Revert      = {
            Remove-Reg "HKCU:\Software\Microsoft\TabletTip\1.7" "EnableAutocorrection"
        }
        Detect      = { (Test-RegValue "HKCU:\Software\Microsoft\TabletTip\1.7" "EnableAutocorrection" 0) }
    }
    @{
        Name        = 'Disable "Highlight misspelled words"'
        Category    = "Miscellaneous"
        SubCategory = "Typing"
        Description = "Stops Windows underlining misspelled words as you type."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "Time & language" -> "Typing" "Highlight misspelled words"'
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\TabletTip\1.7" "EnableSpellchecking" 0
        }
        Revert      = {
            Remove-Reg "HKCU:\Software\Microsoft\TabletTip\1.7" "EnableSpellchecking"
        }
        Detect      = { (Test-RegValue "HKCU:\Software\Microsoft\TabletTip\1.7" "EnableSpellchecking" 0) }
    }
    @{
        Name        = 'Disable "Typing insights"'
        Category    = "Miscellaneous"
        SubCategory = "Typing"
        Description = "Stops Windows collecting statistics about your typing, such as words autocompleted and corrected."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "Time & language" -> "Typing" "Typing insights"'
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Input\Settings" "InsightsEnabled" 0
        }
        Revert      = {
            Remove-Reg "HKCU:\Software\Microsoft\Input\Settings" "InsightsEnabled"
        }
        Detect      = { (Test-RegValue "HKCU:\Software\Microsoft\Input\Settings" "InsightsEnabled" 0) }
    }
    @{
        Name        = 'Disable "Consumer Features"'
        Category    = "Miscellaneous"
        SubCategory = "Apps"
        Description = "Stops Windows automatically installing suggested apps and games (such as Candy Crush) from the Store."
        SafetyLevel = "Safe"
        Location    = "Group Policy: Computer Configuration -> Administrative Templates -> Windows Components -> Cloud Content -> `"Turn off Microsoft consumer experiences`""
        Apply       = { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1 }
        Revert      = { Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" }
        Detect      = { Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1 }
    }
    @{
        Name        = 'Enable "Long file paths"'
        Category    = "Miscellaneous"
        SubCategory = "Developer options"
        Description = "Lets programs that support it use file paths longer than 260 characters. Useful for developers and deep folder structures."
        SafetyLevel = "Advanced"
        Location    = 'Located in "Settings" -> "System" -> "Advanced" "Enable long paths"'
        Apply       = { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1 }
        Revert      = { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 0 }
        Detect      = { Test-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1 }
    }
    @{
        Name        = 'Disable "Sticky Keys" shortcut'
        Category    = "Miscellaneous"
        SubCategory = "Accessibility"
        Description = "Disables sticky keys feature. On rare occasion, can activate during gaming if you press Shift a lot."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "Accessibility" -> "Keyboard" -> "Sticky keys" "Keyboard shortcut for Sticky keys"'
        Apply       = {
            Set-Reg "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "String"
        }
        Revert      = {
            Set-Reg "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "510" "String"
        }
        Detect      = {
            (Test-RegValue "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506")
        }
    }
    @{
        Name        = 'Disable "Recall"'
        Category    = "Miscellaneous"
        SubCategory = "Recall"
        Description = "Recall is only available on Copilot+ PCs. This setting will set the disable registry key anyway."
        SafetyLevel = "Safe"
        Location    = "Would normally be located in `"Settings`" -> `"Privacy & security`" -> `"Recall & snapshots`""
        Apply       = {
            Set-Reg "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "AllowRecallEnablement" 0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "TurnOffSavingSnapshots" 1
        }
        Revert      = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WindowsAI\DisableAIDataAnalysis" "value" 0
            Remove-Reg "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis"
            Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis"
            Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "AllowRecallEnablement"
            Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "TurnOffSavingSnapshots"
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1) -and
            (Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1) -and
            (Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "AllowRecallEnablement" 0) -and
            (Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "TurnOffSavingSnapshots" 1)
        }
    }
    @{
        Name        = "User Account Control"
        Category    = "Miscellaneous"
        SubCategory = "User Account Control"
        Type        = "Option"
        SafetyLevel = "Advanced"
        Description = "How Windows asks for permission when apps want to make changes that need administrator rights. Never notify me turns the prompts off but keeps User Account Control itself on."
        Location    = 'Located in "Control Panel" -> "User Accounts" -> "Change User Account Control settings"'
        Options     = @(
            @{ Label = "Always notify"; Apply = {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 2
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" 1
            } }
            @{ Label = "Notify me only when apps try to make changes to my computer (Default)"; Apply = {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 5
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" 1
            } }
            @{ Label = "Notify me only when apps try to make changes to my computer (do not dim my desktop)"; Apply = {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 5
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" 0
            } }
            @{ Label = "Never notify me"; Apply = {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 0
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" 0
            } }
        )
        DetectIndex = {
            $key = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ErrorAction SilentlyContinue
            if ($key -and $null -ne $key.EnableLUA -and $key.EnableLUA -eq 0) { return 0 }
            $consent = if ($key -and $null -ne $key.ConsentPromptBehaviorAdmin) { [int]$key.ConsentPromptBehaviorAdmin } else { 5 }
            $secure = if ($key -and $null -ne $key.PromptOnSecureDesktop) { [int]$key.PromptOnSecureDesktop } else { 1 }
            if ($consent -eq 2 -and $secure -eq 1) { return 1 }
            if ($consent -eq 5 -and $secure -eq 1) { return 2 }
            if ($consent -eq 5 -and $secure -eq 0) { return 3 }
            if ($consent -eq 0 -and $secure -eq 0) { return 4 }
            return 0
        }
    }
    @{
        Name        = 'Disable "Animation effects"'
        SubCategory = "Animations"
        Category    = "Miscellaneous"
        Description = "Disables various Windows animations. 'System properties -> Performance' is not changed"
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Accessibility`" -> `"Visual effects`" `"Animation effects`""
        Apply       = {
            Set-Reg "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x92,0x07,0x80,0x10,0x00,0x00,0x00)) "Binary"
            Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
        }
        Revert      = {
            Remove-Reg "HKCU:\Control Panel\Desktop" "UserPreferencesMask"
            Remove-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate"
        }
        Detect      = {
            $prop = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -ErrorAction SilentlyContinue
            if (-not $prop) { return $false }
            $bytes = $prop.UserPreferencesMask
            ($bytes.Count -ge 2 -and $bytes[0] -eq 0x90 -and $bytes[1] -eq 0x92) -and
            (Test-RegValue "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0")
        }
    }
    @{
        Name        = "Mouse Menu Delay"
        SubCategory = "Animations"
        Category    = "Miscellaneous"
        Type        = "Option"
        Description = "How long Windows waits before opening a menu. Lower feels faster/snappier."
        Location    = "Registry: `"HKEY_CURRENT_USER\Control Panel\Desktop`" -> `"MenuShowDelay`""
        SafetyLevel = "Safe"
        Options     = @(
            @{ Label = "0ms";             Apply = { Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String" } }
            @{ Label = "100ms";           Apply = { Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "100" "String" } }
            @{ Label = "200ms";           Apply = { Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "200" "String" } }
            @{ Label = "300ms";           Apply = { Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "300" "String" } }
            @{ Label = "400ms (Default)"; Apply = { Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "400" "String" } }
        )
        DetectIndex = {
            $v = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -ErrorAction SilentlyContinue).MenuShowDelay
            if ($null -eq $v) { return 5 }
            switch ("$v") { "0" { return 1 } "100" { return 2 } "200" { return 3 } "300" { return 4 } "400" { return 5 } default { return 0 } }
        }
    }
)
