#!/bin/bash
# CClean-Killer Test Framework - Assertions Library
# Provides assertion functions for testing

# =============================================================================
# Assertion Functions
# =============================================================================

# Assert equality
# Usage: assert_equals "expected" "actual" "description"
assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="${3:-Values should be equal}"

    if [ "$expected" = "$actual" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Expected: '$expected'"
            echo "    Actual:   '$actual'"
        fi
        return 1
    fi
}

# Assert not equal
# Usage: assert_not_equals "unexpected" "actual" "description"
assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local description="${3:-Values should not be equal}"

    if [ "$unexpected" != "$actual" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Value should not be: '$unexpected'"
        fi
        return 1
    fi
}

# Assert true (exit code 0)
# Usage: assert_true "command" "description"
assert_true() {
    local cmd="$1"
    local description="${2:-Command should succeed}"

    if eval "$cmd" >/dev/null 2>&1; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Command failed: $cmd"
        fi
        return 1
    fi
}

# Assert false (exit code non-0)
# Usage: assert_false "command" "description"
assert_false() {
    local cmd="$1"
    local description="${2:-Command should fail}"

    if ! eval "$cmd" >/dev/null 2>&1; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Command should have failed: $cmd"
        fi
        return 1
    fi
}

# Assert file exists
# Usage: assert_file_exists "/path/to/file" "description"
assert_file_exists() {
    local file="$1"
    local description="${2:-File should exist: $file}"

    if [ -f "$file" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    File not found: $file"
        fi
        return 1
    fi
}

# Assert file does not exist
# Usage: assert_file_not_exists "/path/to/file" "description"
assert_file_not_exists() {
    local file="$1"
    local description="${2:-File should not exist: $file}"

    if [ ! -f "$file" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    File unexpectedly exists: $file"
        fi
        return 1
    fi
}

# Assert directory exists
# Usage: assert_dir_exists "/path/to/dir" "description"
assert_dir_exists() {
    local dir="$1"
    local description="${2:-Directory should exist: $dir}"

    if [ -d "$dir" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Directory not found: $dir"
        fi
        return 1
    fi
}

# Assert directory does not exist
# Usage: assert_dir_not_exists "/path/to/dir" "description"
assert_dir_not_exists() {
    local dir="$1"
    local description="${2:-Directory should not exist: $dir}"

    if [ ! -d "$dir" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Directory unexpectedly exists: $dir"
        fi
        return 1
    fi
}

# Assert string contains
# Usage: assert_contains "haystack" "needle" "description"
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="${3:-String should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    String: '$haystack'"
            echo "    Does not contain: '$needle'"
        fi
        return 1
    fi
}

# Assert string does not contain
# Usage: assert_not_contains "haystack" "needle" "description"
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local description="${3:-String should not contain substring}"

    if [[ "$haystack" != *"$needle"* ]]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    String: '$haystack'"
            echo "    Should not contain: '$needle'"
        fi
        return 1
    fi
}

# Assert string matches regex
# Usage: assert_matches "string" "regex" "description"
assert_matches() {
    local string="$1"
    local regex="$2"
    local description="${3:-String should match pattern}"

    if [[ "$string" =~ $regex ]]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    String: '$string'"
            echo "    Does not match: '$regex'"
        fi
        return 1
    fi
}

# Assert numeric greater than
# Usage: assert_greater_than actual expected "description"
assert_greater_than() {
    local actual="$1"
    local expected="$2"
    local description="${3:-Value should be greater than $expected}"

    if [ "$actual" -gt "$expected" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Actual: $actual"
            echo "    Expected greater than: $expected"
        fi
        return 1
    fi
}

# Assert numeric less than
# Usage: assert_less_than actual expected "description"
assert_less_than() {
    local actual="$1"
    local expected="$2"
    local description="${3:-Value should be less than $expected}"

    if [ "$actual" -lt "$expected" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Actual: $actual"
            echo "    Expected less than: $expected"
        fi
        return 1
    fi
}

# Assert empty string
# Usage: assert_empty "value" "description"
assert_empty() {
    local value="$1"
    local description="${2:-Value should be empty}"

    if [ -z "$value" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Value is not empty: '$value'"
        fi
        return 1
    fi
}

# Assert not empty string
# Usage: assert_not_empty "value" "description"
assert_not_empty() {
    local value="$1"
    local description="${2:-Value should not be empty}"

    if [ -n "$value" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Value is empty"
        fi
        return 1
    fi
}

# Assert exit code
# Usage: assert_exit_code expected_code "command" "description"
assert_exit_code() {
    local expected="$1"
    local cmd="$2"
    local description="${3:-Exit code should be $expected}"

    set +e
    eval "$cmd" >/dev/null 2>&1
    local actual=$?
    set -e

    if [ "$actual" -eq "$expected" ]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Expected exit code: $expected"
            echo "    Actual exit code: $actual"
        fi
        return 1
    fi
}

# Assert output contains
# Usage: assert_output_contains "command" "expected_output" "description"
assert_output_contains() {
    local cmd="$1"
    local expected="$2"
    local description="${3:-Output should contain expected string}"

    local output
    output=$(eval "$cmd" 2>&1) || true

    if [[ "$output" == *"$expected"* ]]; then
        register_test "$description" "pass"
        return 0
    else
        register_test "$description" "fail"
        if [ "$VERBOSE" = true ]; then
            echo "    Command: $cmd"
            echo "    Output: $output"
            echo "    Expected to contain: $expected"
        fi
        return 1
    fi
}

# Skip test (for platform-specific tests)
# Usage: skip_test "reason" "description"
skip_test() {
    local reason="$1"
    local description="${2:-Test skipped}"

    register_test "$description - SKIPPED: $reason" "skip"
    return 0
}

# =============================================================================
# Test Organization
# =============================================================================

# Describe a test suite
# Usage: describe "Suite Name" callback
describe() {
    local suite_name="$1"
    echo ""
    echo -e "  ${CYAN}$suite_name${NC}"
}

# Single test case
# Usage: it "should do something" callback
it() {
    local description="$1"
    # Description is recorded by assertions
}

# Before each test
before_each() {
    : # Override in test files
}

# After each test
after_each() {
    : # Override in test files
}

# Before all tests in file
before_all() {
    : # Override in test files
}

# After all tests in file
after_all() {
    : # Override in test files
}
