$UserConfigScopes = [ordered]@{
    "AppsUninstall"  = @("WindowsApps", "Uninstall")
    "AppsInstall"    = @("WindowsApps", "Install")
    "ProgramsWinget" = @("UserApps", "Winget")
    "ProgramsChoco"  = @("UserApps", "Chocolatey")
}

function Export-UserConfig {
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "Configuration files (*.json)|*.json"
    $dlg.FileName = "SimpleWindowsTool-config.json"
    if (-not $dlg.ShowDialog($window)) { return }
    $switches = [ordered]@{}
    foreach ($e in $ConfigToggles) { $switches[[string]$e.Item.Name] = ($e.Cb.IsChecked -eq $true) }
    $dropdowns = [ordered]@{}
    foreach ($e in $ConfigCombos) {
        if ($e.Combo.SelectedIndex -ge 0) { $dropdowns[[string]$e.Item.Name] = [string]$e.Item.Options[$e.Combo.SelectedIndex].Label }
    }
    $config = [ordered]@{
        Tool          = "Simple Windows 11 Tool"
        Saved         = (Get-Date).ToString("yyyy-MM-dd HH:mm")
        Configuration = [ordered]@{ Switches = $switches; Dropdowns = $dropdowns }
        WindowsApps   = [ordered]@{}
        UserApps      = [ordered]@{}
    }
    foreach ($scope in $UserConfigScopes.Keys) {
        $section = $UserConfigScopes[$scope]
        $config[$section[0]][$section[1]] = @($AllCheckboxes | Where-Object { $ControlScope[$_] -eq $scope -and $_.IsChecked -eq $true } | ForEach-Object { [string]$_.Tag.Name })
    }
    try {
        $config | ConvertTo-Json -Depth 6 | Set-Content -Path $dlg.FileName -Encoding UTF8 -ErrorAction Stop
        Show-AppMessage -Message ("Configuration saved to:`n$($dlg.FileName)")
    } catch {
        Show-AppMessage -Message ("The configuration couldn't be saved:`n$($_.Exception.Message)")
    }
}

function Import-UserConfig {
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "Configuration files (*.json)|*.json"
    if (-not $dlg.ShowDialog($window)) { return }
    try { $data = Get-Content -Raw -Path $dlg.FileName -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
    catch {
        Show-AppMessage -Message ("That file couldn't be read as a configuration.")
        return
    }
    $skipped = New-Object System.Collections.Generic.List[string]
    if ($data.Configuration.Switches) {
        foreach ($prop in $data.Configuration.Switches.PSObject.Properties) {
            $e = $ConfigToggles | Where-Object { $_.Item.Name -eq $prop.Name } | Select-Object -First 1
            if ($e) { if (-not (Test-ToggleLocked -Entry $e)) { $e.Cb.IsChecked = [bool]$prop.Value } } else { $skipped.Add($prop.Name) }
        }
    }
    if ($data.Configuration.Dropdowns) {
        foreach ($prop in $data.Configuration.Dropdowns.PSObject.Properties) {
            $e = $ConfigCombos | Where-Object { $_.Item.Name -eq $prop.Name } | Select-Object -First 1
            $idx = -1
            if ($e) {
                for ($n = 0; $n -lt $e.Item.Options.Count; $n++) {
                    $label = [string]$e.Item.Options[$n].Label
                    if ($label -eq $prop.Value -or ($label -replace '\s*\(.*\)$', '') -eq ([string]$prop.Value -replace '\s*\(.*\)$', '')) { $idx = $n; break }
                }
            }
            if ($idx -ge 0) { $e.Combo.SelectedIndex = $idx } else { $skipped.Add("$($prop.Name): $($prop.Value)") }
        }
    }
    foreach ($scope in $UserConfigScopes.Keys) {
        $section = $UserConfigScopes[$scope]
        $group = $data.($section[0])
        if (-not $group -or -not ($group.PSObject.Properties.Name -contains $section[1])) { continue }
        $names = @($group.($section[1]))
        $boxes = @($AllCheckboxes | Where-Object { $ControlScope[$_] -eq $scope })
        foreach ($cb in $boxes) { $cb.IsChecked = ($names -contains $cb.Tag.Name) }
        foreach ($n in $names) { if (-not ($boxes | Where-Object { $_.Tag.Name -eq $n })) { $skipped.Add($n) } }
    }
    $msg = "Configuration loaded. Changes are marked in blue - press Apply Selected on each page (Configuration, Windows Apps, User Apps) to apply them."
    if ($skipped.Count -gt 0) {
        $shown = @($skipped | Select-Object -First 10)
        $msg += "`n`nSkipped $($skipped.Count) item(s) this version doesn't recognise:`n" + ($shown -join "`n")
        if ($skipped.Count -gt 10) { $msg += "`n..." }
    }
    Show-AppMessage -Message ($msg)
}
