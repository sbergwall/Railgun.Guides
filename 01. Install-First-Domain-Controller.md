# Installing the First Domain Controller

This guide explains the process of setting up the first Domain Controller in a new Active Directory forest, following Microsoft's security best practices and tiered administrative model.

## Prerequisites
- Windows Server 2016 or later
- Static IP address configuration
- Internet connectivity for initial setup
- Server hardware meeting [Microsoft's system requirements](https://learn.microsoft.com/en-us/windows-server/get-started/hardware-requirements)
- Administrator access to the server

The script performs the following key steps:

## 1. Network Configuration
```powershell
$newIP = "192.168.2.10"
$defaultGateway = "192.168.2.1"
$InterfaceIndex = "4"

Get-NetIPAddress -AddressFamily IPv4
New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $newIP -PrefixLength 24 -DefaultGateway $defaultGateway
Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses ($newIP,"8.8.8.8")
```
Sets up static IP addressing and DNS configuration, which is required for a Domain Controller.

## 2. Computer Rename
```powershell
Rename-Computer DC01 -Restart
```
Renames the server to DC01 and restarts it to apply the change.

## 3. Active Directory Installation
```powershell
$domainName = "modc.se"
$DomainNetbiosName = "modc"

Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName $domainName -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "7" -DomainNetbiosName $DomainNetbiosName -ForestMode "7" -InstallDns:$true -LogPath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL"
```

These commands perform two critical steps in setting up a Domain Controller:

1. `Install-windowsfeature` installs the Active Directory Domain Services role and its management tools:
   - Adds the core AD DS server role
   - Installs all necessary PowerShell modules and GUI tools for managing AD

2. `Install-ADDSForest` promotes the server to a Domain Controller and creates a new forest:
   - Creates a new forest named "modc.se" with NetBIOS name "modc"
   - Sets up the AD database and log files in "C:\Windows\NTDS"
   - Configures Domain and Forest functional level to "7" (Windows Server 2016)
   - Installs and configures DNS automatically (`InstallDns:$true`)
   - Creates SYSVOL share at "C:\Windows\SYSVOL" for Group Policy and script storage
   - Skips DNS delegation (`CreateDnsDelegation:$false`) as this is the first DC

During this process, you'll be prompted to enter a Directory Services Restore Mode (DSRM) password, which is crucial for AD recovery scenarios.

## 4. Organizational Unit (OU) Structure

The OU structure implements the Microsoft Privileged Access Model, which uses a tiered administration approach to protect privileged credentials. This model helps prevent lateral movement and privilege escalation by attackers.

### Tier Model Overview:
- **Tier 0**: Contains the most privileged assets (Domain Controllers, domain admins)
- **Tier 1**: Contains server administrators and sensitive servers
- **Tier 2**: Contains helpdesk staff and user workstations

> **Reference**: For detailed information about the tiered model, see [Microsoft's Securing Privileged Access Documentation](https://learn.microsoft.com/en-us/security/privileged-access-workstations/privileged-access-deployment)

```powershell
$Path = "DC=modc,DC=se"
New-ADOrganizationalUnit "modc" –path "$path"

# OU Users
New-ADOrganizationalUnit "Users" –path "OU=modc,$path"
New-ADOrganizationalUnit "Employees" –path "OU=users,OU=modc,$path" -Description "Will hold all Employee accounts."
New-ADOrganizationalUnit "ServiceAccount" –path "OU=users,OU=modc,$path" -Description "Will hold all service accounts, and special use accounts"
New-ADOrganizationalUnit "Disabled-Users" –path "OU=users,OU=modc,$path" -Description "Will hold all disabled user accounts"
New-ADOrganizationalUnit "PAW Account" –path "OU=users,OU=modc,$path"
New-ADOrganizationalUnit "Tier 0" –path "OU=PAW Account,OU=users,OU=modc,$path" -Description "Will hold Tier 0 user accounts (for domain admins)"
New-ADOrganizationalUnit "Tier 1" –path "OU=PAW Account,OU=users,OU=modc,$path" -Description "Will hold Tier 1 user accounts (for server admins)"
New-ADOrganizationalUnit "Tier 2" –path "OU=PAW Account,OU=users,OU=modc,$path" -Description "Will hold Tier 2 user accounts (for helpdesk admins)"
```

This OU structure enforces security boundaries by:
1. Separating regular user accounts from administrative accounts
2. Isolating high-privilege accounts (Tier 0) from lower-privilege accounts
3. Creating dedicated OUs for service accounts and disabled users
4. Enabling targeted Group Policy application based on administrative tiers

## 5. Computer Organization Structure

Similar to the user account structure, computer accounts are organized in a tiered model to enforce security boundaries and enable specific policy application:

- **Workstations**: Standard user computers
- **PAW**: Privileged Access Workstations for administrative tasks
- **Servers**: 
  - Tier 0: Critical security infrastructure (excluding DCs, which are protected by default)
  - Tier 1: Member servers with standard business applications

```powershell
# OU Computers
New-ADOrganizationalUnit "Computers" –path "OU=modc,$path"
New-ADOrganizationalUnit "Workstations" –path "OU=Computers,OU=modc,$path" -Description "Will hold all Computer accounts."
New-ADOrganizationalUnit "PAW" –path "OU=Computers,OU=modc,$path"
New-ADOrganizationalUnit "Servers" –path "OU=Computers,OU=modc,$path" -Description "Will hold all disabled computer accounts"
New-ADOrganizationalUnit "Tier 0" –path "OU=Servers,OU=Computers,OU=modc,$path" -Description "Will hold Tier 0 servers (but not DCs!)"
New-ADOrganizationalUnit "Tier 1" –path "OU=Servers,OU=Computers,OU=modc,$path" -Description "Will hold Tier 1 servers (most member servers)"
```

This structure enables:
- Separate Group Policy application for each tier
- Controlled delegation of administrative access
- Clear separation between standard workstations and PAWs

## 6. Domain Admin Creation

Creating Domain Admin accounts is a critical security operation. These accounts:
- Must be strictly controlled and monitored
- Should only be used from dedicated Privileged Access Workstations (PAWs)
- Should follow the principle of least privilege
- Must have strong passwords and MFA where possible

```powershell
$domainAdmins = "siber-da","maols-da"
$password =  ConvertTo-SecureString "ChooseYourPW!" -AsPlainText -Force

foreach ($da in $domainAdmins) {
    New-ADUser -Name $da -AccountPassword $password -SamAccountName $da -DisplayName $da -Enabled $true -PasswordNeverExpires $true -Path "OU=Tier 0,OU=PAW Account,OU=Users,OU=modc,DC=modc,DC=se" -UserPrincipalName ("$da" + "@" + $env:USERDNSDOMAIN)
    Add-ADGroupMember -Identity "Domain Admins" -Members $da
}
```

> **Important Security Notes**: 
> - Change all default passwords immediately and store them securely in your password management system
> - Consider implementing Smart Card authentication for these accounts
> - Set up auditing and alerting for Domain Admin account usage
> - Create separate standard user accounts for daily tasks
