# Common Parasites Database

A comprehensive database of known persistent processes that apps install and often leave behind.

## What Makes a Parasite?

A "parasite" is a persistent process that:
1. Runs without user awareness
2. Continues after parent app removal
3. May consume resources or send data
4. Provides no value to the user

---

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
| JetBrains Toolbox | `com.jetbrains.toolbox.*` | JetBrains IDEs | Medium |
| Brave Update | `com.brave.update.*` | Brave Browser | Low |
| Firefox Update | `org.mozilla.updater` | Firefox | Low |
| Discord Update | `com.hnc.Discord.ShipIt` | Discord | Low |
| Telegram Update | `com.tdesktop.Telegram.Updater` | Telegram | Low |
| 1Password Update | `com.1password.agent.*` | 1Password | Low |
| Bitwarden Helper | `com.bitwarden.desktop.*` | Bitwarden | Low |

### Category 2: Telemetry / Analytics
These send usage data to the vendor.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Adobe AGS | `com.adobe.agsservice` | Any Adobe | High |
| Adobe GC Invoker | `com.adobe.GC.Invoker.*` | Any Adobe | High |
| Adobe ARMDC | `com.adobe.ARMDC.*` | Any Adobe | Medium |
| CCleaner Services | `com.piriform.ccleaner.services.*` | CCleaner | High |
| Microsoft Telemetry | `com.microsoft.office.licensingV2.helper` | Office 365 | Medium |
| Spotify Analytics | `com.spotify.client.helper` | Spotify | Medium |
| JetBrains Analytics | `com.jetbrains.telemeter` | JetBrains IDEs | Medium |
| VLC Telemetry | `org.videolan.vlc.helper` | VLC | Low |

### Category 3: Background Services
Legitimate but often unnecessary.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Docker Socket | `com.docker.socket` | Docker | Low |
| Docker VMNetD | `com.docker.vmnetd` | Docker Desktop | Low |
| Dropbox Helper | `com.dropbox.*` | Dropbox | Medium |
| Slack Helper | `com.tinyspeck.slackmacgap.*` | Slack | Low |
| OneDrive Sync | `com.microsoft.OneDrive.*` | OneDrive | Medium |
| Box Sync | `com.box.desktop.*` | Box | Medium |
| Google Drive Sync | `com.google.drivefs.*` | Google Drive | Medium |
| iCloud Helper | `com.apple.iCloudHelper` | iCloud (third-party) | Low |
| Plex Media Server | `com.plexapp.plexmediaserver.*` | Plex | Low |
| Teams Helper | `com.microsoft.teams.helper` | Microsoft Teams | Medium |

### Category 4: System Modifications
Apps that modify system behavior.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| macFUSE | `io.macfuse.*` | macFUSE | Low |
| Wireshark BPF | `org.wireshark.ChmodBPF` | Wireshark | Low |
| VPN Helpers | `com.*.vpn.helper` | Various VPNs | Medium |
| Tunnelblick | `net.tunnelblick.*` | Tunnelblick | Low |
| NordVPN Daemon | `com.nordvpn.macos.helper` | NordVPN | Medium |
| ExpressVPN Helper | `com.expressvpn.helper` | ExpressVPN | Medium |
| Tailscale Daemon | `com.tailscale.ipnextension` | Tailscale | Low |

### Category 5: Development Tools
Often forgotten after project completion.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Docker Desktop | `com.docker.helper` | Docker Desktop | Low |
| Xcode Simulator | `com.apple.CoreSimulator.*` | Xcode | Medium |
| Homebrew Services | `homebrew.mxcl.*` | Homebrew | Low |
| npm Background | `npm-check-updates` | npm | Low |
| Node Version Manager | `io.nvm.*` | nvm | Low |
| PostgreSQL | `org.postgresql.*` | PostgreSQL.app | Low |
| MongoDB | `org.mongodb.*` | MongoDB | Low |
| Redis | `io.redis.*` | Redis | Low |
| MySQL | `com.mysql.*` | MySQL | Low |
| VMware Fusion | `com.vmware.*` | VMware Fusion | Low |

