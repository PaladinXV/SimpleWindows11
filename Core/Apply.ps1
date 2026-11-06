function ConvertTo-BatchInput {
    param([array]$Items)
    $out = @()
    foreach ($item in $Items) {
        $out += @{
            Name              = $item.Name
            AppxIds           = @($item.AppxIds)
            StopProcesses     = @($item.StopProcesses)
            RemoveProvisioned = [bool]$item.RemoveProvisioned
        }
    }
    return $out
}

$ApplyAction = {
    $scopes = if ($script:ApplyAllScopes) { @("Config", "AppsUninstall", "AppsInstall", "ProgramsWinget", "ProgramsChoco") } else { @(Get-CurrentScope) }
    $onConfigPage = ($scopes -contains "Config")
    $toggleCbs = @($ConfigToggles | ForEach-Object { $_.Cb })
    $configCbx = @($ConfigCombos | ForEach-Object { $_.Combo })
    $turnOn = @()
    $turnOff = @()
    $changedCombos = @()
    if ($onConfigPage) {
        $turnOn = @($ConfigToggles | Where-Object { $_.Cb.IsChecked -eq $true -and -not $_.Baseline } | ForEach-Object { $_.Cb })
        $turnOff = @($ConfigToggles | Where-Object { $_.Cb.IsChecked -ne $true -and $_.Baseline -and $_.Item.ContainsKey('Revert') } | ForEach-Object { $_.Cb })
        $changedCombos = @($ConfigCombos | Where-Object { $_.Combo.SelectedIndex -ge 0 -and ($_.Combo.SelectedIndex + 1) -ne $_.Baseline } | ForEach-Object { $_.Combo })
    }
    $selected = @($AllCheckboxes | Where-Object { $_.IsChecked -eq $true -and $toggleCbs -notcontains $_ -and $scopes -contains $ControlScope[$_] }) + $turnOn
    $selectedOptions = @($AllOptionSelectors | Where-Object { $_.SelectedIndex -ge 0 -and $configCbx -notcontains $_ -and $scopes -contains $ControlScope[$_] }) + $changedCombos
    $selectedOptions = @($selectedOptions | Where-Object { $_.Tag.RunFirst }) + @($selectedOptions | Where-Object { -not $_.Tag.RunFirst })
    $total = $selected.Count + $selectedOptions.Count + $turnOff.Count
    $script:ProgressExtraDone = 0
    $script:ProgressExtraTotal = if ($script:DeepClean) { @($selected | Where-Object { $_.Tag.Category -eq "System Apps" -and $_.Tag.ContainsKey("AppxIds") -and $_.Tag.AppxIds }).Count } else { 0 }
    if ($total -eq 0) {
        Show-AppMessage -Message ("No changes to apply")
        return
    }
    $onPrograms = ($Pages["Programs"].Visibility -eq "Visible")
    $installRun = $onPrograms -or (($Pages["Apps"].Visibility -eq "Visible") -and ($AppsInstallList.Visibility -eq "Visible"))
    if (@($selected | Where-Object { $ControlScope[$_] -eq "ProgramsWinget" }).Count -gt 0 -and -not (Test-CommandExists winget)) {
        Show-AppMessage -Message ("Winget not detected.`n`nInstall it with the Install / Update Winget button above the list.")
        return
    }
    if (@($selected | Where-Object { $ControlScope[$_] -eq "ProgramsChoco" }).Count -gt 0 -and -not (Test-CommandExists choco)) {
        Show-AppMessage -Message ("Chocolatey not detected.`n`nInstall it with the Install Chocolatey button above the list.")
        return
    }
    Set-RunInProgress -Running $true
    $appCount = 0
    $failedApps = New-Object System.Collections.Generic.List[string]
    $skippedItems = New-Object System.Collections.Generic.List[string]
    $failedRemovals = New-Object System.Collections.Generic.List[string]
    $i = 0

    $scopeLabels = @{ Config = "Configuration"; AppsUninstall = "Windows Apps - Uninstall"; AppsInstall = "Windows Apps - Install"; ProgramsWinget = "User Apps - Winget"; ProgramsChoco = "User Apps - Chocolatey" }
    $script:RunLogLabel = if ($script:ApplyAllScopes) { "All pages (imported config)" } else { $scopeLabels[$scopes[0]] }
    if ($script:DeepClean -and @($selected | Where-Object { $ControlScope[$_] -eq "AppsUninstall" }).Count -gt 0) { $script:RunLogLabel += " - Deep Clean on" }
    "=== Run started ===" | Write-RunLog

    $hasInstalls = @($selected | Where-Object { $_.Tag.ContainsKey("Id") -or $_.Tag.ContainsKey("ChocoId") }).Count -gt 0
    if ($hasInstalls -and $onPrograms) {
        $OverlayNote.Text = "Apps may take some time depending on your connection speed."
        $OverlayNote.Visibility = "Visible"
        Update-UI
    }
    $internetOk = (-not $hasInstalls) -or (Test-InternetConnection)
    if (-not $internetOk) {
        Show-AppMessage -Message "No internet connection detected`n`nApps that need downloading will be skipped."
        "No internet connection detected - installs skipped" | Write-RunLog
    }

    $appxItems = @()
    $serialItems = New-Object System.Collections.Generic.List[object]
    $lastItems = New-Object System.Collections.Generic.List[object]
    foreach ($cb in $selected) {
        $item = $cb.Tag
        if ($item.Category -eq "System Apps" -and $item.ContainsKey("AppxIds") -and $item.AppxIds) {
            $appxItems += $item
        } elseif ($item.RunLast) {
            $lastItems.Add($cb) | Out-Null
        } else {
            $serialItems.Add($cb) | Out-Null
        }
    }

    if ($appxItems.Count -gt 0) {
        foreach ($item in $appxItems) {
            if ($item.BlockReinstall) {
                Block-OobeReinstall -App $item.BlockReinstall
                "Blocked Windows Update reinstall job for $($item.Name)" | Write-RunLog
            }
        }

        $batchInput = ConvertTo-BatchInput -Items $appxItems
        foreach ($item in $appxItems) {
            "Starting uninstall: $($item.Name)" | Write-RunLog
        }

        $batchBase = $i
        $batchTotal = $total
        $progressCallback = {
            param($msg, $done, $tot)
            Set-Progress -Current ($batchBase + $done) -Total $batchTotal -Message $msg
        }.GetNewClosure()

        $appxResults = Invoke-AppxRemovalBatch -Items $batchInput -OnProgress $progressCallback `
            -IndexOffset $batchBase -GrandTotal $batchTotal -CancelToken $CancelToken

        foreach ($item in $appxItems) {
            $i++
            $r = $appxResults[$item.Name]
            $secs = if ($r -and $r.ContainsKey('Seconds')) { " [$($r.Seconds)s]" } else { "" }
            if ($r -and $r.Success) {
                $pathNote = if ($r.Path) { " via $($r.Path)" } else { "" }
                $why = if ($r.CheapError) { " [fast path failed: $($r.CheapError)]" } else { "" }
                $provNote = ""
                if ($null -ne $r.ProvFound) {
                    $provNote = " | provisioned: found $($r.ProvFound) via $($r.ProvCmdlet)"
                    if ($r.ProvError) { $provNote += " FAILED: $($r.ProvError)" }
                }
                "Finished uninstall: $($item.Name)$secs$pathNote$why$provNote" | Write-RunLog
            } elseif ($r -and $r.Skipped) {
                $skippedItems.Add($item.Name)
                "Skipped uninstall: $($item.Name) - skipped with the Skip button" | Write-RunLog
            } elseif ($r -and $r.Cancelled) {
                "Cancelled: $($item.Name)" | Write-RunLog
            } else {
                $reason = if ($r -and $r.Error) { $r.Error } else { "unknown error" }
                $failedRemovals.Add("$($item.Name) - $reason")
                "Failed uninstall: $($item.Name)$secs - $reason" | Write-RunLog
            }

            if ($item.PostApply) {
                try { & $item.PostApply }
                catch { "PostApply failed: $($item.Name) - $($_.Exception.Message)" | Write-RunLog }
            }
        }

        if ($script:DeepClean -and -not $CancelToken.Requested) {
            $k = 0
            foreach ($item in $appxItems) {
                if ($CancelToken.Requested) { break }
                $k++
                $script:ProgressExtraDone = $k
                $r = $appxResults[$item.Name]
                if ($r -and ($r.Skipped -or $r.Cancelled)) { continue }
                $SkipToken.Requested = $false
                Set-Progress -Current $i -Total $total -Message "Deep Clean: $($item.Name) ($k of $($appxItems.Count))"
                $dc = Invoke-DeepClean -Name $item.Name -AppxIds @($item.AppxIds)
                if ($dc.Skipped) {
                    $skippedItems.Add("$($item.Name) (Deep Clean)")
                    "Skipped deep: $($item.Name) - skipped with the Skip button" | Write-RunLog
                } elseif ($dc.Cancelled) {
                    "Cancelled deep: $($item.Name)" | Write-RunLog
                    break
                } elseif ($dc.Success) {
                    "Finished deep: $($item.Name) [$($dc.Seconds)s] via all users" | Write-RunLog
                } else {
                    $failedRemovals.Add("$($item.Name) (Deep Clean) - $($dc.Error)")
                    "Failed deep: $($item.Name) [$($dc.Seconds)s] - $($dc.Error)" | Write-RunLog
                }
            }
        }
    }

    foreach ($cb in $serialItems) {
        if ($CancelToken.Requested) { break }
        $i++
        $item = $cb.Tag
        $SkipToken.Requested = $false
        if ($item.ContainsKey("ChocoId")) {
            "Starting install: $($item.Name) (Chocolatey)" | Write-RunLog
            Set-Progress -Current $i -Total $total -Message "Installing $($item.Name) ($i of $total)"
            if (-not $internetOk) {
                $failedApps.Add("$($item.Name) (no internet)")
                "Skipped install: $($item.Name) - internet check failed" | Write-RunLog
                continue
            }
            $installStart = Get-Date
            $result = Install-ChocoApp -Id $item.ChocoId -CancelToken $CancelToken
            if ($result.Skipped) {
                $skippedItems.Add($item.Name)
                "Skipped install: $($item.Name) - skipped with the Skip button" | Write-RunLog
            } elseif ($result.Cancelled) {
                "Cancelled install: $($item.Name) - stopped with Cancel" | Write-RunLog
                break
            } elseif ($result.AlreadyInstalled) {
                "Already installed: $($item.Name)" | Write-RunLog
            } elseif ($result.Success) {
                $appCount++
                "Finished install: $($item.Name) [$([math]::Round(((Get-Date) - $installStart).TotalSeconds,1))s] via Chocolatey" | Write-RunLog
            } else {
                $why = if ($result.ExitCode -eq -1) { "Chocolatey not installed" } else { "choco exit code $($result.ExitCode)" }
                $failedApps.Add("$($item.Name) ($why)")
                "Failed install: $($item.Name) - $why" | Write-RunLog
                if ($result.Output) { "    choco said: $($result.Output)" | Write-RunLog }
            }
        } elseif ($item.ContainsKey("Id")) {
            if (-not $internetOk) {
                $failedApps.Add("$($item.Name) (no internet)")
                "Skipped install: $($item.Name) - internet check failed" | Write-RunLog
                continue
            }
            "Starting install: $($item.Name)" | Write-RunLog
            Set-Progress -Current $i -Total $total -Message "Installing $($item.Name) ($i of $total)"
            $installStart = Get-Date
            if ($item.AppxIds -and @($item.AppxIds).Count -gt 0) {
                $rr = Restore-StagedAppx -AppxIds $item.AppxIds
                if ($rr.Skipped) {
                    $skippedItems.Add($item.Name)
                    "Skipped install: $($item.Name) - skipped with the Skip button" | Write-RunLog
                    continue
                }
                if ($rr.Restored) {
                    $appCount++
                    "Finished install: $($item.Name) [$([math]::Round(((Get-Date) - $installStart).TotalSeconds,1))s] via re-register - files were still on disk" | Write-RunLog
                    continue
                }
            }
            $onProgress = { param($pct) Set-Progress -Current $i -Total $total -Message "Installing $($item.Name) - $pct% ($i of $total)" }.GetNewClosure()
            $result = Install-WingetApp -Id $item.Id -Source $(if ($item.Source) { $item.Source } else { "winget" }) -OnProgress $onProgress -CancelToken $CancelToken
            if ($result.Skipped) {
                $skippedItems.Add($item.Name)
                "Skipped install: $($item.Name) - skipped with the Skip button" | Write-RunLog
            } elseif ($result.Cancelled) {
                "Cancelled install: $($item.Name) - stopped with Cancel" | Write-RunLog
                break
            } elseif ($result.AlreadyInstalled) {
                "Already installed: $($item.Name)" | Write-RunLog
            } elseif ($result.Success) {
                $appCount++
                Close-AppsLaunchedSince -NamePattern $item.CloseAfterInstall -Since $installStart
                "Finished install: $($item.Name) [$([math]::Round(((Get-Date) - $installStart).TotalSeconds,1))s] via winget" | Write-RunLog
            } elseif ($(Get-AppxSnapshot -Refresh | Out-Null; try { [bool](& $item.Detect) } catch { $false })) {
                $appCount++
                Close-AppsLaunchedSince -NamePattern $item.CloseAfterInstall -Since $installStart
                "Finished install: $($item.Name) [$([math]::Round(((Get-Date) - $installStart).TotalSeconds,1))s] via winget - winget reported $($result.Hex) but the app IS installed" | Write-RunLog
            } else {
                $why = if ($result.ExitCode -eq -1) { "winget not found - is App Installer present?" }
                       elseif ($result.ExitCode -eq -1978335212) { "not found in the catalogue ($($result.Hex)) - ID may be wrong" }
                       else { "winget error $($result.Hex)" }
                $failedApps.Add("$($item.Name) ($why)")
                "Failed install: $($item.Name) - $why" | Write-RunLog
                if ($result.Output) { "    winget said: $($result.Output)" | Write-RunLog }
            }
        } elseif ($item.Category -eq "System Apps") {
            "Starting uninstall: $($item.Name)" | Write-RunLog
            Set-Progress -Current $i -Total $total -Message "Uninstalling $($item.Name) ($i of $total)"
            $itemStart = Get-Date
            try {
                & $item.Apply
                $secs = [math]::Round(((Get-Date) - $itemStart).TotalSeconds, 1)
                "Finished uninstall: $($item.Name) [${secs}s]" | Write-RunLog
            } catch {
                $secs = [math]::Round(((Get-Date) - $itemStart).TotalSeconds, 1)
                if ($_.Exception -is [System.OperationCanceledException]) {
                    $skippedItems.Add($item.Name)
                    "Skipped uninstall: $($item.Name) [${secs}s] - skipped with the Skip button" | Write-RunLog
                } else {
                    $failedRemovals.Add("$($item.Name) - $($_.Exception.Message)")
                    "Failed uninstall: $($item.Name) [${secs}s] - $($_.Exception.Message)" | Write-RunLog
                }
            }
        } elseif ($item.ContainsKey("Apply")) {
            "Starting apply: $($item.Name)" | Write-RunLog
            Set-Progress -Current $i -Total $total -Message "Applying $($item.Name) ($i of $total)"
            try {
                & $item.Apply
                "Finished apply: $($item.Name)" | Write-RunLog
            } catch {
                "Failed apply: $($item.Name) - $($_.Exception.Message)" | Write-RunLog
            }
        }
    }

    $unpinRan = $false
    foreach ($cb in $lastItems) {
        if ($CancelToken.Requested) { break }
        $SkipToken.Requested = $false
        $unpinRan = $true
        $i++
        $item = $cb.Tag
        "Starting apply: $($item.Name)" | Write-RunLog
        Set-Progress -Current $i -Total $total -Message "Applying $($item.Name) ($i of $total)"
        try {
            & $item.Apply
            "Finished apply: $($item.Name)" | Write-RunLog
        } catch {
            $failedRemovals.Add("$($item.Name) - $($_.Exception.Message)")
            "Failed apply: $($item.Name) - $($_.Exception.Message)" | Write-RunLog
        }
    }

    foreach ($cb in $turnOff) {
        if ($CancelToken.Requested) { break }
        $SkipToken.Requested = $false
        $i++
        $item = $cb.Tag
        "Starting default: $($item.Name)" | Write-RunLog
        Set-Progress -Current $i -Total $total -Message "Restoring default: $($item.Name) ($i of $total)"
        try {
            & $item.Revert
            "Finished default: $($item.Name)" | Write-RunLog
        } catch {
            $failedRemovals.Add("$($item.Name) - $($_.Exception.Message)")
            "Failed default: $($item.Name) - $($_.Exception.Message)" | Write-RunLog
        }
    }

    foreach ($combo in $selectedOptions) {
        if ($CancelToken.Requested) { break }
        $SkipToken.Requested = $false
        $i++
        $item = $combo.Tag
        $chosenOption = $item.Options[$combo.SelectedIndex]
        "Starting apply: $($item.Name) -> $($chosenOption.Label)" | Write-RunLog
        Set-Progress -Current $i -Total $total -Message "Applying $($item.Name): $($chosenOption.Label) ($i of $total)"
        try {
            & $chosenOption.Apply
            "Finished apply: $($item.Name) -> $($chosenOption.Label)" | Write-RunLog
        } catch {
            "Failed apply: $($item.Name) -> $($chosenOption.Label) - $($_.Exception.Message)" | Write-RunLog
        }
    }

    Set-Progress -Current $total -Total $total -Message "Checking..."
    Get-AppxSnapshot -Refresh | Out-Null
    Update-AllStatuses
    Sync-ConfigToSystem
    foreach ($cb in $AllCheckboxes) {
        if (($scopes -contains $ControlScope[$cb]) -and $toggleCbs -notcontains $cb) { $cb.IsChecked = $false }
    }

    $anyFailed = ($failedApps.Count -gt 0 -or $failedRemovals.Count -gt 0)
    $summary = if ($installRun) {
        if ($CancelToken.Requested) { "" }
        elseif ($anyFailed) { "Some items failed - see the log" }
        else { "Selected items have been installed" }
    } else {
        if ($CancelToken.Requested) { "Stopped early. Restart your PC to finish applying the changes that were made" }
        else { "Restart your PC to finish applying all changes" }
    }
    if ($anyFailed -and -not $installRun) {
        $summary += "`nSome items failed - see the log"
    }
    if ($skippedItems.Count -gt 0 -and -not $CancelToken.Requested) {
        $summary += "`nSkipped: " + ($skippedItems -join ", ")
    }
    Set-Progress -Current $total -Total $total -Message $summary

    if ($unpinRan) {
        "Pins cleared - applies at next restart" | Write-RunLog
    }
    "=== Run completed ===" | Write-RunLog

    $heading = if ($script:ApplyAllScopes)                     { "Imported config applied" }
               elseif ($Pages["Config"].Visibility -eq "Visible") { "Selected changes applied" }
               elseif ($installRun -and $appCount -eq 0 -and $anyFailed) { "Install failed" }
               elseif ($installRun)                            { "Install Complete!" }
               else                                            { "Selected Apps Uninstalled!" }
    if ($CancelToken.Requested) {
        Set-RunInProgress -Running $false
        return
    }
    Show-OverlayComplete -Message $summary -Title $heading
}
