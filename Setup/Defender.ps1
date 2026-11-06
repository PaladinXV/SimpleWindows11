$DefenderTweaks = @(
    @{
        Name        = 'Disable "Automatic Sample Submission"'
        Category    = "Defender"
        Description = "Stops Windows Security/Defender from sending file samples to Microsoft."
        SafetyLevel = "Advanced"
        Location    = "Located in `"Windows Security`" -> `"Virus & threat protection`" -> `"Manage settings`" `"Automatic sample submission`""
        Apply       = { try { Set-MpPreference -SubmitSamplesConsent NeverSend -ErrorAction Stop } catch { } }
        Revert      = { try { Set-MpPreference -SubmitSamplesConsent SendSafeSamples -ErrorAction Stop } catch { } }
        Detect      = { try { (Get-MpPreference -ErrorAction Stop).SubmitSamplesConsent -eq 2 } catch { $false } }
    }
    @{
        Name        = 'Disable "Virtualization-based Security"'
        Category    = "Defender"
        Description = "Uses hardware virtualization to isolate critical security functions from the main Windows environment, helping protect the operating system from malware and unauthorized access to sensitive system components. Disabling, in combination with Core Isolation, can have small performance gains or even fix stuttering issues in some games."
        SafetyLevel = "Not Recommended"
        Apply       = { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 }
        Revert      = { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 1 }
        Detect      = { Test-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 }
    }
    @{
        Name        = 'Disable "Memory Integrity (Core Isolation)"'
        Category    = "Defender"
        Description = "Uses VBS to protect critical Windows processes and kernel code from malicious or incompatible software, particularly unauthorized drivers attempting to modify protected system memory. Disabling, in combination with VBS, can have small performance gains or even fix stuttering issues in some games."
        SafetyLevel = "Not Recommended"
        Location    = "Located in `"Windows Security`" -> `"Device security`" -> `"Core isolation details`" `"Memory integrity`""
        Apply       = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "WasEnabledBy" 2
        }
        Revert      = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 1
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "WasEnabledBy" 2
        }
        Detect      = { Test-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0 }
    }
)
