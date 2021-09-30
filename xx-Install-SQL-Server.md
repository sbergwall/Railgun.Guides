# Install SQL Server

This guide provides steps how to install and configure a SQL Server.

## Before you begin

  * Verify that all needed disks are mounted. We need to have D:\ (Data), E:\ (Program), F:\ (Backup), L:\ (Log) and T:\ (TempDB) mounted and online.
  * Permissions in Active Directory is needed for creating the service accounts


## Prepare Powershell

Before we begin the installation of SQL Server we need to configure Powershell and installing a couple of modules.

### Execution Policy

Set execution policy to bypass so we can run Powershell commands. If your restart Powershell during this guide you will need to run the below script again for each time Powershell is restarted.

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```

### Install DBAtools module

The DBAtools module will be used for installing SQL Server and configure the Availability Group. If a pop-up windows comes up with the text **NuGet provider is required to continue** select **Yes**.

The client or server needs to have internet access for this to work.

```powershell
If (!(Get-Module DBATools -ListAvailable)) {Install-Module DBATools -Scope CurrentUser -Force}
```

### Install Active Directory module

We will use the Active Directory module to create and configure the service account. If the installation is successfull you will se **Success** under **Exit Code**.

```powershell
Add-WindowsFeature RSAT-AD-PowerShell
```

## Prepare server

Before we begin the installation of SQL Server we will verify that the server is configured correctly.

### Disk Allocation Unit Size

A good practice for disk allocation unit size for the data, log and TempDB disks are 64 KB (65536 bytes).

```powershell
Get-Volume | Select-Object FileSystemLabel,DriveLetter,DriveType,AllocationUnitSize | Format-Table -AutoSize
```

Below script will reformat data, log and TempDB disks to correct size. Note that this script expect that D: is Data, L: is Log and T: is TempDB.

```powershell
Get-Volume -DriveLetter D | Format-Volume -AllocationUnitSize 65536 -NewFileSystemLabel "SQL Data" -Confirm:$false
Get-Volume -DriveLetter L | Format-Volume -AllocationUnitSize 65536 -NewFileSystemLabel "SQL Log" -Confirm:$false
Get-Volume -DriveLetter T | Format-Volume -AllocationUnitSize 65536 -NewFileSystemLabel "SQLTempDB" -Confirm:$false
```

### Power Settings

The power plan on the VM should always be set to High Performance. This setting also needs to be verified in BIOS and on the Hypervisor if we are running on a VM.

```powershell
Set-DbaPowerPlan -PowerPlan 'High Performance' -ComputerName $(hostname)
```

### Set Firewall Rules

```powershell
New-DbaFirewallRule -SqlInstance localhost
```

### Create Service Accounts

We will need two service accounts for a standard SQL Server installation, one for the engine and one for the agent. This only needs to be done from one server.

Note that if the user running the scripts is not in the same domain as the service account this will not work.

Variables that needs to be changed

  * $OU: Path of the OU or container where the new object is created
  * $eDescription: Description of the Engine account
  * $eDescription: Description of the Agent account

Two pop-up windows will be shown, write the username and password for the Engine account in the first pop-up window and write the username and password for the Agent account in the second.

```powershell
$OU = "OU=ServiceAccount,OU=Users,OU=modc,DC=modc,DC=se"
$eDescription = "SQL Server Engine account for testnetag01"
$aDescription = "SQL Server Agent account for testnetag01"

$eCredential = Get-Credential -Message "Name and password for Engine Service Account"
$aCredential = Get-Credential -Message "Name and password for Agent Service Account"

New-ADUser -SamAccountName $eCredential.UserName -Name $eCredential.UserName -Path $OU -Description $eDescription -CannotChangePassword $true -PasswordNeverExpires $true -AccountPassword $eCredential.Password -DisplayName $eCredential.UserName -Enabled $true -UserPrincipalName ($eCredential.UserName + "@" + $env:USERDNSDOMAIN)

New-ADUser -SamAccountName $aCredential.UserName -Name $aCredential.UserName -Path $OU -Description $aDescription -CannotChangePassword $true -PasswordNeverExpires $true -AccountPassword $aCredential.Password -DisplayName $aCredential.UserName -Enabled $true -UserPrincipalName ($aCredential.UserName + "@" + $env:USERDNSDOMAIN)
```

Do not make the service account a local administrator. SQL Server’s installer will automatically grant the least privileges required during setup.


## Install SQL Server

Variables that needs to be changed

  * $Path: Path to installation media
  * $Version: Version of SQL Server we want to install. Default is 2019
  * $DeveloperEdition: Can be either $true for installing Developer Edition or $false for installing the edition that the media comes with.

Three pop-up windows will be shown, one for each service account and one for the SA account. Enter the credentials. The domain name needs to be specified for the engine and agent account, example test.net.ad\svc-sql_a-ag01

A pop-up window will be displayed, click Yes and SQL Server will be installed.

```powershell
$Path = "C:\tmp\SQL_2019"
$Version = "2019"
[bool]$DeveloperEdition = $true

$eCredential = Get-Credential -Message "Credentials for Engine Service account"
$aCredential = Get-Credential -Message "Credentials for Agent Service account"
$saCredential = Get-Credential -Message "Credentials for SA account" 

