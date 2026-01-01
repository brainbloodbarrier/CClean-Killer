# Cross-Platform Implementation Research

> Comprehensive research for extending CClean-Killer to Linux and Windows platforms.

## Executive Summary

This document provides a complete mapping of macOS cleanup concepts to Linux and Windows equivalents, along with 30+ new parasite entries and platform-specific detection algorithms.

---

## Part 1: Platform-Specific Path Mapping

### 1.1 Persistence Mechanisms Mapping

| macOS Location | Linux Equivalent | Windows Equivalent |
|----------------|------------------|-------------------|
| `~/Library/LaunchAgents/` | `~/.config/systemd/user/` | `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\` |
| `/Library/LaunchAgents/` | `/etc/xdg/autostart/` | `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\` |
| `/Library/LaunchDaemons/` | `/etc/systemd/system/` | Services (Registry: `HKLM\SYSTEM\CurrentControlSet\Services`) |
| `~/Library/Application Scripts/` | `~/.local/bin/` (cron) | Task Scheduler (`C:\Windows\System32\Tasks\`) |
| `/Library/PrivilegedHelperTools/` | `/usr/local/sbin/` | `C:\Windows\System32\` (privileged) |

### 1.2 Application Data Mapping

| macOS Location | Linux Equivalent | Windows Equivalent |
|----------------|------------------|-------------------|
| `~/Library/Application Support/<app>` | `~/.local/share/<app>` | `%APPDATA%\<Company>\<App>` |
| `~/Library/Preferences/<app>.plist` | `~/.config/<app>/` | `%APPDATA%\<App>\` or Registry `HKCU\Software\<Company>\<App>` |
| `~/Library/Caches/<app>` | `~/.cache/<app>` | `%LOCALAPPDATA%\<App>\Cache` |
| `~/Library/Logs/<app>` | `~/.local/state/<app>/log` or `/var/log/` | `%LOCALAPPDATA%\<App>\Logs` |
| `~/Library/Saved Application State/` | `~/.local/state/<app>/` | `%LOCALAPPDATA%\<App>\` |
| `~/Library/Cookies/` | `~/.local/share/<app>/cookies` | `%LOCALAPPDATA%\<App>\Cookies` |
| `~/Library/WebKit/<app>` | `~/.local/share/<app>/webkit` | `%LOCALAPPDATA%\<App>\WebKit` |
| `~/Library/HTTPStorages/` | `~/.cache/<app>/http` | `%LOCALAPPDATA%\<App>\` |

### 1.3 Sandboxed/Containerized App Data Mapping

| macOS Location | Linux Equivalent | Windows Equivalent |
|----------------|------------------|-------------------|
| `~/Library/Containers/<bundle-id>` | `~/.var/app/<app-id>/` (Flatpak) | `%LOCALAPPDATA%\Packages\<PackageFamily>` (UWP) |
| `~/Library/Group Containers/` | `~/.local/share/<shared-id>/` | `%APPDATA%\<Company>\Shared\` |
| - | `~/snap/<app>/` (Snap) | - |

### 1.4 System-Level Application Data

| macOS Location | Linux Equivalent | Windows Equivalent |
|----------------|------------------|-------------------|
| `/Library/Application Support/<app>` | `/var/lib/<app>` | `C:\ProgramData\<Company>\<App>` |
| `/Library/Preferences/<app>.plist` | `/etc/<app>/` | `C:\ProgramData\<App>\` or Registry `HKLM\Software\<Company>` |
| `/Library/Caches/<app>` | `/var/cache/<app>` | `C:\ProgramData\<App>\Cache` |

### 1.5 Temporary/Hidden Cache Locations

| macOS Location | Linux Equivalent | Windows Equivalent |
|----------------|------------------|-------------------|
| `/private/var/folders/<random>/<random>/C/` | `/tmp/` or `$XDG_RUNTIME_DIR` | `%TEMP%` or `%LOCALAPPDATA%\Temp` |
| `/private/var/folders/<random>/<random>/T/` | `/tmp/` | `%TEMP%` |
| `/private/var/folders/<random>/<random>/X/` (code_sign_clone) | N/A (no equivalent) | N/A |

---

## Part 2: Known Parasites Database - Extended (30+ New Entries)

### 2.1 Browser Parasites

#### Chrome/Chromium (All Platforms)

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `com.google.keystone.agent` | `~/Library/LaunchAgents/` | Hourly update checker | Medium |
| macOS | `com.google.keystone.xpcservice` | `~/Library/LaunchAgents/` | XPC update service | Medium |
| macOS | `com.google.GoogleUpdater.wake` | `~/Library/LaunchAgents/` | Wake-up trigger | Medium |
| Linux | `google-chrome.desktop` | `~/.config/autostart/` | Background startup | Low |
| Linux | `chrome-gnome-shell` | `~/.local/share/gnome-shell/extensions/` | GNOME integration daemon | Low |
| Windows | `GoogleUpdate.exe` | `%LOCALAPPDATA%\Google\Update\` | Scheduled task updater | Medium |
| Windows | `GoogleCrashHandler.exe` | Task Scheduler | Crash telemetry | High |
| Windows | `Software Reporter Tool` | `%LOCALAPPDATA%\Google\Chrome\Application\*\` | Weekly "cleanup" scan | High |

**Chrome Data Remnants:**
```
# macOS
~/Library/Application Support/Google/Chrome/
~/Library/Caches/Google/Chrome/
~/Library/Google/GoogleSoftwareUpdate/
/private/var/folders/*/X/com.google.Chrome.code_sign_clone/

# Linux
~/.config/google-chrome/
~/.cache/google-chrome/
~/.local/share/applications/google-chrome.desktop

# Windows
%LOCALAPPDATA%\Google\Chrome\User Data\
%LOCALAPPDATA%\Google\Update\
%PROGRAMDATA%\Google\Update\
```

#### Firefox (All Platforms)

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `org.mozilla.plugincontainer` | Background process | Plugin isolation | Low |
| Linux | `firefox.desktop` | `~/.config/autostart/` | Optional startup | Low |
| Windows | `Firefox Default Browser Agent` | Task Scheduler | Default browser check | Medium |
| Windows | `Mozilla Maintenance Service` | Windows Services | Update service | Low |

**Firefox Data Remnants:**
```
# macOS
~/Library/Application Support/Firefox/
~/Library/Caches/Firefox/
~/Library/Mozilla/

# Linux
~/.mozilla/firefox/
~/.cache/mozilla/firefox/

# Windows
%APPDATA%\Mozilla\Firefox\
%LOCALAPPDATA%\Mozilla\Firefox\
%PROGRAMDATA%\Mozilla\
```

#### Microsoft Edge (All Platforms)

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `com.microsoft.EdgeUpdater` | `~/Library/LaunchAgents/` | Edge updater | Medium |
| Windows | `MicrosoftEdgeUpdate.exe` | Task Scheduler | Update checker | Medium |
| Windows | `Microsoft Edge Elevation Service` | Windows Services | Privileged updates | Low |

### 2.2 Adobe Suite Parasites (Extended)

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `com.adobe.agsservice` | `/Library/LaunchDaemons/` | Adobe Genuine Software - license check | High |
| macOS | `com.adobe.GC.Invoker-1.0` | `/Library/LaunchAgents/` | Analytics/telemetry collector | High |
| macOS | `com.adobe.ARMDC.Communicator` | `/Library/LaunchDaemons/` | ARM Desktop Communicator | Medium |
| macOS | `com.adobe.ARMDC.SMJobBlessHelper` | `/Library/LaunchDaemons/` | Privileged helper | Medium |
| macOS | `com.adobe.ARMDCHelper.*` | `/Library/LaunchAgents/` | Update helpers | Medium |
| macOS | `com.adobe.AdobeCreativeCloud` | `~/Library/LaunchAgents/` | CC Desktop app | Low |
| macOS | `com.adobe.acc.installer` | `/Library/LaunchDaemons/` | Installer service | Low |
| Linux | `adobe-cleaner` | `~/.config/autostart/` | Remnant cleanup agent | Low |
| Windows | `AdobeGCInvoker-1.0` | Task Scheduler | GC Invoker task | High |
| Windows | `Adobe Acrobat Update Task` | Task Scheduler | Update check | Medium |
| Windows | `AdobeAAMUpdater-1.0` | Task Scheduler | AAM Update | Medium |
| Windows | `AGSService` | Windows Services | Genuine Software service | High |
| Windows | `AdobeUpdateService` | Windows Services | Update service | Medium |

**Adobe Data Remnants (Massive):**
```
# macOS (often 6+ GB)
~/Library/Application Support/Adobe/
~/Library/Application Support/com.adobe.dunamis/
~/Library/Caches/Adobe/
~/Library/Caches/com.adobe.*/
~/Library/Preferences/com.adobe.*.plist
~/Library/Logs/Adobe/
/Library/Application Support/Adobe/

