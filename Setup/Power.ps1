$DiskTimeoutMinutes  = @(0, 1, 2, 5, 10, 20, 30, 60, 90, 120, 180, 360, 720)
$ScreenTimeoutMinutes = @(0, 1, 2, 3, 5, 10, 15, 20, 30, 60, 90, 120, 180)

function New-PowerTimeoutOptions {
    param([string]$Setting, [int[]]$Minutes, [int]$DefaultMinutes, [string]$Source = "both")
    $sources = if ($Source -eq "both") { @("ac", "dc") } else { @($Source) }
    foreach ($m in $Minutes) {
        $label = if ($m -eq 0) { "Never" } elseif ($m -eq 1) { "1 minute" } else { "$m minutes" }
        if ($m -eq $DefaultMinutes) { $label += " (Default)" }
        @{
            Label = $label
            Apply = {
                foreach ($src in $sources) { powercfg /change "$Setting-$src" $m | Out-Null }
            }.GetNewClosure()
        }
    }
}

function Get-TimeoutIndex {
    param([int[]]$Minutes, $Current)
    if ($null -eq $Current) { return 0 }
    $i = [array]::IndexOf($Minutes, [int]$Current)
    if ($i -ge 0) { return $i + 1 }
    return 0
}

function Get-PowerSettingMinutes {
    param([string]$SubGroup, [string]$Setting, [switch]$OnBattery)
    $hex = @([regex]::Matches((powercfg /q SCHEME_CURRENT $SubGroup $Setting | Out-String), '0x[0-9a-fA-F]{8}') | ForEach-Object { $_.Value })
    if ($hex.Count -lt 2) { return $null }
    $pick = if ($OnBattery) { $hex[$hex.Count - 1] } else { $hex[$hex.Count - 2] }
    return [int]([Convert]::ToInt64($pick, 16) / 60)
}

$PowerPlanGuids = @{
    Balanced        = "381b4222-f694-41f0-9685-ff5bb260df2e"
    PowerSaver      = "a1841308-3541-4fab-bc81-f71556f20b4a"
    HighPerformance = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    Ultimate        = "e9a42b02-d5df-448d-aa00-03f14749eb61"
}

