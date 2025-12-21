# Safe to Remove Guide

A definitive guide on what's safe to delete and what requires caution.

## Safety Tiers

### Tier 1: Always Safe (Green Light)
These can always be deleted without risk:

| Category | Examples | Why Safe |
|----------|----------|----------|
| **Caches** | `~/Library/Caches/*`, `~/.cache/*` | Regenerated automatically |
| **Temp files** | `/tmp/*`, `%TEMP%/*` | Designed to be deleted |
| **Package manager caches** | npm, pip, brew caches | Can redownload |
| **Downloaded installers** | `*.dmg`, `*.exe`, `*.pkg` | Already installed |
| **Trash** | `~/.Trash/*`, Recycle Bin | User already deleted |
| **Log files** | `~/Library/Logs/*`, `/var/log/` (old) | Historical only |

### Tier 2: Safe If App Removed (Yellow Light)
These are safe IF the corresponding app is uninstalled:

| Category | Check Before Deleting |
|----------|----------------------|
| `~/Library/Application Support/<App>` | App not in /Applications |
| `~/Library/Containers/<bundle-id>` | App not installed |
| `~/.config/<app>` | App not installed |
| Registry entries | App uninstalled |

### Tier 3: Requires Backup (Orange Light)
Always backup before deleting:

| Category | Risk |
|----------|------|
| LaunchAgents/Daemons | May break functionality |
| `/Library/Application Support/` | System-wide impact |
| Registry (Windows) | System stability |
| `/etc/` configs (Linux) | Service configuration |

### Tier 4: Never Delete (Red Light)
**NEVER** delete these:

| Location | Why |
|----------|-----|
| `/System/` (macOS) | Operating system |
| `C:\Windows\System32\` | Operating system |
| `~/.ssh/` | SSH keys - unrecoverable! |
| `~/.gnupg/` | GPG keys - unrecoverable! |
| `~/Library/Keychains/` | Passwords and certificates |
| `/etc/passwd`, `/etc/shadow` | User accounts |

## Detailed Safe Deletions

### Package Manager Caches

#### npm (All Platforms)
```bash
npm cache clean --force
rm -rf ~/.npm/_cacache
```
**Safe because:** Packages redownload on demand

#### Homebrew (macOS)
```bash
brew cleanup --prune=all
brew autoremove
```
**Safe because:** Only removes old versions and downloads

#### pip (All Platforms)
```bash
pip cache purge
```
**Safe because:** Packages redownload on demand

#### apt (Linux)
```bash
sudo apt clean
sudo apt autoremove
```
**Safe because:** Removes cached packages, keeps installed ones

### IDE Caches

#### VS Code / Cursor
```bash
rm -rf ~/Library/Application\ Support/Code/CachedExtensionVSIXs/*
rm -rf ~/Library/Application\ Support/Cursor/CachedExtensionVSIXs/*
```
**Safe because:** Extension cache, regenerates on update

#### JetBrains
```bash
rm -rf ~/Library/Caches/JetBrains/*/
```
**Safe because:** Index cache, rebuilds on startup

### Docker

```bash
docker image prune -a    # Unused images
docker volume prune      # Orphaned volumes
docker builder prune     # Build cache
```
**Safe because:** Only removes unused resources

**CAUTION:** Don't delete images you're actively using!

### Time Machine (macOS)

```bash
tmutil listlocalsnapshots /
sudo tmutil deletelocalsnapshots <date>
```
**Safe IF:** You have external Time Machine backup

**CAUTION:** These are your only local backup!

## Orphan Detection Rules

An application's data is ORPHANED if:

1. **App not installed** - Check `/Applications/`, `which <command>`
2. **Not running** - Check `ps aux | grep <app>`
3. **No dependencies** - Other apps don't need it
4. **Not a system component** - Not Apple/Microsoft/system

### Cross-Reference Commands

#### macOS
```bash
# Check if app exists
ls /Applications/ | grep -i "<app>"

# Check if process running
pgrep -i "<app>"

# Check if bundle ID exists
mdfind "kMDItemCFBundleIdentifier == '*<app>*'"
```

#### Linux
```bash
# Check if package installed
dpkg -l | grep -i "<app>"   # Debian
rpm -qa | grep -i "<app>"   # RHEL

# Check if command exists
which <command>
```

## What to Keep

### System Health
- Keep ONE backup solution working
- Keep system logs for recent period (30 days)
- Keep crash reports until issues resolved

### Development
- Keep `node_modules` in active projects
- Keep virtual environments for active projects
- Keep recent IDE settings

### Security
- ALL SSH keys
- ALL GPG keys
- ALL certificates
- Password manager data

## Pre-Deletion Checklist

Before deleting anything in Tier 2-3:

- [ ] App is confirmed uninstalled
- [ ] No process using the files (`lsof <path>`)
- [ ] Backup created (for Tier 3)
- [ ] Not a system component
- [ ] Not shared by other apps
- [ ] Know how to restore if needed

## Recovery Options

If you deleted something important:

### macOS
1. Time Machine backup
2. `.cclean-killer/backup/` (if using our backup)
3. Reinstall app to regenerate data

### Linux
1. Timeshift snapshot
2. `/home/.snapshot/` (if on ZFS/btrfs)
3. Reinstall package

### Windows
1. System Restore
2. Previous Versions (if enabled)
3. Reinstall application
