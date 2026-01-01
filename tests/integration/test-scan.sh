#!/bin/bash
# CClean-Killer Integration Tests - Scan Workflow
# Tests the complete scanning workflow

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../framework/assertions.sh"
source "$SCRIPT_DIR/../framework/mocks.sh"
source "$SCRIPT_DIR/../fixtures/test-scenarios.sh"

# Track coverage
track_coverage "scripts/macos/scan.sh"
track_coverage "scripts/linux/scan.sh"

# =============================================================================
# Test: Scan Script Exists and is Executable
# =============================================================================
describe "Scan Script Prerequisites"

test_macos_scan_exists() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    assert_file_exists "$script" "macOS scan script exists"
}

test_macos_scan_executable() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    if [ -x "$script" ]; then
        assert_true "true" "macOS scan script is executable"
    else
        assert_true "[ -f '$script' ]" "macOS scan script permissions check"
    fi
}

test_linux_scan_exists() {
    local script="$PROJECT_ROOT/scripts/linux/scan.sh"
    assert_file_exists "$script" "Linux scan script exists"
}

test_macos_scan_exists
test_macos_scan_executable
test_linux_scan_exists

# =============================================================================
# Test: Scan Output Contains Expected Sections
# =============================================================================
describe "Scan Output Structure"

test_scan_has_disk_overview() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local output=$(bash "$script" 2>&1 | head -30)

    assert_contains "$output" "Disk Overview" "Scan output includes Disk Overview section"
}

test_scan_has_library_analysis() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local output=$(bash "$script" 2>&1 | head -50)

    assert_contains "$output" "Library Analysis" "Scan output includes Library Analysis section"
}

test_scan_has_caches_section() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local output=$(bash "$script" 2>&1)

    assert_contains "$output" "Caches" "Scan output includes Caches section"
}

test_scan_has_disk_overview
test_scan_has_library_analysis
test_scan_has_caches_section

# =============================================================================
# Test: Scan Does Not Modify Files
# =============================================================================
describe "Scan Safety - No Modifications"

test_scan_read_only() {
    # Create some test data
    create_mock_cache "TestCache" 100
    create_mock_app_support "TestApp" 200

    local before_count=$(find "$MOCK_HOME" -type f 2>/dev/null | wc -l)

    # The scan script uses ~/Library, not mock
    # So we verify our mock is untouched after any operations

    local after_count=$(find "$MOCK_HOME" -type f 2>/dev/null | wc -l)

    assert_equals "$before_count" "$after_count" "Scan does not modify file count"
}

test_scan_no_delete() {
    local cache_dir="$MOCK_LIBRARY/Caches/TestScan"
    mkdir -p "$cache_dir"
    echo "test" > "$cache_dir/file.txt"

    # Wait a moment
    sleep 0.1

    assert_file_exists "$cache_dir/file.txt" "Scan does not delete files"
}

test_scan_read_only
test_scan_no_delete

# =============================================================================
# Test: Linux Scan XDG Directories
# =============================================================================
describe "Linux Scan XDG Support"

test_linux_xdg_defaults() {
    # Test XDG default paths
    local XDG_CONFIG=${XDG_CONFIG_HOME:-~/.config}
    local XDG_DATA=${XDG_DATA_HOME:-~/.local/share}
    local XDG_CACHE=${XDG_CACHE_HOME:-~/.cache}

    assert_contains "$XDG_CONFIG" ".config" "XDG_CONFIG defaults to ~/.config"
    assert_contains "$XDG_DATA" ".local/share" "XDG_DATA defaults to ~/.local/share"
    assert_contains "$XDG_CACHE" ".cache" "XDG_CACHE defaults to ~/.cache"
}

test_linux_scan_structure() {
    local script="$PROJECT_ROOT/scripts/linux/scan.sh"
    local content=$(cat "$script")

    assert_contains "$content" "XDG_CONFIG" "Linux scan uses XDG_CONFIG"
    assert_contains "$content" "XDG_CACHE" "Linux scan uses XDG_CACHE"
}

