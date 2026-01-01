# Adding New Parasites

Guide for adding newly discovered parasites to the CClean-Killer database.

## Table of Contents

- [What Qualifies as a Parasite](#what-qualifies-as-a-parasite)
- [Research Process](#research-process)
- [Documentation Format](#documentation-format)
- [Adding to Scripts](#adding-to-scripts)
- [Testing](#testing)

---

## What Qualifies as a Parasite

A process or file is a "parasite" if it meets these criteria:

### Must Have

1. **Installed by an application** - Not a system component
2. **Persists after removal** - Survives app uninstallation
3. **Runs automatically** - Starts without user action

### Often Has

4. **Phones home** - Makes network connections
5. **Consumes resources** - Uses CPU, memory, or disk
6. **No user benefit** - Provides nothing to the user

### Categories

| Category | Description | Risk Level |
|----------|-------------|------------|
| **Telemetry** | Sends usage data to vendor | High |
| **Update Checker** | Checks for updates constantly | Medium |
| **Background Service** | Runs even when app not active | Low-Medium |
| **Helper Daemon** | Privileged helper for app features | Low |

---

## Research Process

### Step 1: Identify the Persistence

Find where the parasite lives:

```bash
# macOS - List non-Apple agents
ls ~/Library/LaunchAgents/ | grep -v "com.apple"
ls /Library/LaunchAgents/ | grep -v "com.apple"
ls /Library/LaunchDaemons/ | grep -v "com.apple"
ls /Library/PrivilegedHelperTools/ | grep -v "com.apple"
```

```bash
# Linux - List user services
systemctl --user list-units --type=service
ls ~/.config/systemd/user/
ls ~/.config/autostart/
```

```powershell
# Windows - Check startup
Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run
Get-ScheduledTask | Where-Object {$_.TaskPath -notlike "\Microsoft\*"}
```

### Step 2: Analyze the Plist/Service

**macOS - Read plist:**
```bash
cat ~/Library/LaunchAgents/com.example.agent.plist
# Look for:
# - ProgramArguments (what it runs)
# - RunAtLoad (starts at login)
# - KeepAlive (restarts if killed)
# - StartInterval (how often it runs)
```

**Linux - Check service:**
```bash
cat ~/.config/systemd/user/example.service
# Look for:
# - ExecStart (what it runs)
# - Restart (if it auto-restarts)
```

### Step 3: Check Network Activity

```bash
# macOS/Linux
lsof -i -n | grep <process_name>
```

### Step 4: Verify App Relationship

```bash
# Check if parent app exists
ls /Applications/ | grep -i <app_name>

# Find bundle ID
mdls -name kMDItemCFBundleIdentifier /Applications/<App>.app
```

### Step 5: Document All Related Files

Find everything the parasite owns:
```bash
# Find all related files
sudo find / -name "*<pattern>*" 2>/dev/null
```

---

## Documentation Format

Add the parasite to `knowledge/common-parasites.md`:

```markdown
---

### [App Name]

**What it is:** Brief description of the app and its persistence mechanisms.

**Files:**
```
~/Library/LaunchAgents/com.company.app.agent.plist
/Library/LaunchDaemons/com.company.app.daemon.plist
/Library/PrivilegedHelperTools/com.company.app.helper
~/Library/Application Support/AppName/
~/Library/Caches/com.company.app/
~/Library/Preferences/com.company.app.plist
```

**Behavior:**
- What processes run
- Network activity (if any)
- Resource usage (if notable)
- Frequency (StartInterval, etc.)

**Removal:**
```bash
# User LaunchAgents
launchctl unload ~/Library/LaunchAgents/com.company.app.agent.plist
rm -f ~/Library/LaunchAgents/com.company.app.*.plist

# System components (requires sudo)
sudo launchctl unload /Library/LaunchDaemons/com.company.app.daemon.plist
sudo rm -f /Library/LaunchDaemons/com.company.app.*.plist
sudo rm -f /Library/PrivilegedHelperTools/com.company.app.helper

# App data
rm -rf ~/Library/Application\ Support/AppName
rm -rf ~/Library/Caches/com.company.app*
rm -f ~/Library/Preferences/com.company.app.plist
```
```

---

## Adding to Scripts

### Update Pattern Database

**File:** `scripts/macos/find-parasites.sh`

Add to the `KNOWN_PARASITES` array:

```bash
declare -A KNOWN_PARASITES
# Existing entries...
KNOWN_PARASITES["com.company.app"]="App Name - Description of what it does"
```

### Add Detection Logic (if special handling needed)

```bash
# For apps that need special detection
case "$name" in
  *"com.company.app"*)
    echo -e "${RED}KNOWN PARASITE: $name${NC}"
    echo "  App Name - persistence type"
    # Check related files
    if [ -f "/Library/PrivilegedHelperTools/com.company.app.helper" ]; then
      echo "  Also found: PrivilegedHelper (requires sudo)"
    fi
    ;;
esac
```

---

## Testing

### 1. Verify Detection

```bash
# Run parasite scan
/parasites

# Check if your parasite is detected
# Should show:
# KNOWN PARASITE: com.company.app.agent
#    App Name - Description
#    Location: ~/Library/LaunchAgents/
```

### 2. Test Removal (on test system only!)

```bash
# 1. Install the app
# 2. Verify parasites are created
/parasites

# 3. Uninstall the app (drag to trash)
# 4. Verify parasites remain (they should!)
/parasites

# 5. Test removal commands manually
launchctl unload ~/Library/LaunchAgents/com.company.app.plist
rm ~/Library/LaunchAgents/com.company.app.plist

# 6. Verify removal
/parasites  # Should no longer show the parasite
```

### 3. Verify No Side Effects

After removal:
- System functions normally
- No crash reports
- No error dialogs

---

## Example: Adding a New Parasite

Let's say we discovered "ExampleApp" leaves behind a telemetry daemon.

### Research Results

```
Files found:
- ~/Library/LaunchAgents/com.example.telemetry.plist
- /Library/LaunchDaemons/com.example.updater.plist
- /Library/PrivilegedHelperTools/com.example.helper

Network activity:
- Connects to telemetry.example.com:443 every hour
- Connects to update.example.com:443 every 4 hours

Resources:
- Uses ~50MB memory
- 0.1% CPU average
```

### Add to Knowledge Base

**File:** `knowledge/common-parasites.md`

```markdown
---

### ExampleApp

**What it is:** ExampleApp installs aggressive telemetry and update checking
that persists after uninstallation.

**Files:**
```
~/Library/LaunchAgents/com.example.telemetry.plist
/Library/LaunchDaemons/com.example.updater.plist
/Library/PrivilegedHelperTools/com.example.helper
~/Library/Application Support/ExampleApp/
~/Library/Caches/com.example.app/
```

**Behavior:**
- Telemetry agent runs hourly, phones home
- Update daemon runs every 4 hours
- Combined ~50MB memory usage

**Removal:**
```bash
# User agent
launchctl unload ~/Library/LaunchAgents/com.example.telemetry.plist
rm -f ~/Library/LaunchAgents/com.example.*.plist

# System daemons (requires sudo)
sudo launchctl unload /Library/LaunchDaemons/com.example.updater.plist
sudo rm -f /Library/LaunchDaemons/com.example.*.plist
sudo rm -f /Library/PrivilegedHelperTools/com.example.helper

# App data
rm -rf ~/Library/Application\ Support/ExampleApp
rm -rf ~/Library/Caches/com.example.*
```
```

### Add to Script

**File:** `scripts/macos/find-parasites.sh`

```bash
KNOWN_PARASITES["com.example"]="ExampleApp - Telemetry and update daemons"
```

### Submit PR

Include:
- How you discovered this parasite
- Platform(s) tested
- Confirmation of removal working

---

## Questions?

If unsure whether something qualifies as a parasite:
1. Open an issue with your findings
2. Describe the behavior
3. Share the file locations

The community can help determine if it should be added.
