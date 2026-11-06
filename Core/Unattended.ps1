$UnattendedPlaceholder = '# Placeholder for User Config'

$UnattendedSourceFiles = @(
    "Modules\Helpers.ps1", "Setup\Personalization.ps1", "Setup\StartMenu.ps1", "Setup\Privacy.ps1", "Setup\Miscellaneous.ps1",
    "Setup\WindowsUpdates.ps1", "Setup\Defender.ps1", "Setup\EdgeTweaks.ps1", "Setup\FolderOptions.ps1", "Setup\Mouse.ps1",
    "Setup\Sound.ps1", "Setup\Taskbar.ps1", "Setup\Gaming.ps1", "Setup\ScheduledTasks.ps1", "Setup\Power.ps1",
    "Setup\Laptop.ps1", "Setup\Notifications.ps1", "Setup\DNS.ps1", "Programs\AppRemoval.ps1"
)

function Get-UnattendedSourceIndex {
    $funcs = @{}
    $assigns = @{}
    foreach ($rel in $UnattendedSourceFiles) {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $script:ToolRoot $rel), [ref]$null, [ref]$null)
        foreach ($fd in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) { $funcs[$fd.Name] = $fd.Extent.Text }
        foreach ($st in $ast.EndBlock.Statements) {
            if ($st -is [System.Management.Automation.Language.AssignmentStatementAst] -and $st.Left -is [System.Management.Automation.Language.VariableExpressionAst]) {
                $name = $st.Left.VariablePath.UserPath
                if ($name -notmatch 'Tweaks$|Preset|Removal|^AppDescriptions$|^SystemAppsList$|^AppRemovals$') { $assigns[$name] = $st.Extent.Text }
            }
        }
    }
    $funcs['Wait-UI'] = 'function Wait-UI { param([int]$Milliseconds = 50) Start-Sleep -Milliseconds $Milliseconds }'
    @{ Functions = $funcs; Assignments = $assigns }
}

function Get-UnattendedReferences {
    param([string]$Text)
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$null, [ref]$null)
    [PSCustomObject]@{
        Commands  = @($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ } | Sort-Object -Unique)
        Variables = @($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) | ForEach-Object { $_.VariablePath.UserPath } | Sort-Object -Unique)
    }
}

function ConvertTo-UnattendedLiteral {
    param($Value)
    if ($Value -is [array]) { return '@(' + (($Value | ForEach-Object { ConvertTo-UnattendedLiteral $_ }) -join ', ') + ')' }
    if ($Value -is [int] -or $Value -is [long] -or $Value -is [byte]) { return "$Value" }
    if ($Value -is [bool]) { return '$' + "$Value".ToLower() }
    return "'" + ("$Value" -replace "'", "''") + "'"
}

function Get-UnattendedBlockText {
    param([scriptblock]$Block, [hashtable]$Assignments)
    $body = $Block.ToString().Trim()
    $lines = @()
    if ($Block.Module) {
        foreach ($name in (Get-UnattendedReferences $body).Variables) {
            if ($name -in '_', 'true', 'false', 'null' -or $Assignments.ContainsKey($name)) { continue }
            $value = & $Block.Module { param($n) Get-Variable -Name $n -ValueOnly -ErrorAction SilentlyContinue } $name
            if ($null -ne $value) { $lines += "`$$name = $(ConvertTo-UnattendedLiteral $value)" }
        }
    }
    (@($lines) + $body) -join "`n"
}

