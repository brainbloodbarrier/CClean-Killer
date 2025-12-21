# CClean-Killer

> **The CCleaner Killer** - A Claude Code project that actually cleans your system without becoming the problem itself.

## Project Philosophy

Unlike CCleaner (which installs 6 persistent daemons to "clean" your system), CClean-Killer:
- Runs ONLY when you ask it to
- Leaves NO persistent processes
- Is completely transparent about what it does
- Never phones home or collects telemetry

## Quick Start

```bash
# Scan your system
/scan

# Hunt for parasites (zombie processes from uninstalled apps)
/parasites

# Clean orphaned data safely
/clean

# Generate a full report
/report
```

## What This Project Does

### 1. System Scanning
Analyzes disk usage across all platforms (macOS, Linux, Windows) to identify:
- Large files and directories
- Orphaned application data
- Duplicate applications with overlapping functions
- Hidden caches in obscure locations

### 2. Parasite Hunting
Finds and eliminates "zombie" processes - LaunchAgents, LaunchDaemons, and services from apps that have been uninstalled but left persistent processes behind.

**Known Parasites:**
- Google Keystone (Chrome updater that persists after Chrome removal)
- Adobe Telemetry (agsservice, GC.Invoker, ARMDC)
- CCleaner itself (6 daemons for a "cleaner" app)
- Zoom daemons
- Microsoft AutoUpdate

### 3. Orphan Hunting
Finds data directories for applications that are no longer installed:
- `~/Library/Application Support/` entries without corresponding apps
- Container data for removed sandboxed apps
- Group containers for uninstalled apps
- Hidden dotfiles in home directory

### 4. Safe Cleanup
Removes only what's confirmed safe:
- Caches (always regenerable)
- Orphaned data (no corresponding app)
- Zombie processes (from uninstalled apps)
- Duplicate/old versions of CLIs

## Platform Detection

The project automatically detects the operating system and adjusts paths:

```
macOS:  ~/Library/, /Library/, /private/var/
Linux:  ~/.local/, ~/.cache/, ~/.config/, /var/
Windows: %APPDATA%, %LOCALAPPDATA%, %TEMP%
```

## Architecture

```
CClean-Killer/
├── skills/           # Individual capabilities
├── agents/           # Complex multi-step operations
├── .claude/commands/ # Slash commands for quick access
├── scripts/          # Platform-specific shell scripts
└── knowledge/        # Database of known parasites and locations
```

## Safety First

- **Never deletes system files**
- **Always asks before removing anything important**
- **Creates backups of LaunchAgent plists before removal**
- **Dry-run mode available for all operations**

## Usage Examples

### Find what's eating your disk
```
/scan
```

### Hunt zombie processes from uninstalled apps
```
/parasites
```

### Clean orphaned app data
```
/clean --dry-run   # Preview what would be removed
/clean             # Actually remove orphaned data
```

### Generate full system report
```
/report
```

## Contributing

Found a new parasite? Know a hidden location where apps dump data?
Add it to `knowledge/common-parasites.md` or `knowledge/hidden-locations/`.
