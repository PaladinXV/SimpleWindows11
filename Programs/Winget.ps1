function Install-Winget {
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript({
        $ProgressPreference = 'SilentlyContinue'
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Force -AllowClobber -Scope AllUsers -ErrorAction Stop | Out-Null
        Import-Module Microsoft.WinGet.Client -Force -ErrorAction Stop
        Repair-WinGetPackageManager -AllUsers -Latest -Force -ErrorAction Stop | Out-Null
    }.ToString()) | Out-Null
    $handle = $ps.BeginInvoke()
    while (-not $handle.IsCompleted) {
        if ($CancelToken -and $CancelToken.Requested) {
            try { $ps.BeginStop($null, $null) | Out-Null } catch { }
            return [PSCustomObject]@{ Success = $false; Stopped = $true; Error = "Stopped" }
        }
        Wait-UI -Milliseconds 50
    }
    $err = ""
    try { $ps.EndInvoke($handle) | Out-Null } catch { $err = $_.Exception.InnerException.Message; if (-not $err) { $err = $_.Exception.Message } }
    if (-not $err -and $ps.Streams.Error.Count -gt 0) { $err = "$($ps.Streams.Error[0])" }
    try { $ps.Dispose(); $rs.Dispose() } catch { }
    Update-SessionPath
    $ok = [bool](Test-CommandExists winget)
    return [PSCustomObject]@{ Success = $ok; Stopped = $false; Error = $err }
}

