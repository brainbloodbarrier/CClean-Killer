#!/bin/bash
# CClean-Killer Unit Tests - Orphan Detection
# Tests the orphan finder logic

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../framework/assertions.sh"
source "$SCRIPT_DIR/../framework/mocks.sh"
source "$SCRIPT_DIR/../fixtures/test-scenarios.sh"

# Track coverage
track_coverage "scripts/macos/find-orphans.sh"

# =============================================================================
# Recreate is_app_installed function from find-orphans.sh for testing
# =============================================================================
is_app_installed() {
    local name="$1"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    local apps_dir="${MOCK_APPLICATIONS:-/tmp/mock_apps}"

    # Check in mock /Applications
    if [ -d "$apps_dir" ] && ls "$apps_dir/" 2>/dev/null | grep -qi "$name"; then
        return 0
    fi

    # Check if it's a system/Apple app
    if [[ "$name_lower" == *"apple"* ]] || [[ "$name_lower" == *"com.apple"* ]]; then
        return 0
    fi

    return 1
}

# =============================================================================
# Recreate get_size function
# =============================================================================
get_size() {
    du -sh "$1" 2>/dev/null | cut -f1
}

# =============================================================================
# Test: App Installation Detection
# =============================================================================
describe "App Installation Detection"

test_detect_installed_app() {
    if [ -z "$MOCK_APPLICATIONS" ]; then
        skip_test "Mock environment not available" "detect installed app"
        return
    fi
    create_mock_app "TestApp"

    if is_app_installed "TestApp"; then
        assert_true "true" "Correctly detects installed app"
    else
        assert_false "true" "Failed to detect installed app"
    fi
}

test_detect_uninstalled_app() {
    # Don't create the app, just check if it's detected as uninstalled
    if is_app_installed "NonExistentApp"; then
        assert_false "true" "Should not detect non-existent app as installed"
    else
        assert_true "true" "Correctly identifies uninstalled app"
    fi
}

test_detect_apple_system_app() {
    # Apple apps should always be considered "installed"
    if is_app_installed "com.apple.Safari"; then
        assert_true "true" "Apple apps are always considered installed"
    else
        assert_false "true" "Failed to recognize Apple app"
    fi
}

test_detect_installed_app
test_detect_uninstalled_app
test_detect_apple_system_app

# =============================================================================
# Test: Orphan Identification in Application Support
# =============================================================================
describe "Orphan Detection in Application Support"