function Get-UnattendedSelection {
    param([ValidateSet('Recommended', 'Aggressive', 'Config', 'Current')][string]$Base, $ConfigData)
    $steps = New-Object System.Collections.Generic.List[object]
    $apps = @()
    $winget = @()
    $choco = @()
    if ($Base -eq 'Current') {
        foreach ($e in $ConfigToggles) {
            if ($e.Cb.IsChecked -eq $true) { $steps.Add(@{ Name = $e.Item.Name; Block = $e.Item.Apply }) }
        }
        foreach ($e in $ConfigCombos) {
            $index = $e.Combo.SelectedIndex
            if ($index -lt 0 -or ($index + 1) -eq (Get-DefaultOptionIndex -Item $e.Item)) { continue }
            $option = $e.Item.Options[$index]
            $steps.Add(@{ Name = "$($e.Item.Name): $($option.Label)"; Block = $option.Apply })
        }
        $apps = @($AllCheckboxes | Where-Object { $ControlScope[$_] -eq 'AppsUninstall' -and $_.IsChecked -eq $true } | ForEach-Object { $_.Tag.Name })
        $winget = @($AllCheckboxes | Where-Object { $ControlScope[$_] -eq 'ProgramsWinget' -and $_.IsChecked -eq $true } | ForEach-Object { $_.Tag.Name })
        $choco = @($AllCheckboxes | Where-Object { $ControlScope[$_] -eq 'ProgramsChoco' -and $_.IsChecked -eq $true } | ForEach-Object { $_.Tag.Name })
    } elseif ($Base -eq 'Config') {
        if ($ConfigData.Configuration.Switches) {
            foreach ($prop in $ConfigData.Configuration.Switches.PSObject.Properties) {
                if (-not $prop.Value) { continue }
                $tweak = $Tweaks | Where-Object { $_.Name -eq $prop.Name -and $_.Type -ne 'Option' } | Select-Object -First 1
                if ($tweak) { $steps.Add(@{ Name = $tweak.Name; Block = $tweak.Apply }) }
            }
        }
        if ($ConfigData.Configuration.Dropdowns) {
            foreach ($prop in $ConfigData.Configuration.Dropdowns.PSObject.Properties) {
                $tweak = $Tweaks | Where-Object { $_.Name -eq $prop.Name -and $_.Type -eq 'Option' } | Select-Object -First 1
                if (-not $tweak) { continue }
                $wanted = [string]$prop.Value -replace '\s*\(.*\)$', ''
                for ($n = 0; $n -lt $tweak.Options.Count; $n++) {
                    if (($tweak.Options[$n].Label -replace '\s*\(.*\)$', '') -ne $wanted) { continue }
                    if (($n + 1) -ne (Get-DefaultOptionIndex -Item $tweak)) { $steps.Add(@{ Name = "$($tweak.Name): $($tweak.Options[$n].Label)"; Block = $tweak.Options[$n].Apply }) }
                    break
                }
            }
        }
        if ($ConfigData.WindowsApps -and $ConfigData.WindowsApps.Uninstall) { $apps = @($ConfigData.WindowsApps.Uninstall) }
        if ($ConfigData.UserApps -and $ConfigData.UserApps.Winget) { $winget = @($ConfigData.UserApps.Winget) }
        if ($ConfigData.UserApps -and $ConfigData.UserApps.Chocolatey) { $choco = @($ConfigData.UserApps.Chocolatey) }
    } else {
        foreach ($entry in $ConfigPresets[$Base]) {
            if ($entry -is [string]) {
                $tweak = $Tweaks | Where-Object { $_.Name -eq $entry } | Select-Object -First 1
                if ($tweak) { $steps.Add(@{ Name = $entry; Block = $tweak.Apply }) }
            } else {
                $tweak = $Tweaks | Where-Object { $_.Name -eq $entry.Name } | Select-Object -First 1
                $option = $tweak.Options | Where-Object { $_.Label -like "$($entry.Option)*" } | Select-Object -First 1
                if ($option) { $steps.Add(@{ Name = "$($entry.Name): $($option.Label)"; Block = $option.Apply }) }
            }
        }
        $apps = @($AppPresets[$Base])
    }
    @{
        Steps  = $steps
        Apps   = $apps
        Winget = @($WingetApps | Where-Object { $winget -contains $_.Name })
        Choco  = @($ChocoApps | Where-Object { $choco -contains $_.Name } | ForEach-Object { $_.ChocoId })
    }
}

