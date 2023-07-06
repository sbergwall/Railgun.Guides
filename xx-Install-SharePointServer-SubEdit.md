# Install SharePoint Server Subscription Edition

## Links
https://docs.microsoft.com/en-us/sharepoint/install/installing-sharepoint-server-subscription-edition-on-windows-server-core
https://learn.microsoft.com/en-us/sharepoint/install/initial-deployment-administrative-and-service-accounts-in-sharepoint-server
https://learn.microsoft.com/en-us/sharepoint/install/account-permissions-and-security-settings-in-sharepoint-server-2016

## Download 

https://www.microsoft.com/en-us/download/details.aspx?id=103599

SharePoint Server Standard Trial: KGN4V-82BMC-H383V-QJVFT-VCHJ7
f
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
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "User Profile Import Account" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
```

portal Super User Account 
```powershell
$Name = "sp-superuser"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "SharePoint Portal Super User" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
```

Portal supoer Readoner Account 
```powershell
$Name = "sp-superread"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "SharePoint Portal Super Reader" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
```

Seach Crawl Account
```powershell
$Name = "sp-crawl"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "SharePoint Crawl Account" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
```

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

## Managed Accounts

Register the managed account we will be using for SharePoint.

```powershell
# SharePoint Service Application Pool Account
$cred = Get-Credential -UserName "modc\sp-service" -Message "SharePoint Service Application Pool Account"
New-SPManagedAccount -Credential $cred

# SharePoint Web Application Pool Account
$cred = Get-Credential -UserName "modc\sp-web" -Message "SharePoint Web Application Pool Account"
New-SPManagedAccount -Credential $cred

# Claims to Windows Token Service Account
$cred = Get-Credential -UserName "modc\sp-c2wts" -Message "Claims to Windows Token Service Account"
New-SPManagedAccount -Credential $cred

# SharePoint User Profile Service
$cred = Get-Credential -UserName "modc\sp-sync" -Message "SharePoint User Profile Service"
New-SPManagedAccount -Credential $cred
```

## Service Application Pool

We will use a single application pool for all of our Service Applications.

```powershell
New-SPServiceApplicationPool -Name "SharePoint Web Services Default" -Account (Get-SPManagedAccount "modc\sp-service")
```

## Configure ULS and Usage Logs

```powershell
Set-SPDiagnosticConfig -DaysToKeepLogs 7 -LogDiskSpaceUsageGB 15 -LogMaxDiskSpaceUsageEnabled:$true -LogLocation C:\Logs\ULS
Set-SPUsageService -UsageLogLocation C:\Logs\ULS\
```

## Claims to Windos Token Service

The Claims to Windos Token Service needs local Administrator permissions. It also needs specific permissions. Start secpol-msc, add the Claims account to the following User Rights Assignments under Local Policies.

- Act as part of the operating system
- Impersonate a client after authentication
- Log on as a service

```powershell
$sharePointServer = "spse"
Invoke-Command -ScriptBlock {Add-LocalGroupMember -Group Administrators -Member "modc\sp-c2wts"} -ComputerName $sharePointServer
```

Configure Kerberos for the Claims account

```powershell
setspn.exe -S C2WTS/Dummy modc\sp-c2wts
```

Configure Claims account in SharePoint

```powershell
$account = Get-SPManagedAccount "modc\sp-c2wts"
$farm = Get-SPFarm
$svc =$farm.Services | where {$_.TypeName -eq "Claims to Windows Token Service"}
$svcIdentity =$svc.ProcessIdentity
$svcIdentity.CurrentIdentityType = [Microsoft.SharePoint.Administration.IdentityType]::SpecificUser
$svcIdentity.Username =$account.Username
$svcIdentity.Update()
$svcIdentity.Deploy()
```

## Distributed Cache Service

Configure Distributed Cache Service to run as the Service Application Pool account instead of the Farm account that is used by default.
```powershell
$acct = Get-SPManagedAccount "modc\sp-service"
$farm=Get-SPFarm
$svc = $farm.Services | where {$_.TypeName -eq "Distributed Cache"}
$svc.ProcessIdentity.CurrentIdentityType = "SpecificUser"
$svc.ProcessIdentity.ManagedAccount = $acct
$svc.ProcessIdentity.Update()
$svc.ProcessIdentity.Deploy()
```

For completing the identity change we need to stop, removeand add the Distributed Cache instance. 
```powershell
Stop-SPDistributedCacheServiceInstance -Graceful
Remove-SPDistributedCacheServiceInstance
Add-SPDistributedCacheServiceInstance
```

## Managed Metadata Service

Provides taxonomies for end-users and for SharePoint services such as Search and User Profile.
```powershell
$sa = New-SPMetadataServiceApplication -Name "Managed Metadata Service" -DatabaseName "SP_ManagedMetadata" -ApplicationPool "SharePoint Web Services Default" -SyndicationErrorReportEnabled