If ($DeveloperEdition) {Install-DbaInstance -Version $Version -Feature Default -Path $Path -InstancePath E:\Program -DataPath D:\Data -LogPath L:\Logs -TempPath T:\TempDB -BackupPath F:\Backups -EngineCredential $eCredential -AgentCredential $aCredential -SaCredential $saCredential -PerformVolumeMaintenanceTasks -AuthenticationMode Mixed -ProductID 22222-00000-00000-00000-00000 -Verbose}
else {Install-DbaInstance -Version $Version -Feature Default -Path $Path -InstancePath E:\Program -DataPath D:\Data -LogPath L:\Logs -TempPath T:\TempDB -BackupPath F:\Backups -EngineCredential $eCredential -AgentCredential $aCredential -SaCredential $saCredential -PerformVolumeMaintenanceTasks -AuthenticationMode Mixed -Verbose}
```

## Configure SQL Server

### TempDB

A good practice for TempDB file count is one file for each core up to 8 cores. The file size is by getting the total size of the TempDB volume and fill up 80% of the volume.

Restarting the SQL Server service is required.

```powershell
$tempDBFileCount = (Test-DbaTempDbConfig -SqlInstance $(hostname) | Where-Object {$_.Rule -eq "File Count"}).Recommended
$tempDBFileSize= [math]::round(((Get-Volume -DriveLetter T).Size/1MB) * 0.80)
Set-DbaTempDbConfig -SqlInstance $(hostname) -DataFileCount $tempDBFileCount -DataFileSize $tempDBFileSize

Restart-Service MSSQLSERVER -Force
```


### Max Degree of parallelism

SQL Server 2019 (15.x) introduces automatic recommendations for setting the MAXDOP server configuration option during the installation process based on the number of processors available.

Rule of thumb: set this to the number of physical cores in a single NUMA node (processor) socket on your hardware or less. This number should always be even. Only use the value of 1 if you have specific vendor requirements to disable parallelism, like with Microsoft SharePoint Server.

Variables that needs to be changed

  * $maxdopValue: Set this to the recommended value for the specific server

```powershell
[int]$maxdopValue = 4
Set-DbaSpConfigure -Name MaxDegreeOfParallelism -Value $maxdopValue -SqlInstance $(hostname)
```

### Cost Threshold for Parallelism

The optimizer uses that cost threshold to figure out when it should start evaluating plans 
that can use multiple threads. A good starting point is to set this to between 50 and 75.

```powershell
Set-DbaSpConfigure -Name CostThresholdForParallelism -Value 50 -SqlInstance $(hostname)
```

### Max Memory

This can be tweaked and is more of a suggestion but default setting is not recommended.

If you’re using SQL Server Integration Services, Analysis Services, Reporting Services, 
or any other applications on this server, you may need to lower max memory even 
farther. 

```powershell
Set-DbaMaxMemory -SqlInstance $(hostname)
```

### Enable Agent XPs

```powershell
Set-DbaSpConfigure -Name AgentXPsEnabled -Value 1 -SqlInstance $(hostname)
```

### Enable Default Backup Compression

If we enable Backup Compression as default the backup files will be smaller in size, but the CPU cost will be marginally larger during the time of the backup job.

```powershell
Set-DbaSpConfigure -Name 'DefaultBackupCompression' -Value 1 -SqlInstance $(hostname)
```

### Enable Remote Dedicated Admin Connection

```powershell
Set-DbaSpConfigure -Name 'RemoteDacConnectionsEnabled' -Value 1 -SqlInstance $(hostname)
```

### Enable Database Mail

This is used when sending mail from SQL Server.

```powershell
Set-DbaSpConfigure -Name DatabaseMailEnabled -Value 1 -SqlInstance $(hostname)
```

### Configure Model Database

The Model database should be configured to 256MB for data files and 128MB for log files. This is a soft recommendation and can change depending on system, but this is better than the default.

```powershell
$sql = @" 
USE [master]
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', SIZE = 512000KB , FILEGROWTH = 262144KB )
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modellog', SIZE = 256000KB , FILEGROWTH = 131072KB )
GO
"@
Invoke-DbaQuery -Database model -Query $sql -SqlInstance $(hostname)
```

### SQLTools database

This database will contain our tools and scripts, including Ola Hallengrens Maintenance Solutions.

```powershell
New-DbaDatabase  -Name SQLTools -SqlInstance $(hostname)
```

#### Installs or updates the First Responder Kit stored procedures.
[Link](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/tree/master)

```Powershell
Install-DbaFirstResponderKit -Force -Database SQLTools -SqlInstance $(hostname) -Verbose
```

#### Automatically installs or updates sp_WhoisActive by Adam Machanic.
```Powershell
Install-DbaWhoIsActive -Database SQLTools -SqlInstance $(hostname)
```

## SQL Server Agent

### Increase Job History Max Rows and Max Rows per Job

```powershell
$sql = @"
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=5000,
		@jobhistory_max_rows_per_job=200
GO
"@
Invoke-DbaQuery -Database msdb -Query $sql -SqlInstance $(hostname)
```

### New Dba Operator

```powershell
$sql = @"
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'Dba',
		@enabled=1,
		@pager_days=0,
		@email_address=N'mail@domain.com'
GO
"@

Invoke-DbaQuery -Database msdb -Query $sql -SqlInstance $(hostname)
````
