# Hidden Data Locations: Windows

A comprehensive guide to where applications hide data on Windows systems.

## Overview

Windows has multiple layers of app data storage, registry entries, and service configurations.

## User Data Locations

### AppData Folders

| Location | Variable | Purpose |
|----------|----------|---------|
| `C:\Users\<user>\AppData\Roaming` | `%APPDATA%` | Roaming profile data |
| `C:\Users\<user>\AppData\Local` | `%LOCALAPPDATA%` | Local app data |
| `C:\Users\<user>\AppData\LocalLow` | `%LOCALAPPDATA%Low` | Low-integrity data |

### Typical Structure
```
%APPDATA%\
├── <Company>\<App>\      # Roaming app data
├── Microsoft\            # Microsoft apps
└── npm\                  # Node.js global

%LOCALAPPDATA%\
├── <Company>\<App>\      # Local app data
├── Programs\             # User-installed apps
├── Packages\             # UWP apps
├── Temp\                 # Temporary files
└── Microsoft\            # Microsoft cache
```

## System Locations

### Program Files
```
C:\Program Files\         # 64-bit programs
C:\Program Files (x86)\   # 32-bit programs
```

### ProgramData
```
C:\ProgramData\           # System-wide app data
├── <Company>\<App>\
├── Microsoft\
└── Package Cache\        # Installer cache
```

### Windows System
```
C:\Windows\
├── Temp\                 # System temp
├── Prefetch\             # App prefetch
├── SoftwareDistribution\ # Windows Update
└── Installer\            # MSI cache
```

## Registry Locations

### User Registry (HKCU)
```
HKEY_CURRENT_USER\Software\<Company>\<App>
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run      # Startup
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall
```

### System Registry (HKLM)
```
HKEY_LOCAL_MACHINE\SOFTWARE\<Company>\<App>
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run     # Startup
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services                 # Services
```

## Persistence Mechanisms

### Startup Locations
```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup   # User startup
C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup  # All users
```

### Scheduled Tasks
```powershell
# List scheduled tasks
Get-ScheduledTask | Where-Object {$_.TaskPath -notlike "\Microsoft\*"}

# Location
C:\Windows\System32\Tasks\
```

### Services
```powershell
# List non-Microsoft services
Get-Service | Where-Object {$_.DisplayName -notlike "*Microsoft*" -and $_.DisplayName -notlike "*Windows*"}
```

## Development Tool Locations

### Node.js
```
%APPDATA%\npm\             # Global packages
%APPDATA%\npm-cache\       # npm cache
%LOCALAPPDATA%\Yarn\       # Yarn cache
```

### Python
```
%LOCALAPPDATA%\Programs\Python\   # Python installation
%LOCALAPPDATA%\pip\              # pip cache
%USERPROFILE%\.virtualenvs\      # virtualenvs
```

### Rust
```
%USERPROFILE%\.cargo\      # Cargo
%USERPROFILE%\.rustup\     # Rustup
```

### Java
```
%USERPROFILE%\.m2\         # Maven
%USERPROFILE%\.gradle\     # Gradle
```

## Common Orphan Locations

### After App Uninstall, Check:
```
%APPDATA%\<App>
%LOCALAPPDATA%\<App>
C:\ProgramData\<App>
HKCU\Software\<Company>
HKLM\SOFTWARE\<Company>
```

## PowerShell Cleanup Commands

### Clear Temp Files
```powershell
Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
```

### Clear Specific App Data
```powershell
$app = "AppName"
Remove-Item -Path "$env:APPDATA\$app" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\$app" -Recurse -Force -ErrorAction SilentlyContinue
```

### Clear Windows Update Cache
```powershell
Stop-Service wuauserv
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force
Start-Service wuauserv
```

### Clear Package Cache
```powershell
# Clears installer cache (can be several GB)
Remove-Item -Path "C:\ProgramData\Package Cache\*" -Recurse -Force
```

### Find Large Folders
```powershell
Get-ChildItem -Path $env:LOCALAPPDATA -Directory |
    ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Size = "{0:N2} MB" -f ((Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum / 1MB)
        }
    } | Sort-Object {[double]($_.Size -replace ' MB','')} -Descending |
    Select-Object -First 20
```

## Registry Cleanup

### Find Orphaned Keys
```powershell
# List uninstall entries
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, InstallLocation |
    Where-Object { $_.InstallLocation -and !(Test-Path $_.InstallLocation) }
```

### Remove Registry Key
```powershell
# Caution: Backup registry first!
Remove-Item -Path "HKCU:\Software\<Company>\<App>" -Recurse
```

## Safety Rules

1. **NEVER** delete `C:\Windows\System32\`
2. **NEVER** delete user profile folders without backup
3. **ALWAYS** export registry keys before deleting
4. **BACKUP** before major cleanup operations
5. **CREATE** System Restore point before changes
