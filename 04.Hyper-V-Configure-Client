$newIP = "192.168.2.50"
$defaultGateway = "192.168.2.1"
$InterfaceIndex = "3"
$clientName = "client01"
$dnsServerIP = "192.168.2.10"
$domainName = "modc.se"

Rename-Computer $clientName -Restart

Get-NetIPAddress -AddressFamily IPv4
New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $newIP -PrefixLength 24 -DefaultGateway $defaultGateway
Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses ($dnsServerIP,"8.8.8.8")

add-computer –domainname $domainName  -restart

Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

"git","vscode","vscode-powershell" | ForEach-Object {choco install $_ -y}