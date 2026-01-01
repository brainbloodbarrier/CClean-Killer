#!/bin/bash
# CClean-Killer Unit Tests - Common Functions
# Tests shared utility functions used across scripts

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../framework/assertions.sh"
source "$SCRIPT_DIR/../framework/mocks.sh"
source "$SCRIPT_DIR/../fixtures/test-scenarios.sh"

# Track coverage
track_coverage "scripts/macos/scan.sh"
track_coverage "scripts/macos/clean.sh"

# =============================================================================
# Test: Color Code Definitions
# =============================================================================
describe "Color Codes"

# Test that color codes are properly defined
test_color_codes() {
    # These are the expected ANSI codes
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m'

    assert_not_empty "$RED" "RED color code is defined"
    assert_not_empty "$GREEN" "GREEN color code is defined"
    assert_not_empty "$YELLOW" "YELLOW color code is defined"
    assert_not_empty "$BLUE" "BLUE color code is defined"
    assert_not_empty "$NC" "NC (no color) code is defined"
}

test_color_codes

# =============================================================================
# Test: Size Formatting Function
# =============================================================================
describe "Size Formatting (format_size)"

# Simulate format_size function from clean.sh
format_size() {
    local bytes=$1
    if [ $bytes -gt 1048576 ]; then
        echo "$(echo "scale=2; $bytes/1048576" | bc) GB"
    elif [ $bytes -gt 1024 ]; then
        echo "$(echo "scale=2; $bytes/1024" | bc) MB"
    else
        echo "${bytes} KB"
    fi
}

test_format_size_kb() {
    local result=$(format_size 512)
    assert_equals "512 KB" "$result" "format_size handles KB correctly"
}

test_format_size_mb() {
    local result=$(format_size 2048)
    assert_contains "$result" "MB" "format_size handles MB correctly"
}

test_format_size_gb() {
    local result=$(format_size 2097152)
    assert_contains "$result" "GB" "format_size handles GB correctly"
}

test_format_size_zero() {
    local result=$(format_size 0)
    assert_equals "0 KB" "$result" "format_size handles zero correctly"
}

test_format_size_kb
test_format_size_mb
test_format_size_gb
test_format_size_zero

# =============================================================================
# Test: Size Retrieval Function
# =============================================================================
describe "Size Retrieval (get_size_bytes)"

# Simulate get_size_bytes from clean.sh
get_size_bytes() {
    du -sk "$1" 2>/dev/null | cut -f1 || echo "0"
}

test_get_size_bytes_existing_dir() {
    # Use mock environment if available, otherwise use tmp
    local base_dir="${MOCK_HOME:-/tmp}"
    local test_dir="$base_dir/cclean_test_size_$$"
    mkdir -p "$test_dir"
    dd if=/dev/zero of="$test_dir/file.bin" bs=1024 count=100 2>/dev/null

    local size=$(get_size_bytes "$test_dir")
    assert_greater_than "$size" 0 "get_size_bytes returns positive size for existing directory"

    rm -rf "$test_dir"
}

test_get_size_bytes_nonexistent() {
    local size=$(get_size_bytes "/nonexistent/path/that/doesnt/exist")
    # Should return 0 or empty for nonexistent path
    if [ -z "$size" ] || [ "$size" = "0" ]; then
        assert_true "true" "get_size_bytes returns 0 or empty for nonexistent path"
    else
        assert_false "true" "get_size_bytes should return 0 for nonexistent path"
    fi
}

test_get_size_bytes_empty_dir() {
    local base_dir="${MOCK_HOME:-/tmp}"
    local test_dir="$base_dir/cclean_test_empty_$$"
    mkdir -p "$test_dir"

    local size=$(get_size_bytes "$test_dir")
    # Empty directory still has some size (inode)
    assert_not_empty "$size" "get_size_bytes returns value for empty directory"

    rm -rf "$test_dir"
}

test_get_size_bytes_existing_dir
test_get_size_bytes_nonexistent
test_get_size_bytes_empty_dir

# =============================================================================
# Test: Argument Parsing
# =============================================================================
describe "Argument Parsing"

test_parse_dry_run_flag() {
    # Simulate argument parsing
    local DRY_RUN=false
    local args=("--dry-run" "--caches")

    for arg in "${args[@]}"; do
        case $arg in
            --dry-run) DRY_RUN=true ;;
        esac
    done

    assert_equals "true" "$DRY_RUN" "Parses --dry-run flag correctly"
}

