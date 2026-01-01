---
name: knowledge-manager
description: Research and document new parasites, cleanup locations, and hidden data. Use when asked to add a parasite, discover zombie processes, research app persistence, add cleanup locations, or run iterative discovery loops (Ralph Wiggum). Handles all knowledge base modifications.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, WebSearch, WebFetch
---

# Knowledge Manager

Research, document, and implement new parasites and cleanup locations for the CClean-Killer database.

## Purpose

Expand the project's knowledge base by:
- Researching new parasites (LaunchAgents/Daemons from uninstalled apps)
- Adding new cleanup locations
- Running iterative discovery workflows (Ralph Wiggum loops)

## Modes

### Mode: add-parasite

Add a new parasite to the database after researching its behavior.

**When to use:** User says "add parasite", "new detection for [app]", "research [app] persistence"

**Workflow:**

1. **Research Phase**
   - Web search for "[app] macOS LaunchAgent" and "[app] persistence mechanism"
   - Check common locations on user's system:
     ```bash
     ls -la ~/Library/LaunchAgents/ | grep -i "[app]"
     ls -la /Library/LaunchAgents/ | grep -i "[app]"
     ls -la /Library/LaunchDaemons/ | grep -i "[app]"
     ```
   - Read plist files to understand bundle ID patterns

2. **Document Phase**
   - Add entry to `knowledge/common-parasites.md` following existing format:
     - Service name and pattern
     - Parent app
     - Risk level (Low/Medium/High)
     - File locations
     - Removal commands

3. **Implementation Phase**
   - Add pattern to `knowledge/parasite-fingerprints.json`
   - Update pattern array in `scripts/macos/find-parasites.sh` if needed

4. **Validation Phase**
   - Run detection to verify pattern works:
     ```bash
     ./scripts/macos/find-parasites.sh --verbose | grep -i "[app]"
     ```

**Files Modified:**
- `knowledge/common-parasites.md`
- `knowledge/parasite-fingerprints.json`
- `scripts/macos/find-parasites.sh` (PARASITE_PATTERNS array)

---

### Mode: add-location

Add a new cleanup scan location to the project.

**When to use:** User says "add location", "scan [path]", "add cleanup target"

**Workflow:**

1. **Research Phase**
   - Analyze what data lives in the location
   - Determine if content regenerates automatically (cache vs config)
   - Check typical sizes
   - Identify which apps use it

2. **Document Phase**
   - Add to `knowledge/hidden-locations/macos.md` (or linux.md, windows.md)
   - Include:
     - Path pattern
     - Typical size range
     - Content type (cache/config/data/logs)
     - Safety tier (1-4)

3. **Implementation Phase**
   - Add scan function to `scripts/macos/scan.sh`
   - Add cleanup logic to `scripts/macos/clean.sh` if appropriate
   - Add skip patterns for sensitive data

**Files Modified:**
- `knowledge/hidden-locations/*.md`
- `scripts/macos/scan.sh`
- `scripts/macos/clean.sh`

---

### Mode: ralph-loop

Run an iterative discovery workflow to find unknown parasites on the current system.

**When to use:** User says "ralph loop", "discover parasites", "find unknown zombies", "iterative discovery"

**Workflow:**

1. **Discovery Phase**
   - Scan all LaunchAgent/Daemon locations
   - Compare against known parasites database
   - Identify unknown items:
     ```bash
     for plist in ~/Library/LaunchAgents/*.plist /Library/LaunchAgents/*.plist; do
       name=$(basename "$plist" .plist)
       if ! grep -q "$name" knowledge/parasite-fingerprints.json; then
         echo "UNKNOWN: $plist"
       fi
     done
     ```

2. **Research Each Unknown**
   - For each unknown, run the add-parasite workflow
   - Research bundle ID, parent app, behavior

3. **Iterate Until Complete**
   - Continue until all unknowns are categorized
   - Output `<promise>DISCOVERY COMPLETE</promise>` when done

**Note:** This mode is designed for Ralph Wiggum iterative loops. Each iteration should process 1-3 unknowns, allowing the loop to continue until all are handled.

---

## Safety Rules

1. **NEVER** suggest deleting system files (`com.apple.*`)
2. **ALWAYS** verify parent app before flagging as zombie
3. **VERIFY** patterns don't match legitimate services
4. **INCLUDE** both user and system locations in research
5. **DOCUMENT** sudo requirements for system-level removal

## Entry Templates

### Parasite Database Entry (common-parasites.md)

```markdown
| Service | Pattern | Parent App | Risk Level |
|---------|---------|------------|------------|
| App Name Service | `com.vendor.app.*` | App Name | Medium |
```

### Detailed Profile (for major parasites)

```markdown
### App Name

**What it is:** Brief description.

**Files:**
\`\`\`
~/Library/LaunchAgents/com.vendor.app.plist
/Library/LaunchDaemons/com.vendor.app.daemon.plist
~/Library/Application Support/AppName/
\`\`\`

**Behavior:**
- Bullet point behaviors

**Removal:**
\`\`\`bash
launchctl unload ~/Library/LaunchAgents/com.vendor.app.plist
rm -f ~/Library/LaunchAgents/com.vendor.app.plist
\`\`\`
```

### JSON Fingerprint Entry

```json
{
  "id": "app-name-service",
  "name": "App Name Service",
  "vendor": "Vendor Name",
  "category": "update-service",
  "risk": "medium",
  "patterns": ["com.vendor.app.*", "vendor.*"],
  "platforms": ["macos"],
  "locations": [
    "~/Library/LaunchAgents/com.vendor.app.plist"
  ],
  "removal": {
    "macos": {
      "commands": ["launchctl unload ~/Library/LaunchAgents/com.vendor.app.plist"],
      "sudo": false
    }
  }
}
```

## Examples

### Example 1: Add Notion parasite

```
User: "Add parasite detection for Notion"

1. Research Notion's persistence on macOS
2. Find: ~/Library/LaunchAgents/notion.id.helper.plist
3. Add to common-parasites.md under "Communication Apps"
4. Add JSON entry to parasite-fingerprints.json
5. Verify detection works
```

### Example 2: Ralph loop discovery

```
User: "Run a ralph loop to find all unknown parasites"

1. Scan ~/Library/LaunchAgents/
2. Find 3 unknown: Acme.helper, FooBar.agent, Mystery.daemon
3. Research each, add to database
4. Rescan to confirm detection
5. Output <promise>DISCOVERY COMPLETE</promise>
```

## Related Skills

- **code-maintainer**: For fixing detection issues after adding parasites
- **quality-assurance**: For adding tests after adding new parasites
