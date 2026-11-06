function Set-Progress {
    param([int]$Current, [int]$Total, [string]$Message)
    if (-not $SkipToken.Requested -and -not $CancelToken.Requested) { $BtnOverlaySkip.IsEnabled = $true }
    $barTotal = $Total + $script:ProgressExtraTotal
    $ProgressBar.Value = if ($barTotal -le 0) { 0 } else { [math]::Round((($Current + $script:ProgressExtraDone) / $barTotal) * 100) }
    if ($Message -match '^(Uninstalling|Installing|Applying|Deep Clean:|Restoring default:) (.+?)(?: - \d+%)?(?: \(\d+ of \d+\))?$') {
        $OverlayDetail.Text = "$($Matches[1]) $($Matches[2])"
    }
    Update-UI
}

function Invoke-OverlayTask {
    param([string]$Working, [scriptblock]$Work, [string]$Note = "", [switch]$NoCancel)
    Set-RunInProgress -Running $true
    $OverlayTitle.Text = $Working
    $script:OverlayTaskRunning = $true
    $titleRow = $window.FindName("OverlayTitleRow")
    $titleRow.Margin = $(if ($Note) { "0,0,0,4" } else { "0" })
    $BtnOverlaySkip.Visibility = "Collapsed"
    if ($NoCancel) { $OverlayRunButtons.Visibility = "Collapsed" }
    $ProgressBar.Visibility = "Collapsed"
    $OverlayDetail.Visibility = "Collapsed"
    if ($Note) {
        $OverlayNote.Text = $Note
        $OverlayNote.Visibility = "Visible"
    }
    Update-UI
    $result = & $Work
    $script:OverlayTaskRunning = $false
    $titleRow.Margin = "0,0,0,18"
    if ($CancelToken.Requested) {
        Set-RunInProgress -Running $false
        return
    }
    Show-OverlayComplete -Message $result.Message -Title $result.Title -Success:([bool]$result.Success)
}

function Show-OverlayComplete {
    param([string]$Message, [string]$Title = "Complete!", [switch]$Success)
    $Spinner.Visibility           = "Collapsed"
    $ProgressBar.Visibility       = "Collapsed"
    $OverlayDetail.Visibility     = "Collapsed"
    $OverlayNote.Visibility       = "Collapsed"
    $OverlayRunButtons.Visibility = "Collapsed"
    $OverlayTick.Visibility       = $(if ($Success -and -not $CancelToken.Requested) { "Visible" } else { "Collapsed" })
    $OverlayTitle.Text            = $(if ($CancelToken.Requested) { "Stopped" } else { $Title })
    $OverlayTitle.FontSize        = 20
    $OverlaySummary.Text          = $Message
    $OverlaySummary.Visibility    = $(if ($Message) { "Visible" } else { "Collapsed" })
    $BtnOverlayClose.Visibility   = "Visible"
    Update-UI
}

function Set-RunInProgress {
    param([bool]$Running)
    $BusyOverlay.Visibility = $(if ($Running) { "Visible" } else { "Collapsed" })
    if ($Running) {
        $Spinner.Visibility           = "Visible"
        $ProgressBar.Visibility       = "Visible"
        $ProgressBar.Value            = 0
        $OverlayTick.Visibility       = "Collapsed"
        $OverlayTitle.Text            = "Processing Selected Items"
        $OverlayTitle.FontSize        = 16
        $OverlayDetail.Text           = ""
        $OverlayDetail.Visibility     = "Visible"
        $OverlayNote.Visibility       = "Collapsed"
        $OverlaySummary.Visibility    = "Collapsed"
        $BtnOverlayClose.Visibility   = "Collapsed"
        $OverlayRunButtons.Visibility = "Visible"
        $BtnOverlayCancel.IsEnabled   = $true
        $BtnOverlaySkip.Visibility    = "Visible"
        $BtnOverlaySkip.IsEnabled     = $true
        $SkipToken.Requested          = $false
        $CancelToken.Requested        = $false
    } else {
        $script:ProgressExtraDone  = 0
        $script:ProgressExtraTotal = 0
    }
    foreach ($b in $ActionButtons) { $b.IsEnabled = -not $Running }
    foreach ($k in $NavButtons.Keys) { $NavButtons[$k].IsEnabled = -not $Running }
    $BtnAppsUninstall.IsEnabled = -not $Running
    $BtnAppsInstall.IsEnabled   = -not $Running
    $BtnDetectApps.IsEnabled    = -not $Running
    $BtnDetectTweaks.IsEnabled  = -not $Running
    $BtnRevertAll.IsEnabled     = -not $Running
    $SearchBox.IsEnabled        = -not $Running
}
