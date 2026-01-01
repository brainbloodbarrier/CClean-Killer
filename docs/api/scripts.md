# Scripts Reference

Platform-specific shell scripts for system analysis and cleanup.

## Table of Contents

- [macOS Scripts](#macos-scripts)
- [Linux Scripts](#linux-scripts)
- [Windows Scripts](#windows-scripts)

---

## macOS Scripts

Located in `/scripts/macos/`

### scan.sh

Analyzes disk usage on macOS systems.

**Usage:**
```bash
./scripts/macos/scan.sh
```

**What It Scans:**
- Disk overview (`df -h /`)
- `~/Library/*` breakdown
- `~/Library/Application Support/*`
- `~/Library/Caches/*`
- `~/Library/Containers/*`
- `~/Library/Group Containers/*`
- Hidden dotfiles (`~/.*`)
- Developer caches (npm, pnpm, Homebrew, Cargo, pip)
- Docker (if installed)
- `/Library/Application Support/*`

**Output:**
Formatted tables with sizes sorted by largest first.

---

### find-parasites.sh

Hunts for zombie LaunchAgents and LaunchDaemons.

**Usage:**
```bash
./scripts/macos/find-parasites.sh
```

**What It Checks:**
- `~/Library/LaunchAgents/*.plist`
- `/Library/LaunchAgents/*.plist`
- `/Library/LaunchDaemons/*.plist`
- `/Library/PrivilegedHelperTools/*`
- Code signing clones in `/private/var/folders/*/X/`

**Known Parasites Database:**
The script includes a built-in database of known parasites:
- Google Keystone
- Adobe (agsservice, GC.Invoker, ARMDC)
- CCleaner
- Zoom
- Spotify Web Helper
- Microsoft Update

**Cross-Reference Logic:**
For each plist found, the script:
1. Checks if it matches a known parasite pattern
2. Extracts the app name from the bundle ID
3. Checks if the corresponding app exists in `/Applications/`
4. Reports status (RUNNING, Loaded, Orphan)

---

### find-orphans.sh

Finds application data for apps that are no longer installed.

**Usage:**
```bash
./scripts/macos/find-orphans.sh
```

**Locations Scanned:**
| Location | Description |
|----------|-------------|
| `~/Library/Application Support/` | Main app data directories |
| `~/Library/Containers/` | Sandboxed app data |
| `~/Library/Group Containers/` | Shared data between apps |
| `~/Library/Saved Application State/` | Window state data |

**Detection Logic:**
For each directory, the script:
1. Extracts the app name from the directory name
2. Skips system directories (AddressBook, CloudDocs, etc.)
3. Checks if a matching app exists in `/Applications/`
4. Checks if a binary with that name exists in PATH
5. Reports as ORPHAN if no match found

---

### clean.sh

Safely removes caches and orphaned data.

**Usage:**
```bash
./scripts/macos/clean.sh [options]
```

**Options:**
| Option | Description |
|--------|-------------|
| `--dry-run` | Preview without deleting |
| `--caches` | Clean only cache directories |
| `--orphans` | Clean only orphaned app data |
| `--dev` | Clean only developer tool caches |
| `--all` | Clean everything (default) |

**Safe Removal Process:**
1. Check if target exists
2. Calculate size before removal
3. Log the operation
4. Remove with `rm -rf`
5. Track total freed space

**Developer Cache Cleanup:**
- npm: `npm cache clean --force`
- Homebrew: `brew cleanup --prune=all`
- pip: Removes `~/Library/Caches/pip`
- Cargo: Removes `~/.cargo/registry/cache`
- Gradle: Removes `~/.gradle/caches`

---

## Linux Scripts

Located in `/scripts/linux/`

### scan.sh

Analyzes disk usage following XDG Base Directory Specification.

**Usage:**
```bash
./scripts/linux/scan.sh
```

**XDG Directories Scanned:**
| Variable | Default | Purpose |
|----------|---------|---------|
| `$XDG_CONFIG_HOME` | `~/.config` | Configuration |
| `$XDG_DATA_HOME` | `~/.local/share` | Application data |
| `$XDG_CACHE_HOME` | `~/.cache` | Cache files |

**Additional Scans:**
- Hidden home directory files (`~/.*`)
- Developer tools (npm, nvm, Cargo, Rustup, Go, Maven, Gradle)
- Container data (Flatpak, Snap, Docker, Podman)
- Package manager caches (apt, dnf, pacman)
- Trash (`~/.local/share/Trash`)

---

### clean.sh

Safely removes caches and temporary files on Linux.

**Usage:**
```bash
./scripts/linux/clean.sh [options]
```

**Options:**
| Option | Description |
|--------|-------------|
| `--dry-run` | Preview without deleting |
| `--caches` | Clean XDG cache directory |
| `--dev` | Clean developer tool caches |
| `--trash` | Empty trash |
| `--all` | Clean everything (default) |

**Protected Caches:**
These are NOT removed:
- `fontconfig` - Causes font rendering issues
- `mesa_shader_cache` - GPU shader cache

**Developer Tools Cleaned:**
- npm: `npm cache clean --force`
- pip: `pip cache purge`
- Go: `go clean -cache`
- Cargo registry cache
- Gradle caches
- nvm cache

---

## Windows Scripts

Located in `/scripts/windows/`

### scan.ps1

PowerShell script for Windows disk analysis.

**Usage:**
```powershell
.\scripts\windows\scan.ps1
```

**Locations Scanned:**
| Location | Variable | Description |
|----------|----------|-------------|
| AppData\Roaming | `%APPDATA%` | Roaming profile data |
| AppData\Local | `%LOCALAPPDATA%` | Local app data |
| Temp | `%TEMP%` | Temporary files |

**Developer Tools:**
- npm cache (`%APPDATA%\npm-cache`)
- npm global (`%APPDATA%\npm`)
- Yarn (`%LOCALAPPDATA%\Yarn`)
- pip cache (`%LOCALAPPDATA%\pip\cache`)
- Cargo (`%USERPROFILE%\.cargo`)
- Rustup (`%USERPROFILE%\.rustup`)
- Maven (`%USERPROFILE%\.m2`)
- Gradle (`%USERPROFILE%\.gradle`)
- NuGet (`%LOCALAPPDATA%\NuGet`)

**Windows Caches:**
- Windows Update (`C:\Windows\SoftwareDistribution\Download`)
- Windows Installer (`C:\Windows\Installer`)
- Prefetch (`C:\Windows\Prefetch`)
- Windows Temp (`C:\Windows\Temp`)
- Package Cache (`C:\ProgramData\Package Cache`)

**Registry Orphan Detection:**
Checks `HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*` for entries where the `InstallLocation` no longer exists.

---

### clean.ps1

PowerShell script for Windows cleanup.

**Usage:**
```powershell
.\scripts\windows\clean.ps1 [options]
```

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `-DryRun` | switch | Preview without deleting |
| `-Caches` | switch | Clean only temp/caches |
| `-Dev` | switch | Clean only developer caches |
| `-All` | switch | Clean everything (default) |

**Admin-Required Operations:**
- Cleaning `C:\Windows\Temp`
- Cleaning `C:\Windows\Prefetch`

**Developer Tools Cleaned:**
- npm: `npm cache clean --force`
- Yarn: Removes cache folder
- pip: `pip cache purge`
- NuGet: `nuget locals all -clear`
- Cargo registry cache
- Gradle caches

---

## Script Safety Features

All scripts implement these safety measures:

1. **Never delete system directories**
   - macOS: `/System/`
   - Linux: `/etc/`, `/usr/`
   - Windows: `C:\Windows\System32\`

2. **Skip critical user data**
   - SSH keys (`~/.ssh/`)
   - GPG keys (`~/.gnupg/`)
   - Keychains (macOS)

3. **Dry-run support**
   - All scripts support `--dry-run`
   - Shows what would be removed without deleting

4. **Size reporting**
   - Shows size of each item before removal
   - Reports total freed space after cleanup

5. **Error handling**
   - Uses `set -e` (bash) for fail-fast
   - Gracefully handles missing directories
   - Redirects permission errors to null
