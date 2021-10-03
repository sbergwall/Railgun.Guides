# First Windows File Server 

## Read More
https://4sysops.com/archives/how-to-install-file-services-on-server-core/

## Before you begin

  * A volume with driveletter D: must be mounted

## Configure Server & Join to Domain

Rename server

```powershell
$clientName = "FS01"
Rename-Computer $clientName -Restart
```

Get-NetIPAddress -AddressFamily IPv4

```powershell
$newIP = "192.168.2.30"
$defaultGateway = "192.168.2.1"
$InterfaceIndex = "6"
$dnsServerIP = "192.168.2.10"
Get-NetIPAddress -AddressFamily IPv4
New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $newIP -PrefixLength 24 -DefaultGateway $defaultGateway
Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses ($dnsServerIP,"8.8.8.8")

Restart-Computer -Force
```

```powershell
$domainName = "modc.se"
add-computer –domainname $domainName  -restart
```

## Configure Windows Firewall
This will allow Remote Desktop (TCP & UDP 3389), File And Printer Sharing (TCP 445, 139, UDP 137, 138, 5355 and RPC EndPoint) and WMI (TCP 135)

```powershell
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Enabled True
Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True
Set-NetFirewallRule -Displaygroup "Windows Management Instrumentation (WMI)" -Enabled True
```

## Configure File Server 

### Install File Services

```powershell
Install-WindowsFeature File-Services
```

### Install Deduplication and enable it for D:\

```powershell
Install-WindowsFeature FS-Data-Deduplication
Enable-DedupVolume D:
```

### Configure Domain for File Service access
Create OU where we place groups for access to file services.

```powershell
$Path = "OU=SecurityGroups,OU=Groups,OU=modc,DC=modc,DC=se"
New-ADOrganizationalUnit "File-Services" –path "$path"
```




### First folder and SMB Shares

```powershell
mkdir D:\Data
New-SmbShare -Name Data -Path D:\Data -FolderEnumerationMode AccessBased -CachingMode Documents -EncryptData $True -FullAccess "modc\Domain Admins" -ReadAccess "modc\Domain Users"

mkdir D:\System
New-SmbShare -Name System -Path D:\System -FolderEnumerationMode AccessBased -CachingMode Documents -EncryptData $True -FullAccess "modc\Domain Admins" -ReadAccess "modc\Domain Users"
```