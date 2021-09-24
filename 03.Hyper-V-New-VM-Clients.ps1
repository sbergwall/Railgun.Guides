$vmName = "Client01"

$path = "D:\Hyper-V\Configurations\martin.org"
$vmSwith = "Internet"
$isoPath = "F:\Hyper-V\ISO\New MSDN Isos\sv_windows_10_business_editions_version_1809_updated_sept_2019_x64_dvd_b76772ba.iso"

try {
    $ErrorActionPreference = "Stop"
    New-VM -Name $vmName -MemoryStartupBytes 6144MB -Path $path -NewVHDPath "$path\$vmname\$($vmname).vhdx" -NewVHDSizeBytes 60GB -Generation 2 -SwitchName $vmSwith
    Set-VMProcessor -VMName $vmName -Count 4
    Add-VMDVDDrive -VMName $vmName -Path $isoPath

    $vmDVD = Get-VmDvdDrive -VMName $vmName
    $vmHDD =Get-VmHardDiskDrive -VMName $vmName
    Set-VMFirmware -VMName $vmName -BootOrder $vmDVD,$vmHDD
}
catch {
    Write-Error -Message $_.Exception.Message
}