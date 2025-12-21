# /parasites - Zombie Process Hunter

Hunt and eliminate "parasite" processes - LaunchAgents and LaunchDaemons that persist after their parent application has been uninstalled.

## Usage

```
/parasites              # Scan for zombie processes
/parasites --kill       # Remove found parasites
/parasites --backup     # Backup before removing
```

## Instructions

When the user runs /parasites, perform the following analysis:

### 1. Detect Operating System

Only macOS has LaunchAgents/Daemons. For Linux, check systemd user services.

### 2. List All LaunchAgents and Daemons

#### macOS
```bash
# User LaunchAgents
echo "=== User LaunchAgents ==="
ls -la ~/Library/LaunchAgents/ 2>/dev/null

# System LaunchAgents
echo "=== System LaunchAgents ==="
ls -la /Library/LaunchAgents/ 2>/dev/null

# System LaunchDaemons
echo "=== System LaunchDaemons ==="
ls -la /Library/LaunchDaemons/ 2>/dev/null
```

#### Linux
```bash
# User systemd services
systemctl --user list-units --type=service
ls -la ~/.config/systemd/user/ 2>/dev/null
```

### 3. Cross-Reference with Installed Apps

For each LaunchAgent/Daemon found, check if the corresponding app exists:

```bash
# Example: com.google.keystone.agent.plist
# Check if Google Chrome exists
ls /Applications/Google\ Chrome.app 2>/dev/null
```

### 4. Known Parasites Database

Flag these as KNOWN PARASITES (commonly left behind):

| Parasite | Pattern | Parent App |
|----------|---------|------------|
| Google Keystone | `com.google.keystone.*` | Google Chrome |
| Adobe Telemetry | `com.adobe.agsservice`, `com.adobe.GC.Invoker.*`, `com.adobe.ARMDC.*` | Any Adobe |
| CCleaner | `com.piriform.ccleaner.*` | CCleaner |
| Zoom | `us.zoom.*` | Zoom |
| Microsoft AutoUpdate | `com.microsoft.update.*` | Office |
| Spotify Helper | `com.spotify.webhelper` | Spotify |
| Dropbox | `com.dropbox.*` | Dropbox |
| Slack Helper | `com.tinyspeck.slackmacgap.*` | Slack |

### 5. Output Format

Present findings in a table:

| Status | Agent | App Exists? | Recommendation |
|--------|-------|-------------|----------------|
| ZOMBIE | com.google.keystone.agent | NO | Remove |
| ACTIVE | com.docker.vmnetd | YES | Keep |
| PARASITE | com.adobe.agsservice | YES (but telemetry) | Remove |

### 6. Removal Process

If user confirms removal with `--kill`:

```bash
# 1. Unload the agent first
launchctl unload ~/Library/LaunchAgents/com.example.plist 2>/dev/null

# 2. For daemons (requires sudo)
sudo launchctl unload /Library/LaunchDaemons/com.example.plist 2>/dev/null

# 3. Remove the plist file
rm -f ~/Library/LaunchAgents/com.example.plist
# or
sudo rm -f /Library/LaunchDaemons/com.example.plist
```

### 7. Backup Option

If `--backup` is specified, copy plists before removing:

```bash
mkdir -p ~/.cclean-killer-backup/$(date +%Y%m%d)
cp ~/Library/LaunchAgents/com.example.plist ~/.cclean-killer-backup/$(date +%Y%m%d)/
```

## Safety Rules

1. NEVER touch anything in `/System/Library/`
2. NEVER remove agents for currently running apps
3. ALWAYS offer dry-run first
4. ALWAYS backup before removing daemons
