#!/bin/bash
# CClean-Killer Test Framework - Main Test Runner
# Executes all test suites and reports results

set -e

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_DIR="$PROJECT_ROOT/tests"

# Source framework components
source "$SCRIPT_DIR/assertions.sh"
source "$SCRIPT_DIR/mocks.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test results storage
declare -a FAILED_TEST_NAMES=()
declare -a SKIPPED_TEST_NAMES=()

# =============================================================================
# Test Runner Functions
# =============================================================================

# Print banner
print_banner() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}     CClean-Killer Test Suite                                  ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

# Print summary
print_summary() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}                      Test Summary                              ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
    echo -e "  Total:   ${CYAN}$TOTAL_TESTS${NC}"
    echo -e "  Passed:  ${GREEN}$PASSED_TESTS${NC}"
    echo -e "  Failed:  ${RED}$FAILED_TESTS${NC}"
    echo -e "  Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"
    echo ""

    if [ ${#FAILED_TEST_NAMES[@]} -gt 0 ]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test_name in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  - $test_name"
        done
        echo ""
    fi

    if [ ${#SKIPPED_TEST_NAMES[@]} -gt 0 ]; then
        echo -e "${YELLOW}Skipped Tests:${NC}"
        for test_name in "${SKIPPED_TEST_NAMES[@]}"; do
            echo -e "  - $test_name"
        done
        echo ""
    fi

    # Calculate pass rate
    if [ $TOTAL_TESTS -gt 0 ]; then
        local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo -e "  Pass Rate: ${CYAN}${pass_rate}%${NC}"
    fi

    echo ""
    echo -e "${BLUE}================================================================${NC}"
}

# Run a single test file
run_test_file() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .sh)"

    echo ""
    echo -e "${CYAN}Running: $test_name${NC}"
    echo "────────────────────────────────────────────"

    # Reset per-file counters
    FILE_TESTS=0
    FILE_PASSED=0
    FILE_FAILED=0
    FILE_SKIPPED=0

    # Source the test file (runs the tests)
    if source "$test_file"; then
        echo -e "${GREEN}  [PASS]${NC} $test_name completed"
    else
        echo -e "${RED}  [FAIL]${NC} $test_name had errors"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name (file error)")
    fi
}

# Register test result
register_test() {
    local test_name="$1"
    local status="$2"  # pass, fail, skip

    ((TOTAL_TESTS++))

    case "$status" in
        pass)
            ((PASSED_TESTS++))
            echo -e "  ${GREEN}[PASS]${NC} $test_name"
            ;;
        fail)
            ((FAILED_TESTS++))
            FAILED_TEST_NAMES+=("$test_name")
            echo -e "  ${RED}[FAIL]${NC} $test_name"
            ;;
        skip)
            ((SKIPPED_TESTS++))
            SKIPPED_TEST_NAMES+=("$test_name")
            echo -e "  ${YELLOW}[SKIP]${NC} $test_name"
            ;;
    esac
}

# Run all tests in a directory
run_test_dir() {
    local dir="$1"
    local dir_name="$(basename "$dir")"

    if [ ! -d "$dir" ]; then
        echo -e "${YELLOW}Warning: Test directory $dir not found${NC}"
        return 0
    fi

    echo ""
    echo -e "${BLUE}============ $dir_name Tests ============${NC}"

    local test_files=("$dir"/test-*.sh)
    if [ ! -e "${test_files[0]}" ]; then
        echo -e "${YELLOW}  No test files found in $dir${NC}"
        return 0
    fi

    for test_file in "${test_files[@]}"; do
        if [ -f "$test_file" ]; then
            run_test_file "$test_file"
        fi
    done
}

# =============================================================================
# Coverage Tracking
# =============================================================================

declare -a TESTED_SCRIPTS=()

track_coverage() {
    local script="$1"
    if [[ ! " ${TESTED_SCRIPTS[@]} " =~ " ${script} " ]]; then
        TESTED_SCRIPTS+=("$script")
    fi
}

print_coverage() {
    echo ""
    echo -e "${BLUE}============ Coverage Report ============${NC}"
    echo ""

    local all_scripts=(
        "scripts/macos/scan.sh"
        "scripts/macos/find-orphans.sh"
        "scripts/macos/find-parasites.sh"
        "scripts/macos/clean.sh"
        "scripts/linux/scan.sh"
        "scripts/linux/clean.sh"
    )

    local tested_count=0
    local total_count=${#all_scripts[@]}

    for script in "${all_scripts[@]}"; do
        if [[ " ${TESTED_SCRIPTS[@]} " =~ " ${script} " ]]; then
            echo -e "  ${GREEN}[COVERED]${NC} $script"
            ((tested_count++))
        else
            echo -e "  ${YELLOW}[MISSING]${NC} $script"
        fi
    done

    echo ""
    local coverage_pct=$((tested_count * 100 / total_count))
    echo -e "  Script Coverage: ${CYAN}${tested_count}/${total_count}${NC} (${coverage_pct}%)"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    local verbose=false
    local coverage=false
    local filter=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -c|--coverage)
                coverage=true
                shift
                ;;
            -f|--filter)
                filter="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  -v, --verbose    Show detailed output"
                echo "  -c, --coverage   Show coverage report"
                echo "  -f, --filter     Filter tests by name pattern"
                echo "  -h, --help       Show this help"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Export for use in test files
    export VERBOSE="$verbose"
    export PROJECT_ROOT
    export TESTS_DIR

    print_banner

    # Setup mock environment
    setup_mock_environment

    # Trap cleanup
    trap cleanup_mock_environment EXIT

    # Run unit tests
    run_test_dir "$TESTS_DIR/unit"

    # Run integration tests
    run_test_dir "$TESTS_DIR/integration"

    # Cleanup
    cleanup_mock_environment

    # Print results
    print_summary

    if [ "$coverage" = true ]; then
        print_coverage
    fi

    # Exit with appropriate code
    if [ $FAILED_TESTS -gt 0 ]; then
        exit 1
    fi
    exit 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
