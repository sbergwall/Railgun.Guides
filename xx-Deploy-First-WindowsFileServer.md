# First Windows File Server 

## Configure Server

add-computer –domainname $domainName  -restart
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

## Install 