$WingetApps = @(
    @{ Name = 'Brave';                      Id = 'Brave.Brave';                          Category = 'Browsers';      Description = 'Privacy-focused browser with a built-in ad and tracker blocker.' }
    @{ Name = 'Chrome';                     Id = 'Google.Chrome';                        Category = 'Browsers';      Description = "Google's web browser." }
    @{ Name = 'FireFox';                    Id = 'Mozilla.Firefox';                      Category = 'Browsers';      Description = "Mozilla's open-source web browser." }
    @{ Name = 'FireFox ESR';                Id = 'Mozilla.Firefox.ESR';                  Category = 'Browsers';      Description = 'Firefox''s Extended Support Release. Long-term support for a single version.' }
    @{ Name = 'Floorp';                     Id = 'Ablaze.Floorp';                        Category = 'Browsers';      Description = 'Open-source, Firefox-based browser focused on privacy, extensive customisation, and built-in productivity features.' }
    @{ Name = 'Helium';                     Id = 'ImputNet.Helium';                      Category = 'Browsers';      Description = 'Fork of Ungoogled-Chromium with added features, including uBlock Origin.' }
    @{ Name = 'Librewolf';                  Id = 'LibreWolf.LibreWolf';                  Category = 'Browsers';      Description = 'Firefox fork tuned for privacy out of the box.' }
    @{ Name = 'Mullvad Browser';            Id = 'MullvadVPN.MullvadBrowser';            Category = 'Browsers';      Description = 'Privacy-focused browser from Mullvad.' }
    @{ Name = 'Tor Browser';                Id = 'TorProject.TorBrowser';                Category = 'Browsers';      Description = 'Privacy-focused browser that uses the Tor network.' }
    @{ Name = 'Vivaldi';                    Id = 'Vivaldi.Vivaldi';                      Category = 'Browsers';      Description = 'Chromium-based browser that focuses on workflow and customization.' }
    @{ Name = 'Waterfox';                   Id = 'Waterfox.Waterfox';                    Category = 'Browsers';      Description = 'Firefox fork with added functionality.' }
    @{ Name = 'Zen Browser';                Id = 'Zen-Team.Zen-Browser';                 Category = 'Browsers';      Description = 'Firefox fork that focuses on workflow and customization.' }
    @{ Name = 'Discord';                    Id = 'Discord.Discord';                      Category = 'Communication'; Description = 'Free communication platform for text, voice, and video chats.' }
    @{ Name = 'Signal';                     Id = 'OpenWhisperSystems.Signal';            Category = 'Communication'; Description = 'End-to-end encrypted messaging and calls.' }
    @{ Name = 'TeamSpeak';                  Id = 'TeamSpeakSystems.TeamSpeakClient';     Category = 'Communication'; Description = 'Free communication platform for text and voice chat.'; Warning = 'Some regions or VPNs may be blocked from downloads.' }
    @{ Name = 'Telegram';                   Id = 'Telegram.TelegramDesktop';             Category = 'Communication'; Description = 'Cloud-based messaging app with groups and channels.' }
    @{ Name = 'WhatsApp';                   Id = '9NKSQGP7F2NH';                         Source = 'msstore'; Category = 'Communication'; Description = 'Free communication platform with video, text, file sharing and encryption.'; Warning = 'This is installed via the Microsoft Store' }
    @{ Name = 'Adobe Acrobat Reader';       Id = 'Adobe.Acrobat.Reader.64-bit';          Category = 'Documents';     Description = 'Adobe''s free PDF viewer.' }
    @{ Name = 'LibreOffice';                Id = 'TheDocumentFoundation.LibreOffice';    Category = 'Documents';     Description = 'Free and open-source Office Suite.' }
    @{ Name = 'Notepad++';                  Id = 'Notepad++.Notepad++';                  Category = 'Documents';     Description = 'Free, open-source text and source code editor offering syntax highlighting, tabbed editing, and support for multiple programming languages.' }
    @{ Name = 'OpenOffice';                 Id = 'Apache.OpenOffice';                    Category = 'Documents';     Description = 'Free and open-source Office Suite.' }
    @{ Name = 'Battle.net';                 Id = 'Blizzard.BattleNet';                   Category = 'Gaming';        Description = 'Blizzard''s game launcher.' }
    @{ Name = 'EA App';                     Id = 'ElectronicArts.EADesktop';             Category = 'Gaming';        Description = "Electronic Arts' game launcher." }
    @{ Name = 'Epic Games Launcher';        Id = 'EpicGames.EpicGamesLauncher';          Category = 'Gaming';        Description = 'Epic Games game launcher.' }
    @{ Name = 'GOG Launcher';               Id = 'GOG.Galaxy';                           Category = 'Gaming';        Description = 'GOG store and multi-platform game library launcher.' }
    @{ Name = 'Steam';                      Id = 'Valve.Steam';                          Category = 'Gaming';        Description = "Valve's game launcher." }
    @{ Name = 'Ubisoft Connect';            Id = 'Ubisoft.Connect';                      Category = 'Gaming';        Description = 'Ubisoft''s game launcher.' }
    @{ Name = 'Audacity';                   Id = 'Audacity.Audacity';                    Category = 'Multimedia';    Description = 'Free, open-source audio editor and recorder with a range of built-in tools and effects.' }
    @{ Name = 'Foobar2000';                 Id = 'PeterPawlowski.foobar2000';            Category = 'Multimedia';    Description = 'Lightweight, highly configurable audio player.' }
    @{ Name = 'Handbrake';                  Id = 'HandBrake.HandBrake';                  Category = 'Multimedia';    Description = 'Open-source video converter and transcoder.' }
    @{ Name = 'IrfanView';                  Id = 'IrfanSkiljan.IrfanView';               Category = 'Multimedia';    Description = 'Fast, lightweight image viewer and basic editor.' }
    @{ Name = 'iTunes';                     Id = 'Apple.iTunes';                         Category = 'Multimedia';    Description = "Apple's media player and device manager." }
    @{ Name = 'K-Lite Codec Standard';      Id = 'CodecGuide.K-LiteCodecPack.Standard';  Category = 'Multimedia';    Description = 'Audio and video codec pack with a media player.' }
    @{ Name = 'OBS Studio';                 Id = 'OBSProject.OBSStudio';                 Category = 'Utilities';     Description = 'Open-source screen recording and streaming software.' }
    @{ Name = 'ShareX';                     Id = 'ShareX.ShareX';                        Category = 'Multimedia';    Description = 'Screenshot and basic screen recording tool.' }
    @{ Name = 'VLC Media Player';           Id = 'VideoLAN.VLC';                         Category = 'Multimedia';    Description = 'Video and audio player.' }
    @{ Name = '7Zip';                       Id = '7zip.7zip';                            Category = 'Utilities';     Description = 'Open-source file extraction and archive tool.' }
    @{ Name = 'AutoHotkey';                 Id = 'AutoHotkey.AutoHotkey';                Category = 'Utilities';     Description = 'Scripting tool for custom hotkeys and automating tasks.' }
    @{ Name = 'Bitwarden';                  Id = 'Bitwarden.Bitwarden';                  Category = 'Utilities';     Description = 'Password manager.' }
    @{ Name = 'CPU-Z';                      Id = 'CPUID.CPU-Z';                          Category = 'Utilities';     Description = 'Shows detailed CPU, motherboard and memory information.' }
    @{ Name = 'Crystal Disk Info';          Id = 'CrystalDewWorld.CrystalDiskInfo';      Category = 'Utilities';     Description = 'Drive health and SMART status monitor.' }
    @{ Name = 'Crystal Disk Mark';          Id = 'CrystalDewWorld.CrystalDiskMark';      Category = 'Utilities';     Description = 'Drive benchmarking tool.' }
    @{ Name = 'Display Driver Uninstaller'; Id = 'Wagnardsoft.DisplayDriverUninstaller'; Category = 'Utilities';     Description = 'Extensive GPU driver uninstallation tool.' }
    @{ Name = 'Dropbox';                    Id = 'Dropbox.Dropbox';                      Category = 'Utilities';     Description = 'Cloud storage and file sync.' }
    @{ Name = 'Everything';                 Id = 'voidtools.Everything';                 Category = 'Utilities';     Description = 'Simple but extensive file search tool.' }
    @{ Name = 'FanControl';                 Id = 'Rem0o.FanControl';                     Category = 'Utilities';     Description = 'Free fan control software with extensive functionality.' }
    @{ Name = 'GPU-Z';                      Id = 'TechPowerUp.GPU-Z';                    Category = 'Utilities';     Description = 'Shows detailed graphics card information.' }
    @{ Name = 'HWInfo';                     Id = 'REALiX.HWiNFO';                        Category = 'Utilities';     Description = 'In-depth hardware information and sensor monitoring.' }
    @{ Name = 'HWMonitor';                  Id = 'CPUID.HWMonitor';                      Category = 'Utilities';     Description = 'In-depth hardware/sensor monitoring software by CPUID.' }
    @{ Name = 'MSI Afterburner';            Id = 'Guru3D.Afterburner';                   Category = 'Utilities';     Description = 'Graphics card control + extensive system/sensor overlay for gaming.' }
    @{ Name = 'Nanazip';                    Id = 'M2Team.NanaZip';                       Category = 'Utilities';     Description = '7-Zip fork.' }
    @{ Name = '.NET Desktop Runtime 8';     Id = 'Microsoft.DotNet.DesktopRuntime.8';    Category = 'Utilities';     Description = 'Needed to run apps built with .NET 8.' }
    @{ Name = '.NET Desktop Runtime 9';     Id = 'Microsoft.DotNet.DesktopRuntime.9';    Category = 'Utilities';     Description = 'Needed to run apps built with .NET 9.' }
    @{ Name = 'PowerShell 7';               Id = 'Microsoft.PowerShell';                 Category = 'Utilities';     Description = 'The latest PowerShell version.' }
    @{ Name = 'PowerToys';                  Id = 'Microsoft.PowerToys';                  Category = 'Utilities';     Description = 'Microsoft''s collection of extra Windows tools.' }
    @{ Name = 'Process Lasso';              Id = 'BitSum.ProcessLasso';                  Category = 'Utilities';     Description = 'System tweaking tool such as setting core affinities, automated Power Plans etc.' }
    @{ Name = 'qBitTorrent';                Id = 'qBittorrent.qBittorrent';              Category = 'Utilities';     Description = 'Open-source Torrent client.' }
    @{ Name = 'Visual C++ (2015+)';         Id = 'Microsoft.VCRedist.2015+.x64';         Category = 'Utilities';     Description = 'Microsoft runtime. Various apps will require this dependency.' }
    @{ Name = 'Mullvad VPN';                Id = 'MullvadVPN.MullvadVPN';                Category = 'VPN';           Description = 'Mullvad VPN.' }
    @{ Name = 'Proton VPN';                 Id = 'Proton.ProtonVPN';                     Category = 'VPN';           Description = 'Proton VPN. Has a free-tier.' }
)

