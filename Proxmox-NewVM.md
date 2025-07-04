$credential = Get-Credential
$connection = Connect-ProxmoxServer -Server "192.168.1.50" -Credential $credential -Realm "pam" -SkipCertificateValidation 

New-ProxmoxVM -Name "dc1" -Connection $connection -Node "proxmox01" -Memory 2048 -Cores 2 -DiskSize 60 -Storage "hpe_ssd" -NetworkModel "virtio" -NetworkBridge "vmbr0" 
New-ProxmoxVM -Name "wsus1" -Connection $connection -Node "proxmox01" -Memory 4096 -Cores 4 -DiskSize 150 -Storage "hpe_ssd" -NetworkModel "virtio" -NetworkBridge "vmbr0" 
New-ProxmoxVM -Name "wac1" -Connection $connection -Node "proxmox01" -Memory 4096 -Cores 4 -DiskSize 60 -Storage "hpe_ssd" -NetworkModel "virtio" -NetworkBridge "vmbr0" 
New-ProxmoxVM -Name "wec1" -Connection $connection -Node "proxmox01" -Memory 4096 -Cores 4 -DiskSize 100 -Storage "hpe_ssd" -NetworkModel "virtio" -NetworkBridge "vmbr0" 
New-ProxmoxVM -Name "win11" -Connection $connection -Node "proxmox01" -Memory 6144 -Cores 4 -DiskSize 100 -Storage "hpe_ssd" -NetworkModel "virtio" -NetworkBridge "vmbr0" 
