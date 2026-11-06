$WindowsUpdatePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

function New-UpdateDelayOptions {
    param([string]$Kind, [int[]]$DayList, [int]$RecommendedDays)
    @{ Label = "Not delayed (Default)"; Apply = {
        Remove-Reg $WindowsUpdatePolicy "Defer$($Kind)Updates"
        Remove-Reg $WindowsUpdatePolicy "Defer$($Kind)UpdatesPeriodInDays"
    }.GetNewClosure() }
    foreach ($d in $DayList) {
        $label = if ($d -eq 1) { "1 day" } else { "$d days" }
        if ($d -eq $RecommendedDays) { $label += " (Recommended)" }
        @{ Label = $label; Apply = {
            Set-Reg $WindowsUpdatePolicy "Defer$($Kind)Updates" 1
            Set-Reg $WindowsUpdatePolicy "Defer$($Kind)UpdatesPeriodInDays" $d
        }.GetNewClosure() }
    }
}

function Get-UpdateDelayIndex {
    param([string]$Kind, [int[]]$DayList)
    if (-not (Test-RegValue $WindowsUpdatePolicy "Defer$($Kind)Updates" 1)) { return 1 }
    $days = (Get-ItemProperty -Path $WindowsUpdatePolicy -Name "Defer$($Kind)UpdatesPeriodInDays" -ErrorAction SilentlyContinue)."Defer$($Kind)UpdatesPeriodInDays"
    if ($null -eq $days) { return 1 }
    $i = [array]::IndexOf($DayList, [int]$days)
    if ($i -ge 0) { return $i + 2 }
    return 0
}

$FeatureDelayDays = @(7, 14, 30, 90, 180, 365)
$QualityDelayDays = @(1, 4, 7, 14)

$WindowsUpdateTweaks = @(
    @{
        Name        = "Delay Feature Updates"
        SubCategory = "Windows Update"
        Category    = "Windows Updates"
        Type        = "Option"
        Description = "Delays the yearly feature updates (ie 25H2 to 26H2) by the amount of time selected. Generally recommended as you can avoid any major bugs or instability, while still receiving security updates."
        SafetyLevel = "Advanced"
        Location    = "Group Policy: Computer Configuration -> Administrative Templates -> Windows Components -> Windows Update -> Manage updates offered from Windows Update -> `"Select when Preview Builds and Feature Updates are received`""
        Options     = @(New-UpdateDelayOptions -Kind "Feature" -DayList $FeatureDelayDays -RecommendedDays 90)
        DetectIndex = { Get-UpdateDelayIndex -Kind "Feature" -DayList $FeatureDelayDays }
    }
    @{
        Name        = "Delay Security Updates"
        SubCategory = "Windows Update"
        Category    = "Windows Updates"
        Type        = "Option"
        Description = "Delays security updates by the amount of time selected. This can help avoid bugs or instability."
        SafetyLevel = "Advanced"
        Location    = "Group Policy: Computer Configuration -> Administrative Templates -> Windows Components -> Windows Update -> Manage updates offered from Windows Update -> `"Select when Quality Updates are received`""
        Options     = @(New-UpdateDelayOptions -Kind "Quality" -DayList $QualityDelayDays -RecommendedDays 4)
        DetectIndex = { Get-UpdateDelayIndex -Kind "Quality" -DayList $QualityDelayDays }
    }
    @{
        Name        = 'Disable "Delivery Optimization"'
        SubCategory = "Delivery Optimization"
        Category    = "Windows Updates"
        Description = "Disables Delivery Optimization (peer-to-peer update sharing across your network/internet)."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Windows Update`" -> `"Advanced options`" -> `"Delivery Optimization`" `"Allow downloads from other devices`""
        Apply       = { Set-Reg "Registry::HKEY_USERS\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" "DownloadMode" 0 }
        Revert      = { Set-Reg "Registry::HKEY_USERS\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" "DownloadMode" 1 }
        Detect      = { Test-RegValue "Registry::HKEY_USERS\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" "DownloadMode" 0 }
    }
    @{
        Name        = "Device metadata downloads (Beta)"
        SubCategory = "Device installation"
        Category    = "Windows Updates"
        Type        = "Option"
        Description = "Whether Windows will download manufacturers' apps or custom icons for your devices (ie Razer Synapse, LG Software etc)."
        SafetyLevel = "Advanced"
        Location    = 'Located in "Control Panel" -> "System" -> "Advanced system settings" -> "Hardware" -> "Device Installation Settings"'
        Options     = @(
            @{ Label = "Disabled"; Apply = {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" "PreventDeviceMetadataFromNetwork" 1
                Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" "PreventDeviceMetadataFromNetwork" 1
            } }
            @{ Label = "Enabled (Default)"; Apply = {
                Remove-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" "PreventDeviceMetadataFromNetwork"
                Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" "PreventDeviceMetadataFromNetwork"
            } }
        )
        DetectIndex = {
            if (Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" "PreventDeviceMetadataFromNetwork" 1) { return 1 }
            return 2
        }
    }
    @{
        Name        = "Update drivers via Windows Update (Beta)"
        SubCategory = "Device installation"
        Category    = "Windows Updates"
        Type        = "Option"
        Description = "Whether Windows downloads manufacturer drivers from Windows Update. Can be useful if Windows downloads older versions of drivers or a bad driver version."
        SafetyLevel = "Advanced"
        Location    = 'Located in "Control Panel" -> "System" -> "Advanced system settings" -> "Hardware" -> "Device Installation Settings"'
        Options     = @(
            @{ Label = "Disabled"; Apply = {
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 0
                Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "DontSearchWindowsUpdate" 1
                Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" "SearchOrderConfig" 0
                Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" "DontSearchWindowsUpdate" 1
            } }
            @{ Label = "Enabled (Default)"; Apply = {
                Remove-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig"
                Remove-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "DontSearchWindowsUpdate"
                Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" "SearchOrderConfig"
                Remove-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" "DontSearchWindowsUpdate"
            } }
        )
        DetectIndex = {
            if (Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" "DontSearchWindowsUpdate" 1) { return 1 }
            return 2
        }
    }
)