function Get-PowerPlanGuids {
    @(powercfg /list | ForEach-Object {
        if ($_ -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { $Matches[1].ToLower() }
    })
}

function Get-ActivePowerPlanGuid {
    $line = powercfg /getactivescheme | Out-String
    if ($line -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { return $Matches[1].ToLower() }
    return $null
}

$PowerPlanStore = "HKLM:\SOFTWARE\SimpleWindowsTool\PowerPlans"

function Resolve-PowerPlan {
    param([string]$Guid)
    $listed = Get-PowerPlanGuids
    if ($listed -contains $Guid) { return $Guid }
    $copy = (Get-ItemProperty -Path $PowerPlanStore -Name $Guid -ErrorAction SilentlyContinue).$Guid
    if ($copy -and ($listed -contains $copy)) { return $copy }
    return $null
}

function Add-PowerPlan {
    param([string]$Guid)
    $have = Resolve-PowerPlan -Guid $Guid
    if ($have) { return $have }
    powercfg -duplicatescheme $Guid $Guid | Out-Null
    if ((Get-PowerPlanGuids) -contains $Guid) { return $Guid }
    $out = powercfg -duplicatescheme $Guid | Out-String
    if ($out -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
        $new = $Matches[1].ToLower()
        if ((Get-PowerPlanGuids) -contains $new) {
            Set-Reg $PowerPlanStore $Guid $new "String"
            return $new
        }
    }
    throw "This PC doesn't offer this power plan. Modern Standby PCs only have Balanced."
}

function Set-PowerPlan {
    param([string]$Guid)
    $use = Add-PowerPlan -Guid $Guid
    powercfg /setactive $use | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "powercfg could not switch to this power plan." }
}

$PowerTweaks = @(
    @{
        Name        = "Power off hard disk after"
        SubCategory = "Power Options"
        Category    = "Power"
        Type        = "Option"
        Description = "How long a hard drive can sit idle before it spins down. Applies to the active power plan, both plugged in and on battery. SSDs aren't affected."
        SafetyLevel = "Safe"
        Location    = 'Located in "Control Panel" -> "Power Options" -> "Change plan settings" -> "Change advanced power settings" -> "Hard disk"'
        Options     = @(New-PowerTimeoutOptions -Setting "disk-timeout" -Minutes $DiskTimeoutMinutes -DefaultMinutes 20)
        DetectIndex = { Get-TimeoutIndex -Minutes $DiskTimeoutMinutes -Current (Get-PowerSettingMinutes -SubGroup "SUB_DISK" -Setting "DISKIDLE") }
    }
    @{
        Name        = "Turn off screen after (Plugged in)"
        SubCategory = "Power & battery"
        Category    = "Power"
        Type        = "Option"
        Description = "How long Windows will sit idle before turning the screen off (plugged in) for the selected power plan. For OLED displays, it's recommended to have this at 10-15 minutes to help prevent burn-in."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Screen, sleep, & hibernate timeouts"'
        Options     = @(New-PowerTimeoutOptions -Setting "monitor-timeout" -Minutes $ScreenTimeoutMinutes -DefaultMinutes 5 -Source "ac")
        DetectIndex = { Get-TimeoutIndex -Minutes $ScreenTimeoutMinutes -Current (Get-PowerSettingMinutes -SubGroup "SUB_VIDEO" -Setting "VIDEOIDLE") }
    }
    @{
        Name        = "Sleep after (Plugged in)"
        SubCategory = "Power & battery"
        Category    = "Power"
        Type        = "Option"
        Description = "How long the PC will sit idle before it goes to sleep (plugged in). If you're a gamer, you may want to set `"Never`" to prevent any strange bugs or glitches from drivers/devices waking up from sleep."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Screen, sleep, & hibernate timeouts"'
        Options     = @(New-PowerTimeoutOptions -Setting "standby-timeout" -Minutes $ScreenTimeoutMinutes -DefaultMinutes 15 -Source "ac")
        DetectIndex = { Get-TimeoutIndex -Minutes $ScreenTimeoutMinutes -Current (Get-PowerSettingMinutes -SubGroup "SUB_SLEEP" -Setting "STANDBYIDLE") }
    }
    @{
        Name        = "Turn off screen after (On battery)"
        SubCategory = "Power & battery"
        Category    = "Power"
        Type        = "Option"
        Description = "How long Windows will sit idle before turning the screen off (on battery) for the selected power plan. For OLED displays, it's recommended to have this at 10-15 minutes to help prevent burn-in."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Screen, sleep, & hibernate timeouts"'
        Options     = @(New-PowerTimeoutOptions -Setting "monitor-timeout" -Minutes $ScreenTimeoutMinutes -DefaultMinutes 5 -Source "dc")
        DetectIndex = { Get-TimeoutIndex -Minutes $ScreenTimeoutMinutes -Current (Get-PowerSettingMinutes -SubGroup "SUB_VIDEO" -Setting "VIDEOIDLE" -OnBattery) }
    }
    @{
        Name        = "Sleep after (On battery)"
        SubCategory = "Power & battery"
        Category    = "Power"
        Type        = "Option"
        Description = "How long the PC will sit idle before it goes to sleep (on battery). If you're a gamer, you may want to set `"Never`" to prevent any strange bugs or glitches from drivers/devices waking up from sleep."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "System" -> "Power & battery" -> "Screen, sleep, & hibernate timeouts"'
        Options     = @(New-PowerTimeoutOptions -Setting "standby-timeout" -Minutes $ScreenTimeoutMinutes -DefaultMinutes 15 -Source "dc")
        DetectIndex = { Get-TimeoutIndex -Minutes $ScreenTimeoutMinutes -Current (Get-PowerSettingMinutes -SubGroup "SUB_SLEEP" -Setting "STANDBYIDLE" -OnBattery) }
    }
    @{
        Name        = "Hibernate"
        SubCategory = "Power Options"
        Category    = "Power"
        Type        = "Option"
        Description = "Disables Windows Hibernation mode. Windows continually writes to the hibernation file, increasing SSD writes. It also frees up some disk space. If you have a laptop, it might be worth keeping enabled."
        SafetyLevel = "Advanced"
        Location    = 'Located in "Control Panel" -> "Power Options" -> "Choose what the power buttons do" -> "Hibernate"'
        Options     = @(
            @{ Label = "Enabled (Default)";      Apply = { powercfg /hibernate on | Out-Null } }
            @{ Label = "Disabled (Recommended)"; Apply = { powercfg /hibernate off | Out-Null } }
        )
        DefaultIndex = 1
        DetectIndex = {
            $v = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -ErrorAction SilentlyContinue).HibernateEnabled
            if ($v -eq 1) { return 1 }
            if ($v -eq 0) { return 2 }
            return 0
        }
    }
    @{
        Name        = "Power plan"
        RunFirst    = $true
        SubCategory = "Power Options"
        Category    = "Power"
        Type        = "Option"
        Description = "Sets the power plan. Balanced is generally recommended outside of some niche scenarios. Ultimate Performance can be added, or added and activated."
        SafetyLevel = "Safe"
        Location    = 'Located in "Control Panel" -> "Power Options"'
        Options     = @(
            @{ Label = "Balanced (Default)"; Apply = { Set-PowerPlan -Guid $PowerPlanGuids.Balanced } }
            @{ Label = "Power saver";      Apply = { Set-PowerPlan -Guid $PowerPlanGuids.PowerSaver } }
            @{ Label = "High performance"; Apply = { Set-PowerPlan -Guid $PowerPlanGuids.HighPerformance } }
            @{ Label = "Ultimate Performance (Add)";            Apply = { Add-PowerPlan -Guid $PowerPlanGuids.Ultimate | Out-Null } }
            @{ Label = "Ultimate Performance (Add + Activate)"; Apply = { Set-PowerPlan -Guid $PowerPlanGuids.Ultimate } }
        )
        DefaultIndex = 1
        DetectIndex = {
            $active = Get-ActivePowerPlanGuid
            if ($active -and $active -eq (Resolve-PowerPlan -Guid $PowerPlanGuids.Balanced))        { return 1 }
            if ($active -and $active -eq (Resolve-PowerPlan -Guid $PowerPlanGuids.PowerSaver))      { return 2 }
            if ($active -and $active -eq (Resolve-PowerPlan -Guid $PowerPlanGuids.HighPerformance)) { return 3 }
            if ($active -and $active -eq (Resolve-PowerPlan -Guid $PowerPlanGuids.Ultimate))        { return 5 }
            return 0
        }
    }
    @{
        Name        = 'Disable "Fast Startup"'
        Category    = "Power"
        SubCategory = "Power Options"
        Description = "Does a full shutdown instead of a partial hibernation. Avoids issues such as drivers not resetting properly. You can check your uptime in Task Manager -> Performance -> CPU -> Up time."
        SafetyLevel = "Safe"
        Location    = 'Located in "Control Panel" -> "Power Options" -> "Choose what the power buttons do" -> "Turn on fast startup"'
        Apply       = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0
        }
        Revert      = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 1
        }
        Detect      = {
            (Test-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0)
        }
    }
)