New-SPMetadataServiceApplicationProxy -Name "Managed Metadata Service" -ServiceApplication $sa -DefaultProxyGroup -ContentTypePushdownEnabled -DefaultKeywordTaxonomy -DefaultSiteCollectionTaxonomy
```

## Enterprise Search Service

https://stackoverflow.com/questions/70557735/how-to-create-search-service-application-using-powershell-in-sharepoint-2019
https://social.technet.microsoft.com/Forums/en-US/27f7eaa4-93f1-47e6-997a-3485a29e6841/creating-search-service-application-in-sp-2016-using-powershell

```powershell
$sa = New-SPEnterpriseSearchServiceApplication -Name "Search Service Application" -DatabaseName "SP_Search" -ApplicationPool "SharePoint Web Services Default" -AdminApplicationPool "SharePoint Web Services Default"

New-Spenterprisesearchserviceapplicationproxy -Name "Search Service Application" -searchapplication $sa
$si = get-spenterprisesearchserviceinstance -local
$clone = $sa.activetopology.clone()

New-SPEnterpriseSearchAdminComponent -SearchTopology $clone -SearchServiceInstance $si
New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $clone -SearchServiceInstance $si
New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $clone -SearchServiceInstance $si
New-SPEnterpriseSearchCrawlComponent -SearchTopology $clone -SearchServiceInstance $si
New-SPEnterpriseSearchIndexComponent  -SearchTopology $clone -SearchServiceInstance $si -IndexPartition 0 -RootDirectory C:\SP_Search\Index -Verbose
New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $clone -SearchServiceInstance $si
```


## User Profile Service

Create the User Profile Service and Proxy
```powershell
$ups = New-SPProfileServiceApplication -name "User Profile Service Application" -ApplicationPool "SharePoint web services Default" -ProfileDBName "SP_Profile" -SocialDBName "SP_Social" -ProfileSyncDBName "SP_Sync"
New-SPProfileServiceApplicationProxy -Name "User Profile Service Application" -ServiceApplication $ups -DefaultProxyGroup
```

Add the Crawl account to the admin permission for UPS
```powershell
$user = New-SPClaimsPrincipal "modc\sp-crawl" -IdentityType WindowsSamAccountName
$security = Get-SPServiceApplicationSecurity $ups -Admin
Grant-SPObjectSecurity $security $user "Retrieve People Data for Search Crawlers"
Set-SPServiceApplicationSecurity $ups $security -Admin
```

Add the Sync account to domain permissions Replicating Directory Changes. Configure the domain connection needs to be done manually.

## Create Web Applications and root site collection

If you want to use a self-signed certificate for the sites run

```powershell
New-SelfSignedCertificate -DnsName "sharepoint.modc.se","sharepoint-my.modc.se" -CertStoreLocation "cert:\LocalMachine\My"
```

Set SPN and create web applications for SharePoint and My Site.

```powershell
setspn -S http://sharepoint.modc.se modc\sp-web
setspn -S http://sharepoint-my.modc.se modc\sp-web

