# Adding Platform Support

Guide for adding support for a new operating system to CClean-Killer.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Required Components](#required-components)
- [Step-by-Step Guide](#step-by-step-guide)
- [Platform-Specific Considerations](#platform-specific-considerations)
- [Testing](#testing)

---

## Prerequisites

Before adding a new platform, understand:

1. **File system hierarchy** - Where apps store data
2. **Persistence mechanisms** - How services auto-start
3. **Package management** - How software is installed/removed
4. **User permissions** - What requires elevated access
5. **Shell environment** - Available scripting languages

---

## Required Components

Adding a platform requires these files:

```
scripts/
  [platform]/
    scan.sh          # Disk analysis script
    clean.sh         # Cleanup script
    find-orphans.sh  # (optional) Orphan detection
    find-parasites.sh # (optional) Parasite detection

knowledge/
  hidden-locations/
    [platform].md    # Data location documentation
```

Plus updates to:
- `skills/*.md` - Platform detection and paths
- `README.md` - Platform support table
- `.claude/commands/*.md` - Platform-specific instructions

---

## Step-by-Step Guide

### Step 1: Create Hidden Locations Documentation

**File:** `knowledge/hidden-locations/[platform].md`

```markdown
# Hidden Data Locations: [Platform]

A comprehensive guide to where applications hide data on [Platform] systems.

## Overview

Brief description of platform's file system philosophy.

## User Data Locations

### Primary Locations
| Location | Purpose | Typical Size |
|----------|---------|--------------|
| `~/path/to/config` | Configuration | varies |
| `~/path/to/data` | App data | varies |
| `~/path/to/cache` | Cache | varies |

## System Locations

### System-Wide App Data
| Location | Purpose | Requires Root? |
|----------|---------|----------------|
| `/path/to/system/data` | System apps | Yes |

## Persistence Mechanisms

### [Service System Name]
```
/path/to/service/files
```

How to list services:
```bash
command-to-list-services
```

## Package Manager Caches

### [Package Manager Name]
```bash
# Location
/path/to/cache

# Cleanup command
package-manager clean-cache
```

## Safety Rules

1. **NEVER** delete [critical path]
2. **BACKUP** before deleting [important path]
```

### Step 2: Create Scan Script

**File:** `scripts/[platform]/scan.sh`

```bash
#!/bin/bash
# CClean-Killer - [Platform] System Scanner
# Analyzes disk usage

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}+==========================================+${NC}"
echo -e "${BLUE}|    CClean-Killer - [Platform] Scanner   |${NC}"
echo -e "${BLUE}+==========================================+${NC}"
echo ""

# Disk Overview
echo -e "${GREEN}Disk Overview${NC}"
echo "--------------------------------------------"
df -h / | tail -1 | awk '{print "Total: "$2"  Used: "$3"  Available: "$4"  ("$5" used)"}'
echo ""

# User directories
echo -e "${GREEN}User Data Directories${NC}"
echo "--------------------------------------------"
du -sh ~/path/to/data/*/ 2>/dev/null | sort -hr | head -15
echo ""

# Cache directories
echo -e "${GREEN}Cache Directories${NC}"
echo "--------------------------------------------"
du -sh ~/path/to/cache/*/ 2>/dev/null | sort -hr | head -10
echo ""

# Developer tools (common across platforms)
echo -e "${GREEN}Developer Tools${NC}"
echo "--------------------------------------------"
echo -n "npm:    "; du -sh ~/.npm 2>/dev/null | cut -f1 || echo "Not found"
echo -n "Cargo:  "; du -sh ~/.cargo 2>/dev/null | cut -f1 || echo "Not found"
echo ""

# Package manager cache (platform-specific)
echo -e "${GREEN}Package Manager${NC}"
echo "--------------------------------------------"
# Add platform-specific package manager cache check
echo ""

# Summary
echo -e "${BLUE}============================================${NC}"
echo "  ./clean.sh --all  to clean everything"
echo -e "${BLUE}============================================${NC}"
```

### Step 3: Create Clean Script

**File:** `scripts/[platform]/clean.sh`

```bash
#!/bin/bash
# CClean-Killer - [Platform] Cleanup Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
DRY_RUN=false
CLEAN_CACHES=false
CLEAN_DEV=false
CLEAN_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --caches) CLEAN_CACHES=true; shift ;;
        --dev) CLEAN_DEV=true; shift ;;
        --all) CLEAN_ALL=true; shift ;;
        *)
            echo "Usage: $0 [--dry-run] [--caches] [--dev] [--all]"
            exit 1
            ;;
    esac
done

# Default to all if nothing specified
if ! $CLEAN_CACHES && ! $CLEAN_DEV; then
    CLEAN_ALL=true
fi

if $CLEAN_ALL; then
    CLEAN_CACHES=true
    CLEAN_DEV=true
fi

echo -e "${BLUE}+==========================================+${NC}"
echo -e "${BLUE}|   CClean-Killer - [Platform] Cleanup    |${NC}"
echo -e "${BLUE}+==========================================+${NC}"
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}DRY RUN MODE - No files will be deleted${NC}"
    echo ""
fi

total_freed=0

format_size() {
    local kb=$1
    if [ $kb -gt 1048576 ]; then
        echo "$(echo "scale=2; $kb/1048576" | bc) GB"
    elif [ $kb -gt 1024 ]; then
        echo "$(echo "scale=2; $kb/1024" | bc) MB"
    else
        echo "${kb} KB"
    fi
}

safe_remove() {
    local path="$1"
    local desc="$2"

    if [ -e "$path" ]; then
        local size=$(du -sk "$path" 2>/dev/null | cut -f1 || echo "0")
        local size_formatted=$(format_size $size)

        if $DRY_RUN; then
            echo -e "${YELLOW}Would remove:${NC} $desc ($size_formatted)"
        else
            echo -e "${GREEN}Removing:${NC} $desc ($size_formatted)"
            rm -rf "$path"
            total_freed=$((total_freed + size))
        fi
    fi
}

# Cache cleanup
if $CLEAN_CACHES; then
    echo -e "${GREEN}Cleaning Caches...${NC}"
    echo "--------------------------------------------"

    # Platform-specific cache paths
    for cache in ~/path/to/cache/*/; do
        if [ -d "$cache" ]; then
            name=$(basename "$cache")
            # Skip critical caches
            if [[ "$name" != "critical-cache" ]]; then
                safe_remove "$cache" "Cache: $name"
            fi
        fi
    done
    echo ""
fi

# Developer tools cleanup
if $CLEAN_DEV; then
    echo -e "${GREEN}Cleaning Developer Caches...${NC}"
    echo "--------------------------------------------"

    # npm cache (cross-platform)
    if command -v npm &> /dev/null; then
        if $DRY_RUN; then
            echo -e "${YELLOW}Would run:${NC} npm cache clean --force"
        else
            npm cache clean --force 2>/dev/null || true
        fi
    fi
    safe_remove ~/.npm/_cacache "npm cache"

    # Platform-specific package manager cleanup
    # ...

    echo ""
fi

# Summary
echo -e "${BLUE}============================================${NC}"
if $DRY_RUN; then
    echo -e "${BLUE}Dry run complete. No files deleted.${NC}"
else
    echo -e "${BLUE}Cleanup complete!${NC}"
    echo -e "${BLUE}Total freed: $(format_size $total_freed)${NC}"
fi
echo -e "${BLUE}============================================${NC}"
```

### Step 4: Update Skills

Add platform detection and paths to each skill file.

**Example in `skills/system-scanner.md`:**

```markdown
### [Platform]
```bash
[PLATFORM]_PATHS=(
  "~/path/to/data"
  "~/path/to/cache"
  "~/path/to/config"
  "/system/path/if/applicable"
)
```
```

### Step 5: Update Commands

Add platform-specific instructions to command files.

**Example in `.claude/commands/scan.md`:**

```markdown
#### [Platform]
```bash
# Primary directories
du -sh ~/data/* 2>/dev/null | sort -hr | head -20

# Cache directories
du -sh ~/cache/* 2>/dev/null | sort -hr | head -15
```
```

### Step 6: Update README

Add platform to the support table:

```markdown
| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Full Support | ... |
| Linux | Full Support | ... |
| Windows | Full Support | ... |
| [New Platform] | Full Support | [Notes] |
```

---

## Platform-Specific Considerations

### BSD/FreeBSD

- Uses ports tree instead of apt/dnf
- `/usr/local/` for third-party software
- rc.d for services instead of systemd
- Different flag syntax for some commands

### ChromeOS (Linux mode)

- Limited file system access
- Containers for Linux apps
- Specific paths for Android apps

### WSL (Windows Subsystem for Linux)

- Access to Windows paths via `/mnt/c/`
- Mixed Linux and Windows applications
- Interop considerations

---

## Testing

### 1. Test Scan Script

```bash
# Should complete without errors
./scripts/[platform]/scan.sh

# Verify output formatting
# Verify paths are correct for platform
```

### 2. Test Clean Script (Dry Run)

```bash
# Always test dry-run first!
./scripts/[platform]/clean.sh --dry-run

# Verify paths are correct
# Verify critical paths are skipped
```

### 3. Test Clean Script (Actual)

On a test system or VM:

```bash
# Create some test files
mkdir -p ~/path/to/cache/test-app
echo "test" > ~/path/to/cache/test-app/file.txt

# Run cleanup
./scripts/[platform]/clean.sh --caches

# Verify test files removed
ls ~/path/to/cache/test-app  # Should fail/not exist
```

### 4. Test Integration

```bash
# Open project in Claude Code
claude .

# Test commands work
/scan
/clean --dry-run
```

---

## Submission Checklist

Before submitting a PR:

- [ ] Hidden locations documented
- [ ] Scan script works on target platform
- [ ] Clean script works (dry-run tested)
- [ ] Skills updated with platform paths
- [ ] Commands updated with platform instructions
- [ ] README updated with platform status
- [ ] Tested on actual platform (not just written)
- [ ] Safety rules enforced (critical paths protected)
