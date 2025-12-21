# Skill: Duplicate Finder

A skill for identifying applications with overlapping functionality and duplicate data.

## Trigger

Use this skill when the user asks to:
- Find duplicate apps
- Find apps with same function
- Consolidate applications
- Reduce app bloat

## Duplicate Categories

### Code Editors / IDEs
```bash
CODE_EDITORS=(
  "/Applications/Visual Studio Code.app"
  "/Applications/Cursor.app"
  "/Applications/Zed.app"
  "/Applications/Sublime Text.app"
  "/Applications/Atom.app"
  "/Applications/Nova.app"
  "/Applications/TextMate.app"
  "/Applications/BBEdit.app"
  "/Applications/Xcode.app"
)
```

### Terminal Emulators
```bash
TERMINALS=(
  "/Applications/iTerm.app"
  "/Applications/Ghostty.app"
  "/Applications/Warp.app"
  "/Applications/Hyper.app"
  "/Applications/Alacritty.app"
  "/Applications/kitty.app"
  "/System/Applications/Utilities/Terminal.app"
)
```

### Web Browsers
```bash
BROWSERS=(
  "/Applications/Google Chrome.app"
  "/Applications/Firefox.app"
  "/Applications/Microsoft Edge.app"
  "/Applications/Brave Browser.app"
  "/Applications/Arc.app"
  "/Applications/Opera.app"
  "/Applications/Vivaldi.app"
  "/System/Applications/Safari.app"
)
```

### Password Managers
```bash
PASSWORD_MANAGERS=(
  "/Applications/1Password.app"
  "/Applications/Bitwarden.app"
  "/Applications/LastPass.app"
  "/Applications/Dashlane.app"
  "/Applications/Proton Pass.app"
  "/Applications/Enpass.app"
  "/System/Applications/Passwords.app"
)
```

### System Cleaners
```bash
SYSTEM_CLEANERS=(
  "/Applications/CCleaner.app"
  "/Applications/CleanMyMac.app"
  "/Applications/OnyX.app"
  "/Applications/AppCleaner.app"
  "/Applications/DaisyDisk.app"
  "/Applications/Disk Diag.app"
)
```

### Note-Taking Apps
```bash
NOTE_APPS=(
  "/Applications/Obsidian.app"
  "/Applications/Notion.app"
  "/Applications/Bear.app"
  "/Applications/Craft.app"
  "/Applications/Roam Research.app"
  "/Applications/Logseq.app"
  "/System/Applications/Notes.app"
)
```

### Virtualization
```bash
VIRTUALIZATION=(
  "/Applications/Docker.app"
  "/Applications/VMware Fusion.app"
  "/Applications/Parallels Desktop.app"
  "/Applications/UTM.app"
  "/Applications/VirtualBox.app"
)
```

## Detection Logic

```bash
find_duplicates() {
  local category=$1
  local -n apps=$2
  local found=()

  for app in "${apps[@]}"; do
    if [[ -d "$app" ]]; then
      local size=$(du -sh "$app" 2>/dev/null | cut -f1)
      found+=("$app:$size")
    fi
  done

  if [[ ${#found[@]} -gt 1 ]]; then
    echo "=== $category (${#found[@]} apps) ==="
    for item in "${found[@]}"; do
      echo "  - $item"
    done
  fi
}
```

## Data Overlap Detection

Some apps share data or have overlapping caches:

```bash
# VS Code family
VSCODE_FAMILY=(
  "~/Library/Application Support/Code"
  "~/Library/Application Support/Cursor"
  "~/.vscode"
  "~/.cursor"
)

# Chromium-based browsers share some data structures
CHROMIUM_DATA=(
  "~/Library/Application Support/Google/Chrome"
  "~/Library/Application Support/Microsoft Edge"
  "~/Library/Application Support/BraveSoftware"
)
```

## Output Format

```
=== DUPLICATE ANALYSIS ===

CODE EDITORS (3 apps found)
| App | Size | Data | Total | Recommendation |
|-----|------|------|-------|----------------|
| VS Code | 659 MB | 321 MB | 980 MB | Keep if primary |
| Cursor | 583 MB | 512 MB | 1.1 GB | Keep if using AI |
| Xcode | 4.9 GB | 228 KB | 4.9 GB | Keep if iOS dev |

Potential savings if consolidated: ~1-2 GB

TERMINALS (2 apps found)
| App | Size | Recommendation |
|-----|------|----------------|
| iTerm | 140 MB | Keep (most features) |
| Ghostty | 49 MB | Keep (faster) |

SYSTEM CLEANERS (3 apps found)
| App | Size | Daemons | Recommendation |
|-----|------|---------|----------------|
| CCleaner | 122 MB | 6 | REMOVE |
| OnyX | 13 MB | 0 | Keep |
| Disk Diag | 9 MB | 0 | Keep |

*** ALERT: CCleaner has 6 persistent daemons! ***
*** Recommend removal - use OnyX instead ***
```

## Recommendations Logic

### Keep Criteria
- Only app in its category
- Unique feature set
- No persistent daemons
- Actively used

### Remove Criteria
- Duplicate functionality
- Excessive daemons/services
- Known bloatware
- Not used in 30+ days

## Integration with Other Skills

After finding duplicates, suggest:
1. `/clean` to remove orphaned data
2. `/parasites` to remove leftover daemons
3. `/report` for full analysis
