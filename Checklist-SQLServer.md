# SQL Server

- [SQL Server](#sql-server)
      - [NTFS allocation unit size](#ntfs-allocation-unit-size)
  * [Server](#server)
      - [Power Plan should be High Performance](#power-plan-should-be-high-performance)
      - [Enable Instant File Initialization](#enable-instant-file-initialization)
  * [Instance](#instance)
      - [Verify TCP/IP in enabled](#verify-tcp-ip-in-enabled)
      - [Enable Database Mail](#enable-database-mail)
      - [Enable Agent XPs](#enable-agent-xps)
      - [Enable Default Backup Compression](#enable-default-backup-compression)
      - [Enable Remote Dedicated Admin Connection](#enable-remote-dedicated-admin-connection)
      - [Set Max Degree of parallelism](#set-max-degree-of-parallelism)
      - [Set Cost Threshold for parallelism](#set-cost-threshold-for-parallelism)
      - [TempDB](#tempdb)
      - [Max Memory](#max-memory)
      - [Model Database](#model-database)
      - [SQLTools database](#sqltools-database)
  * [Database](#database)
      - [TO DO](#to-do-1)
      - [Checksum, AutoShrink and AutoClose](#checksum--autoshrink-and-autoclose)
  * [SQL Server Agent](#sql-server-agent)
      - [Install Ola Hallengren Maintenence Solutions](#install-ola-hallengren-maintenence-solutions)
        * [Backup, Index Maintenance and Integrity Check Jobs Schedules](#backup--index-maintenance-and-integrity-check-jobs-schedules)
        * [New Optimization Query](#new-optimization-query)
      - [Schedules, OwnerLoginName and OperatorToEmail](#schedules--ownerloginname-and-operatortoemail)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

[[_TOC_]]

## Server

#### NTFS Allocation Unit Size

Before installing SQL Server on a server, when formatting the data disk, it is recommended that you use a 64-KB allocation unit size for data and log files as well as TempDB. If TempDB is placed on the temporary disk (D:\ drive) the performance gained by leveraging this drive outweighs the need for a 64K allocation unit size.

```powershell
Get-Volume  | Format-List AllocationUnitSize, FileSystemLabel

AllocationUnitSize : 65536
FileSystemLabel    : Data
```

#### Power Plan should be High Performance

[Link](https://www.brentozar.com/archive/2010/10/sql-server-on-powersaving-cpus-not-so-fast/)

This setting also needs to be verified in BIOS and on the Hypervisor if we are running on a VM.

```powershell
Set-DbaPowerPlan -PowerPlan 'High Performance'
```

#### Enable Instant File Initialization

  [Link](https://www.brentozar.com/archive/2013/07/will-instant-file-initialization-really-help-my-databases/)

  Grant the 'Perform Volume Maintenance Tasks' right to the account that will be used for the SQL Server service (the engine, not the agent). This setting can be configured by Group Policy or any other Config.Mgmt system so verify this before continuing.

```powershell
(Get-DbaPrivilege).where({$_.InstantFileInitialization})

ComputerName              : EKUTB4
User                      : BUILTIN\Administrators
LogonAsBatch              : True
InstantFileInitialization : True
LockPagesInMemory         : False
GenerateSecurityAudit     : False
```

If the service account is not seen in the above query you can run (as long as GP/CM systems are not configuring this).

```powershell
Set-DbaPrivilege -ComputerName localhost -Type IFI
```

## Instance

#### Verify TCP/IP in enabled

If this is not enabled you might not be able to connect to the instance

```powershell
Get-DbaTcpPort

ComputerName : SP01SQL02TST
InstanceName : MSSQLSERVER
SqlInstance  : SP01SQL02TST
IPAddress    : fe80::6839:a8c2:3a6c:71ff%6
Port         : 1433
```

#### Enable Database Mail

This is used when sending mail from SQL Server.

```powershell
Set-DbaSpConfigure -Name DatabaseMailEnabled -Value 1
```

#### Enable Agent XPs

```powershell
Set-DbaSpConfigure -Name AgentXPsEnabled -Value 1
```

#### Enable Default Backup Compression

If we enable Backup Compression as default the backup files will be smaller in size, but the CPU cost will be marginally larger during the time of the backup job.

```powershell
Set-DbaSpConfigure -Name 'DefaultBackupCompression' -Value 1
```

#### Enable Remote Dedicated Admin Connection

[Link](https://www.brentozar.com/blitz/remote-dedicated-admin-connection/)

```powershell
Set-DbaSpConfigure -Name 'RemoteDacConnectionsEnabled' -Value 1
```

#### Set Max Degree of parallelism

The Microsoft SQL Server max degree of parallelism (MAXDOP) configuration option controls the number of processors that are used for the execution of a query in a parallel plan. This option determines the number of threads that are used for the query plan operators that perform the work in parallel. [Link](https://support.microsoft.com/en-gb/help/2806535/recommendations-and-guidelines-for-the-max-degree-of-parallelism-confi)

Recommendations from supplier is also needed. For example SharePoint only work with MaxDOP = 1, meaning no opertions will work in parallel. Usually 2 or 4 is good enough.

```powershell
Set-DbaSpConfigure -Name MaxDegreeOfParallelism -Value 2
```

#### Set Cost Threshold for parallelism

The recommendation is to start with between 50 and 75, the default value of 5 is usually to low.

```powershell
Set-DbaSpConfigure -Name CostThresholdForParallelism -Value 50
```

#### Create a Mail Account

```powershell
New-DbaDbMailAccount -Name $(hostname) -DisplayName $(hostname) -EmailAddress noreply@<YourDomain> -MailServer <YourSMTPServer> -Force

ComputerName   : VOICE2
InstanceName   : MSSQLSERVER
SqlInstance    : VOICE2
Id             : 2
Name           : Voice2
DisplayName    : Voice2
Description    :
EmailAddress   : noreply@<YourDomain>
ReplyToAddress :
IsBusyAccount  : False
MailServers    : {<YourSMTPServer>}
```

#### Create a Mail Profile
```powershell
New-DbaDbMailProfile -Name "Database Mail Profile"

ComputerName  : VOICE2
InstanceName  : MSSQLSERVER
SqlInstance   : VOICE2
Id            : 1
Name          : Database Mail Profile
Description   :
IsBusyProfile : False
```

#### TempDB

A good enough rule is to create 4 data files with a size of 1000MB each but this can be changed if needed. For more information and a recommendation to create 8 data files read [this](https://www.brentozar.com/blitz/tempdb-data-files/). The comments are also recommended to read.

```powershell
Set-DbaTempDbConfig  -DataFileCount 4 -DataFileSize 4000

ComputerName       : SP01SQL01TST
InstanceName       : MSSQLSERVER
SqlInstance        : SP01SQL01TST
DataFileCount      : 4
DataFileSize       : 3,91 GB
SingleDataFileSize : 1 000,00 MB
LogSize            : 1 000,00 MB
DataPath           : T:\TempDB
LogPath            : T:\TempDB
DataFileGrowth     : 512,00 MB
LogFileGrowth      : 512,00 MB
```

#### Max Memory

This can be tweaked and is more of a suggestion but default setting is not recommended.

```powershell
Set-DbaMaxMemory

ComputerName     : SP01SQL01TST
InstanceName     : MSSQLSERVER
SqlInstance      : SP01SQL01TST
Total            : 16384
MaxValue         : 11264
PreviousMaxValue : 2147483647
```

#### Model Database

The Model database should be configured to 256MB for data files and 128MB for log files. This is a soft recommendation and can change depending on system, but this is better than the default.

#### SQLTools database
This database will contain our tools and scripts, including Ola Hallengrens Maintenance Solutions.

```powershell
New-DbaDatabase  -Name SQLTools

ComputerName       : SP01SQL01TST
InstanceName       : MSSQLSERVER
SqlInstance        : SP01SQL01TST
Name               : SQLTools
Status             : Normal
IsAccessible       : True
RecoveryModel      : Full
LogReuseWaitStatus : Nothing
SizeMB             : 125
Compatibility      : Version140
Collation          : Finnish_Swedish_CI_AS
Owner              : LTBLEKINGE\si2020adm
LastFullBackup     : 0001-01-01 00:00:00
LastDiffBackup     : 0001-01-01 00:00:00
LastLogBackup      : 0001-01-01 00:00:00
```

#### Installs or updates the First Responder Kit stored procedures.
[Link](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/tree/master)

```Powershell
Install-DbaFirstResponderKit -Force -Database SQLTools -Verbose
```

#### Automatically installs or updates sp_WhoisActive by Adam Machanic.
```Powershell
Install-DbaWhoIsActive -Database SQLTools
```

## Database

#### TO DO
* Set autogrowth and initial size settings to a better value than default

#### Checksum, AutoShrink and AutoClose
On all databases, PageVerify should be Checksum, both AutoShrink and AutoClose should be False. If any of the properties is another value please contact supplier and get their recommendation.

```Powershell
Get-DbaDatabase | Select-Object Name,PageVerify,AutoClose,AutoShrink

Name             PageVerify AutoClose AutoShrink
----             ---------- --------- ----------
rd_prod   TornPageDetection      True       True
rd_analys          Checksum     False      False
SQLTools           Checksum     False      False
```


## SQL Server Agent

#### Increase Job History Max Rows and Max Rows per Job

```powershell
$sql = @"
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=5000,
		@jobhistory_max_rows_per_job=200
GO
"@
Invoke-DbaQuery -Database msdb -Query $sql
```

#### New Dba Operator

```powershell
$sql = @"
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'Dba',
		@enabled=1,
		@pager_days=0,
		@email_address=N'<YourMail>'
GO
"@

Invoke-DbaQuery -Database msdb -Query $sql
````

#### Create Alerts
<details><summary>Code</summary>

```powershell
$sql = @"
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 016',
@message_id=0,
@severity=16,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823',
@message_id=823,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 823', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824',
@message_id=824,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 824', @operator_name=N'Dba', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825',
@message_id=825,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 825', @operator_name=N'Dba', @notification_method = 7;
GO
"@

Invoke-DbaQuery -Database msdb -Query $sql
```

</details>

#### Install Ola Hallengren Maintenence Solutions
https://github.com/olahallengren/sql-server-maintenance-solution

CleanupTime is time in hours, after which backup files are deleted. This can be configured later depending on need. We install the Backup, Index Maintenance and Integrity Check jobs. At the moment no schedule or alert is created for the jobs.

```powershell
Install-DbaMaintenanceSolution  -Database SQLTools -CleanupTime '192' -Solution All -InstallJobs -Force -LogToTable
```

##### Backup, Index Maintenance and Integrity Check Jobs Schedules
The agent jobs was installed in the [SQLTools database](#sqltools-database) step but we also need to schedule them.

```powershell
# Set schedule for FULL, DIFF and LOG Backup Jobs
New-DbaAgentSchedule  -Job "DatabaseBackup - SYSTEM_DATABASES - FULL" -Schedule "Daily Full Backup" -FrequencyType "Daily" -FrequencyInterval "EveryDay" -StartTime '043000' -Force

New-DbaAgentSchedule  -Job "DatabaseBackup - USER_DATABASES - FULL" -Schedule "Full Backup" -FrequencyType Weekly -FrequencyInterval "Sunday" -StartTime '050000' -Force

New-DbaAgentSchedule  -Job "DatabaseBackup - USER_DATABASES - DIFF" -Schedule "Diff Backup" -FrequencyType Daily -FrequencyInterval EveryDay -StartTime '050000' -Force
New-DbaAgentSchedule  -Job "DatabaseBackup - USER_DATABASES - LOG" -Schedule "Log Backup" -FrequencySubdayInterval 30 -FrequencySubdayType Minutes -StartTime '050000' -Force

# Set schedule for Weekly SQL Optimization Jobs
New-DbaAgentSchedule  -Job "IndexOptimize - USER_DATABASES" -Schedule "Weekly SQL Optimization" -FrequencyType Weekly -FrequencyInterval "Sunday" -StartTime '060000' -Force

# Set schedule for Weekly SQL Maintenance Jobs
New-DbaAgentSchedule  -Job "DatabaseIntegrityCheck - SYSTEM_DATABASES" -Schedule "Weekly Maintenance" -FrequencyType Weekly -FrequencyInterval "Sunday" -StartTime '070000' -Force
New-DbaAgentSchedule  -Job "DatabaseIntegrityCheck - USER_DATABASES" -Schedule "Weekly Maintenance" -FrequencyType Weekly -FrequencyInterval "Sunday" -StartTime '073000' -Force

# Set schedule for Monthly SQL Maintenance Jobs
New-DbaAgentSchedule  -Job "sp_delete_backuphistory" -Schedule "Monthly Maintenance" -FrequencyType Monthly -FrequencyInterval 1 -StartTime '090000' -Force
New-DbaAgentSchedule  -Job "sp_purge_jobhistory" -Schedule "Monthly Maintenance" -FrequencyType Monthly -FrequencyInterval 1 -StartTime '090500' -Force

New-DbaAgentSchedule  -Job "CommandLog Cleanup" -Schedule "Monthly Maintenance" -FrequencyType Monthly -FrequencyInterval 1 -StartTime '090000' -Force
New-DbaAgentSchedule  -Job "Output File Cleanup" -Schedule "Monthly Maintenance" -FrequencyType Monthly -FrequencyInterval 1 -StartTime '090500' -Force
```

##### New Optimization Query

By default the Optimization job doesn't update statistics. Statistics for query optimization  contain statistical information about the distribution of values in one or more columns of a table or indexed view. The Query Optimizer uses these statistics to estimate the cardinality, or number of rows, in the query result. These cardinality estimates enable the Query Optimizer to create a high-quality query plan and improve performance.

```powershell
Remove-DbaAgentJobStep  -Job "IndexOptimize - USER_DATABASES" -StepName "IndexOptimize - USER_DATABASES"

$OptimizeDB = "EXECUTE dbo.IndexOptimize @Databases = 'USER_DATABASES', @FragmentationLow = NULL, @FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE', @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE', @FragmentationLevel1 = 5, @FragmentationLevel2 = 30, @UpdateStatistics = 'ALL', @OnlyModifiedStatistics = 'Y'"

New-DbaAgentJobStep  -Job "IndexOptimize - USER_DATABASES" -StepID 1 -StepName "IndexOptimize - USER_DATABASES" -Subsystem TransactSql -Command $OptimizeDB -OnSuccessAction QuitWithSuccess -OnFailAction QuitWithFailure
```

#### Test mail config and alerts
Run following T-SQL to raise a test alert and verify that the operators receive an email

```SQL
RAISERROR (N'Test alert!', 20, 1) WITH LOG;
```

#### Schedules, OwnerLoginName and OperatorToEmail

If JobSchedules is empty you need to create a Schedule for that job. The CommandLog Cleanup doesnt have a Schedule so one needs to be created. One exception is if a job is called by a stored procedure, but the Owner of the job should be able to tell if thats the case.

OwnerLoginName should either be a service account or SA account. No personal accounts should be used.

OperatorToEmail & EmailLevel. OperatorToEmail is which Operator to email and should never be empty. EmailLevel is usually "OnFailure" and will email the OperatorToEmail if a job fail.

```powershell
Get-DbaAgentJob  | Select-Object Name,JobSchedules,OperatorToEmail,EmailLevel

Name                                     JobSchedules                          OperatorToEmail EmailLevel
----                                     ------------                          --------------- ----------
Backup System DBs.Backup System DBs      {Backup System DBs.Backup System DBs} Dba              OnFailure
CommandLog Cleanup                       {}                                    Dba              OnFailure
DatabaseBackup - SYSTEM_DATABASES - FULL {Daily Full Backup}                   Dba              OnFailure
DatabaseBackup - USER_DATABASES - DIFF   {Diff Backup}                         Dba              OnFailure
```

If we have jobs without notifications the following script will set dba as the operator and will email if a job fails

```powershell
Get-DbaAgentJob | Where-Object {"" -eq $_.OperatorToEmail} | Set-DbaAgentJob -EmailLevel OnFailure -EventLogLevel OnFailure -EmailOperator 'Dba'

ComputerName           : VOICE2
InstanceName           : MSSQLSERVER
SqlInstance            : VOICE2
Name                   : syspolicy_purge_history
Category               : [Uncategorized (Local)]
OwnerLoginName         : sa
CurrentRunStatus       : Idle
CurrentRunRetryAttempt : 0
Enabled                : True
LastRunDate            : 2020-04-09 02:00:00
LastRunOutcome         : Succeeded
HasSchedule            : True
OperatorToEmail        : Dba
CreateDate             : 2020-02-21 11:05:39
```
