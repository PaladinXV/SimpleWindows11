function New-AppRemovalEntry {
    param(
        [string]$Id,
        [string]$Name,
        [string]$SafetyLevel = "",
        [string[]]$StopProcesses = @(),
        [bool]$RemoveProvisioned = $false,
        [string]$BlockReinstall = '',
        [string]$ReinstallId = '',
        [string]$ReinstallSource = 'msstore',
        [string]$CloseAfterInstall = ''
    )
    return @{
        Name              = $Name
        Category          = "System Apps"
        SafetyLevel       = $SafetyLevel
        AppxIds           = @($Id)
        StopProcesses     = $StopProcesses
        RemoveProvisioned = $RemoveProvisioned
        BlockReinstall    = $BlockReinstall
        ReinstallId       = $ReinstallId
        ReinstallSource   = $ReinstallSource
        CloseAfterInstall = $CloseAfterInstall
        Detect            = { Test-AppxInstalled $Id }.GetNewClosure()
    }
}

$SystemAppsList = @(
    @{ Id = 'Microsoft.WindowsCalculator';            Name = 'Calculator';              SafetyLevel = 'Safe';     ReinstallId = '9WZDNCRFHVN5' }
    @{ Id = 'Microsoft.WindowsCamera';                Name = 'Camera';                  SafetyLevel = 'Safe';     ReinstallId = '9WZDNCRFJBBG' }
    @{ Id = 'Microsoft.WindowsAlarms';                Name = 'Clock';                   SafetyLevel = 'Safe';     ReinstallId = '9WZDNCRFJ3PR' }
    @{ Id = 'Microsoft.MicrosoftOfficeHub';           Name = 'Copilot - Microsoft 365'; SafetyLevel = 'Safe';     ReinstallId = '9WZDNCRD29V9' }
    @{ Id = 'Microsoft.Windows.DevHome';              Name = 'Dev Home';                SafetyLevel = 'Safe';     ReinstallId = '9N8MHTPHNGVV'; BlockReinstall = 'DevHome' }
    @{ Id = 'MicrosoftCorporationII.MicrosoftFamily'; Name = 'Family';                  SafetyLevel = 'Safe';     ReinstallId = '9PDJDJS743XF' }
    @{ Id = 'Microsoft.WindowsFeedbackHub';           Name = 'Feedback Hub';            SafetyLevel = 'Safe';     ReinstallId = '9NBLGGH4R32N' }
    @{ Id = 'Microsoft.XboxGamingOverlay';            Name = 'Game Bar';                SafetyLevel = 'Advanced'; ReinstallId = '9NZKPSTSNW4P' }
    @{ Id = 'Microsoft.GetHelp';                      Name = 'Get Help';                SafetyLevel = 'Advanced'; ReinstallId = '9PKDZBMV1H3T' }
    @{ Id = 'Microsoft.ZuneMusic';                    Name = 'Media Player';            SafetyLevel = 'Advanced'; ReinstallId = '9WZDNCRFJ3PT' }
    @{ Id = 'Microsoft.BingSearch';                   Name = 'Microsoft Bing';          SafetyLevel = 'Safe';     ReinstallId = '9NZBF4GT040C' }
    @{ Id = 'Clipchamp.Clipchamp';                    Name = 'Microsoft Clipchamp';     SafetyLevel = 'Safe';     ReinstallId = '9P1J8S7CCWWT' }
    @{ Id = 'Microsoft.BingNews';                     Name = 'Microsoft News';          SafetyLevel = 'Safe';     ReinstallId = '9WZDNCRFHVFW' }
    @{ Id = 'Microsoft.WindowsStore';                 Name = 'Microsoft Store';         SafetyLevel = 'Advanced'; ReinstallId = '9WZDNCRFJBMP' }
    @{ Id = 'Microsoft.Todos';                        Name = 'Microsoft To Do';         SafetyLevel = 'Safe';     ReinstallId = '9NBLGGH5R558' }
    @{ Id = 'MicrosoftWindows.CrossDevice';           Name = 'Mobile Devices';          SafetyLevel = 'Safe';     ReinstallId = '9NTXGKQ8P7N0' }
    @{ Id = 'Microsoft.WindowsNotepad';               Name = 'Notepad';                 SafetyLevel = 'Advanced'; ReinstallId = '9MSMLRH6LZF3' }
    @{ Id = 'Microsoft.OutlookForWindows';            Name = 'Outlook';                 SafetyLevel = 'Safe';     ReinstallId = '9NRX63209R7B'; RemoveProvisioned = $true; BlockReinstall = 'Outlook' }
    @{ Id = 'Microsoft.Paint';                        Name = 'Paint';                   SafetyLevel = 'Safe';     ReinstallId = '9PCFS5B6T72H'; StopProcesses = @('mspaint', 'PaintApp', 'Paint') }
    @{ Id = 'Microsoft.YourPhone';                    Name = 'Phone Link';              SafetyLevel = 'Advanced'; ReinstallId = '9NMPJ99VJBWV' }
    @{ Id = 'Microsoft.Windows.Photos';               Name = 'Photos';                  SafetyLevel = 'Advanced'; ReinstallId = '9WZDNCRFJBH4' }
    @{ Id = 'Microsoft.PowerAutomateDesktop';         Name = 'Power Automate';          SafetyLevel = 'Safe';     ReinstallId = '9NFTCH6J7FHV' }
    @{ Id = 'MicrosoftCorporationII.QuickAssist';     Name = 'Quick Assist';            SafetyLevel = 'Safe';     ReinstallId = '9P7BP5VNWKX5' }
    @{ Id = 'Microsoft.ScreenSketch';                 Name = 'Snipping Tool';           SafetyLevel = 'Advanced'; ReinstallId = '9MZ95KL8MR0L' }
    @{ Id = 'Microsoft.MicrosoftSolitaireCollection'; Name = 'Solitaire Collection';    SafetyLevel = 'Safe' }
    @{ Id = 'Microsoft.MicrosoftStickyNotes';         Name = 'Sticky Notes';            SafetyLevel = 'Safe';     ReinstallId = '9NBLGGH4QGHW' }
    @{ Id = 'Microsoft.WindowsTerminal';              Name = 'Terminal';                SafetyLevel = 'Advanced'; ReinstallId = '9N0DX20HK701'; StopProcesses = @('WindowsTerminal', 'wt', 'OpenConsole') }
    @{ Id = 'Microsoft.WindowsSoundRecorder';         Name = 'Voice Recorder';          SafetyLevel = 'Safe';     ReinstallId = '9WZDNCRFHWKN' }
    @{ Id = 'Microsoft.BingWeather';                  Name = 'Weather';                 SafetyLevel = 'Safe';     ReinstallId = '9WZDNCRFJ3Q2' }
    @{ Id = 'Microsoft.GamingApp';                    Name = 'Xbox App';                SafetyLevel = 'Advanced'; ReinstallId = '9MV0B5HZVK9Z' }
    @{ Id = 'Microsoft.Xbox.TCUI';                    Name = 'Xbox Live';               SafetyLevel = 'Advanced' }
)

