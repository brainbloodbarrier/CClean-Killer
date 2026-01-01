# Getting Started

Quick start guide to using CClean-Killer for system cleanup.

## Table of Contents

- [What is CClean-Killer?](#what-is-cclean-killer)
- [Installation](#installation)
- [Your First Scan](#your-first-scan)
- [Understanding Results](#understanding-results)
- [Safe Cleanup](#safe-cleanup)
- [Next Steps](#next-steps)

---

## What is CClean-Killer?

CClean-Killer is a system cleanup tool built on Claude Code. Unlike traditional cleanup tools that install persistent background processes, CClean-Killer:

- **Runs only when you ask** - No daemons, no services
- **Is completely transparent** - See exactly what it finds and does
- **Never deletes without permission** - Always confirms before removing
- **Explains everything** - Understand what's using your disk

### The Irony

The project was inspired by discovering that CCleaner - a "cleaner" app - installs 6 persistent background daemons on macOS. CClean-Killer shows you these parasites and helps remove them.

---

## Installation

### Prerequisites

- [Claude Code](https://claude.ai/claude-code) CLI installed
- macOS, Linux, or Windows
- Terminal access

### Setup

```bash
# Clone the repository
git clone https://github.com/brainbloodbarrier/CClean-Killer.git
cd CClean-Killer

# Open with Claude Code
claude .
```

That's it! No installation, no configuration, no background processes.

---

## Your First Scan

Once you have the project open in Claude Code, type:

```
/scan
```

This analyzes your disk usage without making any changes.

### What You'll See

```
Disk Overview
Total: 500GB  Used: 450GB  Available: 50GB  (90% used)

~/Library Analysis (Top 15)
12G    Application Support
4.2G   Caches
2.1G   Containers
...

Application Support (Top 15)
2.1G   JetBrains
1.8G   Google
1.2G   Docker
...

Developer Caches
npm cache:     500 MB
Homebrew:      1.2 GB
...
```

### Scan Options

| Command | Description |
|---------|-------------|
| `/scan` | Full system scan |
| `/scan --quick` | Top-level directories only |
| `/scan --deep` | Include hidden system locations |

---

## Understanding Results

### Size Indicators

| Size | Concern Level |
|------|---------------|
| < 100 MB | Normal |
| 100 MB - 1 GB | Worth checking |
| 1 GB - 10 GB | Consider cleaning |
| > 10 GB | High priority |

### Common Large Directories

| Directory | What It Is | Safe to Clean? |
|-----------|------------|----------------|
| `Application Support` | App databases and settings | Only orphans |
| `Caches` | Temporary cached data | Yes |
| `Containers` | Sandboxed app data | Only orphans |
| `Docker` | Container images/volumes | If unused |
| `.npm` | npm package cache | Yes |

---

## Safe Cleanup

### Step 1: Hunt for Parasites

```
/parasites
```

This finds zombie processes - background services from apps you've uninstalled.

**Example output:**
```
KNOWN PARASITE: com.google.keystone.agent
   Google Keystone - Chrome updater (persists after Chrome removal)
   Status: RUNNING

KNOWN PARASITE: com.adobe.agsservice
   Adobe Genuine Software - License check telemetry
   (Requires sudo to remove)
```

### Step 2: Preview Cleanup

**Always use dry-run first!**

```
/clean --dry-run
```

This shows what WOULD be removed without actually deleting anything:

```
[DRY RUN] Would remove:
- ~/Library/Caches/Homebrew/downloads/* (200 MB)
- ~/.npm/_cacache (500 MB)
- ~/Library/Application Support/Discord (orphan, 259 MB)

Total: 959 MB would be freed
```

### Step 3: Execute Cleanup

If you're happy with the preview:

```
/clean
```

Or clean specific categories:

| Command | What It Cleans |
|---------|----------------|
| `/clean --caches` | Only cache directories |
| `/clean --orphans` | Only orphaned app data |
| `/clean --dev` | Only developer tool caches |
| `/clean --all` | Everything safe |

### Step 4: Generate Report

For a complete analysis:

```
/report
```

This creates a comprehensive report with prioritized recommendations.

---

## Next Steps

### Regular Maintenance

Run these periodically:

| Frequency | Command | Purpose |
|-----------|---------|---------|
| Weekly | `/scan --quick` | Quick health check |
| Monthly | `/parasites` | Find new zombies |
| Quarterly | `/clean --dry-run` | Review cleanup opportunities |

### Learn More

- [Command Reference](commands.md) - All commands in detail
- [Safety Guidelines](safety.md) - What's safe to delete
- [Troubleshooting](troubleshooting.md) - Common issues

### Contributing

Found a new parasite? Know a hidden location where apps dump data?

1. Edit `knowledge/common-parasites.md`
2. Add hidden locations to `knowledge/hidden-locations/`
3. Submit a pull request

---

## Quick Reference

| Task | Command |
|------|---------|
| See disk usage | `/scan` |
| Find zombie processes | `/parasites` |
| Preview cleanup | `/clean --dry-run` |
| Execute cleanup | `/clean` |
| Full report | `/report` |

---

**Remember:** If your "cleaner" app needs 6 persistent daemons, it's not cleaning - it's infesting.