### Category 6: Communication Apps
Background processes for messaging apps.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Discord RPC | `com.discord.rpc` | Discord | Low |
| Slack Presence | `com.tinyspeck.slackmacgap.helper` | Slack | Low |
| Teams Background | `com.microsoft.teams.*` | Microsoft Teams | Medium |
| Skype Helper | `com.skype.skype.helper` | Skype | Medium |
| Telegram Helper | `ru.keepcoder.Telegram.helper` | Telegram | Low |
| WhatsApp Helper | `net.whatsapp.WhatsApp.helper` | WhatsApp Desktop | Low |
| Signal Helper | `org.whispersystems.signal-desktop.helper` | Signal | Low |
| Webex Meetings | `com.cisco.webexmeetingsapp.*` | Cisco Webex | Medium |
| Perplexity AI | `ai.perplexity.*` | Perplexity | Low |

### Category 7: Cloud Storage
Sync daemons that persist after uninstall.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Dropbox Finder | `com.dropbox.DropboxMacUpdate` | Dropbox | Medium |
| OneDrive Finder | `com.microsoft.OneDriveUpdaterDaemon` | OneDrive | Medium |
| Google Drive FS | `com.google.drivefs.helper` | Google Drive | Medium |
| Box Drive | `com.box.desktop.helper` | Box | Medium |
| iCloud Sync | `com.apple.icloud.fmfd` | iCloud | Low |
| Mega Sync | `mega.mac.MEGAupdater` | MEGA | Low |
| pCloud Drive | `com.pcloud.pcloud.drive` | pCloud | Low |
| Sync.com | `com.sync.sync-desktop.helper` | Sync.com | Low |

### Category 8: Media Applications
Streaming and media player background processes.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| Spotify Connect | `com.spotify.client` | Spotify | Low |
| VLC Updater | `org.videolan.vlc-updater` | VLC | Low |
| Plex Helper | `com.plexapp.plex.helper` | Plex | Low |
| OBS Virtual Cam | `com.obsproject.obs-studio.virtualcam` | OBS | Low |
| HandBrake Helper | `fr.handbrake.HandBrake.helper` | HandBrake | Low |
| IINA Helper | `com.colliderli.iina.helper` | IINA | Low |
| Audacity Helper | `org.audacityteam.audacity.helper` | Audacity | Low |

### Category 9: Security Software
VPNs, password managers, antivirus helpers.

| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| 1Password Agent | `com.1password.1password-agent` | 1Password | Low |
| 1Password Browser | `com.1password.browser-helper` | 1Password | Low |
| Bitwarden Helper | `com.bitwarden.desktop.helper` | Bitwarden | Low |
| LastPass Helper | `com.lastpass.LastPassHelper` | LastPass | Medium |
| NordVPN IKE | `com.nordvpn.NordVPN.IKE` | NordVPN | Medium |
| ExpressVPN Daemon | `com.expressvpn.ExpressVPN.agent` | ExpressVPN | Medium |
| Surfshark Helper | `com.surfshark.vpnclient.helper` | Surfshark | Medium |
| Little Snitch | `at.obdev.LittleSnitchHelper` | Little Snitch | Low |
| Malwarebytes | `com.malwarebytes.mbam.*` | Malwarebytes | Low |
| Avast Daemon | `com.avast.daemon` | Avast | Medium |

---

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
/Library/Application Support/Adobe/
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
~/Library/Application Support/zoom.us/
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

---

### JetBrains Toolbox

**What it is:** JetBrains IDE manager with persistent background processes.

**Files:**
```
~/Library/LaunchAgents/com.jetbrains.toolbox.plist
~/Library/LaunchAgents/com.jetbrains.toolbox.helper.plist
~/Library/Application Support/JetBrains/Toolbox/
~/Library/Caches/JetBrains/
~/Library/Logs/JetBrains/
```

