# Troubleshooting

Solutions to common issues with CClean-Killer.

## Table of Contents

- [Scanning Issues](#scanning-issues)
- [Cleanup Issues](#cleanup-issues)
- [Permission Problems](#permission-problems)
- [Platform-Specific Issues](#platform-specific-issues)
- [Recovery](#recovery)

---

## Scanning Issues

### Scan takes too long

**Problem:** `/scan` runs for several minutes.

**Solutions:**
1. Use quick scan mode:
   ```
   /scan --quick
   ```

2. Large directories with many files can be slow. Check for:
   - node_modules folders
   - .git directories
   - Photo libraries

3. Docker images/volumes can take time to calculate.

---

### Disk usage doesn't match Finder/Explorer

**Problem:** Reported sizes differ from what the OS shows.

**Explanation:**
- CClean-Killer shows actual file sizes
- Finder/Explorer may show "size on disk" (includes slack space)
- APFS/ZFS snapshots can cause differences
- Some system files are hidden from normal tools

**Solutions:**
1. Check for Time Machine local snapshots:
   ```bash
   tmutil listlocalsnapshots /
   ```

2. Check for APFS snapshots:
   ```bash
   diskutil apfs listSnapshots disk1s1
   ```

---

### "Permission denied" errors during scan

**Problem:** Some directories show permission errors.

**Explanation:** This is normal - some system directories require elevated access.

**Solution:** The scripts already redirect permission errors to null. If you're seeing errors, you may be running a script directly instead of through Claude Code.

For direct script execution:
```bash
./scripts/macos/scan.sh 2>/dev/null
```

---

## Cleanup Issues

### Cleanup didn't free expected space

**Problem:** Ran `/clean` but disk space didn't increase as expected.

**Possible causes:**

1. **Trash not emptied**
   ```bash
   rm -rf ~/.Trash/*
   ```

2. **Time Machine snapshots**
   ```bash
   sudo tmutil deletelocalsnapshots /
   ```

3. **Docker still holding data**
   ```bash
   docker system prune -a --volumes
   ```

4. **Files were in use during cleanup**
   - Close applications
   - Run cleanup again

---

### "File in use" warnings

**Problem:** Some files couldn't be removed because they're in use.

**Solutions:**
1. Close the application using the files
2. Run cleanup again
3. For stubborn files:
   ```bash
   lsof <path-to-file>  # See what's using it
   ```

---

### LaunchAgent won't unload

**Problem:** `launchctl unload` fails with an error.

**Solutions:**

1. Check if it's a system service (can't unload):
   ```bash
   launchctl print system/com.example.service
   ```

2. Force unload:
   ```bash
   launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.example.plist
   ```

3. For daemons:
   ```bash
   sudo launchctl bootout system /Library/LaunchDaemons/com.example.plist
   ```

---

## Permission Problems

### "Operation not permitted" on macOS

**Problem:** Even with sudo, some operations fail.

**Cause:** System Integrity Protection (SIP) or Full Disk Access.

**Solutions:**

1. Grant Terminal Full Disk Access:
   - System Preferences > Privacy & Security > Full Disk Access
   - Add Terminal (or Claude Code)

2. For SIP-protected files:
   - These are intentionally protected
   - Usually shouldn't be deleted anyway

---

### Need sudo for cleanup

**Problem:** Some items require sudo to remove.

**Explanation:** System-wide LaunchDaemons and `/Library/` contents require admin access.

**Solution:** Claude Code will indicate when sudo is needed:
```bash
sudo rm /Library/LaunchDaemons/com.example.plist
```

---

### Script won't run

**Problem:** Permission denied when running script.

**Solution:**
```bash
chmod +x scripts/macos/scan.sh
./scripts/macos/scan.sh
```

---

## Platform-Specific Issues

### macOS: Keychain access prompts

**Problem:** Cleanup triggers keychain password prompts.

**Explanation:** Some plists reference keychain items.

**Solution:**
- This is normal when unloading agents
- Enter password to allow unload
- Or click "Deny" and manually remove the plist

---

### Linux: systemd service issues

**Problem:** User service won't stop.

**Solutions:**
```bash
# Stop the service
systemctl --user stop example.service

# Disable it
systemctl --user disable example.service

# Remove the file
rm ~/.config/systemd/user/example.service

# Reload systemd
systemctl --user daemon-reload
```

---

### Windows: File locked

**Problem:** "File in use" errors on Windows.

**Solutions:**
1. Close all applications
2. Use Resource Monitor to find the process:
   - Search "Resource Monitor"
   - CPU tab > Associated Handles
   - Search for file name

3. Reboot and try again

4. Use PowerShell (admin):
   ```powershell
   Stop-Process -Name "ProcessName" -Force
   ```

---

## Recovery

### Accidentally deleted something important

**What to do:**

1. **Stop immediately** - Don't run more commands

2. **Check backups:**
   ```bash
   ls ~/.cclean-killer/backup/
   ```

3. **Check Time Machine (macOS):**
   - Open the folder location in Finder
   - Enter Time Machine
   - Navigate to date before deletion

4. **Reinstall the application**
   - Most app data is recreated on install

---

### App not working after cleanup

**Problem:** An app broke after removing its data.

**Solutions:**

1. **Reinstall the app**
   - Most apps create fresh data on install

2. **Restore from backup:**
   ```bash
   cp -r ~/.cclean-killer/backup/DATE/AppData ~/Library/Application\ Support/AppName
   ```

3. **Check what was removed:**
   ```bash
   cat ~/.cclean-killer/cleanup.log
   ```

---

### How to restore a LaunchAgent

```bash
# 1. Find the backup
ls ~/.cclean-killer/backup/*/

# 2. Copy it back
cp ~/.cclean-killer/backup/20241221/com.example.plist ~/Library/LaunchAgents/

# 3. Load it
launchctl load ~/Library/LaunchAgents/com.example.plist

# 4. Verify
launchctl list | grep com.example
```

---

## Getting Help

### Information to gather

When reporting an issue, include:

1. **Platform and version:**
   ```bash
   # macOS
   sw_vers

   # Linux
   cat /etc/os-release

   # Windows
   winver
   ```

2. **Command that failed:**
   - Exact command typed
   - Full error message

3. **Relevant output:**
   ```bash
   /scan 2>&1 | tee scan-output.txt
   ```

### Where to get help

- GitHub Issues: Report bugs and request features
- README: Check for updates
- This documentation: Search for your issue

---

## FAQ

**Q: Will this delete my documents/photos/music?**
A: No. CClean-Killer only targets caches, app data, and system debris. Personal files are never touched.

**Q: Is it safe to use daily?**
A: Yes, but it's unnecessary. Weekly or monthly scans are sufficient.

**Q: Why use this instead of built-in cleanup?**
A: CClean-Killer finds things macOS/Windows cleanup misses, like orphaned app data and parasite daemons.

**Q: Can I undo a cleanup?**
A: For Tier 3 items (LaunchAgents), yes - they're backed up. For caches, no, but they regenerate automatically.

**Q: Why doesn't it run in the background?**
A: By design. Background processes are exactly what we're trying to eliminate.
