# /clean - Safe Cleanup Executor

Remove orphaned application data, caches, and leftovers safely.

## Usage

```
/clean              # Interactive cleanup
/clean --dry-run    # Show what would be removed without removing
/clean --caches     # Only clean caches
/clean --orphans    # Only clean orphaned app data
/clean --all        # Clean everything safe
```

## Instructions

When the user runs /clean, perform the following:

### 1. Detect Platform

```bash
OS=$(uname -s)
case $OS in
  Darwin) echo "macOS" ;;
  Linux)  echo "Linux" ;;
  *)      echo "Unsupported" ;;
esac
```

### 2. Define Safe Cleanup Targets

#### Always Safe to Remove (Caches)

##### macOS
```bash
# User caches
~/Library/Caches/*

# Homebrew downloads
~/Library/Caches/Homebrew/downloads/*

# npm cache
~/.npm/_cacache

# pnpm store (prune, don't delete)
# pnpm store prune
```

##### Linux
```bash
~/.cache/*
```

#### Orphan Detection

For each directory in Application Support, check if app exists:

```bash
# macOS
for dir in ~/Library/Application\ Support/*/; do
  app_name=$(basename "$dir")
  # Check if corresponding app exists
  if ! ls /Applications/*"$app_name"* &>/dev/null; then
    echo "ORPHAN: $dir"
  fi
done
```

### 3. Known Safe Removals

These are ALWAYS safe to remove:

| Location | Description | Command |
|----------|-------------|---------|
| `~/Library/Caches/Homebrew/downloads/*` | Homebrew downloads | `rm -rf` |
| `~/.npm/_cacache` | npm cache | `npm cache clean --force` |
| `~/Library/Application Support/Code/CachedExtensionVSIXs/*` | VS Code cached extensions | `rm -rf` |
| `~/Library/Application Support/Cursor/CachedExtensionVSIXs/*` | Cursor cached extensions | `rm -rf` |
| `~/Downloads/*.dmg` | Old disk images | `rm -f` |
| `~/.Trash/*` | Trash | `rm -rf` |

### 4. Interactive Confirmation

For each category, show:

```
=== Caches (1.2 GB) ===
- Homebrew downloads: 200 MB
- npm cache: 500 MB
- VS Code extensions cache: 500 MB

Remove? [y/N/select]:
```

### 5. Cleanup Execution

```bash
# Package managers
npm cache clean --force 2>/dev/null
pnpm store prune 2>/dev/null
brew cleanup --prune=all 2>/dev/null
brew autoremove 2>/dev/null

# IDE caches
rm -rf ~/Library/Application\ Support/Code/CachedExtensionVSIXs/* 2>/dev/null
rm -rf ~/Library/Application\ Support/Cursor/CachedExtensionVSIXs/* 2>/dev/null

# Docker (if user confirms)
docker image prune -f 2>/dev/null
docker volume prune -f 2>/dev/null
docker builder prune -f 2>/dev/null
```

### 6. Post-Cleanup Report

Show before/after disk usage:

```
=== Cleanup Complete ===

Before: 26 GB available
After:  45 GB available
Freed:  19 GB

Breakdown:
- Caches: 5 GB
- Docker: 10 GB
- Orphans: 4 GB
```

## Dry Run Mode

When `--dry-run` is specified, only output what WOULD be removed:

```
[DRY RUN] Would remove:
- ~/Library/Caches/Homebrew/downloads/* (200 MB)
- ~/.npm/_cacache (500 MB)
- ~/Library/Application Support/Discord (orphan, 259 MB)

Total: 959 MB would be freed
```

## Safety Rules

1. NEVER delete anything without confirmation (unless --yes flag)
2. ALWAYS check if app is still installed before removing its data
3. NEVER touch system directories
4. Log all deletions to ~/.cclean-killer/cleanup.log
