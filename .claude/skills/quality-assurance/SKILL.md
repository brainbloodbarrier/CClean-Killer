---
name: quality-assurance
description: Ensure quality through testing, documentation, and security audits. Use when asked to add tests, improve test coverage, update documentation, write docs, security audit, review safety rules, or verify protected paths are not touched.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Quality Assurance

Ensure quality through testing, documentation, and security auditing.

## Purpose

Maintain project quality by:
- Adding and improving tests
- Updating documentation
- Auditing security and safety rules
- Reviewing code changes

## Modes

### Mode: test

Add or improve unit and integration tests.

**When to use:** User says "add tests", "test coverage", "write tests for", "fix failing tests"

**Workflow:**

1. **Analyze Coverage**
   - Run existing tests:
     ```bash
     npm run test:unit
     npm run test:integration
     ```
   - Identify untested functions or scenarios

2. **Create Test Fixtures**
   - Add mock data to `tests/fixtures/`:
     ```bash
     mkdir -p tests/fixtures/launchagents
     # Create mock plist files
     ```

3. **Write Unit Tests**
   - Follow pattern in `tests/unit/test-parasite-patterns.sh`:
     ```bash
     test_pattern_matches_known_parasite() {
         # Setup
         local pattern="com.google.keystone.*"
         local input="com.google.keystone.agent"

         # Execute
         local result=$(match_pattern "$pattern" "$input")

         # Assert
         assert_equals "true" "$result" "Pattern should match"
     }
     ```

4. **Write Integration Tests**
   - Test end-to-end workflows in `tests/integration/`

5. **Verify Coverage**
   ```bash
   npm run test:coverage
   ```

**Files Modified:**
- `tests/unit/*.sh`
- `tests/integration/*.sh`
- `tests/fixtures/*`
- `tests/framework/assertions.sh` (if new assertions needed)

**Test Categories:**

| Category | Location | What to Test |
|----------|----------|--------------|
| Parasite patterns | `test-parasite-patterns.sh` | Pattern matching accuracy |
| Orphan detection | `test-orphan-detection.sh` | App existence checks |
| Common utilities | `test-common.sh` | Shared library functions |
| Integration | `tests/integration/` | Full workflow execution |

---

### Mode: doc

Update or create documentation.

**When to use:** User says "update docs", "write documentation", "document feature", "add README"

**Workflow:**

1. **Identify Documentation Gaps**
   - Check `docs/` structure:
     ```
     docs/
     ├── api/          # API reference
     ├── user/         # User guides
     ├── dev/          # Developer docs
     └── reviews/      # Code review guidelines
     ```

2. **Write/Update Documentation**
   - Follow existing style and format
   - Include code examples
   - Add command-line usage examples

3. **Verify Links and References**
   - Check internal links work
   - Verify code examples are accurate

**Documentation Types:**

| Type | Location | Content |
|------|----------|---------|
| API Reference | `docs/api/` | Function signatures, parameters, returns |
| User Guides | `docs/user/` | How-to guides, tutorials |
| Developer Docs | `docs/dev/` | Architecture, contributing |
| README | Root | Quick start, overview |

**Files Modified:**
- `docs/**/*.md`
- `README.md`
- `CLAUDE.md` (if exists)

---

### Mode: security

Audit security and safety rules.

**When to use:** User says "security audit", "check safety", "verify protected paths", "audit deletion logic"

**Workflow:**

1. **Audit Protected Paths**
   - Verify NEVER_DELETE patterns in `scripts/macos/lib/common.sh`:
     ```bash
     grep -A 20 "NEVER_DELETE" scripts/macos/lib/common.sh
     ```
   - Ensure system paths are protected:
     - `/System/`
     - `~/.ssh/`
     - `~/.gnupg/`
     - `~/Library/Keychains/`

2. **Audit Deletion Logic**
   - Check all `rm` commands have safety checks
   - Verify backup is offered before destructive operations
   - Ensure dry-run mode works correctly

3. **Audit Permission Handling**
   - Verify sudo is only used when necessary
   - Check for proper error handling on permission denied

4. **Review Safety Tiers**
   - Cross-reference `knowledge/safe-to-remove.md`
   - Verify Tier 4 (NEVER DELETE) items are protected

5. **Generate Security Report**
   - Document findings
   - Recommend fixes for issues

