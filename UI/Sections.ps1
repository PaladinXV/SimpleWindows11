function New-CardSection {
    param($Parent, [string]$Title, [System.Windows.Controls.Panel]$Content, [switch]$Stretch)
    $section = New-Object System.Windows.Controls.StackPanel
    $section.Margin = "0,0,0,22"
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = $Title
    $header.FontWeight = "SemiBold"
    $header.FontSize = 15
    $header.Margin = "0,0,0,10"
    $header.Foreground = $window.Resources["Text"]
    $card = New-Object System.Windows.Controls.Border
    $card.Background = $window.Resources["CardBg"]
    $card.CornerRadius = 6
    $card.Padding = "14,10,14,10"
    $card.HorizontalAlignment = $(if ($Stretch) { "Stretch" } else { "Left" })
    $card.Child = $Content
    $section.Children.Add($header) | Out-Null
    $section.Children.Add($card) | Out-Null
    $Parent.Children.Add($section) | Out-Null
}

function Set-DescriptionText {
    param($Element, [string]$Text, [string]$Location, [string]$Warning)
    $Element.Inlines.Clear()
    $firstLine = $true
    foreach ($line in @($Text -split "`n")) {
        if (-not $firstLine) { $Element.Inlines.Add((New-Object System.Windows.Documents.LineBreak)) | Out-Null }
        $firstLine = $false
        foreach ($part in [regex]::Split($line, '(Warning!)')) {
            if (-not $part) { continue }
            $run = New-Object System.Windows.Documents.Run -ArgumentList $part
            if ($part -eq 'Warning!') {
                $run.Foreground = "#FF9500"
                $run.FontWeight = "Bold"
            }
            $Element.Inlines.Add($run) | Out-Null
        }
    }
    if ($Warning) {
        $Element.Inlines.Add((New-Object System.Windows.Documents.LineBreak)) | Out-Null
        $Element.Inlines.Add((New-Object System.Windows.Documents.LineBreak)) | Out-Null
        $warnRun = New-Object System.Windows.Documents.Run -ArgumentList $Warning
        $warnRun.Foreground = "#FF9500"
        $Element.Inlines.Add($warnRun) | Out-Null
    }
    if ($Location) {
        $Element.Inlines.Add((New-Object System.Windows.Documents.LineBreak)) | Out-Null
        $Element.Inlines.Add((New-Object System.Windows.Documents.LineBreak)) | Out-Null
        $locRun = New-Object System.Windows.Documents.Run -ArgumentList $Location
        $locRun.Foreground = "#7E7E84"
        $locRun.FontStyle = "Italic"
        $locRun.FontSize = 12
        $Element.Inlines.Add($locRun) | Out-Null
    }
}

function Switch-RowSelection {
    param($Rows)
    $shown = @($Rows | Where-Object { $_.Row.Visibility -eq "Visible" })
    if ($shown.Count -eq 0) { return }
    $allOn = @($shown | Where-Object { $_.Cb.IsChecked -ne $true }).Count -eq 0
    foreach ($r in $shown) { $r.Cb.IsChecked = -not $allOn }
}

function Set-ClickableHeading {
    param($TextBlock, $Rows, [string]$What)
    $TextBlock.Cursor = [System.Windows.Input.Cursors]::Hand
    $TextBlock.ToolTip = "Click to select or clear everything in $What"
    $TextBlock.Tag = $TextBlock.Foreground
    $TextBlock.Add_MouseEnter({ param($s, $e) $s.Foreground = $window.Resources["Accent"] })
    $TextBlock.Add_MouseLeave({ param($s, $e) $s.Foreground = $s.Tag })
    $TextBlock.Add_MouseLeftButtonUp({ Switch-RowSelection -Rows $Rows }.GetNewClosure())
}

$ControlScope = @{}
$SafetyColors = @{ "Safe" = "#34C759"; "Advanced" = "#FF9500"; "Not Recommended" = "#FF3B30" }

function Get-SafetyColor {
    param([string]$Level)
    if ($SafetyColors.ContainsKey($Level)) { return $SafetyColors[$Level] }
    return "Gray"
}

function New-SafetyDot {
    param([string]$Level)
    $dot = New-Object System.Windows.Shapes.Ellipse
    $dot.Width = 8
    $dot.Height = 8
    $dot.VerticalAlignment = "Center"
    $dot.Margin = "2,0,6,0"
    $dot.Fill = Get-SafetyColor -Level $Level
    return $dot
}

