====== Install SQL Server ======

How to create the virtual machine for SQL Server is specified here https://wikit.ltblekinge.org/installation_sql

This guide provides steps how to install and configure a SQL Server right after the guide for creating the VM are done.

===== Before you begin =====

  * Verify that all needed disks are mounted. We need to have D:\ (Data), E:\ (Program), F:\ (Backup), L:\ (Log) and T:\ (TempDB) mounted and online.
  * Permissions in Active Directory is needed for creating the service accounts


===== Prepare Powershell =====

Before we begin the installation of SQL Server we need to configure Powershell and installing a couple of modules.

**Execution Policy**

Set execution policy to bypass so we can run Powershell commands. If your restart Powershell during this guide you will need to run the below script again for each time Powershell is restarted.

<code powershell>
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
</code>

**Install DBAtools module**

The DBAtools module will be used for installing SQL Server and configure the Availability Group. If a pop-up windows comes up with the text **NuGet provider is required to continue** select **Yes**.

The client or server needs to have internet access for this to work.

<code powershell>
If (!(Get-Module DBATools -ListAvailable)) {Install-Module DBATools -Scope CurrentUser -Force}
</code>

**Install Active Directory module**

We will use the Active Directory module to create and configure the service account. If the installation is successfull you will se **Success** under **Exit Code**.

<code powershell>
Add-WindowsFeature RSAT-AD-PowerShell
</code>

===== Prepare server =====

Before we begin the installation of SQL Server we will verify that the server is configured correctly.

**Disk Allocation Unit Size**

Best practice for disk allocation unit size for the data, log and TempDB disks are 64 KB (65536 bytes).

<code powershell>
Get-Volume | Select-Object FileSystemLabel,DriveLetter,DriveType,AllocationUnitSize | Format-Table -AutoSize
</code>

If the AllocationUnitSize is anything other than 65536 for the data, log and TempDB disks, the disk will need to be reformated. Below script will reformat data, log and TempDB disks to correct size.

Note that this script expect that D: is Data, L: is Log and T: is TempDB.

<code powershell>
Get-Volume -DriveLetter D | Format-Volume -AllocationUnitSize 65536 -NewFileSystemLabel "SQL Data" -Confirm:$false
Get-Volume -DriveLetter L | Format-Volume -AllocationUnitSize 65536 -NewFileSystemLabel "SQL Log" -Confirm:$false
Get-Volume -DriveLetter T | Format-Volume -AllocationUnitSize 65536 -NewFileSystemLabel "SQLTempDB" -Confirm:$false

</code>

**Power Settings**

The power plan on the VM should always be set to High Performance. This setting also needs to be verified in BIOS and on the Hypervisor if we are running on a VM.

<code powershell>
Set-DbaPowerPlan -PowerPlan 'High Performance' -ComputerName $(hostname)
</code>

===== Set Firewall Rules =====

<code powershell>
New-DbaFirewallRule -SqlInstance localhost
</code>

===== Create Service Accounts =====

We will need two service accounts for a standard SQL Server installation, one for the engine and one for the agent. This only needs to be done from one server.

Note that if the user running the scripts is not in the same domain as the service account this will not work.

Variables that needs to be changed

  * $OU: Path of the OU or container where the new object is created
  * $eDescription: Description of the Engine account
  * $eDescription: Description of the Agent account

Two pop-up windows will be shown, write the username and password for the Engine account in the first pop-up window and write the username and password for the Agent account in the second.

<code powershell>
$OU = "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
$eDescription = "SQL Server Engine account for testnetag01"
$aDescription = "SQL Server Agent account for testnetag01"

$eCredential = Get-Credential -Message "Name and password for Engine Service Account"
$aCredential = Get-Credential -Message "Name and password for Agent Service Account"

New-ADUser -SamAccountName $eCredential.UserName -Name $eCredential.UserName -Path $OU -Description $eDescription -CannotChangePassword $true -PasswordNeverExpires $true -AccountPassword $eCredential.Password -DisplayName $eCredential.UserName -Enabled $true -UserPrincipalName ($eCredential.UserName + "@" + $env:USERDNSDOMAIN)
New-ADUser -SamAccountName $aCredential.UserName -Name $aCredential.UserName -Path $OU -Description $aDescription -CannotChangePassword $true -PasswordNeverExpires $true -AccountPassword $aCredential.Password -DisplayName $aCredential.UserName -Enabled $true -UserPrincipalName ($aCredential.UserName + "@" + $env:USERDNSDOMAIN)
</code>

Do not make the service account a local administrator. SQL Server’s installer will automatically grant the least privileges required during setup.


===== Install SQL Server =====

