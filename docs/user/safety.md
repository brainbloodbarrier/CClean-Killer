# Safety Guidelines

Understanding what's safe to remove and what to protect.

## Table of Contents

- [Safety Tiers](#safety-tiers)
- [Never Delete](#never-delete)
- [Always Safe](#always-safe)
- [Conditional Safety](#conditional-safety)
- [Best Practices](#best-practices)
- [Recovery Options](#recovery-options)

---

## Safety Tiers

CClean-Killer categorizes cleanup targets into four safety tiers:

### Tier 1: Always Safe (Green)

Delete without concern - these regenerate automatically.

| Category | Examples | Why Safe |
|----------|----------|----------|
| Caches | `~/Library/Caches/*` | Rebuilt on demand |
| Temp files | `/tmp/*`, `%TEMP%/*` | Designed for deletion |
| Package caches | npm, pip, brew caches | Redownloads as needed |
| Downloaded installers | `*.dmg`, `*.pkg` | Already installed |
| Trash | `~/.Trash/*` | Already deleted by you |
| Logs | `~/Library/Logs/*` | Historical only |

### Tier 2: Safe If Verified (Yellow)

Safe IF the corresponding application is uninstalled.

| Category | Check Before Deleting |
|----------|----------------------|
| Application Support | App not in /Applications |
| Containers | Bundle ID app not installed |
| Group Containers | No related apps installed |
| Preferences | App fully removed |

### Tier 3: Backup First (Orange)

Create a backup before removing.

| Category | Risk |
|----------|------|
| LaunchAgents | May break app functionality |
| LaunchDaemons | System-wide impact |
| System preferences | May affect services |
| Registry entries (Windows) | System stability |

### Tier 4: Never Delete (Red)

**NEVER** delete these under any circumstances.

| Location | Why |
|----------|-----|
| `/System/` | Operating system |
| `~/.ssh/` | SSH keys - unrecoverable |
| `~/.gnupg/` | GPG keys - unrecoverable |
| `~/Library/Keychains/` | Passwords |
| System32 (Windows) | Operating system |

---

## Never Delete

These paths are absolutely protected:

### All Platforms

```
~/.ssh/              # SSH keys - your server access
~/.gnupg/            # GPG keys - your encryption
```

### macOS

```
/System/             # macOS itself
~/Library/Keychains/ # Passwords and certificates
/usr/                # System binaries
/bin/                # Core utilities
```

### Linux

```
/etc/passwd          # User accounts
/etc/shadow          # Password hashes
/boot/               # Boot configuration
/usr/                # System programs
```

### Windows

```
C:\Windows\System32\ # Core Windows files
C:\Windows\WinSxS\   # Windows components
User profile folders # Without full backup
```

---

## Always Safe

These can always be removed without risk:

### Cache Directories

**macOS:**
```
~/Library/Caches/*
```

**Linux:**
```
~/.cache/*
```

**Windows:**
```
%TEMP%\*
%LOCALAPPDATA%\Temp\*
```

### Package Manager Caches

| Tool | Location | Safe Command |
|------|----------|--------------|
| npm | `~/.npm/_cacache` | `npm cache clean --force` |
| pip | `~/.cache/pip` | `pip cache purge` |
| Homebrew | `~/Library/Caches/Homebrew` | `brew cleanup --prune=all` |
| apt | `/var/cache/apt` | `sudo apt clean` |

### IDE Caches

| IDE | Location | Safe to Remove |
|-----|----------|----------------|
| VS Code | `CachedExtensionVSIXs/*` | Yes |
| JetBrains | `~/Library/Caches/JetBrains` | Yes |
| Xcode | `~/Library/Developer/Xcode/DerivedData` | Yes |

### Downloaded Files

```
~/Downloads/*.dmg    # Disk images
~/Downloads/*.pkg    # Package installers
~/Downloads/*.exe    # Windows installers
~/Downloads/*.zip    # Already extracted
```

---

## Conditional Safety

Safe ONLY if conditions are met:

### Orphaned App Data

Safe if:
- [ ] App is not in /Applications
- [ ] App is not running
- [ ] No other apps depend on it
- [ ] Not a system component

**Check:**
```bash
# Is app installed?
ls /Applications/ | grep -i "AppName"

# Is it running?
pgrep -i "AppName"
```

### LaunchAgents/Daemons

Safe if:
- [ ] Parent app is uninstalled
- [ ] Not a system component
- [ ] Backup created
- [ ] Unloaded before removal

**Check:**
```bash
# Is the agent loaded?
launchctl list | grep "com.example"
```

### Docker Data

Safe if:
- [ ] Images are not in use
- [ ] Volumes are not needed
- [ ] You can rebuild containers

**Commands:**
```bash
# See what would be removed
docker system df

# Remove unused (with caution)
docker system prune -a
```

---

## Best Practices

### Before Any Cleanup

1. **Understand what you're deleting**
   ```
   /scan
   /clean --dry-run
   ```

2. **Check if apps are running**
   ```bash
   # Before removing app data, ensure it's not running
   pgrep -i "AppName"
   ```

3. **Create backups for Tier 3 items**
   ```bash
   mkdir -p ~/.cclean-killer/backup
   cp -r ~/Library/LaunchAgents/*.plist ~/.cclean-killer/backup/
   ```

### During Cleanup

4. **Always use dry-run first**
   ```
   /clean --dry-run
   ```

5. **Start with safest items**
   - Caches first
   - Then orphans
   - LaunchAgents last

6. **Review each category**
   - Don't just blindly clean everything

### After Cleanup

7. **Verify system works**
   - Open apps you use
   - Check for error dialogs

8. **Save the report**
   ```
   /report --markdown
   ```

---

## Recovery Options

### If You Deleted Something Important

**macOS:**
1. **Time Machine**
   - Browse backups
   - Restore specific files

2. **CClean-Killer Backup**
   - Check `~/.cclean-killer/backup/`
   - Restore with `cp`

3. **Reinstall App**
   - Data directories are often recreated

**Linux:**
1. **Timeshift** (if configured)
2. **Reinstall package**
3. **Restore from backup

**Windows:**
1. **System Restore**
   - Restore to earlier point

2. **Previous Versions**
   - Right-click folder
   - "Restore previous versions"

### Restoring a LaunchAgent

```bash
# Copy from backup
cp ~/.cclean-killer/backup/20241221/com.example.plist ~/Library/LaunchAgents/

# Load it
launchctl load ~/Library/LaunchAgents/com.example.plist
```

### Reinstalling Package Manager Caches

They rebuild automatically when you install packages:

```bash
# npm - just install something
npm install some-package

# Homebrew - just install/update
brew update

# pip - just install
pip install some-package
```

---

## Summary Table

| Type | Risk | Action |
|------|------|--------|
| Caches | None | Delete freely |
| Package caches | None | Delete freely |
| Orphaned data | Low | Verify app removed first |
| LaunchAgents | Medium | Backup before removing |
| LaunchDaemons | Medium-High | Backup + careful verification |
| SSH keys | Critical | NEVER delete |
| Keychains | Critical | NEVER delete |
| System files | Critical | NEVER delete |

---

**Remember:** When in doubt, don't delete. Use `--dry-run` to preview first.