$ProgramDetectNames = @{
    '.NET Desktop Runtime 8'     = 'Microsoft Windows Desktop Runtime - 8.*'
    '.NET Desktop Runtime 9'     = 'Microsoft Windows Desktop Runtime - 9.*'
    '7Zip'                       = '7-Zip*'
    'Adobe Acrobat Reader'       = 'Adobe Acrobat*'
    'Audacity'                   = 'Audacity*'
    'AutoHotkey'                 = 'AutoHotkey*'
    'Battle.net'                 = 'Battle.net*'
    'Bitwarden'                  = 'Bitwarden*'
    'Brave'                      = 'Brave*'
    'Chrome'                     = 'Google Chrome*'
    'CPU-Z'                      = 'CPUID CPU-Z*'
    'Crystal Disk Info'          = 'CrystalDiskInfo*'
    'Crystal Disk Mark'          = 'CrystalDiskMark*'
    'Discord'                    = 'Discord*'
    'Display Driver Uninstaller' = 'Display Driver Uninstaller*'
    'Dropbox'                    = 'Dropbox*'
    'EA App'                     = 'EA app*'
    'Epic Games Launcher'        = 'Epic Games Launcher*'
    'Everything'                 = 'Everything*'
    'FanControl'                 = 'FanControl*'
    'FireFox'                    = 'Mozilla Firefox (*'
    'FireFox ESR'                = 'Mozilla Firefox ESR*'
    'Floorp'                     = 'Floorp*'
    'Foobar2000'                 = 'foobar2000*'
    'GOG Launcher'               = 'GOG GALAXY*'
    'GPU-Z'                      = '*GPU-Z*'
    'Handbrake'                  = 'HandBrake*'
    'Helium'                     = 'Helium*'
    'HWInfo'                     = 'HWiNFO*'
    'HWMonitor'                  = 'CPUID HWMonitor*'
    'IrfanView'                  = 'IrfanView*'
    'iTunes'                     = 'iTunes'
    'K-Lite Codec Standard'      = 'K-Lite Codec Pack*'
    'LibreOffice'                = 'LibreOffice*'
    'Librewolf'                  = 'LibreWolf*'
    'MSI Afterburner'            = 'MSI Afterburner*'
    'Mullvad Browser'            = 'Mullvad Browser*'
    'Mullvad VPN'                = 'Mullvad VPN*'
    'Nanazip'                    = 'appx:M2Team.NanaZip*'
    'Notepad++'                  = 'Notepad++*'
    'OBS Studio'                 = 'OBS Studio*'
    'OpenOffice'                 = 'OpenOffice*'
    'PowerShell 7'               = 'PowerShell 7*'
    'PowerToys'                  = 'PowerToys*'
    'Process Lasso'              = 'Process Lasso*'
    'Proton VPN'                 = 'Proton VPN*'
    'qBitTorrent'                = 'qBittorrent*'
    'ShareX'                     = 'ShareX*'
    'Signal'                     = 'Signal*'
    'Steam'                      = 'Steam'
    'TeamSpeak'                  = 'TeamSpeak*'
    'Telegram'                   = 'Telegram Desktop*'
    'Tor Browser'                = 'Tor Browser*'
    'Ubisoft Connect'            = 'Ubisoft Connect*'
    'Visual C++ (2015+)'         = 'reg:Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
    'Vivaldi'                    = 'Vivaldi*'
    'VLC Media Player'           = 'VLC media player*'
    'Waterfox'                   = 'Waterfox*'
    'WhatsApp'                   = 'appx:5319275A.WhatsAppDesktop*'
    'Zen Browser'                = 'Zen Browser*'
}
