# Command Reference

Quick reference for all CClean-Killer slash commands.

## Table of Contents

- [/scan](#scan)
- [/parasites](#parasites)
- [/clean](#clean)
- [/report](#report)
- [Command Combinations](#command-combinations)

---

## /scan

Analyze disk usage across your system.

### Basic Usage

```
/scan
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| (none) | Full system scan | `/scan` |
| `--quick` | Top-level only (faster) | `/scan --quick` |
| `--deep` | Include hidden system paths | `/scan --deep` |

### What It Shows

- Disk capacity and usage percentage
- Largest directories in your home folder
- Application data sizes
- Cache sizes
- Developer tool storage
- Docker/container usage (if installed)

### Sample Output

```
Disk Overview
Total: 500GB  Used: 450GB  Available: 50GB  (90% used)

~/Library Analysis (Top 15)
12G    Application Support
4.2G   Caches
2.1G   Containers

Developer Caches
npm cache:     500 MB
Homebrew:      1.2 GB
Cargo:         200 MB
```

---

## /parasites

Hunt for zombie processes from uninstalled applications.

### Basic Usage

```
/parasites
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| (none) | Scan and display | `/parasites` |
| `--kill` | Remove found parasites | `/parasites --kill` |
| `--backup` | Backup before removing | `/parasites --backup` |

### What It Finds

| Type | Description |
|------|-------------|
| KNOWN PARASITE | In database of known problematic processes |
| ZOMBIE | LaunchAgent/Daemon without corresponding app |
| TELEMETRY | Data collection services |
| ORPHAN | Process files but no parent app |

### Sample Output

```
=== User LaunchAgents ===
KNOWN PARASITE: com.google.keystone.agent
   Google Keystone - Chrome updater (persists after Chrome removal)
   Location: ~/Library/LaunchAgents/
   Status: RUNNING

=== System LaunchDaemons ===
DAEMON: com.adobe.agsservice
   Adobe Genuine Software - License check telemetry
   (Requires sudo to remove)
```

### Removal

For user agents:
```bash
launchctl unload ~/Library/LaunchAgents/com.example.plist
rm ~/Library/LaunchAgents/com.example.plist
```

For system daemons:
```bash
sudo launchctl unload /Library/LaunchDaemons/com.example.plist
sudo rm /Library/LaunchDaemons/com.example.plist
```

---

## /clean

Remove caches, orphaned data, and cleanup safely.

### Basic Usage

```
/clean --dry-run
```

**Always use `--dry-run` first!**

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Preview without deleting | `/clean --dry-run` |
| `--caches` | Clean only caches | `/clean --caches` |
| `--orphans` | Clean only orphaned app data | `/clean --orphans` |
| `--dev` | Clean only developer caches | `/clean --dev` |
| `--all` | Clean everything safe | `/clean --all` |

### Cleanup Categories

**Caches** (always safe):
- `~/Library/Caches/*` (macOS)
- `~/.cache/*` (Linux)
- Package manager caches
- IDE caches

**Developer Caches**:
- npm cache
- pip cache
- Homebrew downloads
- Cargo registry cache
- Gradle caches

**Orphans** (verified safe):
- Application Support for uninstalled apps
- Container data for removed apps
- Saved application state

### Sample Output

```
[DRY RUN] Would remove:
- ~/Library/Caches/Homebrew/downloads/* (200 MB)
- ~/.npm/_cacache (500 MB)
- ~/Library/Application Support/Discord (orphan, 259 MB)

Total: 959 MB would be freed
```

After actual cleanup:
```
=== Cleanup Complete ===

Before: 26 GB available
After:  45 GB available
Freed:  19 GB
```

---

## /report

Generate a comprehensive system analysis report.

### Basic Usage

```
/report
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| (none) | Display in terminal | `/report` |
| `--markdown` | Save as .md file | `/report --markdown` |
| `--json` | Output as JSON | `/report --json` |

### Report Sections

1. **Executive Summary** - One-paragraph overview
2. **Disk Overview** - Total, used, available
3. **Top Consumers** - Largest directories
4. **Application Audit** - Apps with data footprint
5. **Parasites** - Zombie processes found
6. **Orphans** - Leftover data
7. **Recommendations** - Prioritized actions

### Sample Output

```
=== STORAGE REPORT ===
Generated: 2024-12-21 12:00:00

DISK OVERVIEW
Total:     228 GB
Used:      120 GB (52%)
Available: 108 GB (48%)

RECOMMENDATIONS
| Priority | Action | Space | Command |
|----------|--------|-------|---------|
| 1 | Docker prune | 7 GB | docker system prune -a |
| 2 | npm cache | 2 GB | npm cache clean --force |
| 3 | Orphans | 4 GB | /clean --orphans |
```

### Saved Reports

When using `--markdown`:
- Saved to: `~/.cclean-killer/reports/report-YYYYMMDD.md`

---

## Command Combinations

### Standard Cleanup Workflow

```bash
# 1. Quick overview
/scan --quick

# 2. Find parasites
/parasites

# 3. Preview cleanup
/clean --dry-run

# 4. Execute cleanup
/clean

# 5. Generate report
/report --markdown
```

### Developer-Focused Cleanup

```bash
# Focus on dev tools
/scan
/clean --dev --dry-run
/clean --dev
```

### Deep Investigation

```bash
# Thorough analysis
/scan --deep
/parasites
/report
```

### Quick Maintenance

```bash
# Fast weekly check
/scan --quick
/clean --caches --dry-run
```

---

## Tips

1. **Always preview first** - Use `--dry-run` before any `/clean`
2. **Start with scanning** - Know what you have before cleaning
3. **Check parasites regularly** - Apps leave zombies behind
4. **Generate reports** - Track progress over time
5. **Save reports** - Use `--markdown` for documentation
