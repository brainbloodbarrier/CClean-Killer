# CClean-Killer

> **The CCleaner Killer** - Because your "cleaner" app shouldn't need 6 persistent daemons.

```
   _____ _____ _                        _  ___ _ _
  / ____/ ____| |                      | |/ (_) | |
 | |   | |    | | ___  __ _ _ __ ______| ' / _| | | ___ _ __
 | |   | |    | |/ _ \/ _` | '_ \______|  < | | | |/ _ \ '__|
 | |___| |____| |  __/ (_| | | | |     | . \| | | |  __/ |
  \_____\_____|_|\___|\__,_|_| |_|     |_|\_\_|_|_|\___|_|
```

[![Claude Code](https://img.shields.io/badge/Claude%20Code-Project-blueviolet)](https://claude.ai/claude-code)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## The Problem

You installed CCleaner to "clean" your system. Here's what it installed:

```
/Library/LaunchDaemons/com.piriform.ccleaner.engine.xpc.plist
/Library/LaunchDaemons/com.piriform.ccleaner.services.submit.plist
/Library/LaunchDaemons/com.piriform.ccleaner.services.xpc.plist
/Library/LaunchDaemons/com.piriform.ccleaner.uninstall.plist
/Library/LaunchDaemons/com.piriform.ccleaner.update.xpc.plist
/Library/LaunchAgents/com.piriform.ccleaner.plist
/Library/LaunchAgents/com.piriform.ccleaner.update.plist
```

**Six persistent daemons. For a "cleaner" app.**

The irony.

## The Solution

CClean-Killer is a Claude Code project that actually cleans your system:

- **Runs ONLY when you ask** - No persistent processes. Ever.
- **Completely transparent** - See exactly what it's doing
- **No telemetry** - Zero data collection
- **Open source** - Audit the code yourself

## Quick Start

```bash
# Clone the repo
git clone https://github.com/brainbloodbarrier/CClean-Killer.git
cd CClean-Killer

# Open with Claude Code
claude .

# Scan your system
/scan

# Hunt for parasites (zombie processes from uninstalled apps)
/parasites

# Clean orphaned data
/clean

# Generate a health report
/report
```

## What It Does

### 1. System Scanning (`/scan`)
Analyzes disk usage across all platforms to identify:
- Large hidden directories
- Orphaned application data
- Developer tool caches
- Hidden caches in obscure locations (like `/private/var/folders/*/X/`)

### 2. Parasite Hunting (`/parasites`)
Finds and eliminates "zombie" processes - LaunchAgents, LaunchDaemons, and services from apps you've uninstalled but left persistent processes behind.

**Known Parasites:**
| Parasite | Pattern | What It Does |
|----------|---------|--------------|
| Google Keystone | `com.google.keystone.*` | Checks for Chrome updates every hour - even after Chrome is deleted |
| Adobe Telemetry | `com.adobe.agsservice`, `com.adobe.GC.Invoker.*` | "Genuine Software" checks and analytics |
| CCleaner | `com.piriform.ccleaner.*` | 6 daemons for a "cleaner" (ironic) |
| Zoom | `us.zoom.*` | Background daemons even when not in a call |
| Microsoft AU | `com.microsoft.update.*` | Office update checker |

### 3. Orphan Hunting (`/clean`)
Finds data directories for apps that are no longer installed:
- `~/Library/Application Support/` entries without corresponding apps
- Container data for removed sandboxed apps
- Group containers for uninstalled apps
- Hidden dotfiles in home directory

### 4. Deep Forensics
Investigates obscure locations where apps hide data:

**macOS Secret Spots:**
```
/private/var/folders/<random>/<random>/X/    <- Code signing clones (can be HUGE)
/private/var/folders/<random>/<random>/C/    <- Per-process caches
~/Library/Group Containers/                   <- Shared app data
~/Library/HTTPStorages/                        <- HTTP cache per app
```

## Project Structure

```
CClean-Killer/
├── CLAUDE.md                    # Project instructions for Claude
├── .claude/
│   ├── settings.json            # Project configuration
│   └── commands/                # Slash commands
│       ├── scan.md              # /scan - System analysis
│       ├── parasites.md         # /parasites - Hunt zombies
│       ├── clean.md             # /clean - Safe cleanup
│       └── report.md            # /report - Health report
│
├── skills/                      # Claude Code skills
│   ├── system-scanner.md        # Disk analysis
│   ├── orphan-hunter.md         # Find orphaned data
│   ├── parasite-killer.md       # Eliminate zombies
│   └── duplicate-finder.md      # Find duplicate apps
│
├── agents/                      # Specialized agents
│   ├── storage-expert.md        # Storage analysis
│   ├── forensics.md             # Deep investigation
│   └── cleanup-executor.md      # Safe execution
│
├── scripts/                     # Platform scripts
│   ├── macos/
│   │   ├── scan.sh
│   │   ├── find-orphans.sh
│   │   ├── find-parasites.sh
│   │   └── clean.sh
│   ├── linux/
│   │   ├── scan.sh
│   │   └── clean.sh
│   └── windows/
│       ├── scan.ps1
│       └── clean.ps1
│
└── knowledge/                   # Parasite database
    ├── common-parasites.md      # Known parasites
    ├── safe-to-remove.md        # Safety guidelines
    └── hidden-locations/
        ├── macos.md
        ├── linux.md
        └── windows.md
```

## Safety First

CClean-Killer follows strict safety rules:

### Never Deletes
- `/System/` (macOS) or `C:\Windows\System32\` (Windows)
- `~/.ssh/` or `~/.gnupg/` (your keys!)
- `~/Library/Keychains/` (passwords)
- Active application data

### Always Safe
- Cache directories (regenerate automatically)
- Orphaned app data (app no longer installed)
- Zombie launch agents (app no longer exists)
- Old installer files (already installed)

### Requires Confirmation
- System-level LaunchDaemons
- `/Library/` directories
- Anything that might affect other apps

## The Story

This project was born from a real cleanup session that recovered **89 GB** of disk space:

- Started with 26 GB available, ended with 115 GB
- Found Google Chrome's `code_sign_clone` hiding 1.2 GB in `/private/var/folders/`
- Discovered CCleaner's 6 persistent daemons (the ultimate irony)
- Eliminated Adobe's telemetry network (agsservice, GC.Invoker, ARMDC)
- Cleaned JetBrains orphan data (2 GB from uninstalled PyCharm)
- Removed Discord, Figma, Warp orphaned data

All this knowledge is now encoded in this project.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Full Support | LaunchAgents, LaunchDaemons, var/folders |
| Linux | Full Support | XDG directories, systemd services |
| Windows | Full Support | AppData, Registry, Services |

## Usage Examples

### Find what's eating your disk
```
> /scan

📊 Disk Overview
Total: 500GB  Used: 450GB  Available: 50GB  (90% used)

📁 ~/Library Analysis (Top 15)
12G    Application Support
4.2G   Caches
2.1G   Containers
...
```

### Hunt zombie processes
```
> /parasites

🦠 KNOWN PARASITE: com.google.keystone.agent
   Google Keystone - Chrome updater (persists after Chrome removal)
   Location: ~/Library/LaunchAgents/
   Status: RUNNING

🦠 KNOWN PARASITE: com.adobe.agsservice
   Adobe Genuine Software - License check telemetry
   Location: /Library/LaunchDaemons/
   (Requires sudo to remove)
```

### Clean orphaned data
```
> /clean --dry-run

⚠️  DRY RUN MODE - No files will be deleted

Would remove: JetBrains PyCharm (2.1 GB)
Would remove: Discord data (259 MB)
Would remove: Figma cache (176 MB)

Run without --dry-run to actually clean.
```

## Contributing

Found a new parasite? Know a hidden location where apps dump data?

1. Add parasites to `knowledge/common-parasites.md`
2. Add hidden locations to `knowledge/hidden-locations/`
3. Submit a PR

## License

MIT License - Do whatever you want with it.

---

**Remember:** If your "cleaner" app needs 6 persistent daemons, it's not cleaning - it's infesting.

*Made with Claude Code - the AI that actually helps you clean.*
