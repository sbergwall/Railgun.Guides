$newIP = "192.168.2.10"
$defaultGateway = "192.168.2.1"
$InterfaceIndex = "4"

Get-NetIPAddress -AddressFamily IPv4
New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $newIP -PrefixLength 24 -DefaultGateway $defaultGateway
Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses ($newIP,"8.8.8.8")

Rename-Computer DC01 -Restart

$domainName = "modc.se"
$DomainNetbiosName = "modc"

Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName $domainName -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "7" -DomainNetbiosName $DomainNetbiosName -ForestMode "7" -InstallDns:$true -LogPath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL"

Safe Mode Admin Pass: EnLitenRosaKanin123!

A delegation for this DNS server cannot be created because the authoritative parent zone cannot be found or it does not run Windows DNS server. If you are integrating with an existing DNS infrastructure, you should manually create a delegation to this DNS server in the parent zone to ensure reliable name resolution from outside the domain "martin.org". Otherwise, no action is required.

$Path = "DC=modc,DC=se"
New-ADOrganizationalUnit "modc" –path "$path"

# OU Users
New-ADOrganizationalUnit "Users" –path "OU=modc,$path"
New-ADOrganizationalUnit "Employees" –path "OU=users,OU=modc,$path" -Description "Will hold all Employee accounts."
New-ADOrganizationalUnit "ServiceAccount" –path "OU=users,OU=modc,$path" -Description "Will hold all service accounts, and special use accounts (like accounts that run scheduled tasks)"
New-ADOrganizationalUnit "Disabled-Users" –path "OU=users,OU=modc,$path" -Description "Will hold all disabled user accounts"
New-ADOrganizationalUnit "PAW Account" –path "OU=users,OU=modc,$path"
New-ADOrganizationalUnit "Tier 0" –path "OU=PAW Account,OU=users,OU=modc,$path" -Description "Will hold Tier 0 user accounts (for domain admins)"
New-ADOrganizationalUnit "Tier 1" –path "OU=PAW Account,OU=users,OU=modc,$path" -Description "Will hold Tier 1 user accounts (for server admins)"
New-ADOrganizationalUnit "Tier 2" –path "OU=PAW Account,OU=users,OU=modc,$path" -Description "Will hold Tier 2 user accounts (for helpdesk admins)"

# OU Computers
New-ADOrganizationalUnit "Computers" –path "OU=modc,$path"
New-ADOrganizationalUnit "Workstations" –path "OU=Computers,OU=modc,$path" -Description "Will hold all Computer accounts."
New-ADOrganizationalUnit "PAW" –path "OU=Computers,OU=modc,$path"
New-ADOrganizationalUnit "Servers" –path "OU=Computers,OU=modc,$path" -Description "Will hold all disabled computer accounts"
New-ADOrganizationalUnit "Tier 0" –path "OU=Servers,OU=Computers,OU=modc,$path" -Description "Will hold Tier 0 servers (but not DCs!)"
New-ADOrganizationalUnit "Tier 1" –path "OU=Servers,OU=Computers,OU=modc,$path" -Description "Will hold Tier 1 servers (most member servers)"

# Create Domain Admin Users
$domainAdmins = "siber-da","maols-da"
$password =  ConvertTo-SecureString "ChooseYourPW!" -AsPlainText -Force

foreach ($da in $domainAdmins) {
    New-ADUser -Name $da -AccountPassword $password -SamAccountName $da -DisplayName $da -Enabled $true -PasswordNeverExpires $true -Path "OU=Tier 0,OU=PAW Account,OU=Users,OU=modc,DC=modc,DC=se" -UserPrincipalName ("$da" + "@" + $env:USERDNSDOMAIN)
    Add-ADGroupMember -Identity "Domain Admins" -Members $da
}