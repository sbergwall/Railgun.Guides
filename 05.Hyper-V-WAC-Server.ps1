$newIP = "192.168.2.15"
$defaultGateway = "192.168.2.1"
$InterfaceIndex = "6"
$clientName = "WAC01"
$dnsServerIP = "192.168.2.10"
$domainName = "modc.se"
$tmpPath = "C:\tmp"

Rename-Computer $clientName -Restart

Get-NetIPAddress -AddressFamily IPv4
New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $newIP -PrefixLength 24 -DefaultGateway $defaultGateway
Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses ($dnsServerIP,"8.8.8.8")

add-computer –domainname $domainName  -restart

mkdir $tmpPath
$dlPath = Join-Path -Path $tmpPath -ChildPath "WAC.msi"
Invoke-WebRequest 'http://aka.ms/WACDownload' -OutFile $dlPath

$port = 443
msiexec /i $dlPath /qn /L*v log.txt SME_PORT=$port SSL_CERTIFICATE_OPTION=generate

Import-Module "$env:ProgramFiles\windows admin center\PowerShell\Modules\ExtensionTools"
"msft.sme.active-directory","msft.sme.cluster-creation","msft.sme.software-defined-data-center", "msft.sme.dhcp", "msft.sme.dns", "msft.sme.failover-cluster", "msft.sme.file-explorer", "msft.iis.iis-management", "msft.sme.powershell-console", "msft.sme.remote-desktop", "microsoft.security", "msft.sme.storage", "msft.sme.storage-replica", "msft.sme.windows-update", "msft.sme.hyperv", "msft.sme.storage-migration" | ForEach-Object {Install-Extension -GatewayEndpoint "https://$newIP" $_}

Get-Extension "https://$newIP" | Where-Object {$_.isLatestVersion -eq $false} | ForEach-Object {Update-Extension "https://$newIP" $_.id}

# Configure Kerberos delegation from a DC 
Set-ADComputer -Identity (Get-ADComputer DC01) -PrincipalsAllowedToDelegateToAccount (Get-ADComputer $clientName)