$PersonalizationTweaks = @(
    @{
        Name        = 'Enable "Dark mode"'
        SubCategory = "Colors"
        Category    = "Personalization"
        Description = "Sets the system theme to dark mode"
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Colors`" `"Choose your mode`""
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
        }
        Revert      = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 1
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 1
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0) -and
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0)
        }
    }
    @{
        Name        = 'Disable "Transparency effects"'
        SubCategory = "Colors"
        Category    = "Personalization"
        Description = "Disables transparency effects in Windows"
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Colors`" `"Transparency effects`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 }
        Revert      = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 1 }
    }
    @{
        Name        = 'Disable "Lock screen facts & tips"'
        SubCategory = "Lock screen"
        Category    = "Personalization"
        Description = "Disables 'Get fun facts, tips, tricks and more on your lock screen'"
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Lock screen`" `"Get fun facts, tips, tricks, and more on your lock screen`""
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338387Enabled" 0
        }
        Revert      = {
            Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled"
            Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338387Enabled"
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" 0) -and
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338387Enabled" 0)
        }
    }
    @{
        Name        = 'Disable "Windows Spotlight on the lock screen"'
        SubCategory = "Lock screen"
        Category    = "Personalization"
        Description = "Sets the lock screen background to a static picture instead of rotating Windows Spotlight images"
        SafetyLevel = "Safe"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Lock screen`" `"Personalize your lock screen`""
        Apply       = { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 0 }
        Detect      = { Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 0 }
        Revert      = { Remove-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" }
    }
    @{
        Name        = "Solid Color - Black"
        SubCategory = "Wallpaper"
        Category    = "Personalization"
        Description = "Sets the wallpaper to `"Solid Color -> Black`". Your existing wallpaper will be removed."
        SafetyLevel = "Advanced"
        Location    = "Located in `"Settings`" -> `"Personalization`" -> `"Background`" `"Personalize your background`""
        Apply       = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings" "EnabledState" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" "BackgroundType" 1
            Set-Reg "HKCU:\Control Panel\Colors" "Background" "0 0 0" "String"
            Set-Reg "HKCU:\Control Panel\Desktop" "WallPaper" "" "String"
            Set-Reg "HKCU:\Control Panel\Desktop" "WallPaperStyle" "0" "String"
            Set-Reg "HKCU:\Control Panel\Desktop" "TileWallpaper" "0" "String"
        }
        Detect      = {
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings" "EnabledState" 0) -and
            (Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" "BackgroundType" 1) -and
            (Test-RegValue "HKCU:\Control Panel\Colors" "Background" "0 0 0") -and
            (Test-RegValue "HKCU:\Control Panel\Desktop" "WallPaper" "") -and
            (Test-RegValue "HKCU:\Control Panel\Desktop" "WallPaperStyle" "0") -and
            (Test-RegValue "HKCU:\Control Panel\Desktop" "TileWallpaper" "0")
        }
    }
    @{
        Name        = "Accent color"
        Category    = "Personalization"
        SubCategory = "Colors"
        Type        = "Option"
        Description = "The colour used for highlights in Start, the taskbar, title bars and buttons. You may need to sign out and back in to see it everywhere."
        SafetyLevel = "Safe"
        Location    = 'Located in "Settings" -> "Personalization" -> "Colors" "Accent color"'
        Options     = @(
            @{ Label = "Blue (Default)"; Apply = {
                Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" "AccentPalette" ([byte[]](0x99,0xEB,0xFF,0x00,0x4C,0xC2,0xFF,0x00,0x00,0x91,0xF8,0x00,0x00,0x78,0xD4,0x00,0x00,0x67,0xC0,0x00,0x00,0x3E,0x92,0x00,0x00,0x1A,0x68,0x00,0xF7,0x63,0x0C,0x00)) "Binary"
                Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" "StartColorMenu" -4167936
                Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" "AccentColorMenu" -2852864
            } }
            @{ Label = "Storm (Grey)"; Apply = {
                Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" "AccentPalette" ([byte[]](0xDF,0xDE,0xDC,0x00,0xA6,0xA5,0xA1,0x00,0x68,0x65,0x62,0x00,0x4C,0x4A,0x48,0x00,0x41,0x3F,0x3D,0x00,0x27,0x25,0x24,0x00,0x10,0x0D,0x0D,0x00,0x10,0x7C,0x10,0x00)) "Binary"
                Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" "StartColorMenu" -12763327
                Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" "AccentColorMenu" -12039604
            } }
        )
        DetectIndex = {
            $v = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name "AccentColorMenu" -ErrorAction SilentlyContinue).AccentColorMenu
            if ($null -eq $v) { return 1 }
            switch (([int64]$v) -band 4294967295) { 4292114432 { return 1 } 4282927692 { return 2 } default { return 0 } }
        }
    }
)
