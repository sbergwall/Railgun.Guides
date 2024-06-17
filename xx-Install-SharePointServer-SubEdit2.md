====== Install Evaluation of SharePoint Subscription Edition ======

How to install and configure SharePoint Subscription Edition used for development and evaluation. This deployment will only consist of one SharePoint Server using the Singel Server role in SharePoint and one SQL Server that is not configured for high availability. 

^Name ^Type ^Purpose ^Requirements ^
|spse-misc01-dev|Server|SharePoint Single Server node. All roles will be installed on this server|N/A |
|spse-db01-dev|Server|Database Server|N/A |
|spse_farm-dev_srv |AD Service Account |Timer Service, Insights, IIS App for CA, SP Web Services System, Security Token Service App Pool |Domain user account | 
|spse-svc-dev_srv |AD Service Account |Run SharePoint Services Instances and Windows Services |No manual configuration is necessary. | 
|spse-web-dev_srv |AD Service Account |All Web Applications without Central Administration  |No manual configuration is necessary. | 
|spse-c2wts-dev_srv |AD Service Account |Claims to Windows Token | | 
|spse-sync-dev_srv |AD Service Account |Used for Active Directory Import |Replicate directory changes (Active Directory), read access (other directories) | 
|spse-su-dev_srv |AD Service Account |Object caching | | 
|spse-sr-dev_srv |AD Service Account |Object caching | | 
|spse-crwl-dev_srv |AD Service Account |Search crawling internal and external sources |Read access to the content being crawled. No manual configuration is necessary if this account is only crawling local farm content. | 
|Application (E:) |Volume |Install location for SharePoint Server on spse-misc01-dev | |
|Log (L:) |Volume |Location for log files on spse-misc01-dev||
|Search (S:) |Volume |Location for Search Index on spse-misc01-dev||
|https://spse-ca-dev.ltblekinge.org|Web site|Central Administration|A-record spse-ca-dev pointing at spse-misc01-dev. Certificate with SAN spse-ca-dev |
|https://spse-dev.ltblekinge.org|Web site |Will hold Team Sites, Portals, and so on |A-record spse-dev pointing at spse-misc01-dev. Certificate with SAN spse-dev|
|https://spse-dev-my.ltblekinge.org|Web site |Will contain the MySite host and user’s MySites, also known as OneDrive for Business sites |A-record spse-dev-my pointing at spse-misc01-dev. Certificate with SAN spse-dev-my|

