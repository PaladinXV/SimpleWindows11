function Initialize-PowerModeApi {
    if ('SimpleWindowsSetup.PowerMode' -as [type]) { return }
    Add-Type -Namespace SimpleWindowsSetup -Name PowerMode -MemberDefinition @"
[DllImport("powrprof.dll")] public static extern uint PowerSetUserConfiguredACPowerMode(ref Guid mode);
[DllImport("powrprof.dll")] public static extern uint PowerSetUserConfiguredDCPowerMode(ref Guid mode);
[DllImport("powrprof.dll")] public static extern uint PowerGetUserConfiguredACPowerMode(out Guid mode);
[DllImport("powrprof.dll")] public static extern uint PowerGetUserConfiguredDCPowerMode(out Guid mode);
"@
}

function Set-PowerMode {
    param([string]$Source, [string]$Guid)
    Initialize-PowerModeApi
    $mode = [Guid]$Guid
    $result = if ($Source -eq "AC") { [SimpleWindowsSetup.PowerMode]::PowerSetUserConfiguredACPowerMode([ref]$mode) }
              else { [SimpleWindowsSetup.PowerMode]::PowerSetUserConfiguredDCPowerMode([ref]$mode) }
    if ($result -ne 0) { throw "Windows didn't accept the power mode (error $result)." }
}

function Get-PowerModeIndex {
    param([string]$Source)
    try {
        Initialize-PowerModeApi
        $mode = [Guid]::Empty
        $result = if ($Source -eq "AC") { [SimpleWindowsSetup.PowerMode]::PowerGetUserConfiguredACPowerMode([ref]$mode) }
                  else { [SimpleWindowsSetup.PowerMode]::PowerGetUserConfiguredDCPowerMode([ref]$mode) }
        if ($result -ne 0) { return 0 }
    } catch { return 0 }
    switch ($mode.ToString()) {
        "00000000-0000-0000-0000-000000000000" { return 1 }
        "961cc777-2547-4f9d-8174-7d86181b8a7a" { return 2 }
        "ded574b5-45a0-4f42-8737-46345c09c238" { return 3 }
        default                                { return 0 }
    }
}

function Get-EnergySaverValue {
    param([string]$Setting)
    $hex = @([regex]::Matches((powercfg /qh SCHEME_CURRENT SUB_ENERGYSAVER $Setting | Out-String), '0x[0-9a-fA-F]{8}') | ForEach-Object { $_.Value })
    if ($hex.Count -lt 2) { return $null }
    return [int][Convert]::ToInt64($hex[$hex.Count - 1], 16)
}

function Set-EnergySaverValue {
    param([string]$Setting, [int]$Value, [switch]$OnBatteryOnly)
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER $Setting $Value | Out-Null
    if (-not $OnBatteryOnly) { powercfg /setacvalueindex SCHEME_CURRENT SUB_ENERGYSAVER $Setting $Value | Out-Null }
    powercfg /setactive SCHEME_CURRENT | Out-Null
}

