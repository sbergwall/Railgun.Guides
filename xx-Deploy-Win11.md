# Deploy Windows 11

## Winget

```powershell
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
```

```powershell
"Git.Git","mRemoteNG.mRemoteNG","Microsoft.VisualStudioCode","Microsoft.PowerShell","Microsoft.AzureDataStudio","Microsoft.WindowsTerminal"  |  foreach {winget install $_ --accept-package-agreements}
```
