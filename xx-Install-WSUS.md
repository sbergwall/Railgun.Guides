# Windows Server Update Services (WSUS) Installation Guide

> **Version Information**:  
> - Documentation based on Windows Server 2022/2019
> - Last Updated: July 3, 2025

This guide provides step-by-step instructions for installing and configuring Windows Server Update Services (WSUS) in an enterprise environment.

## Prerequisites
- Windows Server 2019 or 2022 (with latest updates)
- Administrative privileges on the server
- Sufficient disk space for update storage (recommend at least 100GB)
- Static IP address and DNS registration
- Membership in the domain (recommended)

## 1. Install WSUS Role

Open PowerShell as Administrator and run:

```powershell
Install-WindowsFeature -Name UpdateServices,UpdateServices-UI -IncludeManagementTools
```

## 2. Post-Install Tasks

Run the WSUS post-installation tasks (replace D:\WSUS with your storage path):

```powershell
& "C:\Program Files\Update Services\Tools\wsusutil.exe" postinstall CONTENT_DIR=D:\WSUS
```

## 3. Initial Configuration

1. Open **Windows Server Update Services** from the Start menu.
2. Complete the configuration wizard:
   - Choose update storage location
   - Select languages and products
   - Choose classifications (Critical, Security, etc.)
   - Set synchronization schedule
   - Configure upstream server (if using a hierarchy)

## 4. Configure Group Policy

To direct clients to your WSUS server, create or edit a GPO:

- **Path:** Computer Configuration > Policies > Administrative Templates > Windows Components > Windows Update
- **Settings to configure:**
  - **Specify intranet Microsoft update service location:**
    - Set both URLs to `http://wsusserver.domain.local:8530`
  - **Configure Automatic Updates:**
    - Set to your preferred schedule (e.g., auto download and schedule install)

## 5. Policy Update

If needed, run the following on member servers:

```powershell
gpupdate /force
```

Verify with:

```powershell
gpresult /r
```

## 6. Maintenance Recommendations

- Regularly approve and decline updates
- Run the WSUS Cleanup Wizard monthly
- Monitor disk space and database health
- Back up the WSUS database and content

## References

- [Plan your WSUS deployment](https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/plan/plan-your-wsus-deployment)
- [Install the WSUS server role](https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/1-install-the-wsus-server-role?tabs=powershell)
- [WSUS Best Practices](https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/best-practices-wsus)
- [WSUS YouTube Guide](https://www.youtube.com/watch?v=VTCzszyiFz4&list=PLRo_KKs_U-nMdcYRZDnQIVcf1mBc2if7d&index=2)