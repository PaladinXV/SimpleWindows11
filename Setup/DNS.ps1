$DnsProviders = @(
    @{ Label = "1.1.1.1 (Cloudflare)";      Servers = @("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001") }
    @{ Label = "8.8.8.8 (Google)";          Servers = @("8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844") }
    @{ Label = "9.9.9.9 (Quad9)";           Servers = @("9.9.9.9", "149.112.112.112", "2620:fe::fe", "2620:fe::9") }
    @{ Label = "45.90.28.0 (NextDNS)";      Servers = @("45.90.28.0", "45.90.30.0", "2a07:a8c0::", "2a07:a8c1::") }
    @{ Label = "94.140.14.14 (Adguard)";    Servers = @("94.140.14.14", "94.140.15.15", "2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff") }
    @{ Label = "208.67.222.222 (OpenDNS)";  Servers = @("208.67.222.222", "208.67.220.220", "2620:119:35::35", "2620:119:53::53") }
)

function Get-DnsAdapters {
    @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue)
}

function Set-DnsForAllAdapters {
    param([string[]]$Servers)
    foreach ($a in (Get-DnsAdapters)) {
        if ($Servers) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $Servers -ErrorAction Stop }
        else          { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction Stop }
    }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
}

function Get-DnsOptionIndex {
    $adapter = Get-DnsAdapters | Where-Object Status -eq "Up" | Select-Object -First 1
    if (-not $adapter) { $adapter = Get-DnsAdapters | Select-Object -First 1 }
    if (-not $adapter) { return 0 }
    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
    $manual = (Get-ItemProperty -Path $key -Name "NameServer" -ErrorAction SilentlyContinue).NameServer
    if (-not $manual) { return 2 }
    $first = ($manual -split '[, ]+' | Where-Object { $_ })[0]
    for ($i = 0; $i -lt $DnsProviders.Count; $i++) {
        if ($DnsProviders[$i].Servers[0] -eq $first) { return $i + 3 }
    }
    return 0
}

$DnsTweaks = @(
    @{
        Name        = "DNS server"
        Category    = "DNS"
        SubCategory = "Network adapters"
        Type        = "Option"
        Description = "Sets the DNS server used by your network connection. DNS queries are not encrypted."
        SafetyLevel = "Advanced"
        Location    = 'Located in "Settings" -> "Network & internet" -> your connection -> "DNS server assignment"'
        Options     = @(
            @{ Label = "No Change"; Apply = { } }
            @{ Label = "Default (Your ISP)"; Apply = { Set-DnsForAllAdapters -Servers @() } }
        ) + @($DnsProviders | ForEach-Object {
            $servers = $_.Servers
            @{ Label = $_.Label; Apply = { Set-DnsForAllAdapters -Servers $servers }.GetNewClosure() }
        })
        DefaultIndex = 2
        DetectIndex = { Get-DnsOptionIndex }
    }
)