**Security Checklist:**

```markdown
## Pre-Deletion Checks
- [ ] App verified uninstalled before removing data
- [ ] Backup offered for LaunchDaemons
- [ ] User confirmation for system-level changes
- [ ] Dry-run mode tested

## Protected Paths
- [ ] /System/ excluded
- [ ] ~/.ssh/ excluded
- [ ] ~/.gnupg/ excluded
- [ ] ~/Library/Keychains/ excluded
- [ ] com.apple.* patterns skipped

## Permission Handling
- [ ] sudo only for system locations
- [ ] Graceful failure on permission denied
- [ ] Clear error messages
```

**Files to Audit:**
- `scripts/macos/clean.sh`
- `scripts/macos/lib/common.sh`
- `knowledge/safe-to-remove.md`

---

### Mode: review

Review code changes for quality and safety.

**When to use:** User says "review changes", "check my code", "review PR"

**Workflow:**

1. **Check Recent Changes**
   ```bash
   git diff HEAD~1
   # or
   git diff main...HEAD
   ```

2. **Review Against Checklist**
   - Code style consistent
   - Functions documented
   - Error handling present
   - Tests added for new functionality
   - Safety rules followed

3. **Run Quality Checks**
   ```bash
   # Shell script linting
   shellcheck scripts/macos/*.sh

   # Run tests
   npm test

   # Check JSON validity
   jq . knowledge/parasite-fingerprints.json > /dev/null
   ```

4. **Provide Feedback**
   - List issues found
   - Suggest improvements
   - Approve or request changes

---

## Safety Rules Reference

### Tier 4: NEVER DELETE

```bash
NEVER_DELETE=(
    "/System/*"
    "/usr/*"
    "/bin/*"
    "/sbin/*"
    "$HOME/.ssh/*"
    "$HOME/.gnupg/*"
    "$HOME/Library/Keychains/*"
    "/etc/passwd"
    "/etc/shadow"
)
```

### Safe Patterns to Skip

```bash
SAFE_SKIP_PATTERNS=(
    "com.apple.*"
    "*.AddressBook*"
    "*iCloud*"
    "*CloudKit*"
    "*Safari*"
    "*Keychain*"
)
```

## Test Templates

### Unit Test Template

```bash
#!/bin/bash
# tests/unit/test-[feature].sh

source "$(dirname "$0")/../framework/test-runner.sh"
source "$(dirname "$0")/../framework/assertions.sh"

# Setup
setup() {
    TEST_DIR=$(mktemp -d)
    # Create test fixtures
}

# Teardown
teardown() {
    rm -rf "$TEST_DIR"
}

# Tests
test_[specific_scenario]() {
    # Arrange
    local input="test input"

    # Act
    local result=$(function_under_test "$input")

    # Assert
    assert_equals "expected" "$result" "Description"
}

# Run tests
run_tests
```

### Integration Test Template

```bash
#!/bin/bash
# tests/integration/test-[workflow].sh

source "$(dirname "$0")/../framework/test-runner.sh"

test_full_scan_workflow() {
    # Run scan in dry-run mode
    local output=$(./scripts/macos/scan.sh --dry-run --json 2>&1)

    # Verify JSON output
    assert_json_valid "$output"

    # Verify expected sections
    assert_contains "$output" "disk_usage"
    assert_contains "$output" "caches"
}

run_tests
```

## Examples

### Example 1: Add tests for new parasite

```
User: "Add tests for the new Notion parasite detection"

1. Create test case in tests/unit/test-parasite-patterns.sh:
   - test_notion_pattern_matches()
   - test_notion_not_false_positive()
2. Add fixture: tests/fixtures/launchagents/notion.id.helper.plist
3. Run: npm run test:unit
4. Verify all tests pass
```

### Example 2: Security audit before release

```
User: "Do a security audit before we release"

1. Check all protected paths are in NEVER_DELETE
2. Verify dry-run mode works for all commands
3. Audit all rm commands have safety checks
4. Review backup functionality
5. Generate security report with findings
```

### Example 3: Update API documentation

```
User: "Document the new --json flag"

1. Update docs/api/commands.md
2. Add usage example
3. Document JSON output format
4. Add to README.md quick reference
```

## Related Skills

- **code-maintainer**: For fixing issues found during review
- **knowledge-manager**: For documenting new parasites
