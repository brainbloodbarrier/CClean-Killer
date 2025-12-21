# Hidden Data Locations: macOS

A comprehensive guide to where applications hide data on macOS.

## Overview

macOS apps scatter data across many locations. A single app might have data in 10+ places. This document maps all known locations.

## User Library Locations

### Primary Data Storage

| Location | Purpose | Typical Size |
|----------|---------|--------------|
| `~/Library/Application Support/<app>` | Main app data, databases | 100 MB - 10 GB |
| `~/Library/Preferences/com.<company>.<app>.plist` | Settings | < 1 MB |
| `~/Library/Caches/<app>` | Temporary cache | 10 MB - 1 GB |

### Sandboxed App Data

| Location | Purpose | Notes |
|----------|---------|-------|
| `~/Library/Containers/<bundle-id>` | Sandboxed app data | App Store apps |
| `~/Library/Group Containers/<team-id>.<app>` | Shared data between apps | Same developer |

### Secondary Locations

| Location | Purpose |
|----------|---------|
| `~/Library/Logs/<app>` | Application logs |
| `~/Library/Saved Application State/<bundle-id>.savedState` | Window state |
| `~/Library/Cookies/<bundle-id>.binarycookies` | Cookies |
| `~/Library/WebKit/<bundle-id>` | WebKit data |
| `~/Library/HTTPStorages/<bundle-id>` | HTTP cache |

## System Library Locations

### /Library (Requires Admin)

| Location | Purpose | Persists After Uninstall? |
|----------|---------|--------------------------|
| `/Library/Application Support/<app>` | System-wide app data | **YES** |
| `/Library/Preferences/<app>.plist` | System-wide settings | **YES** |
| `/Library/Caches/<app>` | System cache | Sometimes |
| `/Library/LaunchAgents/` | Startup agents | **YES** |
| `/Library/LaunchDaemons/` | System daemons | **YES** |
| `/Library/PrivilegedHelperTools/` | Sudo helpers | **YES** |

## Hidden System Locations

### /private/var/folders

This is where macOS hides per-user temporary and cache data.

```
/private/var/folders/<random>/<random>/
├── 0/          # User-specific data
├── C/          # Caches
│   └── com.<app>.<something>/
├── T/          # Temporary files
│   └── com.<app>.<something>/
└── X/          # Code signing clones  ← IMPORTANT!
    └── com.<app>.code_sign_clone/
```

**The X folder is where code_sign_clone data hides!**

To find your var/folders path:
```bash
echo $TMPDIR
# Returns something like: /var/folders/v1/x29xyyg54.../T/
```

To search for app remnants:
```bash
sudo find /private/var/folders -name "*com.google*" 2>/dev/null
sudo find /private/var/folders -name "*.code_sign_clone" 2>/dev/null
```

### Code Sign Clone Explained

When you first open a downloaded app, macOS creates a "translocation" copy to verify its signature. These clones can be HUGE (full app size) and persist even after you delete the original app.

**Location:** `/private/var/folders/<random>/<random>/X/<bundle-id>.code_sign_clone/`

**To clean:**
```bash
# Find all code_sign_clone directories
sudo find /private/var/folders -type d -name "*.code_sign_clone" 2>/dev/null

# Remove specific app's clone
sudo rm -rf "/private/var/folders/.../X/com.google.Chrome.code_sign_clone"
```

## Home Directory Hidden Files

Apps also create hidden directories in your home folder:

| Location | Common Apps |
|----------|-------------|
| `~/.npm` | Node.js |
| `~/.pnpm` | pnpm |
| `~/.cargo` | Rust |
| `~/.rustup` | Rust |
| `~/.gradle` | Java/Android |
| `~/.m2` | Maven |
| `~/.docker` | Docker |
| `~/.kube` | Kubernetes |
| `~/.ssh` | SSH (don't delete!) |
| `~/.gnupg` | GPG (don't delete!) |
| `~/.config` | XDG config |
| `~/.local` | XDG data |
| `~/.cache` | XDG cache |

## Application-Specific Locations

### Adobe
```
~/Library/Application Support/Adobe/
~/Library/Application Support/com.adobe.dunamis/
~/Library/Caches/Adobe/
~/Library/Caches/com.adobe.*/
~/Library/Preferences/com.adobe.*.plist
~/Library/Logs/Adobe/
/Library/Application Support/Adobe/           ← 6+ GB often!
/Library/Preferences/com.adobe.*.plist
```

### Google Chrome
```
~/Library/Application Support/Google/Chrome/   ← Profile data
~/Library/Application Support/Google/GoogleUpdater/
~/Library/Caches/Google/
~/Library/Caches/com.google.*/
~/Library/Google/
~/Library/Preferences/com.google.*.plist
/private/var/folders/.../X/com.google.Chrome.code_sign_clone/
```

### JetBrains IDEs
```
~/Library/Application Support/JetBrains/<IDE><version>/
~/Library/Caches/JetBrains/<IDE><version>/
~/Library/Logs/JetBrains/<IDE><version>/
~/.idea/  (in project directories)
```

### VS Code / Cursor
```
~/Library/Application Support/Code/
~/Library/Application Support/Cursor/
~/Library/Caches/com.microsoft.VSCode/
~/.vscode/
~/.cursor/
```

### Docker
```
~/Library/Containers/com.docker.docker/
~/Library/Group Containers/group.com.docker/
~/.docker/
~/Library/Application Support/Docker Desktop/
```

## Cleanup Commands by Location

### User Library (No sudo needed)
```bash
rm -rf ~/Library/Application\ Support/<app>
rm -rf ~/Library/Caches/<app>
rm -rf ~/Library/Containers/<bundle-id>
rm -rf ~/Library/Group\ Containers/*<app>*
rm -rf ~/Library/Preferences/com.<company>.<app>.plist
rm -rf ~/Library/Saved\ Application\ State/<bundle-id>.savedState
```

### System Library (Requires sudo)
```bash
sudo rm -rf /Library/Application\ Support/<app>
sudo rm -rf /Library/LaunchDaemons/com.<company>.<app>.plist
sudo rm -rf /Library/PrivilegedHelperTools/com.<company>.<app>
```

### var/folders (Requires sudo)
```bash
sudo find /private/var/folders -name "*<app>*" -exec rm -rf {} \; 2>/dev/null
```

## Safety Rules

1. **NEVER** delete anything in `/System/`
2. **NEVER** delete `~/Library/Keychains/`
3. **NEVER** delete `~/.ssh/` or `~/.gnupg/`
4. **BACKUP** before deleting from `/Library/`
5. **VERIFY** app is uninstalled before cleaning its data