function New-UnattendedScript {
    param([ValidateSet('Recommended', 'Aggressive', 'Config', 'Current')][string]$Base, $ConfigData)
    $index = Get-UnattendedSourceIndex
    $selection = Get-UnattendedSelection -Base $Base -ConfigData $ConfigData
    $apps = @($selection.Apps)
    $configSteps = $selection.Steps

    $embed = { param($rel) "& {`n" + (Get-Content -Raw -LiteralPath (Join-Path $script:ToolRoot $rel)).Trim() + "`n} | Out-Null" }
    $appxIds = @()
    $blocks = @()
    foreach ($name in $apps) {
        $app = $AppRemovals | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if ($app -and $app.ContainsKey('AppxIds') -and $app.AppxIds) {
            $appxIds += $app.AppxIds
            if ($app.BlockReinstall) { $blocks += "Block-OobeReinstall -App '$($app.BlockReinstall)'" }
        }
    }
    $code = New-Object System.Collections.Generic.List[string]
    if ($blocks) { $code.Add($blocks -join "`n") }
    if ($appxIds) { $code.Add("Remove-AppsAllUsers -Ids @(" + (($appxIds | Sort-Object -Unique | ForEach-Object { "'$_'" }) -join ', ') + ")") }
    if ($apps -contains 'Copilot') { $code.Add((& $embed 'Programs\Remove-Copilot.ps1')) }
    if ($apps -contains 'Microsoft Edge') { $code.Add((& $embed 'Programs\Remove-Edge.ps1')) }
    if ($apps -contains 'OneDrive') { $code.Add(@'
for ($i = 0; $i -lt 60 -and (Get-Process -Name 'OneDriveSetup' -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
Get-Process -Name 'OneDrive', 'OneDriveSetup' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDriveSetup', 'OneDrive' -ErrorAction SilentlyContinue
& reg.exe load 'HKU\SWSDefault' "$env:SystemDrive\Users\Default\NTUSER.DAT" 2>&1 | Out-Null
& reg.exe delete 'HKU\SWSDefault\Software\Microsoft\Windows\CurrentVersion\Run' /v 'OneDriveSetup' /f 2>&1 | Out-Null
[gc]::Collect()
& reg.exe unload 'HKU\SWSDefault' 2>&1 | Out-Null
$installers = @(Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Filter 'OneDriveSetup.exe' -Recurse -ErrorAction SilentlyContinue | ForEach-Object FullName) +
    @("$env:SystemRoot\System32\OneDriveSetup.exe", "$env:SystemRoot\SysWOW64\OneDriveSetup.exe", "$env:ProgramFiles\Microsoft OneDrive\OneDriveSetup.exe") | Where-Object { Test-Path $_ }
foreach ($exe in ($installers | Select-Object -Unique)) {
    Start-Process -FilePath $exe -ArgumentList '/uninstall' -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
}
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Force -ErrorAction SilentlyContinue
'@) }
    if ($apps -contains 'Microsoft Teams') { $code.Add('Remove-TeamsMachineWideInstaller') }
    foreach ($step in $configSteps) {
        $text = Get-UnattendedBlockText -Block $step.Block -Assignments $index.Assignments
        if ($text.Trim()) { $code.Add($text) }
    }
    if ($apps -contains 'Clear Start Menu Apps') { $code.Add((& $embed 'Setup\Clear-StartMenuPins.ps1')) }
    if ($apps -contains 'Clear Task Bar Apps') { $code.Add((& $embed 'Setup\Clear-TaskbarPins.ps1')) }
    if ($selection.Winget -or $selection.Choco) {
        $programs = New-Object System.Collections.Generic.List[string]
        $programs.Add(@'
$online = $false
for ($i = 0; $i -lt 30 -and -not $online; $i++) {
    try { $online = (Invoke-WebRequest -Uri 'http://www.msftconnecttest.com/connecttest.txt' -UseBasicParsing -TimeoutSec 5).Content -eq 'Microsoft Connect Test' } catch { }
    if (-not $online) { Start-Sleep -Seconds 2 }
}
if ($online) {
'@)
        if ($selection.Winget) {
            $list = ($selection.Winget | ForEach-Object { "@('$($_.Id)', '$(if ($_.Source) { $_.Source } else { 'winget' })')" }) -join ', '
            $programs.Add(@"
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction SilentlyContinue }
    for (`$i = 0; `$i -lt 30 -and -not (Get-Command winget.exe -ErrorAction SilentlyContinue); `$i++) { Start-Sleep -Seconds 2 }
    foreach (`$app in @($list)) {
        & winget.exe install --id `$app[0] -e -s `$app[1] --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
"@)
        }
        if ($selection.Choco) {
            $list = ($selection.Choco | ForEach-Object { "'$_'" }) -join ' '
            $programs.Add(@"
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Update-SessionPath
    }
    & "`$env:ProgramData\chocolatey\bin\choco.exe" install $list -y --no-progress
"@)
        }
        $programs.Add('}')
        $code.Add(($programs -join "`n"))
    }
    $code.Add(@'
Set-Content -Path (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Simple-Windows-11-Tool.txt') -Encoding UTF8 -Value @"
Thank you for using the Simple Windows 11 Tool unattended

Github
https://github.com/PaladinXV/SimpleWindows11

Tool (Copy + Paste into Terminal/PowerShell)
irm "https://raw.githubusercontent.com/PaladinXV/SimpleWindows11/main/Launch.ps1" | iex
"@
'@)

    $needFunctions = New-Object System.Collections.Generic.HashSet[string]
    $needVariables = New-Object System.Collections.Generic.HashSet[string]
    'Set-Reg', 'Remove-Reg' | ForEach-Object { [void]$needFunctions.Add($_) }
    $queue = New-Object System.Collections.Generic.Queue[string]
    $queue.Enqueue(($code -join "`n"))
    while ($queue.Count -gt 0) {
        $refs = Get-UnattendedReferences $queue.Dequeue()
        foreach ($v in $refs.Variables) { if ($index.Assignments.ContainsKey($v) -and $needVariables.Add($v)) { $queue.Enqueue($index.Assignments[$v]) } }
        foreach ($c in $refs.Commands) { if ($index.Functions.ContainsKey($c) -and $needFunctions.Add($c)) { $queue.Enqueue($index.Functions[$c]) } }
    }

    $out = New-Object System.Text.StringBuilder
    [void]$out.AppendLine("if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Warning 'Run this script as administrator.'; exit 1 }")
    [void]$out.AppendLine("`$ProgressPreference = 'SilentlyContinue'")
    [void]$out.AppendLine(@'
function Remove-AppsAllUsers {
    param([string[]]$Ids)
    $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)
    foreach ($id in $Ids) {
        foreach ($pkg in @(Get-AppxPackage -AllUsers -Name $id -ErrorAction SilentlyContinue)) {
            try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop }
            catch { try { Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop } catch { } }
        }
        foreach ($pp in @($provisioned | Where-Object { $_.DisplayName -eq $id })) {
            try { Remove-AppxProvisionedPackage -Online -PackageName $pp.PackageName -AllUsers -ErrorAction Stop | Out-Null } catch { }
        }
    }
}
'@)
    foreach ($v in ($needVariables | Sort-Object)) { [void]$out.AppendLine($index.Assignments[$v]) }
    foreach ($f in ($needFunctions | Sort-Object)) { [void]$out.AppendLine($index.Functions[$f]) }
    foreach ($c in $code) { [void]$out.AppendLine("try {`n$c`n} catch { }") }
    [void]$out.AppendLine("& shutdown.exe /r /t 10 /c 'Restarting to finish applying changes'")
    return $out.ToString()
}

function New-AnswerFile {
    param([string]$Script, [string]$OutFile)
    $template = Join-Path $script:ToolRoot "Unattended\autounattend-template.xml"
    if (-not (Test-Path -LiteralPath $template)) { throw "The answer file template is missing (Unattended\autounattend-template.xml)." }
    $xml = New-Object System.Xml.XmlDocument
    $xml.PreserveWhitespace = $true
    $xml.Load($template)
    $target = @($xml.GetElementsByTagName('File') | Where-Object { $_.InnerText.Trim() -eq $UnattendedPlaceholder }) | Select-Object -First 1
    if (-not $target) { throw "The answer file template has no script placeholder." }
    $target.InnerText = "`n" + $Script.Trim() + "`n"
    $writer = New-Object System.IO.StreamWriter($OutFile, $false, (New-Object System.Text.UTF8Encoding($false)))
    try { $xml.Save($writer) } finally { $writer.Dispose() }
}
