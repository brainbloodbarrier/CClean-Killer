# Contributing Guide

Guidelines for contributing to CClean-Killer.

## Table of Contents

- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Contribution Types](#contribution-types)
- [Style Guidelines](#style-guidelines)
- [Pull Request Process](#pull-request-process)

---

## Getting Started

### Prerequisites

- Git
- Claude Code CLI (`claude`)
- Basic shell scripting knowledge
- Familiarity with your platform's cleanup mechanisms

### Setup

```bash
# Clone the repository
git clone https://github.com/brainbloodbarrier/CClean-Killer.git
cd CClean-Killer

# Open with Claude Code
claude .
```

### Running Locally

```bash
# Test the scan command
/scan

# Test parasite detection (dry run)
/parasites

# Test cleanup (always use dry-run first!)
/clean --dry-run
```

---

## Project Structure

```
CClean-Killer/
+-- .claude/
|   +-- commands/           # Slash command definitions
|   |   +-- scan.md
|   |   +-- parasites.md
|   |   +-- clean.md
|   |   +-- report.md
|   +-- settings.json       # Project configuration
|
+-- skills/                 # Reusable skill definitions
|   +-- system-scanner.md
|   +-- orphan-hunter.md
|   +-- parasite-killer.md
|   +-- duplicate-finder.md
|
+-- agents/                 # Complex task agents
|   +-- storage-expert.md
|   +-- forensics.md
|   +-- cleanup-executor.md
|
+-- scripts/                # Platform-specific scripts
|   +-- macos/
|   +-- linux/
|   +-- windows/
|
+-- knowledge/              # Reference data
|   +-- common-parasites.md
|   +-- safe-to-remove.md
|   +-- hidden-locations/
|
+-- docs/                   # Documentation
|   +-- api/
|   +-- dev/
|   +-- user/
|
+-- README.md
+-- LICENSE
+-- CLAUDE.md               # Claude Code configuration
```

---

## Contribution Types

### 1. Add a New Parasite

Found a new app that leaves zombies? Add it to the database!

**File:** `knowledge/common-parasites.md`

```markdown
### [App Name]

**What it is:** Description of the app and its parasites.

**Files:**
```
Location 1
Location 2
```

**Behavior:**
- What the parasites do
- Why they're problematic

**Removal:**
```bash
# Commands to remove
```
```

### 2. Add a Hidden Location

Discovered where an app hides data?

**File:** `knowledge/hidden-locations/[platform].md`

Add a new section with:
- Path(s)
- What's stored there
- Size expectations
- Cleanup commands

### 3. Improve Detection Logic

**Files:** `skills/orphan-hunter.md`, `scripts/[platform]/find-orphans.sh`

Enhance:
- App name extraction from bundle IDs
- Cross-referencing with installed apps
- Confidence level assessment

### 4. Add Platform Support

Adding a new platform (e.g., FreeBSD)?

1. Create `scripts/[platform]/scan.sh`
2. Create `scripts/[platform]/clean.sh`
3. Create `knowledge/hidden-locations/[platform].md`
4. Update skills with platform detection

### 5. Improve Documentation

- Fix typos and clarify instructions
- Add examples
- Improve formatting

---

## Style Guidelines

### Markdown Files

```markdown
# Heading 1 (file title only)

Description paragraph.

## Heading 2 (major sections)

### Heading 3 (subsections)

**Bold** for emphasis
`code` for commands and paths
```

### Shell Scripts

```bash
#!/bin/bash
# Description of script
# Usage: script.sh [options]

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Constants in UPPERCASE
BACKUP_DIR="$HOME/.cclean-killer/backup"

# Functions in lowercase_with_underscores
check_prerequisites() {
  # Implementation
}

# Main logic at bottom
main() {
  check_prerequisites
  # ...
}

main "$@"
```

### PowerShell Scripts

```powershell
# Description of script
# Usage: script.ps1 [-Option]

param(
    [switch]$DryRun,
    [switch]$Verbose
)

# Functions in PascalCase
function Get-FolderSize {
    param([string]$Path)
    # Implementation
}

# Main execution at bottom
```

### Documentation Standards

1. **Headers**: Use sentence case (not Title Case)
2. **Code blocks**: Always specify language
3. **Tables**: Align columns for readability
4. **Links**: Use relative paths within project
5. **Lists**: Use `-` for unordered, numbers for ordered

---

## Pull Request Process

### Before Submitting

1. **Test your changes**
   ```bash
   # Test on your platform
   /scan
   /parasites
   /clean --dry-run
   ```

2. **Check documentation**
   - Update relevant docs
   - Add examples if appropriate

3. **Format code**
   - Shell scripts pass shellcheck (if applicable)
   - Markdown is properly formatted

### PR Template

```markdown
## Description

Brief description of changes.

## Type of Change

- [ ] New parasite added
- [ ] New hidden location documented
- [ ] Bug fix
- [ ] Feature enhancement
- [ ] Documentation improvement

## Testing

How did you test this?

- [ ] Tested on macOS
- [ ] Tested on Linux
- [ ] Tested on Windows

## Checklist

- [ ] I've read CONTRIBUTING.md
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] No secrets or personal paths included
```

### Review Process

1. Submit PR against `main` branch
2. Maintainer reviews for:
   - Correctness
   - Safety (no destructive operations without confirmation)
   - Style consistency
   - Documentation quality
3. Address feedback
4. Merge upon approval

---

## Safety Considerations

When contributing cleanup logic:

### Always

- Support `--dry-run` mode
- Log operations
- Verify targets exist before deletion
- Check if files are in use

### Never

- Delete system directories
- Use `rm -rf /` patterns
- Auto-delete without user confirmation
- Store or log sensitive user data

### Require Extra Caution

- System LaunchDaemons (need sudo)
- Registry modifications
- Anything in `/Library/` or `C:\Windows\`

---

## Questions?

- Open an issue for discussion
- Check existing issues first
- Be specific about the platform and scenario

Thank you for contributing to CClean-Killer!
