# Deploy Windows 11

## Winget

```powershell
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
```

```powershell
"Git.Git","mRemoteNG.mRemoteNG"  |  foreach {winget install $_ --accept-package-agreements}
```