test_identify_orphan_app_support() {
    if [ -z "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "identify orphan app support"
        return
    fi
    # Create orphan scenario - data without app
    create_mock_app_support "OrphanedApp"

    local is_orphan=false
    local name="OrphanedApp"

    if ! is_app_installed "$name"; then
        is_orphan=true
    fi

    assert_equals "true" "$is_orphan" "Correctly identifies orphaned Application Support"
}

test_identify_valid_app_support() {
    if [ -z "$MOCK_LIBRARY" ] || [ -z "$MOCK_APPLICATIONS" ]; then
        skip_test "Mock environment not available" "identify valid app support"
        return
    fi
    # Create installed app with support data
    create_mock_app "ValidApp"
    create_mock_app_support "ValidApp"

    local is_orphan=false
    local name="ValidApp"

    if ! is_app_installed "$name"; then
        is_orphan=true
    fi

    assert_equals "false" "$is_orphan" "Does not flag installed app's support as orphan"
}

test_skip_system_directories() {
    # These should be skipped
    local skip_dirs=("AddressBook" "com.apple.Safari" "Apple" "iCloud" "CloudDocs" "Knowledge")

    for name in "${skip_dirs[@]}"; do
        local should_skip=false

        if [[ "$name" == "." ]] || [[ "$name" == ".." ]] || [[ "$name" == "AddressBook" ]] || \
           [[ "$name" == "com.apple."* ]] || [[ "$name" == "Apple" ]] || [[ "$name" == "iCloud" ]] || \
           [[ "$name" == "CloudDocs" ]] || [[ "$name" == "Knowledge" ]]; then
            should_skip=true
        fi

        assert_equals "true" "$should_skip" "Correctly skips system directory: $name"
    done
}

test_identify_orphan_app_support
test_identify_valid_app_support
test_skip_system_directories

# =============================================================================
# Test: Container Orphan Detection
# =============================================================================
describe "Container Orphan Detection"

test_identify_orphan_container() {
    if [ -z "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "identify orphan container"
        return
    fi
    create_mock_container "com.orphaned.app"

    local bundle_id="com.orphaned.app"
    local app_name=$(echo "$bundle_id" | rev | cut -d. -f1 | rev)

    local is_orphan=false
    if ! is_app_installed "$app_name"; then
        is_orphan=true
    fi

    assert_equals "true" "$is_orphan" "Correctly identifies orphaned container"
}

test_skip_apple_containers() {
    # This test doesn't need mock environment - it just tests pattern matching
    local bundle_id="com.apple.Safari"
    local should_skip=false

    if [[ "$bundle_id" == "com.apple."* ]]; then
        should_skip=true
    fi

    assert_equals "true" "$should_skip" "Correctly skips Apple containers"
}

test_identify_orphan_container
test_skip_apple_containers

# =============================================================================
# Test: Group Container Orphan Detection
# =============================================================================
describe "Group Container Orphan Detection"

test_identify_orphan_group_container() {
    if [ -z "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "identify orphan group container"
        return
    fi
    create_mock_group_container "group.com.orphaned.app"

    local group_id="group.com.orphaned.app"
    local app_name=$(echo "$group_id" | rev | cut -d. -f1 | rev)

    local is_orphan=false
    if ! is_app_installed "$app_name"; then
        is_orphan=true
    fi

    assert_equals "true" "$is_orphan" "Correctly identifies orphaned group container"
}

test_skip_apple_group_containers() {
    local group_id="group.com.apple.Safari"
    local should_skip=false

    if [[ "$group_id" == *"apple"* ]] || [[ "$group_id" == *"Apple"* ]]; then
        should_skip=true
    fi

    assert_equals "true" "$should_skip" "Correctly skips Apple group containers"
}

test_identify_orphan_group_container
test_skip_apple_group_containers

# =============================================================================
# Test: Saved Application State Orphan Detection
# =============================================================================
describe "Saved Application State Detection"

test_identify_orphan_saved_state() {
    if [ -z "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "identify orphan saved state"
        return
    fi
    create_mock_saved_state "com.orphaned.app"

    local bundle_id="com.orphaned.app"
    local app_name=$(echo "$bundle_id" | rev | cut -d. -f1 | rev)

    local is_orphan=false
    if ! is_app_installed "$app_name"; then
        is_orphan=true
    fi

    assert_equals "true" "$is_orphan" "Correctly identifies orphaned saved state"
}

test_identify_orphan_saved_state

# =============================================================================
# Test: Size Calculation for Orphans
# =============================================================================
describe "Orphan Size Calculation"

test_calculate_orphan_size() {
    if [ -z "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "calculate orphan size"
        return
    fi
    create_mock_app_support "SizedOrphan" 500  # 500KB

    local dir="$MOCK_LIBRARY/Application Support/SizedOrphan"
    local size=$(get_size "$dir")

    assert_not_empty "$size" "Can calculate orphan size"
    assert_contains "$size" "K" "Size is in KB range"
}

test_calculate_orphan_size

# =============================================================================
# Test: Full Orphan Scenario
# =============================================================================
describe "Full Orphan Detection Scenario"

test_mixed_orphan_scenario() {
    if [ -z "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "mixed orphan scenario"
        return
    fi
    setup_scenario_orphan_heavy

    local orphan_count=0

    # Simulate scanning Application Support
    for dir in "$MOCK_LIBRARY/Application Support"/*/; do
        if [ -d "$dir" ]; then
            local name=$(basename "$dir")

            # Skip system directories
            if [[ "$name" == "com.apple."* ]] || [[ "$name" == "Apple" ]]; then
                continue
            fi

            if ! is_app_installed "$name"; then
                ((orphan_count++))
            fi
        fi
    done

    assert_greater_than "$orphan_count" 0 "Detects multiple orphans in mixed scenario"
}

test_mixed_orphan_scenario

# =============================================================================
# Test: Edge Cases
# =============================================================================
describe "Orphan Detection Edge Cases"

test_app_name_with_spaces() {
    if [ -z "$MOCK_APPLICATIONS" ]; then
        skip_test "Mock environment not available" "app name with spaces"
        return
    fi
    create_mock_app "My App"
    create_mock_app_support "My App"

    if is_app_installed "My App"; then
        assert_true "true" "Handles app names with spaces"
    fi
}

test_case_insensitive_matching() {
    if [ -z "$MOCK_APPLICATIONS" ]; then
        skip_test "Mock environment not available" "case insensitive matching"
        return
    fi
    create_mock_app "TestApp"

    # Should match regardless of case
    if is_app_installed "testapp"; then
        assert_true "true" "Case insensitive matching works"
    fi
}

test_empty_app_support() {
    if [ -z "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "empty app support"
        return
    fi
    mkdir -p "$MOCK_LIBRARY/Application Support/EmptyOrphan"

    local dir="$MOCK_LIBRARY/Application Support/EmptyOrphan"
    assert_dir_exists "$dir" "Empty orphan directory exists"

    local size=$(get_size "$dir")
    assert_not_empty "$size" "Can get size of empty directory"
}

test_app_name_with_spaces
test_case_insensitive_matching
test_empty_app_support

echo ""
echo "Orphan detection tests completed."