**Behavior:**
- Runs continuously to manage IDEs
- Checks for updates every 30 minutes
- Monitors IDE usage for telemetry
- Auto-starts on login

**Removal:**
```bash
launchctl unload ~/Library/LaunchAgents/com.jetbrains.toolbox*.plist
rm -f ~/Library/LaunchAgents/com.jetbrains.*.plist
rm -rf ~/Library/Application\ Support/JetBrains
rm -rf ~/Library/Caches/JetBrains
rm -rf ~/Library/Logs/JetBrains
rm -rf ~/Applications/JetBrains\ Toolbox.app
```

---

### Docker Desktop

**What it is:** Containerization platform with multiple background services.

**Files:**
```
/Library/LaunchDaemons/com.docker.vmnetd.plist
/Library/PrivilegedHelperTools/com.docker.vmnetd
~/Library/LaunchAgents/com.docker.helper.plist
~/Library/Containers/com.docker.docker/
~/Library/Group Containers/group.com.docker/
~/.docker/
~/Library/Application Support/Docker Desktop/
```

**Behavior:**
- VMNetD: Network daemon for containers
- Helper: Desktop UI integration
- Large container storage in Group Containers

**Removal:**
```bash
# Use Docker Desktop's uninstaller first, then:
sudo launchctl unload /Library/LaunchDaemons/com.docker.vmnetd.plist
launchctl unload ~/Library/LaunchAgents/com.docker.*.plist
sudo rm -f /Library/LaunchDaemons/com.docker.*.plist
sudo rm -f /Library/PrivilegedHelperTools/com.docker.*
rm -f ~/Library/LaunchAgents/com.docker.*.plist
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/.docker
rm -rf ~/Library/Application\ Support/Docker\ Desktop
```

---

### Dropbox

**What it is:** Cloud storage with aggressive sync daemon.

**Files:**
```
/Library/LaunchDaemons/com.dropbox.DropboxMacUpdate.daemon.plist
~/Library/LaunchAgents/com.dropbox.DropboxMacUpdate.agent.plist
~/Library/LaunchAgents/com.dropbox.client.plist
~/Library/Application Support/Dropbox/
~/Library/Dropbox/
~/.dropbox/
```

**Behavior:**
- Multiple background processes
- Finder integration
- Continuous file monitoring
- Network activity even when not syncing

