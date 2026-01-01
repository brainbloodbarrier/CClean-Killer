# Testing Guidelines

Guidelines for testing CClean-Killer changes safely.

## Table of Contents

- [Testing Philosophy](#testing-philosophy)
- [Test Environment Setup](#test-environment-setup)
- [Testing Commands](#testing-commands)
- [Testing Scripts](#testing-scripts)
- [Safety Validation](#safety-validation)
- [Regression Testing](#regression-testing)

---

## Testing Philosophy

### Core Principles

1. **Never test on production systems** - Use VMs or containers
2. **Always dry-run first** - Verify before deletion
3. **Create test fixtures** - Use known test data
4. **Validate safety rules** - Ensure critical paths protected
5. **Document expected behavior** - Know what should happen

### Risk Levels

| Test Type | Risk | Environment |
|-----------|------|-------------|
| Read-only scanning | None | Any system |
| Dry-run cleanup | None | Any system |
| Actual cleanup | High | VM only |
| System modifications | Critical | Fresh VM only |

---

## Test Environment Setup

### Virtual Machine Setup

**macOS:**
- Use a macOS VM (VMware Fusion, Parallels)
- Take snapshot before testing
- Install common apps for realistic testing

**Linux:**
- Use Docker, LXC, or VM
- Any distribution works
- Install development tools for cache testing

**Windows:**
- Use Windows Sandbox or Hyper-V VM
- Windows 10/11 preferred
- Take checkpoint before testing

### Creating Test Fixtures

Create predictable test data:

```bash
# macOS test fixtures
mkdir -p ~/Library/Application\ Support/TestOrphanApp
echo "test data" > ~/Library/Application\ Support/TestOrphanApp/data.db

mkdir -p ~/Library/Caches/com.test.cache
dd if=/dev/zero of=~/Library/Caches/com.test.cache/large.file bs=1M count=100

# Create fake LaunchAgent
cat > ~/Library/LaunchAgents/com.test.orphan.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.test.orphan</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/true</string>
    </array>
</dict>
</plist>
EOF
```

```bash
# Linux test fixtures
mkdir -p ~/.config/test-orphan-app
mkdir -p ~/.cache/test-cache
dd if=/dev/zero of=~/.cache/test-cache/large.file bs=1M count=100
mkdir -p ~/.local/share/test-orphan-data
```

---

## Testing Commands

### Test /scan

```bash
# Run scan and verify output
/scan

# Expected:
# - Disk overview displayed
# - Top directories listed by size
# - No errors or warnings
# - Developer tools detected (if present)
```

**Validation Checklist:**
- [ ] Disk usage percentages accurate
- [ ] Sizes formatted correctly (GB, MB)
- [ ] All expected directories scanned
- [ ] No permission errors displayed to user
- [ ] Output is readable and well-formatted

### Test /parasites

```bash
# Create a test parasite
cat > ~/Library/LaunchAgents/com.test.parasite.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.test.parasite</string>
    <key>ProgramArguments</key>
    <array><string>/usr/bin/true</string></array>
</dict>
</plist>
EOF

# Run parasite detection
/parasites

# Expected:
# - Test parasite detected as orphan
# - Apple services NOT listed
# - Status (loaded/not loaded) shown
```

**Validation Checklist:**
- [ ] Known parasites correctly identified
- [ ] Orphan agents detected (no matching app)
- [ ] Apple/system agents excluded
- [ ] Status accurately reflects launchctl state
- [ ] Removal instructions shown

### Test /clean

```bash
# Always start with dry-run
/clean --dry-run

# Expected:
# - Lists what WOULD be removed
# - Shows sizes for each item
# - No actual deletions occur
```

**Validation Checklist:**
- [ ] Dry-run shows all targets
- [ ] Sizes calculated correctly
- [ ] Critical paths NOT listed
- [ ] Summary shows total potential savings

### Test /report

```bash
/report

# Expected:
# - Complete system analysis
# - Recommendations prioritized
# - Actionable commands provided
```

---

## Testing Scripts

### Script Test Protocol

```bash
# 1. Make script executable
chmod +x scripts/macos/scan.sh

# 2. Run with verbose output
bash -x scripts/macos/scan.sh 2>&1 | tee test-output.log

# 3. Check for errors
grep -i error test-output.log
grep -i warning test-output.log

# 4. Verify output format
cat test-output.log
```

### Testing Cleanup Scripts

**Critical: Only on test VM!**

```bash
# 1. Create test fixtures first
./create-test-fixtures.sh

# 2. Note disk space before
df -h /

# 3. Dry run
./scripts/macos/clean.sh --dry-run

# 4. Verify test fixtures would be cleaned
# Should see: TestOrphanApp, test-cache, etc.

# 5. Actual run (VM only!)
./scripts/macos/clean.sh

# 6. Verify disk space freed
df -h /

# 7. Verify test fixtures removed
ls ~/Library/Application\ Support/TestOrphanApp  # Should fail
```

### Testing Parasite Scripts

```bash
# 1. Create test LaunchAgent
./create-test-parasite.sh

# 2. Load it
launchctl load ~/Library/LaunchAgents/com.test.parasite.plist

# 3. Verify detection
./scripts/macos/find-parasites.sh | grep "com.test.parasite"

# 4. Test removal
launchctl unload ~/Library/LaunchAgents/com.test.parasite.plist
rm ~/Library/LaunchAgents/com.test.parasite.plist

# 5. Verify no longer detected
./scripts/macos/find-parasites.sh | grep "com.test.parasite"  # Should fail
```

---

## Safety Validation

### Critical Path Protection Test

Verify that critical paths are NEVER touched:

```bash
# Create a test file in a protected location (requires sudo)
# DO NOT ACTUALLY RUN THIS - just verify the logic would prevent it

# The cleanup should NEVER offer to remove:
# - /System/*
# - ~/.ssh/*
# - ~/.gnupg/*
# - ~/Library/Keychains/*
```

**Validation:**
```bash
# Run dry-run
./scripts/macos/clean.sh --dry-run 2>&1 | tee output.log

# Verify protected paths NOT in output
! grep -E "(\.ssh|\.gnupg|Keychains|/System/)" output.log
echo "Protected paths NOT targeted: PASS"
```

### In-Use File Detection

```bash
# Open a file
tail -f /tmp/test-file &
PID=$!

# Try to detect it's in use
lsof /tmp/test-file

# Cleanup should skip files in use
# Kill the tail
kill $PID
```

### Permission Handling

```bash
# Test script handles permission errors gracefully
./scripts/macos/scan.sh 2>&1 | grep -i "permission denied"
# Should see NO errors (redirected to /dev/null in script)
```

---

## Regression Testing

### After Changes

When modifying code, verify:

1. **Existing functionality works**
   ```bash
   /scan      # Still works?
   /parasites # Still detects known parasites?
   /clean --dry-run  # Still shows correct targets?
   ```

2. **New functionality works**
   - Test the specific feature added

3. **No new safety issues**
   - Critical paths still protected?
   - Dry-run still works?

### Test Matrix

| Platform | Command | Status |
|----------|---------|--------|
| macOS | /scan | Pass/Fail |
| macOS | /parasites | Pass/Fail |
| macOS | /clean --dry-run | Pass/Fail |
| Linux | /scan | Pass/Fail |
| Linux | /clean --dry-run | Pass/Fail |
| Windows | /scan | Pass/Fail |
| Windows | /clean --dry-run | Pass/Fail |

---

## Test Helper Scripts

### Create Test Fixtures Script

```bash
#!/bin/bash
# create-test-fixtures.sh

echo "Creating test fixtures..."

# Orphan app data
mkdir -p ~/Library/Application\ Support/TestOrphanApp
echo "test" > ~/Library/Application\ Support/TestOrphanApp/data

# Cache data
mkdir -p ~/Library/Caches/com.test.cache
dd if=/dev/zero of=~/Library/Caches/com.test.cache/file bs=1M count=10 2>/dev/null

# Test LaunchAgent
cat > ~/Library/LaunchAgents/com.test.orphan.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.test.orphan</string>
    <key>ProgramArguments</key>
    <array><string>/usr/bin/true</string></array>
</dict>
</plist>
EOF

echo "Test fixtures created."
```

### Cleanup Test Fixtures Script

```bash
#!/bin/bash
# cleanup-test-fixtures.sh

echo "Removing test fixtures..."

rm -rf ~/Library/Application\ Support/TestOrphanApp
rm -rf ~/Library/Caches/com.test.cache
rm -f ~/Library/LaunchAgents/com.test.orphan.plist

echo "Test fixtures removed."
```

---

## Reporting Test Results

When submitting a PR, include test results:

```markdown
## Test Results

### Environment
- Platform: macOS 14.x / Ubuntu 24.04 / Windows 11
- Claude Code version: x.x.x

### Tests Performed
- [x] /scan runs without errors
- [x] /parasites detects test fixtures
- [x] /clean --dry-run shows correct targets
- [x] Protected paths NOT targeted
- [x] Cleanup removes test fixtures (VM only)

### Issues Found
- None / List any issues
```
