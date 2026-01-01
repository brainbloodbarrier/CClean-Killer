# Slash Commands Reference

Complete reference for all CClean-Killer slash commands.

## Table of Contents

- [/scan](#scan)
- [/parasites](#parasites)
- [/clean](#clean)
- [/report](#report)

---

## /scan

Perform a comprehensive analysis of your system's disk usage.

### Synopsis

```
/scan [options]
```

### Options

| Option | Description |
|--------|-------------|
| (none) | Full system scan |
| `--quick` | Quick scan (top-level directories only) |
| `--deep` | Deep scan including hidden system locations |

### Description

The `/scan` command analyzes disk usage across your system, identifying:

- Large directories consuming significant space
- Hidden caches and application data
- Developer tool storage (npm, Cargo, Homebrew, etc.)
- Container data (Docker, Flatpak, Snap)
- Orphaned application data

### Example Output

```
Disk Overview
Total: 500GB  Used: 450GB  Available: 50GB  (90% used)

~/Library Analysis (Top 15)
12G    Application Support
4.2G   Caches
2.1G   Containers
...
```

### Platform-Specific Behavior

| Platform | Locations Scanned |
|----------|-------------------|
| macOS | `~/Library/*`, `/Library/*`, `/private/var/folders/` |
| Linux | `~/.config/`, `~/.local/share/`, `~/.cache/` |
| Windows | `%APPDATA%`, `%LOCALAPPDATA%`, `C:\ProgramData` |

---

## /parasites

Hunt and eliminate persistent processes from uninstalled applications.

### Synopsis

```
/parasites [options]
```

### Options

| Option | Description |
|--------|-------------|
| (none) | Scan and display found parasites |
| `--kill` | Remove identified parasites |
| `--backup` | Backup plist files before removal |

### Description

Parasites are background processes that:
- Were installed by an application
- Continue running after the app is removed
- May consume resources or send telemetry data

The command scans:
- User LaunchAgents (`~/Library/LaunchAgents/`)
- System LaunchAgents (`/Library/LaunchAgents/`)
- System LaunchDaemons (`/Library/LaunchDaemons/`)
- PrivilegedHelperTools (`/Library/PrivilegedHelperTools/`)
- Code signing clones (`/private/var/folders/*/X/`)

### Known Parasites Detected

| Parasite | Pattern | Description |
|----------|---------|-------------|
| Google Keystone | `com.google.keystone.*` | Chrome updater (persists after Chrome removal) |
| Adobe AGS | `com.adobe.agsservice` | License check telemetry |
| Adobe GC Invoker | `com.adobe.GC.Invoker.*` | Analytics collection |
| CCleaner | `com.piriform.ccleaner.*` | 6 daemons for a "cleaner" |
| Zoom | `us.zoom.*` | Background daemons |
| Microsoft Update | `com.microsoft.update.*` | Office update checker |

### Example Output

```
KNOWN PARASITE: com.google.keystone.agent
   Google Keystone - Chrome updater (persists after Chrome removal)
   Location: ~/Library/LaunchAgents/
   Status: RUNNING

KNOWN PARASITE: com.adobe.agsservice
   Adobe Genuine Software - License check telemetry
   Location: /Library/LaunchDaemons/
   (Requires sudo to remove)
```

### Removal Commands

For user LaunchAgents:
```bash
launchctl unload ~/Library/LaunchAgents/com.example.plist
rm ~/Library/LaunchAgents/com.example.plist
```

For system LaunchDaemons (requires sudo):
```bash
sudo launchctl unload /Library/LaunchDaemons/com.example.plist
sudo rm /Library/LaunchDaemons/com.example.plist
```

---

## /clean

Remove orphaned application data, caches, and leftovers safely.

### Synopsis

```
/clean [options]
```

### Options

| Option | Description |
|--------|-------------|
| (none) | Interactive cleanup |
| `--dry-run` | Show what would be removed without deleting |
| `--caches` | Only clean cache directories |
| `--orphans` | Only clean orphaned app data |
| `--dev` | Only clean developer tool caches |
| `--all` | Clean everything safe |

### Description

The `/clean` command safely removes:

1. **Caches** - Regenerate automatically
   - `~/Library/Caches/*`
   - `~/.cache/*`
   - Package manager caches

2. **Developer Caches**
   - npm cache (`~/.npm/_cacache`)
   - pnpm store
   - pip cache
   - Cargo registry cache
   - Gradle caches

3. **Orphaned Data**
   - Application Support entries without corresponding apps
   - Container data for removed sandboxed apps
   - Saved Application State for uninstalled apps

### Example: Dry Run

```
/clean --dry-run

[DRY RUN] Would remove:
- ~/Library/Caches/Homebrew/downloads/* (200 MB)
- ~/.npm/_cacache (500 MB)
- ~/Library/Application Support/Discord (orphan, 259 MB)

Total: 959 MB would be freed
```

### Example: Full Cleanup

```
/clean

=== Cleanup Complete ===

Before: 26 GB available
After:  45 GB available
Freed:  19 GB

Breakdown:
- Caches: 5 GB
- Docker: 10 GB
- Orphans: 4 GB
```

### Safety Features

- Always offers dry-run first
- Never deletes system directories
- Logs all deletions to `~/.cclean-killer/cleanup.log`
- Backs up LaunchDaemons before removal

---

## /report

Generate a comprehensive system storage and health report.

### Synopsis

```
/report [options]
```

### Options

| Option | Description |
|--------|-------------|
| (none) | Display report in terminal |
| `--markdown` | Save as markdown file |
| `--json` | Output as JSON |

### Description

Generates a complete analysis including:

1. **System Information** - OS version, hardware specs
2. **Disk Overview** - Total, used, available space
3. **Top Consumers** - Largest directories
4. **Application Audit** - Apps with their data footprint
5. **Parasites** - Zombie processes detected
6. **Orphans** - Leftover data directories
7. **Recommendations** - Prioritized cleanup actions

### Example Output

```
=== STORAGE REPORT ===
Generated: 2024-12-21 12:00:00

DISK OVERVIEW
Total:     228 GB
Used:      120 GB (52%)
Available: 108 GB (48%)

TOP DIRECTORIES
1. ~/Library                    20 GB
2. ~/Documents                  15 GB
3. /Applications                12 GB

RECOMMENDATIONS
Priority | Action          | Space | Command
---------|-----------------|-------|--------
1        | Docker prune    | 7 GB  | docker system prune -a
2        | Remove orphans  | 4 GB  | /clean --orphans
```

### Output Formats

**Markdown** (`--markdown`):
- Saved to `~/.cclean-killer/reports/report-YYYYMMDD.md`
- Full formatting with tables and headers

**JSON** (`--json`):
```json
{
  "generated": "2024-12-21T12:00:00Z",
  "disk": {
    "total": 228000000000,
    "used": 120000000000,
    "available": 108000000000
  },
  "recommendations": [...]
}
```

---

## See Also

- [Scripts Reference](scripts.md) - Platform-specific shell scripts
- [Agents Documentation](agents.md) - Specialized agent capabilities
- [Skills Documentation](skills.md) - Skill triggers and behaviors