$ap = New-SPAuthenticationProvider -DisableKerberos:$false
New-SPWebApplication -Name "SharePoint" -HostHeader "sharepoint.modc.se" -Port 443 -ApplicationPool "SharePoint" -ApplicationPoolAccount (Get-SPManagedAccount "modc\sp-web") -SecureSocketsLayer:$true -AuthenticationProvider $ap -DatabaseName "SP_Content_SharePoint_1" -Verbose
New-SPWebApplication -Name "SharePoint MySites" -HostHeader "sharepoint-my.modc.se" -Port 443 -ApplicationPool "SharePoint" -SecureSocketsLayer:$true -AuthenticationProvider $ap -DatabaseName "SP_Content_SharePoint-My_1" -Verbose
```

After creating the web application, verify that bindings in IIS are correct and the correct certificate are bound. 

Add Managed Path for My Site and enable Self-service creation.

```powershell
New-SPManagedPath -RelativeURL "personal" -WebApplication "https://sharepoint-my.modc.se/"
$wa = Get-SPWebApplication "https://sharepoint-my.modc.se/"
$wa.SelfServiceSiteCreationEnabled = $true
$wa.Update()
```

Create the root site collection for Sharepoint and My Site.

```powershell
New-SPSite -Url "https://sharepoint.modc.se/" -Template STS#3 -Name "Team Site" -OwnerAlias "modc\siber-da"
New-SPSite -Url "https://sharepoint-my.modc.se/" -Template SPSMSITEHOST#0 -Name "Team Site" -OwnerAlias "modc\siber-da"
```

Dont forget to create the A records in DNS.

```powershell
Add-DnsServerResourceRecordA -Name "sharepoint" -IPv4Address 192.168.2.26 -ZoneName "modc.se" -ComputerName dc01
Add-DnsServerResourceRecordA -Name "sharepoint-my" -IPv4Address 192.168.2.26 -ZoneName "modc.se" -ComputerName dc01
```

Configure the Portal Super User and Portal Super Reader. Start by creating the domain accounts and then add them to the Web Application.

```powershell
$Name = "sp-superread"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "SharePoint Portal Super Reader" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"

$Name = "sp-superuser"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@modc.se" -Description "SharePoint Portal Super User" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $false -Path "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"

$wa =Get-SPWebApplication https://sharepoint.modc.se/
$wa.Properties["portalsuperuseraccount"] = "i:0#.w|modc\sp-superuser"
$wa.Properties["portalsuperreaderaccount"] = "i:0#.w|modc\sp-superread"
$wa.Update()


$wa = Get-SPWebApplication "https://sharepoint.modc.se/"  
$zp = $wa.ZonePolicies("Default")
$policy = $zp.Add("i:0#.w|modc\sp-superuser","Portal Super User")
$policyRole = $wa.PolicyRoles.GetSpecialRole("FullControl")
$policy.PolicyRoleBindings.Add($policyRole)

$policy = $zp.Add("i:0#.w|modc\sp-superread","Portal Super Reader")
$policyRole = $wa.PolicyRoles.GetSpecialRole("FullRead")
$policy.PolicyRoleBindings.Add($policyRole)
$wa.Update()
```

A iisreset is needed before the changes can apply.
```powershell
foreach ($server in (Get-SPServer | where {$_.Role -ne "Invalid" -and $_.Role -ne "Search"})) {
    Write-Host "Resseting IIS on $($server.address)"
    iisreset $server.address /noforce
}
```

My Site Configuration
```powershell
$sa =Get-SPServiceApplication | where {$_.TypeName -eq "User Profile Service Application"}
Set-SPProfileServiceApplication -Identity $sa -MySiteHostLocation "https://sharepoint-my.modc.se/"
```

## Custom Tiles 

https://docs.microsoft.com/en-us/sharepoint/administration/custom-tiles-in-sharepoint-server-2016

```powershell
Enable-SPFeature -Identity CustomTiles -Url https://sharepoint.modc.se/ -Force
```

browse to https://sharepoint.modc.se/Lists/Custom%20Tiles/AllItems.aspx to access Custom tiles list.