# Linux
~/.adobe/
~/.macromedia/
~/.config/Adobe/

# Windows (often 10+ GB)
%APPDATA%\Adobe\
%LOCALAPPDATA%\Adobe\
%PROGRAMDATA%\Adobe\
C:\Program Files\Adobe\
C:\Program Files\Common Files\Adobe\
```

### 2.3 Microsoft Suite Parasites

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `com.microsoft.update.agent` | `~/Library/LaunchAgents/` | Microsoft AutoUpdate | Low |
| macOS | `com.microsoft.autoupdate.helper` | `/Library/PrivilegedHelperTools/` | MAU helper | Low |
| macOS | `com.microsoft.OneDriveUpdaterDaemon` | `/Library/LaunchDaemons/` | OneDrive updater | Medium |
| Windows | `Microsoft Office Click-to-Run` | Windows Services | Office updates | Low |
| Windows | `OfficeBackgroundTaskHandlerRegistration` | Task Scheduler | Background tasks | Medium |
| Windows | `OfficeTelemetryAgentLogOn` | Task Scheduler | Telemetry | High |

### 2.4 Video Conferencing Parasites

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `us.zoom.ZoomDaemon` | `/Library/LaunchDaemons/` | Zoom background service | Medium |
| macOS | `us.zoom.updater` | `/Library/LaunchAgents/` | Update checker | Low |
| macOS | `com.webex.meetingmanager` | `/Library/LaunchAgents/` | WebEx daemon | Medium |
| macOS | `com.microsoft.teams.TeamsUpdaterDaemon` | `/Library/LaunchDaemons/` | Teams updater | Medium |
| Windows | `Zoom` | Task Scheduler | Multiple scheduled tasks | Medium |
| Windows | `ZoomOutlookIMPlugin` | Outlook plugins | Integration remnant | Low |
| Windows | `Teams Machine-Wide Installer` | Windows Services | Teams updater | Low |

### 2.5 Cloud Storage Parasites

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `com.dropbox.DropboxMacUpdate.agent` | `~/Library/LaunchAgents/` | Dropbox updater | Medium |
| macOS | `com.getdropbox.dropbox.garcon` | `/Library/LaunchDaemons/` | Finder integration | Low |
| macOS | `com.apple.icloud.*` | System | iCloud sync (don't remove!) | N/A |
| macOS | `com.google.drivefs.helper` | `/Library/LaunchDaemons/` | Google Drive File Stream | Low |
| Linux | `dropbox.desktop` | `~/.config/autostart/` | Dropbox autostart | Low |
| Windows | `Dropbox Update Task` | Task Scheduler | Update task | Low |
| Windows | `GoogleDriveFS` | Windows Services | Drive File Stream | Low |
| Windows | `OneDrive` | Startup | OneDrive sync | Low |

### 2.6 Development Tool Parasites

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `com.docker.socket` | `/Library/LaunchDaemons/` | Docker socket | Low |
| macOS | `com.docker.vmnetd` | `/Library/LaunchDaemons/` | Docker networking | Low |
| macOS | `io.macfuse.filesystems.macfuse` | `/Library/LaunchDaemons/` | macFUSE | Low |
| macOS | `org.wireshark.ChmodBPF` | `/Library/LaunchDaemons/` | Packet capture permissions | Low |
| macOS | `com.jetbrains.toolbox` | `~/Library/LaunchAgents/` | JetBrains Toolbox | Low |
| Linux | `docker.service` | `systemctl --user` | Docker daemon | Low |
| Linux | `jetbrains-toolbox.desktop` | `~/.config/autostart/` | Toolbox autostart | Low |
| Windows | `Docker Desktop Service` | Windows Services | Docker service | Low |
| Windows | `JetBrains Toolbox` | Startup | Toolbox autostart | Low |

### 2.7 Communication App Parasites

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `com.tinyspeck.slackmacgap.helper` | `~/Library/LaunchAgents/` | Slack background helper | Low |
| macOS | `com.spotify.webhelper` | `~/Library/LaunchAgents/` | Spotify web helper | Low |
| macOS | `com.hnc.Discord.shipit` | `~/Library/LaunchAgents/` | Discord updater | Low |
| Windows | `Discord` | Startup + Task Scheduler | Discord autostart | Low |
| Windows | `Spotify` | Startup | Spotify autostart | Low |
| Windows | `Slack` | Startup | Slack autostart | Low |

### 2.8 Security Software Parasites (Often Aggressive)

| Platform | Parasite Name | Location | Description | Risk |
|----------|--------------|----------|-------------|------|
| macOS | `com.avast.*` | Multiple LaunchDaemons | Avast persistence | High |
| macOS | `com.malwarebytes.*` | Multiple LaunchDaemons | Malwarebytes | Medium |
| macOS | `com.kaspersky.*` | Multiple LaunchDaemons | Kaspersky | High |
| macOS | `com.intego.*` | Multiple LaunchDaemons | Intego | Medium |
| Windows | Multiple AV services | Windows Services | AV real-time protection | High |
| Windows | `*Update*` tasks | Task Scheduler | AV update tasks | Medium |

---

## Part 3: Development Tool Cache Locations

### 3.1 Node.js Ecosystem

| Location | Platform | Typical Size | Safe to Remove |
|----------|----------|--------------|----------------|
| `~/.npm/_cacache/` | All | 1-10 GB | Yes |
| `~/.npm/_logs/` | All | 10-100 MB | Yes |
| `~/.nvm/versions/` (old versions) | All | 500 MB - 2 GB per version | Yes (if not in use) |
| `~/.yarn/cache/` | All | 1-5 GB | Yes |
| `~/.pnpm-store/` | All | 1-10 GB | Yes (careful - dedupes) |
| `node_modules/` (orphaned projects) | All | 100 MB - 1 GB per project | Yes (if project deleted) |
| `%APPDATA%\npm-cache\` | Windows | 1-10 GB | Yes |

### 3.2 Python Ecosystem

| Location | Platform | Typical Size | Safe to Remove |
|----------|----------|--------------|----------------|
| `~/.cache/pip/` | macOS/Linux | 500 MB - 5 GB | Yes |
| `~/.pyenv/versions/` (old versions) | All | 300 MB - 1 GB per version | Yes (if not in use) |
| `~/anaconda3/pkgs/` | All | 5-20 GB | Partial (use `conda clean`) |
| `~/miniconda3/pkgs/` | All | 2-10 GB | Partial (use `conda clean`) |
| `~/.virtualenvs/` (old envs) | All | 100-500 MB per env | Yes (if project deleted) |
| `__pycache__/` directories | All | 10-100 MB per project | Yes |
| `%LOCALAPPDATA%\pip\Cache\` | Windows | 500 MB - 5 GB | Yes |

### 3.3 Rust Ecosystem

| Location | Platform | Typical Size | Safe to Remove |
|----------|----------|--------------|----------------|
| `~/.cargo/registry/cache/` | All | 1-5 GB | Yes |
| `~/.cargo/registry/src/` | All | 1-5 GB | Yes |
| `~/.cargo/git/` | All | 500 MB - 2 GB | Yes |
| `~/.rustup/toolchains/` (old versions) | All | 500 MB - 1 GB per toolchain | Yes (if not in use) |
| `target/` directories (project) | All | 1-10 GB per project | Yes |

### 3.4 Java/JVM Ecosystem

| Location | Platform | Typical Size | Safe to Remove |
|----------|----------|--------------|----------------|
| `~/.m2/repository/` | All | 2-20 GB | Partial (can redownload) |
| `~/.gradle/caches/` | All | 2-10 GB | Yes |
| `~/.gradle/wrapper/dists/` | All | 500 MB - 2 GB | Yes (if not needed) |
| `~/.android/avd/` | All | 2-10 GB per AVD | Yes (if not in use) |
| `~/.android/cache/` | All | 500 MB - 2 GB | Yes |
| `~/.sdkman/archives/` | All | 500 MB - 2 GB | Yes |

### 3.5 Go Ecosystem

| Location | Platform | Typical Size | Safe to Remove |
|----------|----------|--------------|----------------|
| `~/go/pkg/mod/cache/` | All | 1-5 GB | Yes |
| `~/.cache/go-build/` | All | 500 MB - 2 GB | Yes |

### 3.6 Other Development Tools

| Location | Platform | Typical Size | Safe to Remove |
|----------|----------|--------------|----------------|
| `~/.composer/cache/` | All (PHP) | 100-500 MB | Yes |
| `~/.gem/` | All (Ruby) | 500 MB - 2 GB | Partial |
| `~/.bundle/cache/` | All (Ruby) | 100-500 MB | Yes |
| `~/.cocoapods/repos/` | macOS | 1-3 GB | Yes (can reclone) |
| `~/Library/Developer/Xcode/DerivedData/` | macOS | 5-50 GB | Yes |
| `~/Library/Developer/Xcode/Archives/` | macOS | 5-20 GB | No (your builds!) |
| `~/Library/Developer/CoreSimulator/Devices/` | macOS | 10-50 GB | Partial (inactive sims) |

---

## Part 4: Detection Algorithms

### 4.1 macOS Detection Algorithm

```bash
#!/bin/bash
# macOS Parasite Detection Algorithm