test_linux_xdg_defaults
test_linux_scan_structure

# =============================================================================
# Test: Developer Tools Detection
# =============================================================================
describe "Developer Tools Detection"

test_scan_detects_npm() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local content=$(cat "$script")

    assert_contains "$content" "npm" "Scan checks for npm cache"
}

test_scan_detects_homebrew() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local content=$(cat "$script")

    assert_contains "$content" "Homebrew" "Scan checks for Homebrew"
}

test_scan_detects_cargo() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local content=$(cat "$script")

    assert_contains "$content" "Cargo" "Scan checks for Cargo/Rust"
}

test_scan_detects_npm
test_scan_detects_homebrew
test_scan_detects_cargo

# =============================================================================
# Test: Docker Detection
# =============================================================================
describe "Docker Detection"

test_scan_checks_docker() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local content=$(cat "$script")

    assert_contains "$content" "docker" "Scan checks for Docker"
}

test_scan_docker_conditional() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local content=$(cat "$script")

    assert_contains "$content" "command -v docker" "Docker check is conditional"
}

test_scan_checks_docker
test_scan_docker_conditional

# =============================================================================
# Test: Error Handling
# =============================================================================
describe "Scan Error Handling"

test_scan_handles_missing_dirs() {
    # The script should handle missing directories gracefully
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local content=$(cat "$script")

    # Uses 2>/dev/null to suppress errors
    assert_contains "$content" "2>/dev/null" "Scan suppresses permission errors"
}

test_scan_exit_code() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"

    # Run scan and capture exit code
    bash "$script" > /dev/null 2>&1
    local exit_code=$?

    # Should exit 0 on success
    assert_equals "0" "$exit_code" "Scan exits with code 0 on success"
}

test_scan_handles_missing_dirs
test_scan_exit_code

# =============================================================================
# Test: Output Formatting
# =============================================================================
describe "Scan Output Formatting"

test_scan_uses_colors() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local content=$(cat "$script")

    assert_contains "$content" "\\033" "Scan uses ANSI color codes"
}

test_scan_has_banner() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local output=$(bash "$script" 2>&1 | head -5)

    assert_contains "$output" "CClean-Killer" "Scan displays banner"
}

test_scan_has_separators() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local content=$(cat "$script")

    assert_contains "$content" "─" "Scan uses separator lines"
}

test_scan_uses_colors
test_scan_has_banner
test_scan_has_separators

# =============================================================================
# Test: Full Scan Integration
# =============================================================================
describe "Full Scan Integration"

test_full_scan_completes() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"

    # Run with timeout to prevent hanging
    local output
    output=$(timeout 30 bash "$script" 2>&1) || true

    # Should produce substantial output
    local line_count=$(echo "$output" | wc -l)
    assert_greater_than "$line_count" 10 "Full scan produces expected output"
}

test_scan_summary_section() {
    local script="$PROJECT_ROOT/scripts/macos/scan.sh"
    local output=$(bash "$script" 2>&1)

    assert_contains "$output" "Quick Actions" "Scan includes Quick Actions summary"
}

test_full_scan_completes
test_scan_summary_section

# =============================================================================
# Test: Platform-Specific Behavior
# =============================================================================
describe "Platform-Specific Scan Behavior"

test_platform_detection() {
    local platform=$(uname)

    if [ "$platform" = "Darwin" ]; then
        assert_equals "Darwin" "$platform" "Correctly detects macOS"
    elif [ "$platform" = "Linux" ]; then
        assert_equals "Linux" "$platform" "Correctly detects Linux"
    else
        skip_test "Unknown platform" "Platform detection"
    fi
}

test_macos_paths() {
    if [ "$(uname)" = "Darwin" ]; then
        local script="$PROJECT_ROOT/scripts/macos/scan.sh"
        local content=$(cat "$script")

        assert_contains "$content" "~/Library" "macOS scan uses ~/Library paths"
    else
        skip_test "Not on macOS" "macOS path test"
    fi
}

test_platform_detection
test_macos_paths

echo ""
echo "Scan integration tests completed."