**Removal:**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.dropbox.*.plist
launchctl unload ~/Library/LaunchAgents/com.dropbox.*.plist
sudo rm -f /Library/LaunchDaemons/com.dropbox.*.plist
rm -f ~/Library/LaunchAgents/com.dropbox.*.plist
rm -rf ~/Library/Application\ Support/Dropbox
rm -rf ~/Library/Dropbox
rm -rf ~/.dropbox
```

---

### Slack

**What it is:** Team communication with background helpers.

**Files:**
```
~/Library/LaunchAgents/com.tinyspeck.slackmacgap.plist
~/Library/LaunchAgents/com.tinyspeck.slackmacgap.helper.plist
~/Library/Application Support/Slack/
~/Library/Caches/com.tinyspeck.slackmacgap/
```

**Behavior:**
- Helper for notifications
- Background presence detection
- Workspace sync

**Removal:**
```bash
launchctl unload ~/Library/LaunchAgents/com.tinyspeck.slackmacgap*.plist
rm -f ~/Library/LaunchAgents/com.tinyspeck.*.plist
rm -rf ~/Library/Application\ Support/Slack
rm -rf ~/Library/Caches/com.tinyspeck.slackmacgap
```

---

### Discord

**What it is:** Gaming communication with update services.

**Files:**
```
~/Library/LaunchAgents/com.hnc.Discord.ShipIt.plist
~/Library/Application Support/discord/
~/Library/Application Support/Discord/
~/Library/Caches/com.hnc.Discord/
```

**Behavior:**
- ShipIt: Auto-update service
- Rich presence integration
- Background notification polling

**Removal:**
```bash
launchctl unload ~/Library/LaunchAgents/com.hnc.Discord.*.plist
rm -f ~/Library/LaunchAgents/com.hnc.Discord.*.plist
rm -rf ~/Library/Application\ Support/discord
rm -rf ~/Library/Application\ Support/Discord
rm -rf ~/Library/Caches/com.hnc.Discord
```

---

### Microsoft Teams

**What it is:** Enterprise communication with extensive background services.

**Files:**
```
~/Library/LaunchAgents/com.microsoft.teams.helper.plist
~/Library/LaunchAgents/com.microsoft.teams.TeamsUpdaterDaemon.plist
~/Library/Application Support/Microsoft/Teams/
~/Library/Caches/com.microsoft.teams/
~/Library/Group Containers/*.com.microsoft.teams/
```

**Behavior:**
- Helper: Background notifications
- TeamsUpdaterDaemon: Update service
- Persistent WebRTC connections

**Removal:**
```bash
launchctl unload ~/Library/LaunchAgents/com.microsoft.teams*.plist
rm -f ~/Library/LaunchAgents/com.microsoft.teams*.plist
rm -rf ~/Library/Application\ Support/Microsoft/Teams
rm -rf ~/Library/Caches/com.microsoft.teams
rm -rf ~/Library/Group\ Containers/*.com.microsoft.teams
```

---

### 1Password

**What it is:** Password manager with browser integration helpers.

**Files:**
```
~/Library/LaunchAgents/com.1password.1password-agent.plist
~/Library/LaunchAgents/com.1password.browser-helper.plist
~/Library/Group Containers/group.1password/
~/Library/Application Support/1Password/
```

**Behavior:**
- Agent: Keychain integration
- Browser Helper: Extension communication
- Secure memory handling

**Removal (caution - ensure passwords exported):**
```bash
launchctl unload ~/Library/LaunchAgents/com.1password.*.plist
rm -f ~/Library/LaunchAgents/com.1password.*.plist
rm -rf ~/Library/Group\ Containers/group.1password
rm -rf ~/Library/Application\ Support/1Password
```

---

### VPN Services (General)

**What it is:** VPN apps often install privileged helpers that persist.

**Common Patterns:**
```
/Library/LaunchDaemons/com.nordvpn.macos.helper.plist
/Library/LaunchDaemons/com.expressvpn.helper.plist
/Library/LaunchDaemons/com.surfshark.vpnclient.helper.plist
/Library/PrivilegedHelperTools/com.*.vpn.*
```

**Behavior:**
- Privileged helpers for network configuration
- System extension for packet filtering
- Persistent even after app removal

**General VPN Removal Pattern:**
```bash
# Replace <vendor> with nordvpn, expressvpn, surfshark, etc.
sudo launchctl unload /Library/LaunchDaemons/com.<vendor>.*.plist
sudo rm -f /Library/LaunchDaemons/com.<vendor>.*.plist
sudo rm -f /Library/PrivilegedHelperTools/com.<vendor>.*
# Remove system extension if present
systemextensionsctl list | grep <vendor>
```

---

### Xcode Developer Tools

**What it is:** Apple's development environment leaves substantial artifacts.

**Files:**
```
~/Library/Developer/CoreSimulator/
~/Library/Developer/XCTestDevices/
~/Library/Caches/com.apple.dt.Xcode/
/Library/Developer/CommandLineTools/
~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.apple.dt.xcode.sfl2
```

**Behavior:**
- CoreSimulator: iOS/watchOS simulators (can be 50+ GB)
- Derived Data: Build caches
- Archives: Old app exports

**Cleanup:**
```bash
# Remove old simulators
xcrun simctl delete unavailable
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
# Remove old archives (review first!)
ls ~/Library/Developer/Xcode/Archives/
```

---

### Homebrew Services

**What it is:** Package manager background services.

**Files:**
```
~/Library/LaunchAgents/homebrew.mxcl.*.plist
/Library/LaunchDaemons/homebrew.mxcl.*.plist
```

**Note:** These are services YOU installed. List them with:
```bash
brew services list
```

**Behavior:**
- Runs databases, servers you installed
- PostgreSQL, MySQL, Redis, etc.

**Management:**
```bash
# Stop and remove a service
brew services stop <service>
brew services cleanup
```

---

### VMware Fusion

**What it is:** Desktop hypervisor with multiple privileged helpers.

**Files:**
```
/Library/LaunchDaemons/com.vmware.DiskHelper.plist
/Library/LaunchDaemons/com.vmware.IDHelper.plist
/Library/LaunchDaemons/com.vmware.MountHelper.plist
/Library/PrivilegedHelperTools/com.vmware.*
/Library/Application Support/VMware/
~/Library/Application Support/VMware Fusion/
```

**Behavior:**
- DiskHelper: Manages virtual disk access
- IDHelper: Handles VM identification
- MountHelper: Mounts virtual machine filesystems
- All run as root via privileged helpers

**Removal (if uninstalling VMware):**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.vmware.*.plist
sudo rm -f /Library/LaunchDaemons/com.vmware.*.plist
sudo rm -f /Library/PrivilegedHelperTools/com.vmware.*
rm -rf ~/Library/Application\ Support/VMware\ Fusion
```

---

### Perplexity AI

**What it is:** AI assistant with browser integration helper.

**Files:**
```
~/Library/LaunchAgents/ai.perplexity.xpc.plist
~/Library/Application Support/Perplexity/PerplexityXPC.xpc
~/Library/Application Support/Perplexity/
~/Library/Caches/ai.perplexity.*/
```

**Behavior:**
- XPC service for browser extension communication
- Runs at login, kept alive on crash
- Provides MachServices for inter-process communication

**Removal:**
```bash
launchctl unload ~/Library/LaunchAgents/ai.perplexity.xpc.plist
rm -f ~/Library/LaunchAgents/ai.perplexity.*.plist
rm -rf ~/Library/Application\ Support/Perplexity
rm -rf ~/Library/Caches/ai.perplexity.*
```

---

## Red Flags

When evaluating an unknown LaunchAgent/Daemon, these are red flags:

1. **No corresponding app** - The parent app doesn't exist
2. **Vague naming** - Generic names like "helper" or "service"
3. **Multiple instances** - Same app with 3+ daemons
4. **Network activity** - Daemon making outbound connections
5. **High resource usage** - CPU/memory consumption when idle

## Detection Commands

### Find All LaunchAgents/Daemons
```bash
# User agents
ls -la ~/Library/LaunchAgents/

