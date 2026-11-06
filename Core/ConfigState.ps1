function Update-ToggleLabel {
    param($Entry)
    $on = ($Entry.Cb.IsChecked -eq $true)
    $Entry.Label.Text = if ($on) { "Enabled" } else { "Default" }
    $Entry.Label.Foreground = if ($on -ne $Entry.Baseline) { $window.Resources["Accent"] }
                              elseif ($on) { "#34C759" }
                              else { $window.Resources["SubText"] }
}

function Update-ComboMark {
    param($Entry)
    if (($Entry.Combo.SelectedIndex + 1) -ne $Entry.Baseline) {
        $Entry.Combo.BorderBrush = $window.Resources["Accent"]
    } else {
        $Entry.Combo.ClearValue([System.Windows.Controls.Control]::BorderBrushProperty)
    }
}

function Get-DetectedToggle {
    param($Item)
    if (-not $Item.Detect) { return $false }
    try { return [bool](& $Item.Detect) } catch { return $false }
}

function Get-DetectedOption {
    param($Item)
    if (-not $Item.ContainsKey('DetectIndex')) { return 0 }
    $idx = 0
    try { $idx = [int](& $Item.DetectIndex) } catch { $idx = 0 }
    if ($idx -lt 0 -or $idx -gt $Item.Options.Count) { $idx = 0 }
    return $idx
}

function Test-ToggleLocked {
    param($Entry)
    (-not $Entry.Item.ContainsKey('Revert')) -and $Entry.Baseline
}

function Sync-ConfigToSystem {
    foreach ($e in $ConfigToggles) {
        $e.Baseline = Get-DetectedToggle -Item $e.Item
        $e.Cb.IsChecked = $e.Baseline
        $e.Cb.IsEnabled = -not (Test-ToggleLocked -Entry $e)
        Update-ToggleLabel -Entry $e
    }
    foreach ($e in $ConfigCombos) {
        $e.Baseline = Get-DetectedOption -Item $e.Item
        $e.Combo.SelectedIndex = $e.Baseline - 1
        Update-ComboMark -Entry $e
    }
}

function Get-ItemStatus {
    param($Item)
    if ($Item.Type -eq "Option") {
        if ($Item.ContainsKey("DetectIndex")) {
            $idx = 0
            try { $idx = & $Item.DetectIndex } catch { $idx = 0 }
            if (-not $idx -and (Get-DefaultOptionIndex -Item $Item) -ge 1) {
                return @{ HasStatus = $true; Color = "Gray"; Text = "Custom" }
            }
            if ($idx -and $idx -ge 1 -and $idx -le $Item.Options.Count -and $idx -ne (Get-DefaultOptionIndex -Item $Item)) {
                return @{ HasStatus = $true; Color = "#34C759"; Text = ($Item.Options[$idx - 1].Label -replace '\s*\(.*\)$', '') }
            }
            return @{ HasStatus = $true; Color = "Gray"; Text = "Default" }
        }
        return @{ HasStatus = $false }
    }
    if ($Item.ContainsKey("Detect")) {
        $isAppItem = $Item.Category -in @("System Apps", "Reinstall")
        $trueLabel = if ($isAppItem) { "Installed" } else { "Applied" }
        $falseLabel = if ($isAppItem) { "Not Installed" } else { "Default" }
        $applied = $false
        try { $applied = [bool](& $Item.Detect) } catch { $applied = $false }
        if ($applied) { return @{ HasStatus = $true; Color = "#34C759"; Text = $trueLabel } }
        return @{ HasStatus = $true; Color = "Gray"; Text = $falseLabel }
    }
    return @{ HasStatus = $false }
}

function Update-AllStatuses {
    foreach ($group in $AllGroups) {
        foreach ($entry in $group.Entries) {
            if (-not $entry.HasStatus) { continue }
            $status = Get-ItemStatus -Item $entry.Item
            if ($status.HasStatus) {
                $entry.StatusDot.Fill = $status.Color
                $entry.StatusLabel.Text = $status.Text
                $entry.StatusLabel.Foreground = $status.Color
            }
        }
    }
}

function Get-DefaultOptionIndex {
    param($Item)
    if ($Item.ContainsKey('DefaultIndex') -and $Item.DefaultIndex) { return [int]$Item.DefaultIndex }
    for ($n = 0; $n -lt $Item.Options.Count; $n++) {
        if ($Item.Options[$n].Label -like "*(Default)*") { return $n + 1 }
    }
    return 0
}

function Get-CurrentScope {
    if ($Pages["Config"].Visibility -eq "Visible") { return "Config" }
    if ($Pages["Apps"].Visibility -eq "Visible") {
        if ($AppsInstallList.Visibility -eq "Visible") { return "AppsInstall" }
        return "AppsUninstall"
    }
    if ($Pages["Programs"].Visibility -eq "Visible") {
        if ($ProgramsWingetList.Visibility -eq "Visible") { return "ProgramsWinget" }
        return "ProgramsChoco"
    }
    return ""
}

function Select-AppPreset {
    param([string]$Name, [switch]$AllItems)
    $wanted = @($AppPresets[$Name])
    $configList = @($ConfigPresets[$Name])
    $configNames = @($configList | Where-Object { $_ -is [string] })
    $configChoices = @{}
    foreach ($entry in @($configList | Where-Object { $_ -is [hashtable] })) { $configChoices[$entry.Name] = $entry.Option }
    foreach ($cb in $AllCheckboxes) {
        if (-not $AllItems -and -not $cb.IsVisible) { continue }
        if ($ControlScope[$cb] -ne 'AppsUninstall') { continue }
        $item = $cb.Tag
        if (-not $item) { continue }
        if ($item.Category -in @('System Apps', 'Unpin apps')) {
            $cb.IsChecked = ($wanted -contains $item.Name)
        }
    }
    if ($deepToggle -and ($AllItems -or $deepToggle.IsVisible)) {
        $deepToggle.IsChecked = (@($AppPresetDeepClean) -contains $Name)
    }
    foreach ($e in ($ConfigToggles | Where-Object { $AllItems -or $_.Cb.IsVisible })) {
        if (Test-ToggleLocked -Entry $e) { continue }
        $e.Cb.IsChecked = ($configNames -contains $e.Item.Name)
    }
    foreach ($e in ($ConfigCombos | Where-Object { $AllItems -or $_.Combo.IsVisible })) {
        $def = Get-DefaultOptionIndex -Item $e.Item
        $e.Combo.SelectedIndex = if ($def -ge 1) { $def - 1 } else { $e.Baseline - 1 }
        if ($configChoices.ContainsKey($e.Item.Name)) {
            for ($n = 0; $n -lt $e.Item.Options.Count; $n++) {
                if ($e.Item.Options[$n].Label -like "$($configChoices[$e.Item.Name])*") { $e.Combo.SelectedIndex = $n; break }
            }
        }
    }
}