$AppRemovals = @(foreach ($app in $SystemAppsList) { New-AppRemovalEntry @app })

function Remove-TeamsMachineWideInstaller {
    $roots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    foreach ($root in $roots) {
        foreach ($key in @(Get-ChildItem -Path $root -ErrorAction SilentlyContinue)) {
            $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
            if ($props.DisplayName -notlike "*Teams Machine-Wide Installer*") { continue }
            $guid = Split-Path -Path $key.PSPath -Leaf
            if ($guid -notmatch '^\{[0-9A-Fa-f-]{36}\}$') { continue }
            Start-ProcessWithTimeout -FilePath 'msiexec.exe' -ArgumentList @("/x", $guid, "/qn", "/norestart") -TimeoutSeconds 120 | Out-Null
        }
    }
}

$AppRemovals += @{
    Name            = "Microsoft Teams"
    Category        = "System Apps"
    SafetyLevel     = "Safe"
    AppxIds         = @('MSTeams', 'MicrosoftTeams')
    StopProcesses   = @('ms-teams', 'msteams', 'Teams', 'ms-teamsupdate', 'MSTeamsUpdate')
    PostApply       = { Remove-TeamsMachineWideInstaller }
    ReinstallId     = 'Microsoft.Teams'
    ReinstallSource = 'winget'
    Detect          = { (Test-AppxInstalled 'MSTeams') -or (Test-AppxInstalled 'MicrosoftTeams') }
}

$AppPresets = [ordered]@{
    'Recommended' = @(
        'Copilot', 'Copilot - Microsoft 365', 'Dev Home', 'Family', 'Feedback Hub',
        'Microsoft Bing', 'Microsoft Clipchamp', 'Microsoft News', 'Microsoft Teams',
        'Microsoft To Do', 'OneDrive', 'Outlook', 'Power Automate', 'Quick Assist',
        'Solitaire Collection', 'Sticky Notes', 'Weather'
    )
    'Aggressive' = @(
        'Camera', 'Clock', 'Copilot', 'Copilot - Microsoft 365', 'Dev Home', 'Family', 'Feedback Hub',
        'Game Bar', 'Get Help', 'Media Player', 'Microsoft Bing', 'Microsoft Clipchamp',
        'Microsoft News', 'Microsoft Teams', 'Microsoft To Do', 'Mobile Devices',
        'OneDrive', 'Outlook', 'Phone Link', 'Photos', 'Power Automate', 'Quick Assist',
        'Solitaire Collection', 'Sticky Notes', 'Voice Recorder', 'Weather',
        'Xbox App', 'Xbox Live',
        'Clear Start Menu Apps', 'Clear Task Bar Apps'
    )
}

