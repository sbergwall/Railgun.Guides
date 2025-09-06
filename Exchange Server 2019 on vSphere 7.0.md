https://www.vmware.com/content/dam/digitalmarketing/vmware/en/pdf/solutions/business-critical-apps/exchange/vmw-microsoft-exchange-server-2019-on-vmware-best-practices.pdf

VMware uses the terms virtual CPU (vCPU) and physical CPU (pCPU) to distinguish between the processors within the VM and the underlying physical processor cores.

# CPU Configuration Guidelines

Configuration Item | Maximum Supported      
Memory Per Exchange Server Instance | 256 GB      
Number of CPUs per Exchange Server Instance | 2 Sockets     

 * Exchange Server (as an application) is unaware of NUMA optimization, VMware still recommends sizing a VM with the physical NUMA topology in mind.
 * The total number of vCPUs assigned to all the VMs be no more than the total number of physical cores on the ESXi host machine, not hyper-threaded cores.

VMware now recommends that, when presenting vCPUs to a VM, customers should allocate the vCPUs in accordance with the PHYSICAL NUMA topology of the underlying ESXi Host. Customers should consult their hardware vendors (or the appropriate documentation) to determine the number of sockets and cores physically present in the server hardware and use that knowledge as operating guidance for VM CPU allocation. The recommendation to present all vCPUs to a VM as “sockets” is no longer valid in modern vSphere/ESXi versions.

Where the number of vCPUs intended for a VM is not greater than the number of cores present in one physical socket, all of the vCPUs so allocated should come from one socket. Conversely, if a VM requires more vCPUs than are physically available in one physical socket, the desired number of vCPUs should be evenly divided between two sockets.

While VMs using vNUMA may benefit from this option, the recommendation for these VMs is to use virtual sockets (CPUs in the web client). Exchange Server 2019 is not a NUMA-aware application and performance tests have shown no significant performance improvements by enabling vNUMA. However, Windows Server 2019 OS is NUMA-aware and Exchange Server 2019 (as an application) does not experience any performance, reliability, or stability issues attributable to vNUMA.

 * Consider sizing Exchange Server 2019 VMs to fit within the size of the physical NUMA node for best performance.
 * Enabling CPU hot add for a VM on vSphere disables vNUMA for the VM. As Exchange Server does not benefit from either vNUMA or CPU hot add, VMware recommends that CPU hot add for an Exchange Server 2019 VM should not be enabled.


# Windows Server 2019 WSFC Thresholds

Verify that WSFC settings are as specified below:

```
PS> Get-Cluster | fl *subnet*,*history*

CrossSubnetDelay          : 1000
CrossSubnetThreshold      : 20
PlumbAllCrossSubnetRoutes : 0
SameSubnetDelay           : 1000
SameSubnetThreshold       : 20
RouteHistoryLength        : 40
```

