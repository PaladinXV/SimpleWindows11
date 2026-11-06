$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
)

function Get-CopilotUninstallEntries {
    foreach ($root in $uninstallRoots) {
        foreach ($key in @(Get-ChildItem -Path $root -ErrorAction SilentlyContinue)) {
            $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
            if ($props.DisplayName -match '^(Microsoft )?Copilot$' -and $props.UninstallString) { $props }
        }
    }
}

function Get-CopilotProcesses {
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @('Copilot', 'mscopilot') -or $_.Path -like '*\Microsoft\Copilot\*' }
}

Get-CopilotProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

foreach ($pkg in @(Get-AppxPackage -AllUsers -Name 'Microsoft.Copilot' -ErrorAction SilentlyContinue)) {
    try { Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop }
    catch {
        try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop } catch { }
    }
}

foreach ($entry in @(Get-CopilotUninstallEntries)) {
    $command = [string]$entry.UninstallString
    if ($command -match 'msiexec' -and $command -match '(\{[0-9A-Fa-f-]{36}\})') {
        $exe = 'msiexec.exe'
        $arguments = "/x $($Matches[1]) /qn /norestart"
    } elseif ($command -match '^\s*"([^"]+)"\s*(.*)$' -or $command -match '^\s*(\S+\.exe)\s*(.*)$') {
        $exe = $Matches[1]
        $arguments = $Matches[2]
        if (-not (Test-Path -LiteralPath $exe)) { continue }
        if ($arguments -notmatch '--force-uninstall') { $arguments = "$arguments --force-uninstall".Trim() }
    } else {
        continue
    }
    try {
        $proc = Start-Process -FilePath $exe -ArgumentList $arguments -WindowStyle Hidden -PassThru -ErrorAction Stop
        if (-not $proc.WaitForExit(180000)) { try { $proc.Kill() } catch { } }
    } catch { }
}

for ($i = 0; $i -lt 20 -and @(Get-CopilotProcesses).Count -gt 0; $i++) { Start-Sleep -Seconds 1 }
Start-Sleep -Milliseconds 750

$storeLeft = [bool](Get-AppxPackage -Name 'Microsoft.Copilot' -ErrorAction SilentlyContinue)
$programLeft = @(Get-CopilotUninstallEntries).Count -gt 0
return -not ($storeLeft -or $programLeft)