For more information about service accounts and permissions:
  * [[https://learn.microsoft.com/en-us/sharepoint/security-for-sharepoint-server/plan-for-administrative-and-service-accounts|Plan for administrative and service accounts in SharePoint Server]] 
  * [[https://learn.microsoft.com/en-us/sharepoint/install/account-permissions-and-security-settings-in-sharepoint-server-2016|Account permissions and security settings in SharePoint Servers]] 
  * [[https://learn.microsoft.com/en-us/sharepoint/install/initial-deployment-administrative-and-service-accounts-in-sharepoint-server|Initial deployment administrative and service accounts in SharePoint Server]] 

===== Before you begin =====

  * The SharePoint farm is deployed in a VMware NSX environment which means by default the servers does not have Internet access. 
  * We will use DBAtools module for Powershell, see [[https://blog.netnerds.net/2023/04/offline-install-of-dbatools-and-dbatools-library/|Offline Installation of dbatools 2.0 with the dbatools.library Dependency]] how to do a offline install.
  * The servers are deployed with a template from VMware vCenter for SQL Server so we will have do change some configuration for this to work with SharePoint
  * Verify that antivirus exclusions are created for the new servers. Microsoft outlines the required exclusions at [[https://support.microsoft.com/help/952167]]



===== Service Accounts =====

We will create all the service accounts needed for SharePoint Server with Powershell. This needs to be ran from a server or client that has the ActiveDirectory Powershell module installed and with a account that has permissions to create new Active Directory accounts.

<code powershell>
$Name = "spse_farm-dev_srv"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@ltblekinge.org" -Description "SharePoint SE Farm Admin Dev Environment" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $true -Path "OU=Service-Accounts,OU=Users,OU=SPSE,OU=Functions,DC=ltblekinge,DC=org" -DisplayName $Name

$Name = "spse-svc-dev_srv"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@ltblekinge.org" -Description "SharePoint SE Service Application Pool Account Dev Environment" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $true -Path "OU=Service-Accounts,OU=Users,OU=SPSE,OU=Functions,DC=ltblekinge,DC=org"  -DisplayName $Name

$Name = "spse-web-dev_srv"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@ltblekinge.org" -Description "SharePoint SE Web Application Pool Account Dev Environment" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $true -Path "OU=Service-Accounts,OU=Users,OU=SPSE,OU=Functions,DC=ltblekinge,DC=org"  -DisplayName $Name

$Name = "spse-c2wts-dev_srv"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@ltblekinge.org" -Description "SharePoint SE Claims to Windows Token Service Account Dev Environment" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $true -Path "OU=Service-Accounts,OU=Users,OU=SPSE,OU=Functions,DC=ltblekinge,DC=org" -DisplayName $Name

$Name = "spse-sync-dev_srv"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@ltblekinge.org" -Description "SharePoint SE User Profile Import Account Dev Environment" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $true -Path "OU=Service-Accounts,OU=Users,OU=SPSE,OU=Functions,DC=ltblekinge,DC=org" -DisplayName $Name

$Name = "spse-su-dev_srv"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@ltblekinge.org" -Description "SharePoint SE Portal Super User Account Dev Environment" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $true -Path "OU=Service-Accounts,OU=Users,OU=SPSE,OU=Functions,DC=ltblekinge,DC=org" -DisplayName $Name

$Name = "spse-sr-dev_srv"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@ltblekinge.org" -Description "SharePoint SE Portal Super Reader Account Dev Environment" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $true -Path "OU=Service-Accounts,OU=Users,OU=SPSE,OU=Functions,DC=ltblekinge,DC=org" -DisplayName $Name

$Name = "spse-crwl-dev_srv"
New-ADUser -Name $Name -SamAccountName $name -UserPrincipalName "$name@ltblekinge.org" -Description "SharePoint SE Search Crawl Account Dev Environment" -Enabled $true -PasswordNeverExpires $true -AccountPassword (Read-Host -AsSecureString "Password") -CannotChangePassword $true -Path "OU=Service-Accounts,OU=Users,OU=SPSE,OU=Functions,DC=ltblekinge,DC=org" -DisplayName $Name
</code>

==== Service Account Security ====

Service accounts should not be able to log into the server either locally or remotely. To 
set this, on each SharePoint server, run secpol.msc. Navigate to Local Policies, then User 
Rights Assignment. Under the policies “Deny log on locally” and “Deny log on through 
Remote Desktop Services,” add all of the service accounts allocated for SharePoint.
===== Configure SQL Server for SharePoint Server =====

Due to some changes to the default encryption settings of the SQL Server connection provider we need to either setup SQL Server connection encryption in SQL Server Configuration Manager/dbatools or revert to the previous, less secure defaults. Read more [[https://blog.netnerds.net/2023/03/new-defaults-for-sql-server-connections-encryption-trust-certificate/|New Encryption and Certificate Defaults in Microsoft's SQL Server Connection Provider]]

For this guide we will use the less secure defaults for the current session only.

<code powershell>
Set-DbatoolsInsecureConnection -SessionOnly
</code>


==== Settings ====

To ensure consistent behavior and performance, configure the following options and settings before you deploy SharePoint Server.

  * Do not enable auto-create statistics on SharePoint content databases. Enabling auto-create statistics is not supported for SharePoint Server. SharePoint Server configures the required settings during provisioning and upgrade. Manually enabling auto-create statistics on a SharePoint database can significantly change the execution plan of a query. The SharePoint databases either use a stored procedure that maintains the statistics (proc_UpdateStatistics) or rely on SQL Server to do this.

  * Set max degree of parallelism (MAXDOP) to 1 for instances of SQL Server that host SharePoint databases to make sure that a single SQL Server process serves each request.

<code powershell>
Set-DbaSpConfigure -Name MaxDegreeOfParallelism -Value 1 -SqlInstance $(hostname)
</code>

  * Max Memory: This can be tweaked and is more of a suggestion but default setting is not recommended. If you’re using SQL Server Integration Services, Analysis Services, Reporting Services, or any other applications on this server, you may need to lower max memory even farther. Please note that it is not recommended to run other services on the SQL server instance 

<code powershell>
Set-DbaMaxMemory -SqlInstance $(hostname)
</code>

  * Enable Default Backup Compression: If we enable Backup Compression as default the backup files will be smaller in size, but the CPU cost will be marginally larger during the time of the backup job.

<code powershell>
Set-DbaSpConfigure -Name 'DefaultBackupCompression' -Value 1 -SqlInstance $(hostname)
</code>

  * Enable Remote Dedicated Admin Connection

<code powershell>
Set-DbaSpConfigure -Name 'RemoteDacConnectionsEnabled' -Value 1 -SqlInstance $(hostname)
</code>

  * Configure Model Database: The Model database should be configured to 256MB for data files and 128MB for log files. This is a soft recommendation and can change depending on system, but this is better than the default.

<code powershell>
$sql = @" 
USE [master]
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', SIZE = 512000KB , FILEGROWTH = 262144KB )
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modellog', SIZE = 256000KB , FILEGROWTH = 131072KB )
GO
"@
Invoke-DbaQuery -Database model -Query $sql -SqlInstance $(hostname)
</code>

  * Increase Job History Max Rows and Max Rows per Job
<code powershell>
$sql = @"
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=5000,
		@jobhistory_max_rows_per_job=200
GO
"@
Invoke-DbaQuery -Database msdb -Query $sql -SqlInstance $(hostname)
</code>


===== Prepare node for SharePoint Server =====

Before we begin installing SharePoint Server Subscription Edition we will configure SQL Server client aliases so we do not hardcode the database server name in the configuration. This will make it easier in the future to change database server if needed.

==== SQL Server Alias ====

  - Open **cliconfg.exe** and go to **Alias**
  - Click **Add** and select **TCP/IP**
  - In **Server alias:** write the name of the alias you want to use
  - Uncheck **Dynamically determine port** and verify **Port number** is correct
  - Press **OK**

==== Run the Microsoft SharePoint Products Preparation Tool ====

Log in to the SharePoint Server using the farm account and run PrerequisiteInstaller.exe thats found in the ISO file for SharePoint Server. Restart the server when PrerequisiteInstaller.exe is done.

==== Run Setup ====

The following procedure installs binaries, configures security permissions, and edits registry settings for SharePoint Server. At the end of Setup, you can choose to start the SharePoint Products Configuration Wizard, which is described later in this section.

If you intend to use this computer as a search server, we recommend that you store the search index files on a separate storage volume or partition. Any other search data that needs to be stored is stored in the same location as the search index files. You can only set this location at installation time.

  * Verify that the user account that is performing this procedure is the farm administrator user account.

  * On the SharePoint Server Start page, click Install SharePoint Server.

  * On the Enter Your Product Key page, enter your product key, and then click Continue.

  * On the Read the Microsoft Software License Terms page, review the terms, select the I accept the terms of this agreement check box, and then click Continue.

  * To install SharePoint Server at a custom location, or to store search index files at a custom location, click the File Location tab, and then either type the custom location or click Browse to find the custom location.
    * For this deployment we will install the binaries on E:\Program Files\Microsoft Office Servers\16.0, and the Search files at S:\Program Files\Microsoft Office Servers\16.0\Data

  * Click Install Now.

  * When Setup finishes, a dialog prompts you to complete the configuration of your server. Ensure that the Run the SharePoint Products Configuration Wizard now check box is **not** selected as we will configure the rest of the installation and configuration from Powershell.

  * Click Close to start the configuration wizard and reboot the server.


If Setup fails, check log files in the Temp folder of the user account you used to run Setup. Ensure that you are logged in using the same user account and then type %temp% in the location bar in Windows Explorer. If the path in Windows Explorer resolves to a location that ends in a "1" or "2", you have to navigate up one level to view the log files. The log file name is SharePoint Server Setup (< time stamp>).


===== SharePoint Server 2019 Configuration =====

Instead of running the SharePoint Configuration Wizard, we will use PowerShell scripts to configure SharePoint.

Run the SharePoint Management Shell as an Administrator on the server that will 
host Central Administration. 

Note that we are using the SQL Alias for the -DatabaseServer parameter.

<code powershell>
New-SPConfigurationDatabase -DatabaseName SPSE_Configuration -AdministrationContentDatabaseName SPSE_Administration -DatabaseServer spse-db-dev -Passphrase (ConvertTo-SecureString "FarmPassphrase" -AsPlainText -Force) -FarmCredentials (Get-Credential -Message "Farm Account" -UserName "LTBLEKINGE\spse_farm-dev_srv") -LocalServerRole SingleServerFarm -Verbose
</code>

The next series of cmdlet secure permissions on the files and registry entries in use 
by SharePoint, provision SharePoint Features, Services, and Help.

<code powershell>
Initialize-SPResourceSecurity
Install-SPFeature -AllExistingFeatures
Install-SPService
Install-SPApplicationContent
</code>

==== Central Administration ====

To configure Central Administration to use Kerberos as the authentication mechanism, 
a new SPN must be set on the Farm Account. The SPN will take the format of HTTP/
CentralAdminFQDN.

<code>
Setspn -U -S HTTP/spse-ca-dev.ltblekinge.org LTBLEKINGE\spse_farm-dev_srv
</code>

<WRAP INFO ROUND>
Tip The SPN for a web site will always start with "HTTP" even if the site is using 
the SSL protocol, as HTTP is a Kerberos service, not a protocol description.
</WRAP>

Create Central Administration using Kerberos and SSL.

<code powershell>
New-SPCentralAdministration -Port 443 -WindowsAuthProvider Kerberos -SecureSocketsLayer:$true
</code>

The next step is to change the default Alternate Access Mapping to align with the 
SPN and SSL certificate. Use Get-SPWebApplication -IncludeCentralAdministration to 
see what the current URL of Central Administration is, then modify it

<code powershell>
Set-SPAlternateUrl -Identity https://spse-misc01-dev -Url https://spse-ca-dev.ltblekinge.org
</code>

If a custom URL was set for Central Administration that does not include the 
machine name, make sure to create an A record in DNS to resolve the new hostname. 
In addition, validate that the IIS Site Bindings for the SharePoint Central Administration 
site are set correctly as shown. Because this server will only have a single 
IP address but will need to support multiple SSL certificates, Server Name Indication will 
be used. 

{{:sharepoint_server_se:administration:install_spse:spse-ca-dev-centraladmin-iis.jpg?nolink|}}

You should now be able to browse Central Administration at https://spse-ca-dev.ltblekinge.org from the server.

==== Install Language Packs ====

Language packs are available here: https://www.microsoft.com/sv-se/download/details.aspx?id=103600

Verify that the user account that is performing this procedure is the Setup user account. For information about the Setup user account, see Initial deployment administrative and service accounts in SharePoint Server.

  - Mount the ISO disc image as a drive on your computer by double-clicking on it, or by specifying it as a virtual drive in your virtual machine manager.
  - Navigate to the mounted drive and run (setup.exe) to launch the language pack setup program.
  - On the Read the Microsoft Software License Terms page, review the terms, select the I accept the terms of this agreement check box, and then click Continue.
  - The Setup runs and installs the language pack.
  - Run SharePoint Products Configuration by using the default settings.


==== Managed Accounts ====

Managed accounts are the service accounts that run SharePoint services. The Farm 
Account account is added by default when the SharePoint farm is created. In this farm, 
we have two additional managed accounts that must be registered, spse-svc-dev_srv to run the 
Service Applications and spse-web-dev_srv to run the Web Applications.

<code powershell>
$cred = Get-Credential -UserName "LTBLEKINGE\spse-svc-dev_srv" -Message "Credentials for spse-svc-dev_srv" 
New-SPManagedAccount -Credential $cred

$cred = Get-Credential -UserName "LTBLEKINGE\spse-web-dev_srv" -Message "Credentials for spse-web-dev_srv"
New-SPManagedAccount -Credential $cred
</code>
==== Service Application Pool ====

Because we will be using the minimal number of Application Pools possible in the farm, 
we will only create a single Application Pool for all Service Applications. This is done 
via PowerShell, and may also be done while creating the first Service Application in 
the farm. Using a single Application Pool reduces overhead as .NET processes cannot 
share memory even though the same binaries have been loaded into the process (e.g., 
Microsoft.SharePoint.dll cannot be shared between two w3wp.exe processes).

<code powershell>
New-SPServiceApplicationPool -Name "SharePoint Web Services Default" -Account (Get-SPManagedAccount "LTBLEKINGE\spse-svc-dev_srv")
</code>

When creating Service Applications, we will now select the “SharePoint Web Services Default” Application Pool

==== Logging ====

=== Unified Logging Service ===


Out of the box, SharePoint logs to the Unified Logging Service (Diagnostic Logging) to “C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\LOGS\”. Logging to the C: drive may not be deal, not only for space reasons, but also for performance due to being on the same volume as all other SharePoint web-based resources that users access.

<code powershell>
Set-SPDiagnosticConfig -DaysToKeepLogs 7 -LogDiskSpaceUsageGB 15 -LogMaxDiskSpaceUsageEnabled:$true -LogLocation L:\ULS
</code>

Note that this path must be on all SharePoint servers in the farm. In addition, you may specify the maximum number of days to retain log files as well as the maximum disk space log files can consume. It is advisable to set the maximum disk space log files can use below the volume size they reside on.


If moving the ULS logs to an alternate location, it is also recommended to move the Usage logs, as well. 

<code powershell>
Set-SPUsageService -UsageLogLocation L:\ULS
</code>

=== IIS ===

Change the default log location for IIS logs to another drive.

<code powershell>
mkdir L:\IIS
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/sites/siteDefaults/logFile' -name 'directory' -value L:\IIS\
</code>

==== Distributed Cache Service ====

In previous versions of SharePoint Server, the Distributed Cache feature relied on Windows Server AppFabric, which was a separately installed component. Starting with SharePoint Server Subscription Edition, the AppFabric caching technology has been directly integrated into the Distributed Cache feature. Distributed Cache no longer relies on the external Windows Server AppFabric component and it will no longer be installed by the Microsoft SharePoint Products Preparation Tool.

The Distributed Cache service requires two modifications. The first change is to replace the Farm Admin account running the AppFabric Caching Service with the services account. The second task is to adjust the amount of memory allocated to Distributed Caching

<code powershell>
$acct = Get-SPManagedAccount "LTBLEKINGE\spse-svc-dev_srv"
$farm = Get-SPFarm
$svc = $farm.Services | ?{$_.TypeName -eq "Distributed Cache"}
$svc.ProcessIdentity.CurrentIdentityType = "SpecificUser"
$svc.ProcessIdentity.ManagedAccount = $acct
$svc.ProcessIdentity.Update()
$svc.ProcessIdentity.Deploy()

Update-SPDistributedCacheSize -CacheSizeInMB 2048
</code>

===== Service Applications =====

Service Application creation will primarily be done via the SharePoint Management 
Shell, but with a few exceptions, Service Applications may also be created via Central 
Administration. Not all Service Applications must be provisioned on every farm. The 
best strategy is determining, via business requirements, to only provision Service 
Applications as they’re required. Service Applications will typically add or activate timer 
jobs, which increases the load within the farm.

==== Usage and Health Data Collection Service Application ====

The Usage and Health Data Collection Service Application provides data collection 
that can be used for farm health and performance analysis via the Usage database. 

<code powershell>
New-SPUsageApplication -Name "Usage and Health Data Collection Service Application" -DatabaseServer spse-db-dev -DatabaseName SPSE_Usage
</code>

==== App Management Service ====

The App Management Service is required for SharePoint Add-ins and Hybrid scenarios. 
This is the first Service Application where we will be specifying the new Service 
Application IIS Application Pool.

<code powershell>
$sa = New-SPAppManagementServiceApplication -Name "App Management Service Application" -DatabaseName "SPSE_AppManagement" -ApplicationPool "SharePoint Web Services Default"

New-SPAppManagementServiceApplicationProxy -Name "App Management Service Application" -ServiceApplication $sa -UseDefaultProxyGroup
</code>

==== Secure Store Service ====

The Secure Store Service provides credential delegation and access to other services 
inside and outside of SharePoint. The -AuditlogMaxSize value is in days.

<code powershell>
$sa = New-SPSecureStoreServiceApplication -Name "Secure Store Service Application" -ApplicationPool "SharePoint Web Services Default" -AuditingEnabled:$true -AuditlogMaxSize 7 -DatabaseName "SPSE_SecureStore"

New-SPSecureStoreServiceApplicationProxy -Name "Secure Store Service Application" -ServiceApplication $sa
</code>

Once the proxy has been created, set the Master Key and keep it in a safe place for 
Disaster Recovery purposes. The master key may be set via Central Administration, 
manage Service Applications. Manage the Secure Store Service Application and click 
Generate New Key.


==== Business Data Connectivity Service ====

Business Data Connectivity Service provides connectivity to external data sources, such 
as SQL databases for exposing them as External Lists.

<code powershell>
New-SPBusinessDataCatalogServiceApplication -Name "Business Data Connectivity Service Application" -DatabaseName "SPSE_BCS" -ApplicationPool "SharePoint Web Services Default"
</code>


==== Managed Metadata Service ====

The Managed Metadata Service provides taxonomies for end-user consumption and 
SharePoint services, such as Search, User Profile Service, and more. The Managed 
Metadata Service should be created prior to the User Profile or Search Service.

<code powershell>
$sa = New-SPMetadataServiceApplication -Name "Managed Metadata Service" -DatabaseName "SPSE_MMS" -ApplicationPool "SharePoint Web Services Default" -SyndicationErrorReportEnabled 

New-SPMetadataServiceApplicationProxy -Name "Managed Metadata Service" -ServiceApplication $sa -DefaultProxyGroup -ContentTypePushdownEnabled -DefaultKeywordTaxonomy -DefaultSiteCollectionTaxonomy
</code>

==== SharePoint Enterprise Search Service ====

The Enterprise Search Configuration is a complex script and is often easier to complete 
via Central Administration. However, when created via Central Administration, the 
Search Server databases will have GUIDs appended to them and the Search topology 
will likely not fit your needs. As adjusting the Search topology requires PowerShell, it is 
beneficial to create the Search Service Application via PowerShell to begin with.

<code powershell>
Get-SPEnterpriseSearchServiceInstance -Local | Start-SPEnterpriseSearchServiceInstance

Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Local | Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance

$sa = New-SPEnterpriseSearchServiceApplication -Name "Search Service Application" -DatabaseName "SPSE_Search" -ApplicationPool "SharePoint Web Services Default" -AdminApplicationPool "SharePoint Web Services Default"
New-SPEnterpriseSearchServiceApplicationProxy -Name "Search Service Application" -SearchApplication $sa
$si = Get-SPEnterpriseSearchServiceInstance -Local
$clone = New-SPEnterpriseSearchTopology -SearchApplication $sa
</code>

Create the initial topology.

<code powershell>
New-SPEnterpriseSearchAdminComponent -SearchTopology $clone -SearchServiceInstance $si

New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $clone -SearchServiceInstance $si

New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $clone -SearchServiceInstance $si

New-SPEnterpriseSearchCrawlComponent -SearchTopology $clone -SearchServiceInstance $si

New-Item -Path "S:\SearchIndex\0" -ItemType Directory
New-SPEnterpriseSearchIndexComponent -SearchTopology $clone -SearchServiceInstance $si -IndexPartition 0 -RootDirectory S:\SearchIndex\0

New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $clone -SearchServiceInstance $si

Set-SPEnterpriseSearchTopology -Identity $clone
</code>

Remove the inactive topologies

<code powershell>
$sa = Get-SPEnterpriseSearchServiceApplication
foreach ($topo in (Get-SPEnterpriseSearchTopology -SearchApplication $sa | Where-Object { $_.State -eq 'Inactive' })) {
    Remove-SPEnterpriseSearchTopology -Identity $topo -Confirm:$false 
}
</code>

Set the Crawl Account for the Search Service Application.
<code powershell>
$sa = Get-SPEnterpriseSearchServiceApplication
$content = New-Object Microsoft.Office.Server.Search.Administration.Content($sa)
$content.SetDefaultGatheringAccount("LTBLEKINGE\spse-crwl-dev_srv", (ConvertTo-SecureString "<Password>" -AsPlainText -Force))
</code>

Configure the same Content Source to use Continuous Crawls. While Continuous Crawls may increase CPU, memory, and/or disk usage, you won’t have to be concerned with timing incremental crawls appropriately.

<code powershell>
$source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $sa 
-Identity "Local SharePoint sites"
$source.EnableContinuousCrawls = $true
$source.Update()
</code>

The last step is to change the service account running the Search services. This can be done via Central Administration under **Security**. Click **Configure service accounts**. Change the service account to **LTBLEKINGE\spse-svc-dev_srv** for the services **Windows Service – Search Host Controller Service** and **Windows Service – SharePoint Server Search**.

==== User Profile Service ====

The User Profile Service synchronizes User and Group objects from Active Directory into 
the SharePoint Profile Service. This service is also responsible for managing Audiences 
and configuration of MySites (OneDrive). Creating the service Application may be done 
via PowerShell.

<code powershell>
$sa = New-SPProfileServiceApplication -Name "User Profile Service Application" -ApplicationPool "SharePoint Web Services Default" -ProfileDBName "SPSE_Profile" -SocialDBName "SPSE_Social" -ProfileSyncDBName "SPSE_Sync"

New-SPProfileServiceApplicationProxy -Name "User Profile Service Application" -ServiceApplication $sa -DefaultProxyGroup
</code>

One thing you’ll notice is that we are specifying a name for the Sync database even 
though the database isn’t used as User Profile Synchronization Service is no longer part 
of SharePoint. This is because SharePoint will create it regardless, although the database 
will be empty with no tables.

Add the Default Content Access Account, LAB\s-crawl, to the Administrator 
permissions of the newly created User Profile Service Application in order to enumerate 
People Data for Search.

<code powershell>
$user = New-SPClaimsPrincipal "LTBLEKINGE\spse-crwl-dev_srv" -IdentityType WindowsSamAccountName
$security = Get-SPServiceApplicationSecurity $sa -Admin
Grant-SPObjectSecurity $security $user "Retrieve People Data for Search Crawlers"
Set-SPServiceApplicationSecurity $sa $security -Admin
</code>

Update the Search Server Service Content Source to use the SPS3S:// protocol (People Crawl over SSL, if using HTTP, use the SPS3:// protocol).

<code powershell>
$sa = Get-SPEnterpriseSearchServiceApplication
$source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $sa -Identity "Local SharePoint sites"
$source.StartAddresses.Add("sps3s://spse-dev-my.ltblekinge.org")
$source.Update()
</code>



===== Web Application Setup =====

Now we will create the Web Applications for https://spse-dev.ltblekinge.org which will hold Team Sites, Portals and so on and https://spse-dev-my.ltblekinge.org which will contain the MySite host and user’s MySites, also known as OneDrive for Business sites

Both Web Applications will be configured to use Kerberos. This requires registering two SPNs:

<code powershell>
Setspn -U -S HTTP/spse-dev.ltblekinge.org LTBLEKINGE\spse-web-dev_srv
Setspn -U -S HTTP/spse-dev-my.ltblekinge.org LTBLEKINGE\spse-web-dev_srv 
</code>

Create the Authentication Provider, enabling Kerberos, and then create the Web Application.
<code powershell>
$ap = New-SPAuthenticationProvider -DisableKerberos:$false

New-SPWebApplication -Name "SharePoint" -HostHeader spse-dev.ltblekinge.org -Port 443 -ApplicationPool "SharePoint" -ApplicationPoolAccount (Get-SPManagedAccount "LTBLEKINGE\spse-web-dev_srv") -SecureSocketsLayer:$true -AuthenticationProvider $ap -DatabaseName SPSE_SharePoint_CDB1 -Verbose

New-SPWebApplication -Name "SharePoint MySites" -HostHeader spse-dev-my.ltblekinge.org -Port 443 -ApplicationPool "SharePoint" -SecureSocketsLayer:$true -AuthenticationProvider $ap -DatabaseName SPSE_SharePoint-My_CDB1 -verbose
</code>

Validate the IIS Bindings are correct on all servers and that the SSL certificate has been correctly selected. SharePoint may not set the SSL certificate for you. 

To support Publishing sites, add the Portal Super User and Portal Super Reader to the SharePoint Web Application. These accounts are used for permission comparison purposes only and the password for these accounts is not required. If there is the possibility that a Publishing site may be created on the SharePoint MySite Web Application, add the accounts there as well. We must set the initial properties on the 
SharePoint Web Application via the SharePoint Management Shell.

<code powershell>
$wa = Get-SPWebApplication https://spse-dev.ltblekinge.org
$wa.Properties["portalsuperuseraccount"] = "i:0#.w|LTBLEKINGE\spse-su-dev_srv"
$wa.Properties["portalsuperreaderaccount"] = "i:0#.w|LTBLEKINGE\spse-sr-dev_srv"
$wa.Update()
</code>

Adding the users to the Web Application Policy may be done through Manage Web 
Applications under Central Administration, or through the SharePoint Management Shell.

<code powershell>
$wa = Get-SPWebApplication https://spse-dev.ltblekinge.org
$zp = $wa.ZonePolicies("Default")

$policy = $zp.Add("i:0#.w|LTBLEKINGE\spse-su-dev_srv", "Portal Super User")
$policyRole = $wa.PolicyRoles.GetSpecialRole("FullControl")
$policy.PolicyRoleBindings.Add($policyRole)

$policy = $zp.Add("i:0#.w|LTBLEKINGE\spse-sr-dev_srv", "Portal Super Reader")
$policyRole = $wa.PolicyRoles.GetSpecialRole("FullRead")
$policy.PolicyRoleBindings.Add($policyRole)

$wa.Update()
</code>

When the Zone Policy has been changed, it will require an IISReset to take effect. To 
perform this, from the SharePoint Management Shell, run the following:

<code powershell>
foreach ($server in (Get-SPServer | Where-Object { $_.Role -ne 'Invalid' -and $_.Role -ne 'Search' })) {
    Write-Host "Resetting IIS on $($server.Address)..."
    iisreset $server.Address /noforce
}
</code>

Add the required Managed Path, “personal” to the SharePoint MySite Web Application and remove the default “sites” Managed Path.

<code powershell>
New-SPManagedPath -RelativeUrl "personal" -WebApplication https://spse-dev-my.ltblekinge.org
Remove-SPManagedPath -Identity "sites" -WebApplication https://spse-dev-my.ltblekinge.org
</code>

Then, enable Self-Service Site Creation.

<code powershell>
$wa = Get-SPWebApplication https://sp-my.cobaltatom.com
$wa.SelfServiceSiteCreationEnabled = $true
$wa.Update()
</code>

===== Root Site Collections =====

Web Applications are required to have a root Site Collection. This is the Site Collection 
that resides at the path “/”. For the SharePoint Web Application, we will deploy a modern 
Communications Site Template and for the SharePoint MySite Web Application, we will 
deploy the MySite Host Template.

<code powershell>
New-SPSite -Url https://spse-dev.ltblekinge.org -Template SITEPAGEPUBLISHING#0 -Name "Communications Site" -OwnerAlias "LTBLEKINGE\si2020adm" -Language 1053

New-SPSite -Url https://spse-dev-my.ltblekinge.org -Template SPSMSITEHOST#0 -Name "OneDrive for Business" -OwnerAlias "LTBLEKINGE\si2020adm" -Language 1053
</code>

===== Content Type Hub and Enterprise Search Center Configuration =====

In addition to these Site Collections, we will also create a Content Type Hub and an 
Enterprise Search Center. The Content Type Hub will be created and then configured in 
the Managed Metadata Service, and the Enterprise Search Center will be created and set 
as the Search Center URL. The Content Type Hub can be a standard classic Team Site Template.

<code powershell>
New-SPSite -Url https://spse-dev.ltblekinge.org/sites/contentTypeHub -Template STS#0 -Name "Content Type Hub" -OwnerAlias "LTBLEKINGE\si2020adm"
</code>

Set the Managed Metadata Service Content Type Hub URL.

<code powershell>
Set-SPMetadataServiceApplication -Identity "Managed Metadata Service" -HubUri https://spse-dev.ltblekinge.org/sites/contentTypeHub
</code>

Next, create the Enterprise Search Center using the SRCHCEN#0 template.

<code powershell>
New-SPSite -Url https://spse-dev.ltblekinge.org/sites/search -Template SRCHCEN#0 -Name "Enterprise Search Center" -OwnerAlias "LTBLEKINGE\si2020adm"
</code>

Finally, set the Enterprise Search Center in the SharePoint Search Service.

<code powershell>
$sa = Get-SPEnterpriseSearchServiceApplication
$sa.SearchCenterUrl = "https://spse-dev.ltblekinge.org/sites/search/Pages"
$sa.Update()
</code>

===== MySite Configuration =====

To configure MySites for the User Profile Service, the only option we must set is the 
MySite Host. All other settings are optional, but can be found in Central Administration 
under Manage Service Applications in the User Profile Service Application. In the Setup 
MySites link are a variety of options to control the MySite configuration.

<code powershell>
$sa = Get-SPServiceApplication | ?{$_.TypeName -eq "User Profile Service Application"}
Set-SPProfileServiceApplication -Identity $sa -MySiteHostLocation https://spse-dev-my.ltblekinge.org
</code>

Recently Shared Items is a new feature for SharePoint On-Premises that displays 
the items recently shared with you. It can only be enabled through the SharePoint 
Management Shell. The URL specified in this cmdlet is the MySite Host URL.

<code powershell>
Enable-SPFeature "RecentlySharedItems" -Url https://spse-dev-my.ltblekinge.org
</code>
===== Modern Self-Service Site Creation =====

<WRAP WARNING ROUND>
Kolla om vi kan skapa siterna på /teams/ istället för på /sites/ som är standard. https://www.sharepointdiary.com/2014/05/configure-self-service-site-creation-in-sharepoint-2013.html
</WRAP>

SharePoint Server 2019 introduces a new feature to allow users to provision Modern 
Team and Communication Sites from the MySite Host.

Enable self-service site creation on the primary Web Application.

<code powershell>
$wa = Get-SPWebApplication https://spse-dev.ltblekinge.org
$wa.SelfServiceSiteCreationEnabled = $true
$wa.Update()
</code>

In addition, you must provide users with at least Read access to the root Site 
Collection. For example, you could add the group 
Everyone to the root Site Collection Visitors group.

The next step is to set up self-service site creation on the MySite host Web Application

<code powershell>
$wa = Get-SPWebApplication https://spse-dev-my.ltblekinge.org
$wa.ShowStartASiteMenuItem = $true
$wa.SelfServiceCreationAlternateUrl = "https://spse-dev.ltblekinge.org"
$wa.Update()
</code>
