$ShortcutGroups = [ordered]@{
    "Legacy Control Panel" = @(
        @{ Name = "Advanced System Properties"; File = "SystemPropertiesAdvanced.exe" }
        @{ Name = "Device Manager";             File = "devmgmt.msc" }
        @{ Name = "Disk Cleanup";               File = "cleanmgr.exe" }
        @{ Name = "Mouse Settings";             File = "control.exe";                  Args = "main.cpl" }
        @{ Name = "Network Options";            File = "control.exe";                  Args = "ncpa.cpl" }
        @{ Name = "Power Options";              File = "control.exe";                  Args = "powercfg.cpl" }
        @{ Name = "Restore Point";              File = "SystemPropertiesProtection.exe" }
        @{ Name = "Sound Settings";             File = "control.exe";                  Args = "mmsys.cpl" }
        @{ Name = "System Configuration (msconfig)"; File = "msconfig.exe" }
        @{ Name = "User Account Control";       File = "UserAccountControlSettings.exe" }
    )
    "Immersive Control Panel" = @(
        @{ Name = "Windows Update";      File = "ms-settings:windowsupdate" }
        @{ Name = "Windows Security";    File = "windowsdefender:" }
        @{ Name = "Installed Apps";      File = "ms-settings:appsfeatures" }
        @{ Name = "Time & Language";     File = "ms-settings:dateandtime" }
        @{ Name = "Printers & Scanners"; File = "ms-settings:printers" }
        @{ Name = "Task Manager";        File = "taskmgr.exe" }
    )
    "Restart & Shut Down" = @(
        @{ Name = "Restart Explorer"; Action = { Restart-Explorer } }
        @{ Name = "Restart PC"; Confirm = "Are you sure you want to restart the PC?"; Action = { Invoke-PowerCommand -Arguments "/r /t 0" } }
        @{ Name = "Shut Down"; Confirm = "Are you sure you want to shut down the PC?"; Action = { Invoke-PowerCommand -Arguments "/s /t 0" } }
        @{ Name = "Sign Out"; Confirm = "Are you sure you want to sign out?"; Action = { Invoke-PowerCommand -Arguments "/l" } }
        @{ Name = "Reboot to Advanced Startup"; Confirm = "Are you sure you want to restart into `"Advanced Startup`"?"; ConfirmDetail = "Advanced Startup is useful for troubleshooting."; Action = { Invoke-PowerCommand -Arguments "/r /o /t 0" } }
        @{ Name = "Reboot to UEFI"; Confirm = "Are you sure you want to restart into the UEFI (BIOS) settings?"; Action = { Invoke-PowerCommand -Arguments "/r /fw /t 0" -FailMessage "This PC couldn't restart into UEFI. It may use a legacy BIOS, or its firmware doesn't support this." } }
        @{ Name = "Reboot to Safe Mode"; Confirm = "Are you sure you want to restart into Safe Mode?"; ConfirmDetail = "The PC will restart to the Advanced Boot Options menu - Select Safe Mode there. Once finished, restart the PC and it will boot normally."; Action = { Restart-ToSafeModeOnce } }
    )
}

function Invoke-PowerCommand {
    param([string]$Arguments, [string]$FailMessage = "")
    $out = & "$env:SystemRoot\System32\shutdown.exe" ($Arguments -split ' ') 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        $msg = if ($FailMessage) { $FailMessage } else { "Windows couldn't do that:`n`n$($out.Trim())" }
        Show-AppMessage -Message ($msg)
    }
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process "$env:WINDIR\explorer.exe" }
}

function Restart-ToSafeModeOnce {
    $out = & "$env:SystemRoot\System32\bcdedit.exe" /set "{current}" onetimeadvancedoptions on 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Show-AppMessage -Message ("Couldn't set up the restart into Safe Mode:`n`n" + $out.Trim())
        return
    }
    Invoke-PowerCommand -Arguments "/r /t 0"
}
