====== Configure Availability Group ======

How to create the virtual machine for SQL Server is specified here https://wikit.ltblekinge.org/installation_sql

How to install and configure SQL Server is specified here https://wikit.ltblekinge.org/sql_server/install_single_node

This guide provides steps how to install and configure a SQL Server Availability Group right after the guide for creating the VM and installing SQL Server are done.

===== Before you begin =====

  * Permissions in Active Directory is needed for manage the cluster node object or permission to create the object if the object is not created beforehand.
  * Permission in DNS to create the A record if this is not done beforehand.
  * Permission to create a file share witness if this is not done beforehand.


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

===== Create Failover Cluster =====

**Cluster Feature**

This needs to be ran on both servers. A restart is required after installation is completed.

<code powershell>
Install-WindowsFeature -Name failover-clustering -IncludeManagementTools -Verbose
Install-WindowsFeature -Name NET-Framework-Core -IncludeManagementTools -verbose
</code>

The rest of the Create Failover Cluster scripts only needs to be ran from one server.

**DNS**

If DNS is not prepared we can create the A record by hand. This needs to be done on a client with the DNS tools installed.

Variables that needs to be changed

  * $clustername: Name of Windows Failover Cluster
  * $clusterIPAddress: IP address of Windows Failover Cluster
  * $agName: Name of the Availability Group
  * $agIPAddress: IP of the Availability Group
  * $zoneName: Name of the DNS zone

<code powershell>
$clustername = 'testnetdbcl01'
$clusterIPAddress = '10.61.42.136'

$agName = 'testnetag01'
$agIPAddress = '10.61.42.135'

$zoneName = "test.net.ad" 

Add-DnsServerResourceRecordA -Name $clustername -IPv4Address $clusterIPAddress -ZoneName $zoneName
Add-DnsServerResourceRecordA -Name $agName -IPv4Address $agIPAddress -ZoneName $zoneName
</code>

**File Share Witness**

If a file share witness is not created before hand we can do that like this. The scripts need to be run from the file share server.

Variables that needs to be changed

  * $shareName: File share name
  * $Path: The local path to the new directory

<code powershell>
$shareName = "testnetag01"
$Path = "C:\Witness\testnetag01"

New-Item -Path $Path -Type Directory
New-SMBShare –Name $shareName –Path $Path –FullAccess Administrators -ReadAccess Users
</code>


**Create Failover Cluster**

Variables that needs to be changed

  * $server1: Name of the first node
  * $server2: Name of the second node
  * $clusterIPAddress: IP address of Windows Failover Cluster
  * $clustername: Name of the cluster
  * $fileshare: UNC path to the smb file share witness


<code powershell>
$server1 = 'testnetdb01'
$server2 = 'testnetdb02'
$clusterIPAddress = '10.61.42.136'
$clustername = 'testnetdbcl01'
$fileshare = '\\testnetquorum\testnetag01'

New-Cluster -Name $clustername -Node $server1, $server2 -StaticAddress $clusterIPAddress -NoStorage -Verbose

Set-ClusterQuorum -FileShareWitness $fileshare -Cluster $clustername -Verbose
</code>


**Create Availability Group**

Variables that needs to be changed

  * $primaryNode = "testnetdb01"
  * $secondaryNode = "testnetdb02"
  * $agName = "testnetag01"
  * $sharedPath = ""
  * $tempDbName = "ag_temp"
  * $IPAddress = "10.61.42.135"

<code powershell>
$primaryNode = "testnetdb01"
$secondaryNode = "testnetdb02"
$agName = "testnetag01"
$sharedPath = "\\testnetquorum\testnetag01"
$tempDbName = "ag_temp"
$IPAddress = "10.61.42.135"

Enable-DbaAgHadr -SqlInstance $primaryNode -Force | Format-Table 
Enable-DbaAgHadr -SqlInstance $secondaryNode -Force | Format-Table 

New-DbaDatabase -Name $tempDbName -SqlInstance $primaryNode -RecoveryModel Full
New-DbaAvailabilityGroup -Primary $primaryNode -Secondary $secondaryNode -Name $agName -ClusterType Wsfc -SharedPath $sharedPath -Database $ag_temp -ConfigureXESession -IPAddress $IPAddress
</code>