# System-wide agents
ls -la /Library/LaunchAgents/

# System daemons (require sudo)
ls -la /Library/LaunchDaemons/
```

### Find Running Parasites
```bash
# List all running background processes
launchctl list | grep -v "^-" | grep -v "com.apple"

# Find processes with no corresponding app
for plist in ~/Library/LaunchAgents/*.plist; do
    bundle_id=$(basename "$plist" .plist)
    if ! mdfind "kMDItemCFBundleIdentifier == '$bundle_id'" > /dev/null 2>&1; then
        echo "Orphan: $plist"
    fi
done
```

### Check Network Activity
```bash
# See what's making network connections
lsof -i -P | grep -i LISTEN
netstat -an | grep ESTABLISHED
```

## Safe to Keep

These are generally safe/necessary:

- `com.apple.*` - Apple system services
- `com.docker.vmnetd` - Docker networking (if using Docker)
- `homebrew.mxcl.*` - Homebrew services you installed
- `org.postgresql.*` - Database servers you need

## Quick Reference: Risk Levels

| Risk | Description | Action |
|------|-------------|--------|
| **Low** | Update services, minimal resource use | Remove if app uninstalled |
| **Medium** | Telemetry, sync services, network activity | Consider removing |
| **High** | Aggressive telemetry, license checking | Remove immediately |
