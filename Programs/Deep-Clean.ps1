param([string]$Ids)

$ProgressPreference = 'SilentlyContinue'
$errors = @()
$idList = @($Ids -split ';' | Where-Object { $_ })

foreach ($id in $idList) {
    foreach ($pkg in @(Get-AppxPackage -AllUsers -Name $id -ErrorAction SilentlyContinue)) {
        try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop }
        catch { $errors += $_.Exception.Message }
    }
}

try {
    $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object { $idList -contains $_.DisplayName })
    foreach ($pp in $provisioned) {
        try { Remove-AppxProvisionedPackage -Online -PackageName $pp.PackageName -ErrorAction Stop | Out-Null }
        catch { $errors += $_.Exception.Message }
    }
} catch {
    $errors += "Could not list provisioned apps: $($_.Exception.Message)"
}

if ($errors.Count -gt 0) {
    Write-Output $errors[0]
    exit 1
}
Write-Output "OK"
exit 0
