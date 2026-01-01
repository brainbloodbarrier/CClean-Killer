# System Architecture

Technical overview of CClean-Killer's design and components.

## Table of Contents

- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Component Design](#component-design)
- [Data Flow](#data-flow)
- [Platform Abstraction](#platform-abstraction)

---

## Overview

CClean-Killer is a Claude Code project that uses a modular architecture:

- **Commands** - User-facing slash commands
- **Skills** - Reusable capabilities
- **Agents** - Complex task orchestration
- **Scripts** - Platform-specific implementations
- **Knowledge** - Database of parasites and safe locations

### Design Principles

1. **Zero Persistence** - No daemons, no background processes
2. **Transparency** - Every action is logged and explained
3. **Safety First** - Never delete without confirmation
4. **Platform Agnostic** - Works on macOS, Linux, and Windows
5. **Modular** - Components can be used independently

---

## Architecture Diagram

```
                    +------------------+
                    |     User CLI     |
                    |   claude code    |
                    +--------+---------+
                             |
                             v
+----------------+  +--------+---------+  +----------------+
|   Commands     |  |    CLAUDE.md     |  |   Knowledge    |
| /scan          |<-|  Configuration   |->| parasites.md   |
| /parasites     |  |   & Rules        |  | safe-remove.md |
| /clean         |  +------------------+  | locations/*.md |
| /report        |                        +----------------+
+-------+--------+
        |
        v
+-------+--------+
|     Skills     |
| system-scanner |
| orphan-hunter  |
| parasite-kill  |
| duplicate-find |
+-------+--------+
        |
        v
+-------+--------+
|     Agents     |
| storage-expert |
| forensics      |
| cleanup-exec   |
+-------+--------+
        |
        v
+-------+--------+      +----------------+
|    Scripts     |----->|   File System  |
| macos/*.sh     |      | Disk Analysis  |
| linux/*.sh     |      | Process Mgmt   |
| windows/*.ps1  |      | Safe Cleanup   |
+----------------+      +----------------+
```

---

## Component Design

### Commands Layer

Commands are the user-facing interface defined in `.claude/commands/`.

```
.claude/commands/
  scan.md       # /scan command definition
  parasites.md  # /parasites command definition
  clean.md      # /clean command definition
  report.md     # /report command definition
```

Each command file contains:
- Usage syntax
- Detailed instructions for Claude
- Platform-specific steps
- Output format requirements
- Safety rules

### Skills Layer

Skills provide reusable functionality that commands and agents use.

```
skills/
  system-scanner.md    # Disk analysis capability
  orphan-hunter.md     # Orphan detection capability
  parasite-killer.md   # Daemon analysis capability
  duplicate-finder.md  # App duplication detection
```

Skills define:
- Trigger phrases (when to use)
- Platform-specific implementations
- Output formats
- Safety considerations

### Agents Layer

Agents orchestrate complex multi-step operations.

```
agents/
  storage-expert.md    # Comprehensive storage analysis
  forensics.md         # Deep investigation
  cleanup-executor.md  # Safe execution with rollback
```

Agents provide:
- Multi-phase protocols
- Cross-referencing logic
- Report generation
- Safety enforcement

### Scripts Layer

Platform-specific shell implementations.

```
scripts/
  macos/
    scan.sh            # macOS disk scanner
    find-parasites.sh  # LaunchAgent/Daemon finder
    find-orphans.sh    # Orphan detector
    clean.sh           # Safe cleanup
  linux/
    scan.sh            # Linux disk scanner
    clean.sh           # Safe cleanup
  windows/
    scan.ps1           # PowerShell scanner
    clean.ps1          # PowerShell cleanup
```

### Knowledge Layer

Reference data for parasite detection and safety.

```
knowledge/
  common-parasites.md  # Known parasites database
  safe-to-remove.md    # Safety tier guide
  hidden-locations/
    macos.md           # macOS hidden paths
    linux.md           # Linux hidden paths
    windows.md         # Windows hidden paths
```

---

## Data Flow

### Scan Flow

```
User: /scan
    |
    v
Command: scan.md
    |
    +-- Detect platform
    |
    v
Skill: system-scanner
    |
    +-- Run platform script
    +-- Collect disk usage
    +-- Identify large dirs
    |
    v
Output: Formatted tables
```

### Parasite Flow

```
User: /parasites
    |
    v
Command: parasites.md
    |
    +-- Enumerate persistence locations
    |
    v
Skill: parasite-killer
    |
    +-- Cross-reference with Knowledge
    +-- Check if apps installed
    +-- Classify (KNOWN, ZOMBIE, ACTIVE)
    |
    v
Output: Parasite report
```

### Cleanup Flow

```
User: /clean
    |
    v
Command: clean.md
    |
    +-- Detect platform
    +-- Determine targets
    |
    v
Agent: cleanup-executor
    |
    +-- Pre-flight checks
    +-- Create backups
    +-- Execute staged cleanup
    +-- Verify results
    |
    v
Output: Cleanup report
```

---

## Platform Abstraction

### Platform Detection

```bash
# Used by all scripts
case "$(uname -s)" in
  Darwin)  PLATFORM="macos" ;;
  Linux)   PLATFORM="linux" ;;
  MINGW*|CYGWIN*|MSYS*) PLATFORM="windows" ;;
  *)       PLATFORM="unknown" ;;
esac
```

### Path Mappings

| Concept | macOS | Linux | Windows |
|---------|-------|-------|---------|
| User Config | `~/Library/Preferences` | `~/.config` | `%APPDATA%` |
| App Data | `~/Library/Application Support` | `~/.local/share` | `%LOCALAPPDATA%` |
| Cache | `~/Library/Caches` | `~/.cache` | `%TEMP%` |
| Startup | `~/Library/LaunchAgents` | `~/.config/autostart` | Startup folder |
| System Services | `/Library/LaunchDaemons` | systemd | Services |

### Command Equivalents

| Operation | macOS/Linux | Windows |
|-----------|-------------|---------|
| Directory size | `du -sh` | `Get-ChildItem` + `Measure-Object` |
| Process list | `ps aux` | `Get-Process` |
| Find files | `find` | `Get-ChildItem -Recurse` |
| Remove files | `rm -rf` | `Remove-Item -Recurse -Force` |

---

## Safety Architecture

### Defense in Depth

```
Layer 1: Command Definition
  - Safety rules documented
  - Dry-run emphasis

Layer 2: Skill Implementation
  - Skip system directories
  - Skip critical user data

Layer 3: Script Execution
  - Pre-flight checks
  - Permission validation
  - Error handling

Layer 4: Cleanup Executor
  - Backup before delete
  - Staged execution
  - Rollback support
```

### Protected Paths

**Never Touch:**
- `/System/` (macOS)
- `C:\Windows\System32\` (Windows)
- `~/.ssh/`
- `~/.gnupg/`
- Keychains

**Require Confirmation:**
- `/Library/` (macOS)
- `C:\ProgramData\` (Windows)
- LaunchDaemons
- Registry entries

**Always Safe:**
- Cache directories
- Temp files
- Package manager caches
- Trash

---

## Extension Points

### Adding New Commands

1. Create `.claude/commands/newcommand.md`
2. Define usage, instructions, and output format
3. Reference appropriate skills

### Adding New Skills

1. Create `skills/new-skill.md`
2. Define triggers and implementation
3. Document platform-specific behavior

### Adding New Parasites

1. Edit `knowledge/common-parasites.md`
2. Add pattern, description, and removal commands
3. Update scripts with new patterns

### Adding Platform Support

1. Create new directory under `scripts/`
2. Implement scan and clean scripts
3. Add hidden locations doc under `knowledge/hidden-locations/`
4. Update platform detection in existing docs
