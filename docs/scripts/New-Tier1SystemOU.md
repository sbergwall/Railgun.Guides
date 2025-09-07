```powershell
function New-Tier1SystemOU {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the new system (e.g., 'Exchange', 'SCCM').")]
        [string]$SystemName
    )

    # Requires the Active Directory module for Windows PowerShell
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue

    # Define the base paths
    $domain = (Get-ADDomain).distinguishedName
    $functionBaseOU = "OU=Function,OU=Tier1,OU=Admin,$domain"
    
    # Define the final nested OUs for each system
    $nestedOUs = 'Accounts', 'Groups', 'Servers', 'ServiceAccounts'

    Write-Host "Creating OU structure for '$SystemName'..."

    # Create the top-level OU for the new system under 'Function'
    $systemOUPath = "OU=$SystemName,$functionBaseOU"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$SystemName'" -SearchBase $functionBaseOU -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $SystemName -Path $functionBaseOU
        Write-Host "Created OU: $SystemName"
    }
    else {
        Write-Host "OU '$SystemName' already exists. Skipping creation."
    }

    # Loop through and create the nested OUs for the new system
    foreach ($nestedOU in $nestedOUs) {
        $nestedOUPath = "OU=$nestedOU,$systemOUPath"
        
        # Check if the nested OU already exists
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$nestedOU'" -SearchBase $systemOUPath -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $nestedOU -Path $systemOUPath
            Write-Host "Created OU: $nestedOU under $SystemName"
        }
        else {
            Write-Host "OU '$nestedOU' under '$SystemName' already exists. Skipping creation."
        }
    }
    
    Write-Host "Finished creating OU structure for '$SystemName'."
}
```