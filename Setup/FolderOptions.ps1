$FolderOptionsTweaks = @(
    @{
        Name        = 'Launch File Explorer to "This PC"'
        SubCategory = "File Explorer Options"
        Category    = "Folder Options"
        Description = "Launches File Explorer to open `"This PC`" rather than `"Home`"."
        SafetyLevel = "Safe"
        Location    = "Located in `"File Explorer Options`" -> `"General`" `"Open File Explorer to:`""
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1 }
        Revert      = { Remove-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" }
    }
    @{
        Name        = 'Disable "Show recently used files"'
        SubCategory = "File Explorer Options"
        Category    = "Folder Options"
        Description = "Disables recently used files from showing in the File Explorer."
        SafetyLevel = "Safe"
        Location    = "Located in `"File Explorer Options`" -> `"General`" `"Show recently used files`""
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0 }
        Revert      = { Remove-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" }
    }
    @{
        Name        = 'Disable "Show frequently used folders"'
        SubCategory = "File Explorer Options"
        Category    = "Folder Options"
        Description = "Disables frequently used folders from showing in the File Explorer."
        SafetyLevel = "Safe"
        Location    = "Located in `"File Explorer Options`" -> `"General`" `"Show frequently used folders`""
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 0 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 0 }
        Revert      = { Remove-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" }
    }
    @{
        Name        = 'Disable "Show Cloud files in File Explorer"'
        SubCategory = "File Explorer Options"
        Category    = "Folder Options"
        Description = "Disables cloud files from your Microsoft account (Office.com and OneDrive) showing in File Explorer."
        SafetyLevel = "Safe"
        Location    = "Located in `"File Explorer Options`" -> `"General`" `"Include account-based insights, recent, favorite and recommended files`". On older versions of Windows 11 this is named `"Show files from Office.com`"."
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowCloudFilesInQuickAccess" 0 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowCloudFilesInQuickAccess" 0 }
        Revert      = { Remove-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowCloudFilesInQuickAccess" }
    }
    @{
        Name        = 'Enable "Show File Extensions"'
        SubCategory = "File Explorer Options"
        Category    = "Folder Options"
        Description = "Shows file extensions (ie .exe, .mp3, .txt, .ps1)."
        SafetyLevel = "Safe"
        Location    = "Located in `"File Explorer Options`" -> `"View`" `"Hide extensions for known file types`" (unticked)"
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 }
        Revert      = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 1 }
    }
    @{
        Name        = 'Enable "File Explorer Compact Mode"'
        SubCategory = "File Explorer"
        Category    = "Folder Options"
        Description = "Enables the Windows 11 `"Compact Mode`" in File Explorer. Padding between items will be smaller."
        SafetyLevel = "Safe"
        Location    = "Located in `"File Explorer`" -> `"View`" -> `"Show`" -> `"Compact view`""
        Apply       = { Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "UseCompactMode" 1 }
        Detect      = { Test-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "UseCompactMode" 1 }
        Revert      = { Remove-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "UseCompactMode" }
    }
    @{
        Name        = 'Show "More Details" during "File Transfer"'
        SubCategory = "File Transfer"
        Category    = "Folder Options"
        Description = "Enables the `"More Details`" option in the pop-up when transferring files. This shows transfer speeds and an animated graph."
        SafetyLevel = "Safe"
        Location    = "Located when transferring files under `"More Details`" on the pop-up"
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" "EnthusiastMode" 1 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" "EnthusiastMode" 1 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" "EnthusiastMode" }
    }
    @{
        Name        = 'Enable "Show hidden files"'
        Category    = "Folder Options"
        SubCategory = "File Explorer Options"
        Description = "Shows hidden files, folders and drives in File Explorer."
        SafetyLevel = "Advanced"
        Location    = 'Located in "File Explorer Options" -> "View" "Hidden files and folders" -> "Show hidden files, folders, and drives"'
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1
        }
        Revert      = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 2
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1)
        }
    }
)
