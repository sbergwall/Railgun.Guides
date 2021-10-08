$vmName = "DB03"

$path = "D:\Hyper-V\Configurations\martin.org"
$vmSwith = "Internet"
$isoPath = "F:\Hyper-V\ISO\New MSDN Isos\en_windows_server_2019_x64_dvd_4cb967d8.iso"

try {
    New-VM -Name $vmName -MemoryStartupBytes 2048MB -Path $path -NewVHDPath "$path\$vmname\$($vmname).vhdx" -NewVHDSizeBytes 40GB -Generation 2 -SwitchName $vmSwith
    Set-VMProcessor -VMName $vmName -Count 2
    Add-VMDVDDrive -VMName $vmName -Path $isoPath

    $vmDVD = Get-VmDvdDrive -VMName $vmName
    $vmHDD = Get-VmHardDiskDrive -VMName $vmName
    Set-VMFirmware -VMName $vmName -BootOrder $vmDVD, $vmHDD
}
catch {
    Write-Error -Message $_.Exception.Message
}

# Add additional disks to DB servers
New-VHD -Path "$path\$vmName\$($vmname)_data.vhdx" -SizeBytes 20GB -Fixed 
add-vmharddiskdrive -vmname $vmName -path "$path\$vmname\$($vmname)_data.vhdx"

New-VHD -Path "$path\$vmname\$($vmname)_log.vhdx" -SizeBytes 11GB -Fixed 
add-vmharddiskdrive -vmname $vmName -path "$path\$vmname\$($vmname)_log.vhdx" 

New-VHD -Path "$path\$vmname\$($vmname)_tempdb.vhdx" -SizeBytes 10GB -Fixed 
add-vmharddiskdrive -vmname $vmName -path "$path\$vmname\$($vmname)_tempdb.vhdx" 

New-VHD -Path "$path\$vmname\$($vmname)_program.vhdx" -SizeBytes 13GB -Fixed 
add-vmharddiskdrive -vmname $vmName -path "$path\$vmname\$($vmname)_program.vhdx" 

New-VHD -Path "$path\$vmname\$($vmname)_Backups.vhdx" -SizeBytes 14GB -Fixed 
add-vmharddiskdrive -vmname $vmName -path "$path\$vmname\$($vmname)_Backups.vhdx" 

$newIP = "192.168.2.22"
$defaultGateway = "192.168.2.1"
$InterfaceIndex = "4"
$clientName = "DB03"
$dnsServerIP = "192.168.2.10"
$domainName = "modc.se"

Get-NetIPAddress -AddressFamily IPv4
New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $newIP -PrefixLength 24 -DefaultGateway $defaultGateway
Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses ($dnsServerIP,"8.8.8.8")

Rename-Computer $clientName -Restart
add-computer –domainname $domainName  -restart
