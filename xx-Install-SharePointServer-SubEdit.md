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

