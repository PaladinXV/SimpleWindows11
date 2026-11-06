$TaskbarSettingsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"

function Set-TaskbarSettingsByte {
    param([int]$Index, [byte]$Value)
    $bytes = (Get-ItemProperty -Path $TaskbarSettingsKey -Name "Settings" -ErrorAction SilentlyContinue).Settings
    if (-not $bytes -or $bytes.Count -le $Index) { throw "The taskbar settings weren't found. Sign out and back in, then try again." }
    $bytes[$Index] = $Value
    Set-Reg $TaskbarSettingsKey "Settings" ([byte[]]$bytes) "Binary"
}

function Get-TaskbarSettingsByte {
    param([int]$Index)
    $bytes = (Get-ItemProperty -Path $TaskbarSettingsKey -Name "Settings" -ErrorAction SilentlyContinue).Settings
    if (-not $bytes -or $bytes.Count -le $Index) { return $null }
    return $bytes[$Index]
}

$TaskbarTweaks = @(
    @{
        Name        = 'Hide "Task view button"'
        SubCategory = "Taskbar items"
        Category    = "Taskbar"
        Description = "Removes the Task View button from the taskbar."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Taskbar`" -> `"Taskbar items`" `"Task view`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" }
    }
    @{
        Name        = 'Enable "Never combine icons and labels"'
        SubCategory = "Taskbar behaviors"
        Category    = "Taskbar"
        Description = "Shows separate taskbar buttons with both icons and labels instead of combining them into a single button."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Taskbar`" -> `"Taskbar behaviors`" `"Combine taskbar buttons and hide labels`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarGlomLevel" 2 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarGlomLevel" 2 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarGlomLevel" }
    }
    @{
        Name        = 'Enable "Automatically hide the taskbar"'
        SubCategory = "Taskbar behaviors"
        Category    = "Taskbar"
        Description = "Hides the taskbar."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Taskbar`" -> `"Taskbar behaviors`" `"Automatically hide the taskbar`""
        Apply       = { Set-TaskbarSettingsByte -Index 8 -Value 3 }
        Revert      = { Set-TaskbarSettingsByte -Index 8 -Value 2 }
        Detect      = { (Get-TaskbarSettingsByte -Index 8) -eq 3 }
    }
    @{
        Name        = "Task bar Icon alignment"
        SubCategory = "Taskbar behaviors"
        Category    = "Taskbar"
        Type        = "Option"
        Description = "Choose where the task bar icons align (Center (Default), Left (Classic))."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Taskbar`" -> `"Taskbar behaviors`" `"Taskbar alignment`""
        Options     = @(
            @{ Label = "Center (Default)"; Apply = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 1 } }
            @{ Label = "Left (Classic)";    Apply = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0 } }
        )
        DetectIndex = {
            $prop = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -ErrorAction SilentlyContinue
            if (-not $prop) { return 1 }
            switch ($prop.TaskbarAl) {
                1 { return 1 }; 0 { return 2 }
                default { return 0 }
            }
        }
    }
    @{
        Name        = "Taskbar Search Box"
        SubCategory = "Taskbar items"
        Category    = "Taskbar"
        Type        = "Option"
        Description = "Choose how the search box appears on the taskbar."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Taskbar`" -> `"Taskbar items`" `"Search`""
        Options     = @(
            @{ Label = "Search Box (Default)"; Apply = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 2 } }
            @{ Label = "Icon Only";             Apply = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1 } }
            @{ Label = "Hidden";                Apply = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0 } }
        )
        DetectIndex = {
            $prop = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -ErrorAction SilentlyContinue
            if (-not $prop) { return 1 }
            switch ($prop.SearchboxTaskbarMode) {
                2 { return 1 }; 1 { return 2 }; 0 { return 3 }
                default { return 0 }
            }
        }
    }
    @{
        Name        = 'Disable "Widgets"'
        SubCategory = "Taskbar items"
        Category    = "Taskbar"
        Description = "Disables Widgets on the taskbar and sets `"Lock screen weather and more`" to `"None`"."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Taskbar`" -> `"Taskbar items`" `"Widgets`""
        Apply       = { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0 }
        Detect      = { Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0 }
        Revert      = { Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" }
    }
)
