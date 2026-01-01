# Agents Documentation

Specialized AI agents for different cleanup and analysis tasks.

## Table of Contents

- [Overview](#overview)
- [Storage Expert](#storage-expert)
- [Forensics Investigator](#forensics-investigator)
- [Cleanup Executor](#cleanup-executor)

---

## Overview

CClean-Killer uses specialized agents that Claude Code can invoke for complex tasks. Each agent has specific capabilities and use cases.

### When Agents Are Used

| Scenario | Agent |
|----------|-------|
| "Deep analysis of my storage" | Storage Expert |
| "Find all traces of Chrome" | Forensics Investigator |
| "Execute the cleanup plan" | Cleanup Executor |
| "What's eating my disk?" | Storage Expert |
| "Investigate suspicious process" | Forensics Investigator |

---

## Storage Expert

**Location:** `/agents/storage-expert.md`

A specialized agent for comprehensive storage analysis and optimization recommendations.

### Capabilities

1. **Multi-pass scanning** - Scans system at different depth levels
2. **Cross-referencing** - Matches app data with installed applications
3. **Historical analysis** - Compares with previous scans if available
4. **Intelligent recommendations** - Prioritizes cleanup by impact and safety

### When to Use

- User asks for "deep analysis" or "thorough scan"
- Storage situation is complex (many apps, unclear usage)
- Need to generate a comprehensive report
- Planning a major cleanup operation

### Analysis Protocol

**Phase 1: System Overview**
- Get total disk capacity and usage
- Identify OS and version
- Note special configurations (APFS, encryption)

**Phase 2: Directory Analysis**
- Scan all major directories
- Identify top 20 consumers
- Flag unusually large directories

**Phase 3: Application Audit**
- List all installed applications
- Find associated data for each app
- Calculate total footprint (app + data)

**Phase 4: Orphan Detection**
- Scan Application Support for orphans
- Check Containers and Group Containers
- Look for hidden dotfiles without apps

**Phase 5: Parasite Scan**
- List all LaunchAgents/Daemons
- Cross-reference with installed apps
- Flag zombies and telemetry

**Phase 6: Cache Analysis**
- System caches
- User caches
- Application caches
- Package manager caches

**Phase 7: Duplicate Detection**
- Find apps with overlapping functions
- Identify redundant data
- Note excessive daemon counts

### Output Format

```
# Storage Analysis Report

## Executive Summary
System has 228 GB total, 120 GB used (52%). Identified 25 GB of
recoverable space across caches, orphans, and parasites.

## Quick Wins (Est. 15 GB)
1. Docker unused images: 7 GB
2. npm/pnpm caches: 2 GB
3. Orphaned app data: 4 GB
4. Time Machine snapshots: 2 GB

## Detailed Findings
[...]

## Recommendations
| Priority | Action | Space | Risk | Command |
|----------|--------|-------|------|---------|
| 1 | Docker prune | 7 GB | Low | docker system prune -a |
| 2 | Remove orphans | 4 GB | Low | /clean --orphans |
```

### Integration

Uses all four skills:
- `system-scanner` for disk analysis
- `orphan-hunter` for orphan detection
- `parasite-killer` for daemon analysis
- `duplicate-finder` for app analysis

---

## Forensics Investigator

**Location:** `/agents/forensics.md`

A specialized agent for deep investigation of hidden data and persistence mechanisms.

### Capabilities

1. **Deep path investigation** - Searches obscure system locations
2. **Process analysis** - Examines running processes and their origins
3. **Persistence mapping** - Maps all persistence mechanisms
4. **Data trail tracking** - Follows app data across multiple locations

### When to Use

- User suspects an app left hidden data
- Need to understand app persistence mechanisms
- Investigating unusual disk usage
- "Forensic" cleanup after problematic app

### Investigation Protocol

**Phase 1: Process Investigation**
```bash
# List non-Apple processes
ps aux | grep -v "com.apple"

# Trace process to origin
lsof -c <process_name>
```

**Phase 2: Persistence Mapping**
- Enumerate user and system LaunchAgents
- Enumerate LaunchDaemons
- Check PrivilegedHelperTools
- Check Application Scripts
- Check Login Items
- Map each to parent app

**Phase 3: Hidden Location Search**
- `/private/var/folders` investigation
- Hidden files in home directory
- Application Scripts directories
- Group Containers

**Phase 4: Data Trail Analysis**

For a specific app, find ALL its data:
| Location | Path |
|----------|------|
| App bundle | `/Applications/<app>.app` |
| Application Support | `~/Library/Application Support/<app>` |
| Preferences | `~/Library/Preferences/com.<company>.<app>.plist` |
| Caches | `~/Library/Caches/com.<company>.<app>` |
| Containers | `~/Library/Containers/com.<company>.<app>` |
| Group Containers | `~/Library/Group Containers/*.<app>` |
| Logs | `~/Library/Logs/<app>` |
| Saved State | `~/Library/Saved Application State/*.savedState` |
| Cookies | `~/Library/Cookies/*.binarycookies` |
| WebKit | `~/Library/WebKit/com.<company>.<app>` |
| HTTPStorages | `~/Library/HTTPStorages/com.<company>.<app>` |
| var/folders | `/private/var/folders/*/*/com.<company>.<app>*` |

**Phase 5: Network Analysis**
```bash
# Check for network connections
lsof -i -n | grep <app>
```

### Output Format

```
# Forensics Report: Google Chrome

## Summary
Chrome has embedded itself in 12 locations across the system.

## Persistence Mechanisms
| Type | Location | Status |
|------|----------|--------|
| LaunchAgent | ~/Library/LaunchAgents/com.google.keystone.agent.plist | Active |
| Helper | /Library/PrivilegedHelperTools/com.google.keystone.updater | Present |

## Data Locations Found
| Location | Size | Purpose |
|----------|------|---------|
| ~/Library/Application Support/Google/Chrome | 2.1 GB | Profile data |
| /private/var/folders/.../X/com.google.Chrome.code_sign_clone | 1.2 GB | Code signing |

## Complete Removal Commands
[Generated removal script]
```

### Use Cases

1. **Post-Chrome removal** - Find all Google remnants
2. **Adobe investigation** - Map entire Adobe footprint
3. **Suspicious process** - Trace unknown process to source
4. **Complete app removal** - Generate exhaustive removal script

---

## Cleanup Executor

**Location:** `/agents/cleanup-executor.md`

A specialized agent for safely executing cleanup operations with validation and rollback support.

### Capabilities

1. **Pre-flight validation** - Verifies targets exist and are safe to remove
2. **Backup creation** - Creates backups of important files before removal
3. **Staged execution** - Runs cleanup in stages with verification
4. **Rollback support** - Can undo operations if something goes wrong
5. **Post-cleanup verification** - Confirms cleanup was successful

### When to Use

- User has reviewed a report and wants to proceed
- Need to execute multiple cleanup operations
- Want safe, logged cleanup with backup
- Running cleanup in batches

### Execution Protocol

**Pre-Flight Checks**

Before ANY deletion:
```bash
preflight_check() {
  local target="$1"

  # Exists?
  [[ -e "$target" ]] || return 1

  # In use?
  lsof "$target" &>/dev/null && return 1

  # System file?
  [[ "$target" == /System/* ]] && return 1
  [[ "$target" == /usr/* ]] && return 1

  # Permission?
  [[ -w "$(dirname "$target")" ]] || return 1

  return 0
}
```

**Backup Strategy**

For important files (LaunchDaemons, preferences):
```bash
BACKUP_DIR="$HOME/.cclean-killer/backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -p "$file" "$BACKUP_DIR/$relative_path"
```

**Execution Stages**

| Stage | Category | Risk Level |
|-------|----------|------------|
| 1 | Caches | Always Safe |
| 2 | Package Manager Cleanup | Safe |
| 3 | Orphaned App Data | Safe (verified) |
| 4 | LaunchAgents | Backup Required |
| 5 | LaunchDaemons | Backup + Sudo Required |

### Output Format

```
# Cleanup Execution Report

## Pre-Flight Summary
- Targets validated: 15
- Targets skipped: 2 (in use)
- Backup location: ~/.cclean-killer/backup/20241221-120000

## Execution Log

### Stage 1: Caches
[OK] Removed ~/Library/Caches/Homebrew/downloads (200 MB)
[OK] Removed ~/.npm/_cacache (500 MB)

### Stage 2: Package Managers
[OK] npm cache clean (freed 100 MB)
[OK] brew cleanup (freed 50 MB)

### Stage 3: Orphans
[OK] Removed ~/Library/Application Support/Discord (259 MB)
[SKIP] ~/Library/Application Support/Slack (in use)

### Stage 4: LaunchAgents
[OK] Unloaded and removed com.google.keystone.agent.plist
[OK] Unloaded and removed com.adobe.GC.Invoker.plist

## Results
- Space freed: 2.5 GB
- Files removed: 1,234
- Directories removed: 45
- Backup size: 15 MB

## Rollback Command (if needed)
~/.cclean-killer/rollback.sh 20241221-120000
```

### Safety Rules

1. **NEVER** delete without pre-flight check
2. **ALWAYS** backup LaunchDaemons/Agents
3. **ALWAYS** unload before removing plists
4. **NEVER** use `rm -rf /` patterns
5. **LOG** every operation
6. **VERIFY** after each deletion
7. **STOP** if multiple failures occur

---

## Agent Invocation

Agents are automatically selected based on user intent:

| User Request | Agent Selected |
|--------------|----------------|
| "Scan my system" | Storage Expert |
| "Find what's using space" | Storage Expert |
| "Investigate [app name]" | Forensics Investigator |
| "Find all traces of..." | Forensics Investigator |
| "Clean up now" | Cleanup Executor |
| "Execute the recommendations" | Cleanup Executor |