function New-CategorySection {
    param([string]$Title, [array]$Items, $TargetCol, $DescTitleEl, $DescBodyEl, [switch]$NoStatus, [switch]$NoDots, [switch]$Toggles, [switch]$ProgramStatus, [string]$Scope = "")

    $groupEntries = New-Object System.Collections.Generic.List[PSCustomObject]
    $ROW_HEIGHT = if ($Toggles) { 22 } else { 20 }
    $onConfigPanel = ($DescTitleEl -eq $ConfigDescTitle)
    $safetyRowEl = if ($onConfigPanel) { $ConfigDescSafetyRow } else { $AppsDescSafetyRow }
    $safetyDotEl = if ($onConfigPanel) { $ConfigDescSafetyDot } else { $AppsDescSafetyDot }
    $safetyTextEl = if ($onConfigPanel) { $ConfigDescSafetyText } else { $AppsDescSafetyText }

    $box = New-Object System.Windows.Controls.Border
    $box.Background = $window.Resources["CardBg"]
    $box.CornerRadius = 6
    $box.Padding = "18,6,18,14"
    $box.Margin = "0,0,0,20"
    $box.HorizontalAlignment = "Stretch"
    $boxStack = New-Object System.Windows.Controls.StackPanel

    $headerRow = New-Object System.Windows.Controls.Grid
    $headerCol0 = New-Object System.Windows.Controls.ColumnDefinition
    $headerCol0.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $headerCol1 = New-Object System.Windows.Controls.ColumnDefinition
    $headerCol1.Width = [System.Windows.GridLength]::new($(if ($Toggles) { 140 } else { 110 }))
    $headerRow.ColumnDefinitions.Add($headerCol0)
    $headerRow.ColumnDefinitions.Add($headerCol1)
    $headerRow.Height = 30

    $tweaksHeader = New-Object System.Windows.Controls.TextBlock
    $tweaksHeader.Text = $Title
    $tweaksHeader.FontWeight = "SemiBold"
    $tweaksHeader.FontSize = 17
    $tweaksHeader.VerticalAlignment = "Center"
    $tweaksHeader.Foreground = $window.Resources["Text"]
    $sectionRows = New-Object System.Collections.Generic.List[object]
    $subGroups = New-Object System.Collections.Generic.List[object]
    $currentSub = $null
    [System.Windows.Controls.Grid]::SetColumn($tweaksHeader, 0)
    $headerRow.Children.Add($tweaksHeader) | Out-Null

    $statusHeaderCell = New-Object System.Windows.Controls.TextBlock
    $statusHeaderCell.Text = if ($NoStatus) { "" } else { "Status" }
    $statusHeaderCell.FontWeight = "SemiBold"
    $statusHeaderCell.FontSize = 17
    $statusHeaderCell.VerticalAlignment = "Center"
    $statusHeaderCell.Foreground = $window.Resources["Text"]
    [System.Windows.Controls.Grid]::SetColumn($statusHeaderCell, 1)
    $headerRow.Children.Add($statusHeaderCell) | Out-Null

    $boxStack.Children.Add($headerRow) | Out-Null

    foreach ($item in $Items) {
        $desc = if ($item.ContainsKey('Description') -and $item['Description']) { $item['Description'] } else { "No description available." }
        $name = "$($item.Name)"

        $sub = if ($item.ContainsKey('SubCategory')) { $item['SubCategory'] } else { $null }
        if ($sub -and (-not $currentSub -or $sub -ne $currentSub.Name)) {
            $subText = New-Object System.Windows.Controls.TextBlock
            $subText.Text = $sub
            $subText.FontWeight = "SemiBold"
            $subText.FontSize = 14
            $subText.Foreground = $window.Resources["SubText"]
            $subText.HorizontalAlignment = "Left"
            $subText.Margin = $(if ($subGroups.Count -eq 0) { "0,2,0,2" } else { "0,12,0,2" })
            $boxStack.Children.Add($subText) | Out-Null
            $currentSub = [PSCustomObject]@{
                Name     = $sub
                Heading  = $subText
                Rows     = New-Object System.Collections.Generic.List[object]
                RowGrids = New-Object System.Collections.Generic.List[object]
            }
            $subGroups.Add($currentSub) | Out-Null
        }

        $rowGrid = New-Object System.Windows.Controls.Grid
        $rowGrid.MinHeight = $ROW_HEIGHT
        if ($sub -and $currentSub) { $currentSub.RowGrids.Add($rowGrid) | Out-Null }
        $rowCol0 = New-Object System.Windows.Controls.ColumnDefinition
        $rowCol0.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $rowCol1 = New-Object System.Windows.Controls.ColumnDefinition
        $rowCol1.Width = [System.Windows.GridLength]::new($(if ($Toggles) { 140 } else { 110 }))
        $rowGrid.ColumnDefinitions.Add($rowCol0)
        $rowGrid.ColumnDefinitions.Add($rowCol1)

        $toggleEntry = $null
        if ($item.Type -eq "Option") {
            $left = New-Object System.Windows.Controls.StackPanel
            $left.Orientation = "Vertical"
            $left.Margin = "1,4,1,4"
            $label = New-Object System.Windows.Controls.TextBlock
            $label.Text = $name
            $label.Margin = "0,0,0,3"
            $label.Foreground = $window.Resources["Text"]
            $combo = New-Object System.Windows.Controls.ComboBox
            $combo.Width = 250
            $combo.HorizontalAlignment = "Left"
            foreach ($opt in $item.Options) { $combo.Items.Add($opt.Label) | Out-Null }
            $combo.SelectedIndex = -1
            $combo.Tag = $item
            $AllOptionSelectors.Add($combo) | Out-Null
            $ControlScope[$combo] = $Scope
            if ($Toggles) {
                $comboEntry = [PSCustomObject]@{ Combo = $combo; Item = $item; Baseline = (Get-DetectedOption -Item $item) }
                $combo.SelectedIndex = $comboEntry.Baseline - 1
                $ConfigCombos.Add($comboEntry) | Out-Null
                $combo.Add_SelectionChanged({ Update-ComboMark -Entry $comboEntry }.GetNewClosure())
            }
            if (-not $NoDots -and $item.ContainsKey('SafetyLevel') -and $item['SafetyLevel']) {
                $labelRow = New-Object System.Windows.Controls.StackPanel
                $labelRow.Orientation = "Horizontal"
                $labelRow.Children.Add((New-SafetyDot -Level $item['SafetyLevel'])) | Out-Null
                $labelRow.Children.Add($label) | Out-Null
                $left.Children.Add($labelRow) | Out-Null
            } else {
                $left.Children.Add($label) | Out-Null
            }
            $left.Children.Add($combo) | Out-Null
            [System.Windows.Controls.Grid]::SetColumn($left, 0)
            $rowGrid.Children.Add($left) | Out-Null
        } else {
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $name
            $cb.IsChecked = $false
            $cb.Tag = $item
            if ($Toggles) {
                $cb.Content = $null
                $cb.Style = $window.Resources["ToggleSwitch"]
                $stateText = New-Object System.Windows.Controls.TextBlock
                $stateText.VerticalAlignment = "Center"
                $stateText.Margin = "8,0,0,0"
                $toggleEntry = [PSCustomObject]@{ Cb = $cb; Label = $stateText; Item = $item; Baseline = (Get-DetectedToggle -Item $item) }
                $cb.IsChecked = $toggleEntry.Baseline
                $cb.IsEnabled = -not (Test-ToggleLocked -Entry $toggleEntry)
                Update-ToggleLabel -Entry $toggleEntry
                $ConfigToggles.Add($toggleEntry) | Out-Null
                $cb.Add_Checked({ Update-ToggleLabel -Entry $toggleEntry }.GetNewClosure())
                $cb.Add_Unchecked({ Update-ToggleLabel -Entry $toggleEntry }.GetNewClosure())
            }
            $cb.Margin = "1,0,1,0"
            $cb.VerticalAlignment = "Center"
            $AllCheckboxes.Add($cb) | Out-Null
            $ControlScope[$cb] = $Scope
            $rowEntry = [PSCustomObject]@{ Cb = $cb; Row = $rowGrid }
            $sectionRows.Add($rowEntry) | Out-Null
            if ($sub -and $currentSub) { $currentSub.Rows.Add($rowEntry) | Out-Null }

            if (-not $toggleEntry -and -not $NoDots -and $item.ContainsKey('SafetyLevel') -and $item['SafetyLevel']) {
                $safetyWrap = New-Object System.Windows.Controls.StackPanel
                $safetyWrap.Orientation = "Horizontal"
                $safetyWrap.Children.Add((New-SafetyDot -Level $item['SafetyLevel'])) | Out-Null
                $safetyWrap.Children.Add($cb) | Out-Null
                [System.Windows.Controls.Grid]::SetColumn($safetyWrap, 0)
                $rowGrid.Children.Add($safetyWrap) | Out-Null
            } elseif ($toggleEntry) {
                $nameText = New-Object System.Windows.Controls.TextBlock
                $nameText.Text = $name
                $nameText.Foreground = $window.Resources["Text"]
                $nameText.VerticalAlignment = "Center"
                $nameText.TextTrimming = "CharacterEllipsis"
                $nameText.Margin = "1,0,8,0"
                $nameText.Cursor = [System.Windows.Input.Cursors]::Hand
                $nameText.Tag = $nameText.Foreground
                $nameText.Add_MouseEnter({ param($s, $e) $s.Foreground = $window.Resources["Accent"] })
                $nameText.Add_MouseLeave({ param($s, $e) $s.Foreground = $s.Tag })
                $switchCb = $cb
                $nameText.Add_MouseLeftButtonUp({ if ($switchCb.IsEnabled) { $switchCb.IsChecked = -not ($switchCb.IsChecked -eq $true) } }.GetNewClosure())
                if (-not $NoDots -and $item.ContainsKey('SafetyLevel') -and $item['SafetyLevel']) {
                    $nameWrap = New-Object System.Windows.Controls.StackPanel
                    $nameWrap.Orientation = "Horizontal"
                    $nameWrap.VerticalAlignment = "Center"
                    $nameWrap.Children.Add((New-SafetyDot -Level $item['SafetyLevel'])) | Out-Null
                    $nameWrap.Children.Add($nameText) | Out-Null
                    [System.Windows.Controls.Grid]::SetColumn($nameWrap, 0)
                    $rowGrid.Children.Add($nameWrap) | Out-Null
                } else {
                    [System.Windows.Controls.Grid]::SetColumn($nameText, 0)
                    $rowGrid.Children.Add($nameText) | Out-Null
                }
            } else {
                [System.Windows.Controls.Grid]::SetColumn($cb, 0)
                $rowGrid.Children.Add($cb) | Out-Null
            }
        }

        $capturedName = $name
        $capturedDesc = $desc
        $capturedLoc = if ($item.ContainsKey('Location')) { $item['Location'] } else { "" }
        $capturedWarning = if ($item.ContainsKey('Warning')) { $item['Warning'] } else { "" }
        $capturedSafety = if ($item.ContainsKey('SafetyLevel')) { $item['SafetyLevel'] } else { "" }
        $capturedSafetyNote = if ($item.ContainsKey('SafetyNote')) { $item['SafetyNote'] } else { "" }
        $capturedRowEl = $safetyRowEl
        $capturedDotEl = $safetyDotEl
        $capturedTextEl = $safetyTextEl
        $rowGrid.Add_MouseEnter({
            $DescTitleEl.Text = $capturedName
            Set-DescriptionText -Element $DescBodyEl -Text $capturedDesc -Location $capturedLoc -Warning $capturedWarning
            if ($capturedSafety) {
                $capturedDotEl.Fill = Get-SafetyColor -Level $capturedSafety
                $capturedTextEl.Inlines.Clear()
                $levelRun = New-Object System.Windows.Documents.Run -ArgumentList $capturedSafety
                $levelRun.Foreground = $capturedDotEl.Fill
                $levelRun.FontWeight = "SemiBold"
                $capturedTextEl.Inlines.Add($levelRun) | Out-Null
                if ($capturedSafetyNote) {
                    foreach ($part in [regex]::Split(" - $capturedSafetyNote", '(Warning!)')) {
                        if (-not $part) { continue }
                        $noteRun = New-Object System.Windows.Documents.Run -ArgumentList $part
                        if ($part -eq 'Warning!') {
                            $noteRun.Foreground = "#FF9500"
                            $noteRun.FontWeight = "Bold"
                        } else {
                            $noteRun.Foreground = $window.Resources["SubText"]
                        }
                        $capturedTextEl.Inlines.Add($noteRun) | Out-Null
                    }
                }
                $capturedRowEl.Visibility = "Visible"
            } else {
                $capturedRowEl.Visibility = "Collapsed"
            }
        }.GetNewClosure())

        $statusPanel = New-Object System.Windows.Controls.StackPanel
        $statusPanel.Orientation = "Horizontal"
        $statusPanel.VerticalAlignment = "Center"
        $dot = New-Object System.Windows.Shapes.Ellipse
        $dot.Width = 8
        $dot.Height = 8
        $dot.VerticalAlignment = "Center"
        $dot.Margin = "0,0,6,0"
        $statusLabel = New-Object System.Windows.Controls.TextBlock
        $statusLabel.VerticalAlignment = "Center"
        $statusLabel.TextTrimming = "CharacterEllipsis"

        $status = if ($ProgramStatus) { @{ HasStatus = $true; Color = "Gray"; Text = "-" } }
                  elseif ($NoStatus -or ($Toggles -and $item.Type -ne "Option")) { @{ HasStatus = $false } }
                  else { Get-ItemStatus -Item $item }
        if ($Toggles -and $toggleEntry) {
            $statusPanel.Children.Add($cb) | Out-Null
            $statusPanel.Children.Add($toggleEntry.Label) | Out-Null
        }
        if ($status.HasStatus) {
            $dot.Fill = $status.Color
            $statusLabel.Text = $status.Text
            $statusLabel.Foreground = $status.Color
            $statusPanel.Children.Add($dot) | Out-Null
            $statusPanel.Children.Add($statusLabel) | Out-Null
        }
        [System.Windows.Controls.Grid]::SetColumn($statusPanel, 1)
        $rowGrid.Children.Add($statusPanel) | Out-Null

        $boxStack.Children.Add($rowGrid) | Out-Null
        if ($ProgramStatus) {
            $dot.Visibility = "Collapsed"
            $ProgramStatusRows.Add([PSCustomObject]@{ Item = $item; Dot = $dot; Label = $statusLabel }) | Out-Null
        }

        $groupEntries.Add([PSCustomObject]@{
            Element     = $rowGrid
            Name        = $name
            Description = $desc
            Item        = $item
            StatusDot   = $dot
            StatusLabel = $statusLabel
            HasStatus   = $status.HasStatus
        }) | Out-Null
    }

    $box.Child = $boxStack
    $TargetCol.Children.Add($box) | Out-Null

    if ($sectionRows.Count -gt 0) {
        Set-ClickableHeading -TextBlock $tweaksHeader -Rows $sectionRows -What $Title
    }
    foreach ($g in $subGroups) {
        if ($g.Rows.Count -gt 0) {
            Set-ClickableHeading -TextBlock $g.Heading -Rows $g.Rows -What $g.Name
        }
        $grp = $g
        $syncSub = {
            $anyShown = @($grp.RowGrids | Where-Object { $_.Visibility -eq "Visible" }).Count -gt 0
            $grp.Heading.Visibility = if ($anyShown) { "Visible" } else { "Collapsed" }
        }.GetNewClosure()
        $AllHeaderSyncs.Add($syncSub) | Out-Null
    }

    $AllGroups.Add([PSCustomObject]@{
        Box     = $box
        Entries = $groupEntries
    }) | Out-Null
}