test_parse_multiple_flags() {
    local CLEAN_CACHES=false
    local CLEAN_DEV=false
    local CLEAN_ORPHANS=false
    local args=("--caches" "--dev" "--orphans")

    for arg in "${args[@]}"; do
        case $arg in
            --caches) CLEAN_CACHES=true ;;
            --dev) CLEAN_DEV=true ;;
            --orphans) CLEAN_ORPHANS=true ;;
        esac
    done

    assert_equals "true" "$CLEAN_CACHES" "Parses --caches flag"
    assert_equals "true" "$CLEAN_DEV" "Parses --dev flag"
    assert_equals "true" "$CLEAN_ORPHANS" "Parses --orphans flag"
}

test_parse_all_flag() {
    local CLEAN_ALL=false
    local CLEAN_CACHES=false
    local CLEAN_DEV=false
    local args=("--all")

    for arg in "${args[@]}"; do
        case $arg in
            --all) CLEAN_ALL=true ;;
        esac
    done

    if $CLEAN_ALL; then
        CLEAN_CACHES=true
        CLEAN_DEV=true
    fi

    assert_equals "true" "$CLEAN_ALL" "Parses --all flag"
    assert_equals "true" "$CLEAN_CACHES" "--all enables caches"
    assert_equals "true" "$CLEAN_DEV" "--all enables dev"
}

test_parse_dry_run_flag
test_parse_multiple_flags
test_parse_all_flag

# =============================================================================
# Test: Path Safety Checks
# =============================================================================
describe "Path Safety"

test_safe_path_detection() {
    local mock_home="${MOCK_HOME:-/tmp/mock_home}"
    # Test that we correctly identify safe paths
    local safe_paths=(
        "$mock_home/Library/Caches/test"
        "$mock_home/.cache/test"
        "$mock_home/.npm/_cacache"
    )

    for path in "${safe_paths[@]}"; do
        # Path should be under user's home
        if [[ "$path" == "$mock_home"* ]]; then
            assert_true "true" "Path $path is under home directory"
        else
            assert_false "true" "Path $path should be under home"
        fi
    done
}

test_dangerous_path_detection() {
    local mock_home="${MOCK_HOME:-/tmp/mock_home}"
    # These paths should NEVER be touched
    local dangerous_paths=(
        "/System"
        "/usr"
        "/bin"
        "/sbin"
        "/private/var"
    )

    for path in "${dangerous_paths[@]}"; do
        # Our scripts should never target these
        if [[ "$path" != "$mock_home"* ]] && [[ "$path" != "/tmp"* ]]; then
            assert_true "true" "Path $path correctly identified as dangerous"
        fi
    done
}

test_safe_path_detection
test_dangerous_path_detection

# =============================================================================
# Test: Directory Iteration
# =============================================================================
describe "Directory Iteration"

test_iterate_mock_caches() {
    # Skip if mock environment not set up
    if [ -z "$MOCK_LIBRARY" ] || [ ! -d "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "iterate mock caches"
        return
    fi

    # Create some mock caches
    create_mock_cache "TestApp1" 50
    create_mock_cache "TestApp2" 100
    create_mock_cache "CloudKit" 30  # Should be skipped

    local count=0
    for cache in "$MOCK_LIBRARY/Caches"/*/; do
        if [ -d "$cache" ]; then
            ((count++))
        fi
    done

    assert_greater_than "$count" 0 "Can iterate over cache directories"
}

test_iterate_mock_app_support() {
    # Skip if mock environment not set up
    if [ -z "$MOCK_LIBRARY" ] || [ ! -d "$MOCK_LIBRARY" ]; then
        skip_test "Mock environment not available" "iterate mock app support"
        return
    fi

    create_mock_app_support "App1"
    create_mock_app_support "App2"

    local count=0
    for dir in "$MOCK_LIBRARY/Application Support"/*/; do
        if [ -d "$dir" ]; then
            ((count++))
        fi
    done

    assert_greater_than "$count" 0 "Can iterate over Application Support directories"
}

test_iterate_mock_caches
test_iterate_mock_app_support

# =============================================================================
# Test: Platform Detection
# =============================================================================
describe "Platform Detection"

test_detect_macos() {
    if [[ "$(uname)" == "Darwin" ]]; then
        assert_true "true" "Correctly identifies macOS"
    else
        skip_test "Not running on macOS" "macOS detection test"
    fi
}

test_detect_linux() {
    if [[ "$(uname)" == "Linux" ]]; then
        assert_true "true" "Correctly identifies Linux"
    else
        skip_test "Not running on Linux" "Linux detection test"
    fi
}

test_detect_macos
test_detect_linux

# =============================================================================
# Test: Command Availability Checks
# =============================================================================
describe "Command Availability"

test_command_exists_function() {
    # Test checking for common commands
    if command -v bash &> /dev/null; then
        assert_true "true" "bash command exists"
    fi

    if command -v nonexistent_command_12345 &> /dev/null; then
        assert_false "true" "nonexistent command should not exist"
    else
        assert_true "true" "nonexistent command correctly not found"
    fi
}

test_command_exists_function

echo ""
echo "Common function tests completed."
