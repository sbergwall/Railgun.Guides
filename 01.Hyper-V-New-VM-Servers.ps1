$vmName = "DC01","WAC01","DB01","DB02"

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