function Sort-SectionItems {
    param([array]$Items)
    $order = New-Object System.Collections.Generic.List[string]
    $groups = @{}
    foreach ($it in $Items) {
        $key = if ($it.ContainsKey('SubCategory') -and $it.SubCategory) { [string]$it.SubCategory } else { '' }
        if (-not $groups.ContainsKey($key)) {
            $groups[$key] = @()
            $order.Add($key)
        }
        $groups[$key] += ,$it
    }
    $mixed = @()
    $dropOnly = @()
    $other = @()
    foreach ($key in $order) {
        $boxes = @($groups[$key] | Where-Object { $_.Type -ne 'Option' })
        $drops = @($groups[$key] | Where-Object { $_.Type -eq 'Option' })
        if ($key -eq 'Other') { $other += $boxes + $drops }
        elseif ($boxes.Count -eq 0) { $dropOnly += $boxes + $drops }
        else { $mixed += $boxes + $drops }
    }
    return ,($mixed + $dropOnly + $other)
}

function Update-ItemVisibility {
    $query = $SearchBox.Text.Trim()
    foreach ($group in $AllGroups) {
        $anyVisible = $false
        foreach ($entry in $group.Entries) {
            $visible = [string]::IsNullOrEmpty($query) -or
                ($entry.Name -and $entry.Name.IndexOf($query, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) -or
                ($entry.Description -and $entry.Description.IndexOf($query, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
            $entry.Element.Visibility = if ($visible) { "Visible" } else { "Collapsed" }
            if ($visible) { $anyVisible = $true }
        }
        $group.Box.Visibility = if ($anyVisible) { "Visible" } else { "Collapsed" }
    }
    foreach ($sync in $AllHeaderSyncs) { & $sync }
}
