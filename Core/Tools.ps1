$DriversBackupFolder = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Drivers Backup - SimpleWin11'

$ToolGroups = [ordered]@{
    "Export System Drivers" = @(
        @{
            Name        = "Export Drivers"
            Icon        = [string][char]0xE950
            Description = "Export System Drivers to a folder on the desktop"
            Detail      = "Saved to: Desktop\Drivers Backup - SimpleWin11"
            Action      = { Export-SystemDrivers }
        }
    )
}

function Export-SystemDrivers {
    $dest = $DriversBackupFolder
    if (@(Get-ChildItem -LiteralPath $dest -Force -ErrorAction SilentlyContinue).Count -gt 0) {
        if (-not (Show-ConfirmDialog -Question "Replace the existing driver backup?" -Detail "The `"Drivers Backup - SimpleWin11`" folder on the desktop already has files in it. They will be deleted and replaced.")) { return }
        Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $total = @(Get-ChildItem -Path "$env:SystemRoot\INF" -Filter 'oem*.inf' -ErrorAction SilentlyContinue).Count
    Set-RunInProgress -Running $true
    $OverlayTitle.Text = "Extracting System Drivers"
    $OverlayDetail.Text = "Saving to a folder on the desktop"
    $BtnOverlaySkip.Visibility = "Collapsed"
    Update-UI
    $proc = Start-Process -FilePath "$env:SystemRoot\System32\dism.exe" -ArgumentList "/English /Online /Export-Driver /Destination:`"$dest`"" -WindowStyle Hidden -PassThru
    $null = $proc.Handle
    while (-not $proc.HasExited) {
        if ($CancelToken.Requested) {
            try { $proc.Kill() } catch { }
            break
        }
        $done = @(Get-ChildItem -LiteralPath $dest -Directory -ErrorAction SilentlyContinue).Count
        if ($total -gt 0) { $ProgressBar.Value = [math]::Min(99, [math]::Round(($done / $total) * 100)) }
        Wait-UI -Milliseconds 250
    }
    if ($CancelToken.Requested) {
        Set-RunInProgress -Running $false
        return
    }
    $ProgressBar.Value = 100
    $count = @(Get-ChildItem -LiteralPath $dest -Directory -ErrorAction SilentlyContinue).Count
    if ($proc.ExitCode -eq 0) {
        Show-OverlayComplete -Success -Title "Drivers Exported!" -Message "$count drivers saved to:`n$dest"
    } else {
        Show-OverlayComplete -Title "Export Failed" -Message ("Windows couldn't export the drivers (error 0x{0:X8})." -f ([int64]$proc.ExitCode -band 0xFFFFFFFF))
    }
}
