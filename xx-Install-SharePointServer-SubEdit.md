# Install SharePoint Server Subscription Edition

## Links
https://docs.microsoft.com/en-us/sharepoint/install/installing-sharepoint-server-subscription-edition-on-windows-server-core


## Download 

https://www.microsoft.com/en-us/download/details.aspx?id=103599

SharePoint Server Standard Trial: KGN4V-82BMC-H383V-QJVFT-VCHJ7

SharePoint Server Enterprise Trial: VW2FM-FN9FT-H22J4-WV9GT-H8VKF

Project Server Trial: WD6NX-PGRBH-3FQ88-BRBVC-8XFTV


## Service Accounts

https://docs.microsoft.com/en-us/sharepoint/install/account-permissions-and-security-settings-in-sharepoint-server-2016

SharePoint Farm Admin
```powershell
$Name = "sp-farm"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "SharePoint Farm Admin" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"

$sharePointServer = "spse"
Invoke-Command -ScriptBlock {Add-LocalGroupMember -Group Administrators -Member $using:name} -ComputerName $sharePointServer
```

SharePoint Service Application Pool Account
```powershell
$Name = "sp-service"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "SharePoint Service Application Pool Account" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
```

SharePoint Web Application Pool Account
```powershell
$Name = "sp-web"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "SharePoint Web Application Pool Account" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
```

Claims to Windows Token Service Account
```powershell
$Name = "sp-c2wts"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "Claims to Windows Token Service Account" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
```

User Profile Import Account
```powershell
$Name = "sp-sync"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "Claims to Windows Token Service Account" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
```

portal Super User Account 

Portal supoer Readoner Account 

Seach Crawl Account


## Pre requirements

https://docs.microsoft.com/en-us/sharepoint/install/installing-sharepoint-server-subscription-edition-on-windows-server-core

Run the SharePoint prerequisite installer (prerequisiteinstaller.exe) on your server.

## Setup

Run setup.exe as the farm installation account.

## Configuration

```powershell
New-SPConfigurationDatabase -DatabaseName SP_Configuration -AdministrationContentDatabaseName SP_Administration -DatabaseServer DB -Passphrase (ConvertTo-SecureString "FarmPassphrase1" -AsPlainText -Force) -FarmCredentials (Get-Credential) -LocalServerRole SingleServerFarm -Verbose
```

## Central Administration

Set up SPN for Central Administration 

```powershell
setspn -S HTTP/ca.modc.se modc\sp-farm
```

Create Central Administration with Kerberos and without TLS.

```powershell
New-SPCentralAdministration -WindowsAuthProvider Kerberos -SecureSocketsLayer:$True -Port 443
```

Change default Alternative Access Mapping

```powershell
Set-SPAlternateUrl -Identity https://spse -Url https://ca.modc.se 
```

Create a Self Signed certificate if you dont have a PKI environment

```powershell
New-SelfSignedCertificate -DnsName "ca.modc.se" -CertStoreLocation "cert:\LocalMachine\My"
```

Validate in IIS Manager that the site for Central Administation is using the certificate and that SNI is enabled. 

Create a A record in DNS for Central Administration

```powershell
Add-DnsServerResourceRecordA -Name ca -IPv4Address 192.168.2.26 -ZoneName "modc.se" -ComputerName dc01
```

## Enforce resource security on the local server.

```powershell
 Initialize-SPResourceSecurity
 Install-SPFeature -AllExistingFeatures
 Install-SPService
 Install-SPHelpCollection -All
 ```
 
 ## SQL Kerberos Validation

Sessions to the databases should be Kerberos. If they are showing as NTLM please investigate.

 ```sql
 select 
	s.session_id,
	c.connect_time,
	s.login_time,
	s.login_name,
	c.protocol_type,
	c.auth_scheme,
	s.HOST_NAME,
	s.program_name
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c
on s.session_id = c.session_id
WHERE HOST_NAME like 'SPSE%'
```


