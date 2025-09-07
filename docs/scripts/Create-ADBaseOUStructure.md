```powershell
# Requires the Active Directory module for Windows PowerShell
Import-Module ActiveDirectory

# Define the domain and base OU
$domain = (Get-ADDomain).distinguishedName
$baseOU = "OU=Admin,$domain"
$tier1OU = "OU=Tier1,$baseOU"
$functionOU = "OU=Function,$tier1OU"

# Define the sub-OUs for 'Function'
$functionSubOUs = 'WSUS', 'WEC', 'WAC', 'SCOM', 'SPSE', 'MSSQL'

# Define the final nested OUs for each sub-OU
$nestedOUs = 'Accounts', 'Groups', 'Servers', 'ServiceAccounts'

# Check and create the base Admin OU
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Admin'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name 'Admin' -Path $domain
    Write-Host 'Created OU: Admin'
}
else {
    Write-Host "OU 'Admin' already exists. Skipping creation."
}

# Check and create the Tier1 OU under Admin
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Tier1'" -SearchBase $baseOU -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name 'Tier1' -Path $baseOU
    Write-Host 'Created OU: Tier1'
}
else {
    Write-Host "OU 'Tier1' already exists. Skipping creation."
}

# Check and create the Function OU under Tier1
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Function'" -SearchBase $tier1OU -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name 'Function' -Path $tier1OU
    Write-Host 'Created OU: Function'
}
else {
    Write-Host "OU 'Function' already exists. Skipping creation."
}

# Loop through each function and create the sub-OUs
foreach ($function in $functionSubOUs) {
    $functionPath = "OU=$function,$functionOU"
    
    # Check if the function OU already exists
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$function'" -SearchBase $functionOU -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $function -Path $functionOU
        Write-Host "Created OU: $function under Function"
    }
    else {
        Write-Host "OU '$function' under 'Function' already exists. Skipping creation."
    }

    # Loop through each nested OU and create it under the function OU
    foreach ($nestedOU in $nestedOUs) {
        $nestedPath = "OU=$nestedOU,$functionPath"

        # Check if the nested OU already exists
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$nestedOU'" -SearchBase $functionPath -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $nestedOU -Path $functionPath
            Write-Host "Created OU: $nestedOU under $function"
        }
        else {
            Write-Host "OU '$nestedOU' under '$function' already exists. Skipping creation."
        }
    }
}

Write-Host 'Script execution complete.'
```