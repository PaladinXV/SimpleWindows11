function Get-MatchingScheduledTasks {
    param([string]$TaskPath, [string[]]$TaskNames)
    @(Get-ScheduledTask -TaskPath $TaskPath -ErrorAction SilentlyContinue | Where-Object {
        $name = $_.TaskName
        @($TaskNames | Where-Object { $name -like "$_*" }).Count -gt 0
    })
}

function Set-ScheduledTasksEnabled {
    param([string]$TaskPath, [string[]]$TaskNames, [bool]$Enabled)
    $failed = @()
    foreach ($task in @(Get-MatchingScheduledTasks -TaskPath $TaskPath -TaskNames $TaskNames)) {
        $full = "$($task.TaskPath)$($task.TaskName)"
        try {
            if ($Enabled) { Enable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null }
            else { Disable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null }
        } catch {
            & schtasks.exe /Change /TN $full $(if ($Enabled) { "/Enable" } else { "/Disable" }) 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { $failed += $task.TaskName }
        }
    }
    if ($failed) { throw "Windows blocked changing: $($failed -join ', ')" }
}

function New-ScheduledTaskTweak {
    param([string]$Name, [string]$TaskPath, [string[]]$TaskNames, [string]$Description)
    @{
        Name        = $Name
        Category    = "Scheduled Tasks (Telemetry)"
        Description = $Description
        SafetyLevel = "Advanced"
        Location    = "Located in `"Task Scheduler`" -> `"Task Scheduler Library`" -> `"$($TaskPath.Trim('\') -replace '\\', '`" -> `"')`""
        Apply       = { Set-ScheduledTasksEnabled -TaskPath $TaskPath -TaskNames $TaskNames -Enabled $false }.GetNewClosure()
        Revert      = { Set-ScheduledTasksEnabled -TaskPath $TaskPath -TaskNames $TaskNames -Enabled $true }.GetNewClosure()
        Detect      = {
            $tasks = @(Get-MatchingScheduledTasks -TaskPath $TaskPath -TaskNames $TaskNames)
            ($tasks.Count -gt 0) -and (@($tasks | Where-Object { "$($_.State)" -ne 'Disabled' }).Count -eq 0)
        }.GetNewClosure()
    }
}

$ScheduledTaskTweaks = @(
    New-ScheduledTaskTweak -Name 'Disable "Compatibility Appraiser"' -TaskPath '\Microsoft\Windows\Application Experience\' -TaskNames 'Microsoft Compatibility Appraiser' `
        -Description "Scans installed apps and drivers and sends compatibility data to Microsoft. Also used to check if the PC is eligible for Windows upgrades."
    New-ScheduledTaskTweak -Name 'Disable "Autochk Proxy"' -TaskPath '\Microsoft\Windows\Autochk\' -TaskNames 'Proxy' `
        -Description "Collects and uploads disk check (Autochk) data for the Customer Experience Improvement Program."
    New-ScheduledTaskTweak -Name 'Disable "CEIP Consolidator"' -TaskPath '\Microsoft\Windows\Customer Experience Improvement Program\' -TaskNames 'Consolidator' `
        -Description "Gathers and sends usage data for the Customer Experience Improvement Program."
    New-ScheduledTaskTweak -Name 'Disable "CEIP USB Data"' -TaskPath '\Microsoft\Windows\Customer Experience Improvement Program\' -TaskNames 'UsbCeip' `
        -Description "Collects data about USB devices and sends it to Microsoft for the Customer Experience Improvement Program."
    New-ScheduledTaskTweak -Name 'Disable "Disk Diagnostic Data Collector"' -TaskPath '\Microsoft\Windows\DiskDiagnostic\' -TaskNames 'Microsoft-Windows-DiskDiagnosticDataCollector' `
        -Description "Collects general disk and system information and sends it to Microsoft. Drive health warnings from your drive itself are not affected."
    New-ScheduledTaskTweak -Name 'Disable "Feedback (DmClient)"' -TaskPath '\Microsoft\Windows\Feedback\Siuf\' -TaskNames 'DmClient', 'DmClientOnScenarioDownload' `
        -Description "Downloads and runs Microsoft's feedback surveys and data collection scenarios (the pop-ups asking how you'd rate Windows)."
    New-ScheduledTaskTweak -Name 'Disable "Error Reporting Queue"' -TaskPath '\Microsoft\Windows\Windows Error Reporting\' -TaskNames 'QueueReporting' `
        -Description "Sends queued crash and error reports to Microsoft in the background."
    New-ScheduledTaskTweak -Name 'Disable "Recommended Troubleshooting Scanner"' -TaskPath '\Microsoft\Windows\Diagnosis\' -TaskNames 'RecommendedTroubleshootingScanner' `
        -Description "Checks for problems in the background and recommends or runs troubleshooters automatically."
)