$AppPresetDeepClean = @('Aggressive')

$AppDescriptions = @{
    "Clear Start Menu Apps" = @{ Text = "Removes most pinned apps from the Start Menu. Promoted apps like `"WhatsApp`" and `"LinkedIn`" aren't actually installed - they're only placeholders, and are cleared too."; Note = "May require a restart. Apps you pinned yourself are also removed." }
    "Clear Task Bar Apps" = @{ Text = "Removes all pinned apps from the Task Bar."; Note = "May require a restart. Apps you pinned yourself are also removed." }
    "Calculator" = @{ Text = "Built-in Calculator app." }
    "Camera" = @{ Text = "Built-in Camera app for photo/video capture." }
    "Clock" = @{ Text = "Built-in Clock app for alarms, timers etc." }
    "Copilot" = @{ Text = "Microsoft's AI Copilot app." }
    "Copilot - Microsoft 365" = @{ Text = "The Microsoft 365 Copilot app (formerly the Microsoft 365 / Office app)." }
    "Dev Home" = @{ Text = "Microsoft's developer dashboard app for setting up dev environments." }
    "Family" = @{ Text = "Microsoft's Parental Controls app." }
    "Feedback Hub" = @{ Text = "App for sending feedback and bug reports to Microsoft." }
    "Game Bar" = @{ Text = "Microsoft's gaming overlay that can display an FPS counter, do clip recording etc."; Note = "Warning! AMD Ryzen chipset drivers use Game Bar to detect when a game is running. This handles core parking on multi-chiplet/CCD CPUs (e.g. 3900X, 9950X3D). Without it, there may be stuttering or performance dips. You can set this up manually but this tool does not cover that." }
    "Get Help" = @{ Text = "Microsoft's help app. A more advanced version of the `"Windows Troubleshooter`" with search, prompts, tools etc." }
    "Media Player" = @{ Text = "Microsoft's built-in music and video player."; Note = "Safe to remove but should be replaced with a third party program." }
    "Microsoft Bing" = @{ Text = "Microsoft's Bing search app." }
    "Microsoft Clipchamp" = @{ Text = "Microsoft's built-in video editor." }
    "Microsoft Edge" = @{ Text = "Microsoft's built-in web browser based on Chromium."; Note = "Make sure you have another web browser installed first. WebView2 is not touched." }
    "Microsoft News" = @{ Text = "Microsoft's News app." }
    "Microsoft Store" = @{ Text = "Microsoft's Store app."; Note = "Winget isn't uninstalled. The Store can easily be reinstalled." }
    "Microsoft Teams" = @{ Text = "Microsoft's communication app for chat, voice, calls, file sharing etc."; Note = "May try to reinstall itself after a Windows Update." }
    "Microsoft To Do" = @{ Text = "Microsoft's task/to do list app." }
    "Mobile Devices" = @{ Text = "Windows background component that links your PC with connected mobile devices." }
    "Notepad" = @{ Text = "Microsoft's modern/updated version of Notepad."; Note = "Make sure you have another text editor installed." }
    "OneDrive" = @{ Text = "Microsoft's cloud storage client." }
    "Outlook" = @{ Text = "Microsoft's email app." }
    "Paint" = @{ Text = "Microsoft's basic image editing app." }
    "Phone Link" = @{ Text = "Connects your phone to Windows, giving access to messages, calls, notifications, photos and other phone features." }
    "Photos" = @{ Text = "Windows' built-in photo viewer and basic editor." }
    "Power Automate" = @{ Text = "Microsoft's desktop automation/workflow app." }
    "Quick Assist" = @{ Text = "Built-in screen sharing/remote support tool." }
    "Snipping Tool" = @{ Text = "Screenshot and screen-capture tool." }
    "Solitaire Collection" = @{ Text = "Solitaire game." }
    "Sticky Notes" = @{ Text = "Notes app." }
    "Terminal" = @{ Text = "Modern Windows command-line app that combines Command Prompt and PowerShell."; Note = "Command Prompt and PowerShell still work without it, in the older console window." }
    "Voice Recorder" = @{ Text = "Voice recording app." }
    "Weather" = @{ Text = "Microsoft's Weather app." }
    "Xbox App" = @{ Text = "Windows app for Xbox games, friends, achievements and Game Pass."; Note = "Needed for Microsoft games (e.g. Halo, Forza). It can be reinstalled with this tool, with Winget or from Microsoft's website." }
    "Xbox Live" = @{ Text = "Xbox App component used for sign-in and friends pop-ups."; Note = "Comes back when the Xbox App is opened." }
}