$LaptopTweaks = @(
    @{
        Name        = 'Disable "Adaptive Brightness"'
        SubCategory = "Display"
        Category    = "Laptop"
        Description = "Disables content-adaptive brightness control (CABC) on supported displays."
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"System`" -> `"Display`" -> `"Brightness`" `"Change brightness based on content`""
        Apply       = { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "CABCOption" 0 }
        Detect      = { Test-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "CABCOption" 0 }
        Revert      = { Remove-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "CABCOption" }
    }
    @{
        Name        = 'Show "Battery percentage" on the taskbar'
        Category    = "Laptop"
        SubCategory = "Power & battery"
        SafetyLevel = "Safe"
        Description = "Shows the battery percentage next to the battery icon on the taskbar."
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Battery percentage"'
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "IsBatteryPercentageEnabled" 1 }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "IsBatteryPercentageEnabled" 0 }
        Detect      = { (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IsBatteryPercentageEnabled" -ErrorAction SilentlyContinue).IsBatteryPercentageEnabled -eq 1 }
    }
    @{
        Name        = "Power Mode (Plugged in)"
        Category    = "Laptop"
        SubCategory = "Power & battery"
        Type        = "Option"
        SafetyLevel = "Safe"
        Description = "Windows' power mode when plugged in. Only works with the Balanced power plan, and can't be changed while energy saver is on."
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Power Mode" -> "Plugged in"'
        Options     = @(
            @{ Label = "Balanced (Default)";    Apply = { Set-PowerMode -Source "AC" -Guid "00000000-0000-0000-0000-000000000000" } }
            @{ Label = "Best Power Efficiency"; Apply = { Set-PowerMode -Source "AC" -Guid "961cc777-2547-4f9d-8174-7d86181b8a7a" } }
            @{ Label = "Best Performance";      Apply = { Set-PowerMode -Source "AC" -Guid "ded574b5-45a0-4f42-8737-46345c09c238" } }
        )
        DetectIndex = { Get-PowerModeIndex -Source "AC" }
    }
    @{
        Name        = "Power Mode (On battery)"
        Category    = "Laptop"
        SubCategory = "Power & battery"
        Type        = "Option"
        SafetyLevel = "Safe"
        Description = "Windows' power mode when on battery. Only works with the Balanced power plan, and can't be changed while energy saver is on."
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Power Mode" -> "On battery"'
        Options     = @(
            @{ Label = "Balanced (Default)";    Apply = { Set-PowerMode -Source "DC" -Guid "00000000-0000-0000-0000-000000000000" } }
            @{ Label = "Best Power Efficiency"; Apply = { Set-PowerMode -Source "DC" -Guid "961cc777-2547-4f9d-8174-7d86181b8a7a" } }
            @{ Label = "Best Performance";      Apply = { Set-PowerMode -Source "DC" -Guid "ded574b5-45a0-4f42-8737-46345c09c238" } }
        )
        DetectIndex = { Get-PowerModeIndex -Source "DC" }
    }
    @{
        Name        = "Turn energy saver on automatically at"
        Category    = "Laptop"
        SubCategory = "Power & battery"
        Type        = "Option"
        SafetyLevel = "Safe"
        Description = "The battery level at which energy saver turns on by itself. Energy saver reduces background activity and screen brightness to make the battery last longer."
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Energy saver"'
        Options     = @(
            @{ Label = "Never"; Apply = { Set-EnergySaverValue -Setting "ESBATTTHRESHOLD" -Value 0 -OnBatteryOnly } }
            @{ Label = "10%"; Apply = { Set-EnergySaverValue -Setting "ESBATTTHRESHOLD" -Value 10 -OnBatteryOnly } }
            @{ Label = "20%"; Apply = { Set-EnergySaverValue -Setting "ESBATTTHRESHOLD" -Value 20 -OnBatteryOnly } }
            @{ Label = "30% (Default)"; Apply = { Set-EnergySaverValue -Setting "ESBATTTHRESHOLD" -Value 30 -OnBatteryOnly } }
            @{ Label = "40%"; Apply = { Set-EnergySaverValue -Setting "ESBATTTHRESHOLD" -Value 40 -OnBatteryOnly } }
            @{ Label = "50%"; Apply = { Set-EnergySaverValue -Setting "ESBATTTHRESHOLD" -Value 50 -OnBatteryOnly } }
            @{ Label = "On battery"; Apply = { Set-EnergySaverValue -Setting "ESBATTTHRESHOLD" -Value 100 -OnBatteryOnly } }
        )
        DetectIndex = {
            switch (Get-EnergySaverValue -Setting "ESBATTTHRESHOLD") {
                $null { return 4 }
                0 { return 1 }; 10 { return 2 }; 20 { return 3 }; 30 { return 4 }; 40 { return 5 }; 50 { return 6 }; 100 { return 7 }
                default { return 0 }
            }
        }
    }
    @{
        Name        = 'Disable "Lower screen brightness when using energy saver"'
        Category    = "Laptop"
        SubCategory = "Power & battery"
        SafetyLevel = "Safe"
        Description = "Stops energy saver from dimming the screen. By default it lowers the brightness by 30%."
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Energy saver"'
        Apply       = { Set-EnergySaverValue -Setting "ESBRIGHTNESS" -Value 100 }
        Revert      = { Set-EnergySaverValue -Setting "ESBRIGHTNESS" -Value 70 }
        Detect      = { (Get-EnergySaverValue -Setting "ESBRIGHTNESS") -eq 100 }
    }
)
