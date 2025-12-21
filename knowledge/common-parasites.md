# Common Parasites Database

A comprehensive database of known persistent processes that apps install and often leave behind.

## What Makes a Parasite?

A "parasite" is a persistent process that:
1. Runs without user awareness
2. Continues after parent app removal
3. May consume resources or send data
4. Provides no value to the user

## Parasite Categories

### Category 1: Update Services
These check for updates even when the app isn't running.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Google Keystone | `com.google.keystone.*` | Chrome, Earth, Drive | Medium |
| Microsoft AutoUpdate | `com.microsoft.update.*` | Office, Edge | Low |
| Adobe Updater | `com.adobe.ARMDC.*` | Any Adobe | Low |
| Spotify Helper | `com.spotify.webhelper` | Spotify | Low |
| Zoom Updater | `us.zoom.updater` | Zoom | Low |

### Category 2: Telemetry / Analytics
These send usage data to the vendor.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Adobe AGS | `com.adobe.agsservice` | Any Adobe | High |
| Adobe GC Invoker | `com.adobe.GC.Invoker.*` | Any Adobe | High |
| Adobe ARMDC | `com.adobe.ARMDC.*` | Any Adobe | Medium |
| CCleaner Services | `com.piriform.ccleaner.services.*` | CCleaner | High |

### Category 3: Background Services
Legitimate but often unnecessary.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Docker Socket | `com.docker.socket` | Docker | Low |
| Dropbox Helper | `com.dropbox.*` | Dropbox | Medium |
| Slack Helper | `com.tinyspeck.slackmacgap.*` | Slack | Low |

### Category 4: System Modifications
Apps that modify system behavior.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| macFUSE | `io.macfuse.*` | macFUSE | Low |
| Wireshark BPF | `org.wireshark.ChmodBPF` | Wireshark | Low |

## Detailed Parasite Profiles

### Google Keystone

**What it is:** Google's update mechanism for all Google products.

**Files:**
```
~/Library/LaunchAgents/com.google.keystone.agent.plist
~/Library/LaunchAgents/com.google.keystone.xpcservice.plist
~/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist
~/Library/Google/GoogleSoftwareUpdate/
~/Library/Caches/com.google.SoftwareUpdate/
```

**Behavior:**
- Runs every hour to check for updates
- Persists even after all Google apps removed
- Downloads update data

**Removal:**
```bash
launchctl unload ~/Library/LaunchAgents/com.google.keystone.*.plist
launchctl unload ~/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist
rm -f ~/Library/LaunchAgents/com.google.*.plist
rm -rf ~/Library/Google
rm -rf ~/Library/Caches/com.google.*
```

---

### Adobe Telemetry Suite

**What it is:** Adobe's analytics and license verification system.

**Files:**
```
/Library/LaunchDaemons/com.adobe.agsservice.plist
/Library/LaunchAgents/com.adobe.GC.Invoker-1.0.plist
/Library/LaunchDaemons/com.adobe.ARMDC.Communicator.plist
/Library/LaunchDaemons/com.adobe.ARMDC.SMJobBlessHelper.plist
/Library/LaunchAgents/com.adobe.ARMDCHelper.*.plist
```

**Behavior:**
- AGS: "Adobe Genuine Software" - checks license validity
- GC.Invoker: Analytics collection
- ARMDC: Update and telemetry relay

**Removal:**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.adobe.agsservice.plist
sudo launchctl unload /Library/LaunchDaemons/com.adobe.ARMDC.*.plist
launchctl unload ~/Library/LaunchAgents/com.adobe.GC.Invoker-1.0.plist
sudo rm -f /Library/LaunchDaemons/com.adobe.agsservice.plist
sudo rm -f /Library/LaunchDaemons/com.adobe.ARMDC.*.plist
sudo rm -f /Library/LaunchAgents/com.adobe.ARMDCHelper.*.plist
rm -f ~/Library/LaunchAgents/com.adobe.GC.Invoker-1.0.plist
```

---

### CCleaner

**What it is:** Ironically, a "cleaner" app with extensive persistence.

**Files:**
```
/Library/LaunchDaemons/com.piriform.ccleaner.engine.xpc.plist
/Library/LaunchDaemons/com.piriform.ccleaner.services.submit.plist
/Library/LaunchDaemons/com.piriform.ccleaner.services.xpc.plist
/Library/LaunchDaemons/com.piriform.ccleaner.uninstall.plist
/Library/LaunchDaemons/com.piriform.ccleaner.update.xpc.plist
/Library/LaunchAgents/com.piriform.ccleaner.plist
/Library/LaunchAgents/com.piriform.ccleaner.update.plist
```

**Behavior:**
- 6+ persistent processes for a "cleaner"
- Background scanning
- Update checking
- Telemetry

**Removal:**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.piriform.ccleaner.*.plist
launchctl unload /Library/LaunchAgents/com.piriform.ccleaner.*.plist
sudo rm -rf /Applications/CCleaner.app
sudo rm -f /Library/LaunchDaemons/com.piriform.ccleaner.*.plist
rm -f /Library/LaunchAgents/com.piriform.ccleaner.*.plist
rm -rf ~/Library/Application\ Support/CCleaner
rm -rf ~/Library/Caches/com.piriform.ccleaner
```

---

### Zoom

**What it is:** Video conferencing with aggressive background presence.

**Files:**
```
/Library/LaunchDaemons/us.zoom.ZoomDaemon.plist
/Library/LaunchAgents/us.zoom.updater.plist
/Library/LaunchAgents/us.zoom.updater.login.check.plist
```

**Behavior:**
- Daemon runs even when Zoom not in use
- Frequent update checks
- Audio device monitoring

**Removal (if uninstalling Zoom):**
```bash
sudo launchctl unload /Library/LaunchDaemons/us.zoom.ZoomDaemon.plist
launchctl unload /Library/LaunchAgents/us.zoom.updater*.plist
sudo rm -f /Library/LaunchDaemons/us.zoom.*.plist
rm -f /Library/LaunchAgents/us.zoom.*.plist
rm -rf ~/Library/Application\ Support/zoom.us
```

## Red Flags

When evaluating an unknown LaunchAgent/Daemon, these are red flags:

1. **No corresponding app** - The parent app doesn't exist
2. **Vague naming** - Generic names like "helper" or "service"
3. **Multiple instances** - Same app with 3+ daemons
4. **Network activity** - Daemon making outbound connections
5. **High resource usage** - CPU/memory consumption when idle

## Safe to Keep

These are generally safe/necessary:

- `com.apple.*` - Apple system services
- `com.docker.vmnetd` - Docker networking (if using Docker)
- `homebrew.mxcl.*` - Homebrew services you installed
- `org.postgresql.*` - Database servers you need
