$taskband = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
Remove-Item -Path $taskband -Recurse -Force -ErrorAction SilentlyContinue
$quickLaunch = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch"
if (Test-Path $quickLaunch) {
    Get-ChildItem -Path $quickLaunch -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -notmatch 'File Explorer' } |
        ForEach-Object { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue }
}

if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force | Out-Null
}
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -PropertyType DWord -Force | Out-Null

return (-not (Test-Path $taskband))
