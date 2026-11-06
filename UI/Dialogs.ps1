function Show-AppDialog {
    param([string]$Message, [string]$Detail = "", [switch]$YesNo)
    [xml]$dialogXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" ResizeMode="NoResize" SizeToContent="WidthAndHeight" ShowInTaskbar="False"
        WindowStartupLocation="CenterOwner" Background="Transparent" AllowsTransparency="True">
    <Border Background="{DynamicResource PanelBg}" BorderBrush="{DynamicResource Border}" BorderThickness="1"
            CornerRadius="8" Padding="26,22,26,20" MaxWidth="460">
        <StackPanel>
            <TextBlock x:Name="DialogQuestion" FontSize="16" FontWeight="SemiBold" Foreground="{DynamicResource Text}" TextWrapping="Wrap" TextAlignment="Center"/>
            <TextBlock x:Name="DialogDetail" Foreground="{DynamicResource SubText}" TextWrapping="Wrap" TextAlignment="Center" Margin="0,8,0,0"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,22,0,0">
                <Button x:Name="DialogYes" Content="Yes" MinWidth="90"/>
                <Button x:Name="DialogNo" Content="No" MinWidth="90" IsCancel="True" Margin="0"/>
            </StackPanel>
        </StackPanel>
    </Border>
</Window>
'@
    $dialog = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $dialogXaml))
    try { $dialog.Resources.MergedDictionaries.Add($window.Resources) }
    catch { foreach ($key in @($window.Resources.Keys)) { $dialog.Resources[$key] = $window.Resources[$key] } }
    if ($window.IsLoaded) { $dialog.Owner = $window } else { $dialog.WindowStartupLocation = "CenterScreen" }
    $dialog.FindName("DialogQuestion").Text = $Message
    $detailText = $dialog.FindName("DialogDetail")
    if ($Detail) { $detailText.Text = $Detail } else { $detailText.Visibility = "Collapsed" }
    $yesButton = $dialog.FindName("DialogYes")
    $noButton = $dialog.FindName("DialogNo")
    if (-not $YesNo) {
        $yesButton.Content = "OK"
        $yesButton.IsDefault = $true
        $noButton.Visibility = "Collapsed"
    }
    $yesButton.Add_Click({ $dialog.DialogResult = $true }.GetNewClosure())
    $noButton.Add_Click({ $dialog.DialogResult = $false }.GetNewClosure())
    return [bool]$dialog.ShowDialog()
}

function Show-ConfirmDialog {
    param([string]$Question, [string]$Detail = "")
    return (Show-AppDialog -Message $Question -Detail $Detail -YesNo)
}

function Show-AppMessage {
    param([string]$Message)
    $parts = $Message -split "`r?`n`r?`n", 2
    Show-AppDialog -Message $parts[0] -Detail $(if ($parts.Count -gt 1) { $parts[1] } else { "" }) | Out-Null
}