Variables that needs to be changed

  * $Path: Path to installation media
  * $Version: Version of SQL Server we want to install. Default is 2019
  * $DeveloperEdition: Can be either $true for installing Developer Edition or $false for installing the edition that the media comes with.

Three pop-up windows will be shown, one for each service account and one for the SA account. Enter the credentials. The domain name needs to be specified for the engine and agent account, example ltblekinge\serviceaccount or test.net.ad\svc-sql_a-ag01

A pop-up window will be displayed, click Yes and SQL Server will be installed.

<code powershell>
$Path = "C:\tmp\SQL_2019"
$Version = "2019"
[bool]$DeveloperEdition = $true

$eCredential = Get-Credential -Message "Credentials for Engine Service account"
$aCredential = Get-Credential -Message "Credentials for Agent Service account"
$saCredential = Get-Credential -Message "Credentials for SA account" 

If ($DeveloperEdition) {Install-DbaInstance -Version $Version -Feature Default -Path $Path -InstancePath E:\Program -DataPath D:\Data -LogPath L:\Logs -TempPath T:\TempDB -BackupPath F:\Backups -EngineCredential $eCredential -AgentCredential $aCredential -SaCredential $saCredential -PerformVolumeMaintenanceTasks -AuthenticationMode Mixed -ProductID 22222-00000-00000-00000-00000 -Verbose}
else {Install-DbaInstance -Version $Version -Feature Default -Path $Path -InstancePath E:\Program -DataPath D:\Data -LogPath L:\Logs -TempPath T:\TempDB -BackupPath F:\Backups -EngineCredential $eCredential -AgentCredential $aCredential -SaCredential $saCredential -PerformVolumeMaintenanceTasks -AuthenticationMode Mixed -Verbose}
</code>

===== Configure SQL Server =====

**TempDB**

The recommended TempDB file count is one file for each core up to 8 cores. The recommended file size is by getting the total size of the TempDB volume and fill up 80% of the volume.

Restarting the SQL Server service is required.

<code powershell>
$tempDBFileCount = (Test-DbaTempDbConfig -SqlInstance $(hostname) | Where-Object {$_.Rule -eq "File Count"}).Recommended
$tempDBFileSize= [math]::round(((Get-Volume -DriveLetter T).Size/1MB) * 0.80)
Set-DbaTempDbConfig -SqlInstance $(hostname) -DataFileCount $tempDBFileCount -DataFileSize $tempDBFileSize

Restart-Service MSSQLSERVER -Force
</code>


**Max Degree of parallelism**

SQL Server 2019 (15.x) introduces automatic recommendations for setting the MAXDOP server configuration option during the installation process based on the number of processors available.

Rule of thumb: set this to the number of physical cores in a single NUMA node (processor) socket on your hardware or less. This number should always be even. Only use the value of 1 if you have specific vendor requirements to disable parallelism, like with Microsoft SharePoint Server.

Variables that needs to be changed

  * $maxdopValue: Set this to the recommended value for the specific server

<code powershell>
[int]$maxdopValue = 4
Set-DbaSpConfigure -Name MaxDegreeOfParallelism -Value $maxdopValue -SqlInstance $(hostname)
</code>

**Cost Threshold for Parallelism**

The optimizer uses that cost threshold to figure out when it should start evaluating plans 
that can use multiple threads. A good starting point is to set this to between 50 and 75.

<code powershell>
Set-DbaSpConfigure -Name CostThresholdForParallelism -Value 50 -SqlInstance $(hostname)
</code>

**Max Memory**

This can be tweaked and is more of a suggestion but default setting is not recommended.

If you’re using SQL Server Integration Services, Analysis Services, Reporting Services, 
or any other applications on this server, you may need to lower max memory even 
farther. 

<code powershell>
Set-DbaMaxMemory -SqlInstance $(hostname)
</code>

**Enable Agent XPs**

<code powershell>
Set-DbaSpConfigure -Name AgentXPsEnabled -Value 1 -SqlInstance $(hostname)
</code> 

**Enable Default Backup Compression**

If we enable Backup Compression as default the backup files will be smaller in size, but the CPU cost will be marginally larger during the time of the backup job.

<code powershell>
Set-DbaSpConfigure -Name 'DefaultBackupCompression' -Value 1 -SqlInstance $(hostname)
</code>

**Enable Remote Dedicated Admin Connection**

<code powershell>
Set-DbaSpConfigure -Name 'RemoteDacConnectionsEnabled' -Value 1 -SqlInstance $(hostname)
</code>

**Enable Database Mail**

This is used when sending mail from SQL Server.

<code powershell>
Set-DbaSpConfigure -Name DatabaseMailEnabled -Value 1 -SqlInstance $(hostname)
</code>