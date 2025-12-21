# Skill: Parasite Killer

A skill for identifying and removing persistent processes (LaunchAgents/Daemons) from uninstalled applications.

## Trigger

Use this skill when the user asks to:
- Remove zombie processes
- Clean up LaunchAgents
- Find persistent processes
- Kill background services
- Remove startup items

## What are Parasites?

Parasites are persistent processes that:
1. Were installed by an application
2. Continue to run after the app is removed
3. May phone home, use resources, or just waste space

## macOS Persistence Locations

```bash
PERSISTENCE_LOCATIONS=(
  "$HOME/Library/LaunchAgents"           # User agents (user-writable)
  "/Library/LaunchAgents"                 # System agents (root-writable)
  "/Library/LaunchDaemons"                # System daemons (root-writable)
  "/Library/PrivilegedHelperTools"        # Privileged helpers
  "$HOME/Library/Application Scripts"     # Automation scripts
)
```

## Known Parasites Database

### Always Parasites (Telemetry/Tracking)
```bash
TELEMETRY_PARASITES=(
  "com.adobe.agsservice"
  "com.adobe.GC.Invoker"
  "com.adobe.ARMDC"
  "com.adobe.ARMDCHelper"
  "com.microsoft.update"
  "com.spotify.webhelper"
)
```

### Zombie If App Removed
```bash
ZOMBIE_PATTERNS=(
  "com.google.keystone"    # Google Updater
  "com.piriform.ccleaner"  # CCleaner
  "us.zoom"                # Zoom
  "com.dropbox"            # Dropbox
  "com.tinyspeck.slackmacgap"  # Slack
)
```

## Detection Logic

```bash
find_parasites() {
  local parasites=()

  # Check user LaunchAgents
  for plist in ~/Library/LaunchAgents/*.plist; do
    [[ -f "$plist" ]] || continue
    local name=$(basename "$plist" .plist)

    # Check if it's a known parasite
    if is_known_parasite "$name"; then
      parasites+=("USER_AGENT:$plist")
      continue
    fi

    # Check if parent app exists
    if ! app_exists_for_agent "$name"; then
      parasites+=("ZOMBIE:$plist")
    fi
  done

  # Check system LaunchAgents
  for plist in /Library/LaunchAgents/*.plist; do
    [[ -f "$plist" ]] || continue
    local name=$(basename "$plist" .plist)

    if is_known_parasite "$name" || ! app_exists_for_agent "$name"; then
      parasites+=("SYSTEM_AGENT:$plist")
    fi
  done

  # Check LaunchDaemons
  for plist in /Library/LaunchDaemons/*.plist; do
    [[ -f "$plist" ]] || continue
    local name=$(basename "$plist" .plist)

    if is_known_parasite "$name" || ! app_exists_for_daemon "$name"; then
      parasites+=("DAEMON:$plist")
    fi
  done

  printf '%s\n' "${parasites[@]}"
}
```

## Removal Process

### Step 1: Unload First
```bash
# User agents
launchctl unload "$plist" 2>/dev/null

# System agents/daemons
sudo launchctl unload "$plist" 2>/dev/null
```

### Step 2: Backup (Optional)
```bash
backup_dir="$HOME/.cclean-killer/backup/$(date +%Y%m%d)"
mkdir -p "$backup_dir"
cp "$plist" "$backup_dir/"
```

### Step 3: Remove
```bash
# User agents
rm -f "$plist"

# System agents/daemons
sudo rm -f "$plist"
```

### Step 4: Clean Related Data
```bash
# For Google Keystone
rm -rf ~/Library/Google
rm -rf ~/Library/Caches/com.google.*
rm -rf ~/Library/Preferences/com.google.*

# For Adobe
rm -rf ~/Library/Application\ Support/Adobe/*Cache*
rm -rf ~/Library/Caches/Adobe
```

## Output Format

| Type | Name | Status | App Exists | Action |
|------|------|--------|------------|--------|
| Agent | com.google.keystone.agent | ZOMBIE | NO | Remove |
| Daemon | com.docker.vmnetd | ACTIVE | YES | Keep |
| Agent | com.adobe.GC.Invoker | PARASITE | YES (telemetry) | Remove |

## Safety Rules

1. **NEVER** touch `/System/Library/LaunchAgents`
2. **NEVER** touch `/System/Library/LaunchDaemons`
3. **ALWAYS** unload before removing
4. **ALWAYS** backup daemons (they require root to restore)
5. **NEVER** remove agents for running processes without confirmation
6. **VERIFY** process isn't critical before removal

## Recovery

If something goes wrong:

```bash
# Restore from backup
cp ~/.cclean-killer/backup/YYYYMMDD/com.example.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.example.plist
```
