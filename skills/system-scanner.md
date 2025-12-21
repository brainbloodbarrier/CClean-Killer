# Skill: System Scanner

A skill for analyzing disk usage and identifying storage consumption patterns across different operating systems.

## Trigger

Use this skill when the user asks to:
- Analyze disk space
- Find large files
- Check storage usage
- Scan the system
- Understand what's using space

## Platform Detection

```bash
detect_platform() {
  case "$(uname -s)" in
    Darwin)  echo "macos" ;;
    Linux)   echo "linux" ;;
    MINGW*|CYGWIN*|MSYS*) echo "windows" ;;
    *)       echo "unknown" ;;
  esac
}
```

## Platform-Specific Paths

### macOS
```bash
MACOS_PATHS=(
  "$HOME/Library/Application Support"
  "$HOME/Library/Caches"
  "$HOME/Library/Containers"
  "$HOME/Library/Group Containers"
  "$HOME/Library/Logs"
  "$HOME/Library/Saved Application State"
  "/Library/Application Support"
  "/Library/Caches"
  "/private/var/folders"
  "/opt/homebrew"
)
```

### Linux
```bash
LINUX_PATHS=(
  "$HOME/.local/share"
  "$HOME/.cache"
  "$HOME/.config"
  "/var/cache"
  "/var/log"
  "/tmp"
  "/opt"
)
```

### Windows (PowerShell)
```powershell
$WINDOWS_PATHS = @(
  "$env:APPDATA"
  "$env:LOCALAPPDATA"
  "$env:TEMP"
  "$env:USERPROFILE\Downloads"
  "C:\ProgramData"
)
```

## Scanning Commands

### Quick Scan
```bash
# Top-level directories
du -sh ~/* 2>/dev/null | sort -hr | head -20
```

### Deep Scan
```bash
# All directories > 100MB
find ~ -type d -exec du -sh {} + 2>/dev/null | awk '$1 ~ /[0-9]+G|[0-9]{3,}M/' | sort -hr
```

### Application Support Scan (macOS)
```bash
du -sh ~/Library/Application\ Support/* 2>/dev/null | sort -hr | head -30
```

### Hidden Files Scan
```bash
du -sh ~/.[!.]* 2>/dev/null | sort -hr
```

## Output Format

Always present results as:

1. **Summary**
   - Total disk size
   - Used space
   - Available space
   - Percentage used

2. **Top Consumers Table**
   | Rank | Directory | Size | % of Used |
   |------|-----------|------|-----------|
   | 1 | ~/Library | 20 GB | 25% |

3. **Recommendations**
   - Largest directories that could be cleaned
   - Estimated recoverable space

## Best Practices

1. Always handle permission errors gracefully (`2>/dev/null`)
2. Sort by size descending (`sort -hr`)
3. Limit output to prevent overwhelming (`head -N`)
4. Use human-readable sizes (`-h` flag)
5. Check for platform before running commands