detect_macos_parasites() {
    local parasites=()

    # 1. Scan User LaunchAgents
    for plist in ~/Library/LaunchAgents/*.plist; do
        [[ -f "$plist" ]] || continue
        local name=$(basename "$plist" .plist)
        local bundle_id=$(echo "$name" | sed 's/\.agent$//' | sed 's/\.plist$//')

        # Check against known parasites
        if is_known_parasite "$name"; then
            parasites+=("PARASITE:USER_AGENT:$plist")
        # Check if corresponding app exists
        elif ! check_app_exists_macos "$bundle_id"; then
            parasites+=("ZOMBIE:USER_AGENT:$plist")
        fi
    done

    # 2. Scan System LaunchAgents (requires checking with elevated parsing)
    for plist in /Library/LaunchAgents/*.plist; do
        [[ -f "$plist" ]] || continue
        local name=$(basename "$plist" .plist)

        if is_known_parasite "$name" || ! check_app_exists_macos "$name"; then
            parasites+=("SYSTEM_AGENT:$plist")
        fi
    done

    # 3. Scan LaunchDaemons
    for plist in /Library/LaunchDaemons/*.plist; do
        [[ -f "$plist" ]] || continue
        local name=$(basename "$plist" .plist)

        # Skip Apple daemons
        [[ "$name" == com.apple.* ]] && continue

        if is_known_parasite "$name" || ! check_daemon_required "$name"; then
            parasites+=("DAEMON:$plist")
        fi
    done

    # 4. Scan code_sign_clone directories
    sudo find /private/var/folders -type d -name "*.code_sign_clone" 2>/dev/null | \
    while read clone_dir; do
        local bundle=$(basename "$clone_dir" .code_sign_clone)
        if ! check_app_exists_macos "$bundle"; then
            parasites+=("CODE_SIGN_CLONE:$clone_dir")
        fi
    done

    printf '%s\n' "${parasites[@]}"
}

check_app_exists_macos() {
    local bundle_id="$1"
    # Check if app exists via mdfind
    local result=$(mdfind "kMDItemCFBundleIdentifier == '$bundle_id'" 2>/dev/null)
    [[ -n "$result" ]]
}

is_known_parasite() {
    local name="$1"
    local parasites=(
        "com.adobe.agsservice"
        "com.adobe.GC.Invoker"
        "com.adobe.ARMDC"
        "com.google.keystone"
        "com.piriform.ccleaner"
        "us.zoom.updater"
        "com.spotify.webhelper"
    )

    for parasite in "${parasites[@]}"; do
        [[ "$name" == *"$parasite"* ]] && return 0
    done
    return 1
}
```

### 4.2 Linux Detection Algorithm

```bash
#!/bin/bash
# Linux Parasite Detection Algorithm

detect_linux_parasites() {
    local parasites=()

    # 1. Scan systemd user services
    while IFS= read -r service; do
        [[ -z "$service" ]] && continue
        local name=$(echo "$service" | awk '{print $1}')

        # Skip system services
        [[ "$name" == dbus* ]] && continue
        [[ "$name" == systemd* ]] && continue

        # Check if app exists
        local exec=$(systemctl --user show "$name" -p ExecStart 2>/dev/null | cut -d= -f2)
        local binary=$(echo "$exec" | awk '{print $1}')

        if [[ -n "$binary" ]] && ! command -v "$binary" &>/dev/null && ! [[ -f "$binary" ]]; then
            parasites+=("ZOMBIE:SYSTEMD_USER:$name")
        fi
    done < <(systemctl --user list-units --type=service --all 2>/dev/null | grep -v "^UNIT")

    # 2. Scan XDG autostart
    for desktop in ~/.config/autostart/*.desktop; do
        [[ -f "$desktop" ]] || continue
        local exec=$(grep "^Exec=" "$desktop" | cut -d= -f2 | awk '{print $1}')
        local name=$(basename "$desktop" .desktop)

        if [[ -n "$exec" ]] && ! command -v "$exec" &>/dev/null && ! [[ -f "$exec" ]]; then
            parasites+=("ZOMBIE:AUTOSTART:$desktop")
        fi
    done

    # 3. Check for orphaned Flatpak data
    if command -v flatpak &>/dev/null; then
        for app_dir in ~/.var/app/*/; do
            local app_id=$(basename "$app_dir")
            if ! flatpak list --app --columns=application 2>/dev/null | grep -q "^$app_id$"; then
                parasites+=("ORPHAN:FLATPAK:$app_dir")
            fi
        done
    fi

    # 4. Check for orphaned Snap data
    if command -v snap &>/dev/null; then
        for snap_dir in ~/snap/*/; do
            local snap_name=$(basename "$snap_dir")
            if ! snap list 2>/dev/null | grep -q "^$snap_name "; then
                parasites+=("ORPHAN:SNAP:$snap_dir")
            fi
        done
    fi

    # 5. Scan cron for orphaned entries
    crontab -l 2>/dev/null | while read -r line; do
        [[ "$line" == \#* ]] && continue
        [[ -z "$line" ]] && continue
        local cmd=$(echo "$line" | awk '{for(i=6;i<=NF;i++) printf $i" "; print ""}' | awk '{print $1}')
        if [[ -n "$cmd" ]] && ! command -v "$cmd" &>/dev/null && ! [[ -f "$cmd" ]]; then
            parasites+=("ZOMBIE:CRON:$line")
        fi
    done

    printf '%s\n' "${parasites[@]}"
}
```

### 4.3 Windows Detection Algorithm (PowerShell)

```powershell
# Windows Parasite Detection Algorithm

function Detect-WindowsParasites {
    $parasites = @()

    # 1. Check Startup folder items
    $startupPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    )

    foreach ($path in $startupPaths) {
        Get-ChildItem -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
            $target = $null
            if ($_.Extension -eq ".lnk") {
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($_.FullName)
                $target = $shortcut.TargetPath
            }

            if ($target -and !(Test-Path $target)) {
                $parasites += [PSCustomObject]@{
                    Type = "ZOMBIE"
                    Location = "STARTUP"
                    Path = $_.FullName
                    Target = $target
                }
            }
        }
    }

    # 2. Check Registry Run keys
    $runKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    )

    foreach ($key in $runKeys) {
        $regKey = Get-Item -Path $key -ErrorAction SilentlyContinue
        if ($regKey) {
            $regKey.GetValueNames() | ForEach-Object {
                $value = $regKey.GetValue($_)
                $executable = ($value -split '"')[1]
                if (-not $executable) { $executable = ($value -split ' ')[0] }

                if ($executable -and !(Test-Path $executable)) {
                    $parasites += [PSCustomObject]@{
                        Type = "ZOMBIE"
                        Location = "REGISTRY_RUN"
                        Path = "$key\$_"
                        Target = $executable
                    }
                }
            }
        }
    }

    # 3. Check Scheduled Tasks
    Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $_.TaskPath -notlike "\Microsoft\*"
    } | ForEach-Object {
        $actions = $_.Actions
        foreach ($action in $actions) {
            if ($action.Execute -and !(Test-Path $action.Execute)) {
                $parasites += [PSCustomObject]@{
                    Type = "ZOMBIE"
                    Location = "SCHEDULED_TASK"
                    Path = $_.TaskPath + $_.TaskName
                    Target = $action.Execute
                }
            }
        }
    }

    # 4. Check Services
    Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -notlike "*Windows*" -and
        $_.DisplayName -notlike "*Microsoft*"
    } | ForEach-Object {
        $wmiService = Get-WmiObject Win32_Service -Filter "Name='$($_.Name)'" -ErrorAction SilentlyContinue
        if ($wmiService -and $wmiService.PathName) {
            $executable = ($wmiService.PathName -split '"')[1]
            if (-not $executable) { $executable = ($wmiService.PathName -split ' ')[0] }

            if ($executable -and !(Test-Path $executable)) {
                $parasites += [PSCustomObject]@{
                    Type = "ZOMBIE"
                    Location = "SERVICE"
                    Path = $_.Name
                    Target = $executable
                }
            }
        }
    }

    # 5. Check orphaned AppData folders
    $knownOrphans = @(
        "Adobe", "JetBrains", "Discord", "Slack", "zoom.us"
    )

    foreach ($appName in $knownOrphans) {
        $paths = @(
            "$env:APPDATA\$appName",
            "$env:LOCALAPPDATA\$appName"
        )
        foreach ($path in $paths) {
            if (Test-Path $path) {
                # Check if corresponding program exists
                $programFiles = @(
                    "$env:ProgramFiles\$appName*",
                    "${env:ProgramFiles(x86)}\$appName*"
                )
                $exists = $false
                foreach ($pf in $programFiles) {
                    if (Test-Path $pf) { $exists = $true; break }
                }
                if (-not $exists) {
                    $parasites += [PSCustomObject]@{
                        Type = "ORPHAN"
                        Location = "APPDATA"
                        Path = $path
                        Target = "N/A"
                    }
                }
            }
        }
    }

    return $parasites
}
```

---

## Part 5: Safe-to-Remove Guidelines by Platform

### 5.1 Universal Safe Deletions (All Platforms)

| Category | Examples | Why Safe |
|----------|----------|----------|
| Package manager caches | npm, pip, cargo, gem caches | Redownloads on demand |
| Build caches | target/, node_modules/ (orphaned), __pycache__ | Rebuilds automatically |
| Thumbnail caches | thumbnails, icon caches | Regenerates automatically |
| Log files (old) | Logs older than 30 days | Historical only |
| Temp files | /tmp/*, %TEMP%/* | Designed to be temporary |
| Downloaded installers | .dmg, .exe, .pkg, .deb, .rpm | Already installed |

### 5.2 macOS-Specific Safe Deletions

| Location | Condition | Safe to Remove |
|----------|-----------|----------------|
| `~/Library/Caches/*` | Always | Yes |
| `~/Library/Logs/*` | If > 30 days old | Yes |
| `~/Library/Application Support/<App>` | If app uninstalled | Yes |
| `~/Library/Containers/<bundle-id>` | If app uninstalled | Yes |
| `~/Library/Group Containers/*<app>*` | If all related apps uninstalled | Yes |
| `~/Library/Saved Application State/*` | Always | Yes |
| `~/Library/LaunchAgents/*` | If app uninstalled | Yes (backup first) |
| `/private/var/folders/*/C/*` | Always | Yes |
| `/private/var/folders/*/T/*` | Always | Yes |
| `/private/var/folders/*/X/*.code_sign_clone` | If app uninstalled | Yes |
| `~/Library/Developer/Xcode/DerivedData/*` | Always | Yes |
| `~/Library/Developer/CoreSimulator/Devices/*` | Inactive simulators | Yes |

### 5.3 Linux-Specific Safe Deletions

| Location | Condition | Safe to Remove |
|----------|-----------|----------------|
| `~/.cache/*` | Always | Yes |
| `~/.local/share/<app>` | If app uninstalled | Yes |
| `~/.config/<app>` | If app uninstalled | Yes (backup first) |
| `~/.var/app/<app-id>` (Flatpak) | If flatpak uninstalled | Yes |
| `~/snap/<app>` | If snap uninstalled | Yes |
| `/var/cache/apt/archives/*.deb` | Always (apt clean) | Yes |
| `/var/cache/pacman/pkg/*` | Old packages (pacman -Sc) | Yes |
| `/var/tmp/*` | Always | Yes |
| `~/.local/share/Trash/*` | Always | Yes |
| Journal logs > 30 days | `journalctl --vacuum-time=30d` | Yes |
| Old kernels | `apt autoremove` | Yes |

### 5.4 Windows-Specific Safe Deletions

| Location | Condition | Safe to Remove |
|----------|-----------|----------------|
| `%TEMP%\*` | Always | Yes |
| `C:\Windows\Temp\*` | Always | Yes |
| `%LOCALAPPDATA%\Temp\*` | Always | Yes |
| `C:\Windows\SoftwareDistribution\Download\*` | Always | Yes |
| `C:\Windows\Prefetch\*` | Always | Yes (will rebuild) |
| `%APPDATA%\<App>` | If app uninstalled | Yes |
| `%LOCALAPPDATA%\<App>` | If app uninstalled | Yes |
| `C:\ProgramData\Package Cache\*` | Always | Yes |
| Recycle Bin | Always | Yes |
| Windows.old | After verifying stability | Yes |
| `$RECYCLE.BIN` on drives | Always | Yes |

### 5.5 NEVER Delete (All Platforms)

| Location | Platform | Reason |
|----------|----------|--------|
| `~/.ssh/` | All | SSH keys - unrecoverable |
| `~/.gnupg/` | All | GPG keys - unrecoverable |
| `~/Library/Keychains/` | macOS | Passwords and certificates |
| `/System/` | macOS | Operating system |
| `C:\Windows\System32\` | Windows | Operating system |
| `/etc/passwd`, `/etc/shadow` | Linux | User accounts |
| `/boot/` | Linux | Boot files |
| Registry backups | Windows | System recovery |

---

## Part 6: Implementation Recommendations

### 6.1 Priority Order for Implementation

1. **High Priority**
   - Browser parasites (Chrome, Firefox, Edge) - most common
   - Adobe suite parasites - highest resource impact
   - Development tool caches - largest space savings

2. **Medium Priority**
   - Video conferencing parasites (Zoom, Teams, WebEx)
   - Cloud storage orphans (Dropbox, Google Drive, OneDrive)
   - Communication app parasites (Slack, Discord, Spotify)

3. **Low Priority**
   - Security software remnants (complex, requires care)
   - System-level services (risky, requires admin)
   - Platform-specific edge cases

### 6.2 Testing Strategy

1. **Unit Tests**
   - Mock filesystem for each platform
   - Test parasite detection accuracy
   - Validate safe-to-remove rules

2. **Integration Tests**
   - Test on real VMs for each platform
   - Verify no system breakage
   - Confirm backup/restore works

3. **Dry-Run Mode**
   - Always default to dry-run
   - Show what would be removed
   - Require explicit confirmation for actual deletion

### 6.3 Rollback Mechanisms

| Platform | Backup Location | Restore Command |
|----------|-----------------|-----------------|
| macOS | `~/.cclean-killer/backup/YYYYMMDD/` | `cp -r backup/* original_location/` |
| Linux | `~/.cclean-killer/backup/YYYYMMDD/` | `cp -r backup/* original_location/` |
| Windows | `%USERPROFILE%\.cclean-killer\backup\YYYYMMDD\` | PowerShell copy |

---

## Appendix A: Quick Reference Tables

### A.1 XDG Base Directory Mapping (Linux)

| Variable | Default | Purpose |
|----------|---------|---------|
| `$XDG_CONFIG_HOME` | `~/.config` | User configuration |
| `$XDG_DATA_HOME` | `~/.local/share` | User data |
| `$XDG_CACHE_HOME` | `~/.cache` | Non-essential cache |
| `$XDG_STATE_HOME` | `~/.local/state` | State data |
| `$XDG_RUNTIME_DIR` | `/run/user/$UID` | Runtime files |

### A.2 Windows Environment Variables

| Variable | Typical Path | Purpose |
|----------|--------------|---------|
| `%APPDATA%` | `C:\Users\<user>\AppData\Roaming` | Roaming profile data |
| `%LOCALAPPDATA%` | `C:\Users\<user>\AppData\Local` | Local app data |
| `%TEMP%` | `C:\Users\<user>\AppData\Local\Temp` | Temporary files |
| `%PROGRAMDATA%` | `C:\ProgramData` | System-wide app data |
| `%PROGRAMFILES%` | `C:\Program Files` | 64-bit programs |
| `%PROGRAMFILES(X86)%` | `C:\Program Files (x86)` | 32-bit programs |

### A.3 macOS Special Directories

| Directory | Purpose | Notes |
|-----------|---------|-------|
| `/System/` | Operating system | Never modify |
| `/Library/` | System-wide application data | Requires admin |
| `~/Library/` | User application data | User-writable |
| `/private/var/` | Variable system data | Contains hidden caches |
| `/Applications/` | Applications | Standard install location |

---

## Research Methodology

This research was compiled from:

1. **Analysis of existing CClean-Killer codebase** - Current macOS implementation
2. **XDG Base Directory Specification** - Linux standard for application data
3. **Windows developer documentation** - Microsoft's recommended data locations
4. **Empirical testing** - Real-world observation of application behavior
5. **Security research** - Known persistence mechanisms by vendors
6. **Community knowledge** - Open-source cleanup tool patterns

---

*Document generated by CClean-Killer Research Agent*
*Last updated: Research Phase 1 Complete*
