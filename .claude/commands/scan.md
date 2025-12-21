# /scan - System Storage Scanner

Perform a comprehensive scan of your system to identify storage usage, large files, and potential cleanup opportunities.

## Usage

```
/scan              # Full system scan
/scan --quick      # Quick scan (top-level only)
/scan --deep       # Deep scan including hidden locations
```

## Instructions

When the user runs /scan, perform the following analysis:

### 1. Detect Operating System
```bash
uname -s  # Darwin = macOS, Linux = Linux
```

### 2. Check Overall Disk Usage
```bash
df -h /
```

### 3. Scan User Directories (Platform-Specific)

#### macOS
```bash
# Top-level usage
du -sh ~/* 2>/dev/null | sort -hr | head -20

# Library breakdown
du -sh ~/Library/* 2>/dev/null | sort -hr | head -20

# Application Support details
du -sh ~/Library/Application\ Support/* 2>/dev/null | sort -hr | head -25

# Caches
du -sh ~/Library/Caches/* 2>/dev/null | sort -hr | head -15

# Containers
du -sh ~/Library/Containers/* 2>/dev/null | sort -hr | head -15

# Group Containers
du -sh ~/Library/Group\ Containers/* 2>/dev/null | sort -hr | head -15

# Hidden dotfiles
du -sh ~/.[!.]* 2>/dev/null | sort -hr | head -15
```

#### Linux
```bash
du -sh ~/* 2>/dev/null | sort -hr | head -20
du -sh ~/.local/share/* 2>/dev/null | sort -hr | head -20
du -sh ~/.cache/* 2>/dev/null | sort -hr | head -15
du -sh ~/.config/* 2>/dev/null | sort -hr | head -15
```

### 4. Check for Large Files
```bash
find ~ -type f -size +100M 2>/dev/null | head -20
```

### 5. Check Package Manager Caches

#### macOS
```bash
# Homebrew
du -sh /opt/homebrew/Cellar 2>/dev/null
du -sh ~/Library/Caches/Homebrew 2>/dev/null

# npm
du -sh ~/.npm 2>/dev/null

# pnpm
du -sh ~/Library/pnpm 2>/dev/null
```

#### Linux
```bash
# apt
du -sh /var/cache/apt 2>/dev/null

# snap
du -sh ~/snap 2>/dev/null
```

### 6. Docker (if installed)
```bash
docker system df 2>/dev/null
```

## Output Format

Present results as a table:

| Category | Size | Location | Action |
|----------|------|----------|--------|
| Docker Images | X GB | ~/.docker | `docker image prune -a` |
| npm cache | X MB | ~/.npm | `npm cache clean --force` |
| ... | ... | ... | ... |

## Recommendations

After scanning, provide:
1. Top 5 largest directories
2. Estimated reclaimable space
3. Suggested cleanup commands
