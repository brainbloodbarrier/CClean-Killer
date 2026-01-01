# Skills Documentation

Skills are reusable capabilities that Claude Code can invoke during cleanup operations.

## Table of Contents

- [Overview](#overview)
- [System Scanner](#system-scanner)
- [Orphan Hunter](#orphan-hunter)
- [Parasite Killer](#parasite-killer)
- [Duplicate Finder](#duplicate-finder)

---

## Overview

Skills are modular components that provide specific functionality. They are triggered by user intent and can be combined by agents for complex operations.

### Skill Architecture

```
User Request
     |
     v
Intent Detection --> Skill Selection --> Execution
                          |
                          v
                    [system-scanner]
                    [orphan-hunter]
                    [parasite-killer]
                    [duplicate-finder]
```

---

## System Scanner

**Location:** `/skills/system-scanner.md`

Analyzes disk usage and identifies storage consumption patterns.

### Triggers

- "Analyze disk space"
- "Find large files"
- "Check storage usage"
- "Scan the system"
- "What's using space"

### Platform Detection

```bash
detect_platform() {
  case "$(uname -s)" in
    Darwin)  echo "macos" ;;
    Linux)   echo "linux" ;;
    MINGW*|CYGWIN*|MSYS*) echo "windows" ;;
    *)       echo "unknown" ;;
  esac
}
```

### Platform-Specific Paths

**macOS:**
| Path | Purpose |
|------|---------|
| `~/Library/Application Support` | App data |
| `~/Library/Caches` | User caches |
| `~/Library/Containers` | Sandboxed apps |
| `~/Library/Group Containers` | Shared data |
| `/private/var/folders` | System temp/cache |
| `/opt/homebrew` | Homebrew packages |

**Linux:**
| Path | Purpose |
|------|---------|
| `~/.local/share` | XDG data |
| `~/.cache` | XDG cache |
| `~/.config` | XDG config |
| `/var/cache` | System cache |
| `/var/log` | System logs |

**Windows:**
| Path | Purpose |
|------|---------|
| `%APPDATA%` | Roaming data |
| `%LOCALAPPDATA%` | Local data |
| `%TEMP%` | Temp files |
| `C:\ProgramData` | Shared data |

### Scanning Commands

**Quick Scan:**
```bash
du -sh ~/* 2>/dev/null | sort -hr | head -20
```

**Deep Scan:**
```bash
find ~ -type d -exec du -sh {} + 2>/dev/null | \
  awk '$1 ~ /[0-9]+G|[0-9]{3,}M/' | sort -hr
```

### Output Format

1. **Summary** - Total, used, available, percentage
2. **Top Consumers Table** - Ranked by size
3. **Recommendations** - Cleanup suggestions

---

## Orphan Hunter

**Location:** `/skills/orphan-hunter.md`

Finds application data that belongs to apps that are no longer installed.

### Triggers

- "Find leftover data"
- "Find orphaned files"
- "Clean up after uninstalled apps"
- "Find data without apps"

### Detection Logic

For each directory in Application Support:
1. Extract app name from directory name
2. Skip system directories (AddressBook, CloudDocs)
3. Check if corresponding app exists
4. Report as orphan if no match

### Common Orphan Patterns

| App | Location | Typical Size |
|-----|----------|--------------|
| JetBrains/* | `~/Library/Application Support/JetBrains` | 1-5 GB |
| Discord | `~/Library/Application Support/discord` | 200-500 MB |
| Slack | `~/Library/Application Support/Slack` | 100-300 MB |
| Figma | `~/Library/Application Support/Figma` | 100-200 MB |
| Spotify | `~/Library/Application Support/Spotify` | 500 MB - 2 GB |
| Chrome | `~/Library/Application Support/Google/Chrome` | 1-5 GB |

### Container Orphan Detection

For sandboxed apps, use bundle ID lookup:
```bash
for container in ~/Library/Containers/*/; do
  bundle_id=$(basename "$container")
  app_path=$(mdfind "kMDItemCFBundleIdentifier == '$bundle_id'" | head -1)
  if [[ -z "$app_path" ]]; then
    echo "ORPHAN: $container"
  fi
done
```

### Confidence Levels

| Level | Description |
|-------|-------------|
| CONFIRMED | App definitely doesn't exist |
| LIKELY | Strong indication app was removed |
| UNCERTAIN | Might be shared data or system component |

### Safety Rules

1. Never auto-delete - always confirm with user
2. Skip anything with "apple" or "com.apple"
3. Skip system directories
4. Show last modified date
5. Warn if data is recent (< 7 days)

---

## Parasite Killer

**Location:** `/skills/parasite-killer.md`

Identifies and removes persistent processes from uninstalled applications.

### Triggers

- "Remove zombie processes"
- "Clean up LaunchAgents"
- "Find persistent processes"
- "Kill background services"
- "Remove startup items"

### What Are Parasites?

Parasites are persistent processes that:
1. Were installed by an application
2. Continue to run after the app is removed
3. May phone home, use resources, or just waste space

### Persistence Locations (macOS)

| Location | Access Level |
|----------|--------------|
| `~/Library/LaunchAgents` | User-writable |
| `/Library/LaunchAgents` | Root-writable |
| `/Library/LaunchDaemons` | Root-writable |
| `/Library/PrivilegedHelperTools` | Root-writable |
| `~/Library/Application Scripts` | User-writable |

### Known Parasites Database

**Always Parasites (Telemetry):**
```
com.adobe.agsservice
com.adobe.GC.Invoker
com.adobe.ARMDC
com.adobe.ARMDCHelper
com.microsoft.update
com.spotify.webhelper
```

**Zombie If App Removed:**
```
com.google.keystone
com.piriform.ccleaner
us.zoom
com.dropbox
com.tinyspeck.slackmacgap
```

### Removal Process

1. **Unload first:**
   ```bash
   launchctl unload "$plist"
   ```

2. **Backup (optional):**
   ```bash
   mkdir -p ~/.cclean-killer/backup
   cp "$plist" ~/.cclean-killer/backup/
   ```

3. **Remove:**
   ```bash
   rm -f "$plist"
   ```

4. **Clean related data:**
   ```bash
   rm -rf ~/Library/Caches/com.example.*
   rm -rf ~/Library/Preferences/com.example.*
   ```

### Safety Rules

1. **NEVER** touch `/System/Library/LaunchAgents`
2. **NEVER** touch `/System/Library/LaunchDaemons`
3. **ALWAYS** unload before removing
4. **ALWAYS** backup daemons (require root to restore)
5. **NEVER** remove agents for running processes without confirmation

---

## Duplicate Finder

**Location:** `/skills/duplicate-finder.md`

Identifies applications with overlapping functionality.

### Triggers

- "Find duplicate apps"
- "Find apps with same function"
- "Consolidate applications"
- "Reduce app bloat"

### Duplicate Categories

**Code Editors:**
- Visual Studio Code
- Cursor
- Zed
- Sublime Text
- Xcode

**Terminal Emulators:**
- iTerm
- Ghostty
- Warp
- Alacritty

**Web Browsers:**
- Chrome
- Firefox
- Safari
- Arc
- Brave

**Password Managers:**
- 1Password
- Bitwarden
- macOS Passwords

**System Cleaners:**
- CCleaner (not recommended)
- CleanMyMac
- OnyX
- DaisyDisk

### Data Overlap Detection

Some apps share data structures:

**VS Code Family:**
- `~/Library/Application Support/Code`
- `~/Library/Application Support/Cursor`
- `~/.vscode`
- `~/.cursor`

**Chromium Browsers:**
- `~/Library/Application Support/Google/Chrome`
- `~/Library/Application Support/Microsoft Edge`
- `~/Library/Application Support/BraveSoftware`

### Output Format

```
=== DUPLICATE ANALYSIS ===

CODE EDITORS (3 apps found)
| App | Size | Data | Total | Recommendation |
|-----|------|------|-------|----------------|
| VS Code | 659 MB | 321 MB | 980 MB | Keep if primary |
| Cursor | 583 MB | 512 MB | 1.1 GB | Keep if using AI |
| Xcode | 4.9 GB | 228 KB | 4.9 GB | Keep if iOS dev |

SYSTEM CLEANERS (3 apps found)
| App | Size | Daemons | Recommendation |
|-----|------|---------|----------------|
| CCleaner | 122 MB | 6 | REMOVE |
| OnyX | 13 MB | 0 | Keep |

*** ALERT: CCleaner has 6 persistent daemons! ***
```

### Recommendation Logic

**Keep if:**
- Only app in its category
- Unique feature set
- No persistent daemons
- Actively used

**Consider Removing if:**
- Duplicate functionality
- Excessive daemons/services
- Known bloatware
- Not used in 30+ days

---

## Skill Composition

Agents combine skills for complex operations:

```
Storage Expert Agent
  |
  +-- system-scanner (disk analysis)
  +-- orphan-hunter (find orphans)
  +-- parasite-killer (find parasites)
  +-- duplicate-finder (find duplicates)
  |
  v
Comprehensive Report
```
