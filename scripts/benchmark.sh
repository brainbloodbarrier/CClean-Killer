#!/usr/bin/env bash
# Requires bash 4+ for associative arrays
# On macOS, install with: brew install bash
# CClean-Killer - Performance Benchmark Script
# Measures and compares performance of original vs optimized algorithms
#
# Usage: ./benchmark.sh [--iterations N] [--output FILE]

set -e

# ============================================
# CONFIGURATION
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$SCRIPT_DIR/macos"
LIB_DIR="$MACOS_DIR/lib"

ITERATIONS=${ITERATIONS:-5}
OUTPUT_FILE="${OUTPUT_FILE:-}"
VERBOSE=${VERBOSE:-false}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --iterations|-n)
            ITERATIONS="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--iterations N] [--output FILE] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --iterations, -n  Number of iterations (default: 5)"
            echo "  --output, -o      Output file for results"
            echo "  --verbose, -v     Show detailed output"
            echo "  --help, -h        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================
# BENCHMARK UTILITIES
# ============================================

# High-precision timer (uses perl if available for sub-second precision)
get_time_ms() {
    if command -v perl &> /dev/null; then
        perl -MTime::HiRes=time -e 'printf "%.3f\n", time * 1000'
    else
        echo $(($(date +%s) * 1000))
    fi
}

# Run a command and measure time
benchmark_cmd() {
    local name="$1"
    shift
    local cmd="$@"

    local start=$(get_time_ms)
    eval "$cmd" > /dev/null 2>&1
    local end=$(get_time_ms)

    echo "scale=2; $end - $start" | bc
}

# Calculate statistics
calc_stats() {
    local -a times=("$@")
    local sum=0
    local min=${times[0]}
    local max=${times[0]}

    for t in "${times[@]}"; do
        sum=$(echo "scale=2; $sum + $t" | bc)
        if (( $(echo "$t < $min" | bc -l) )); then
            min=$t
        fi
        if (( $(echo "$t > $max" | bc -l) )); then
            max=$t
        fi
    done

    local avg=$(echo "scale=2; $sum / ${#times[@]}" | bc)
    echo "$avg|$min|$max"
}

# ============================================
# BENCHMARK TESTS
# ============================================

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   CClean-Killer Performance Benchmark     ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${CYAN}Configuration:${NC}"
echo "  Iterations: $ITERATIONS"
echo "  Scripts directory: $MACOS_DIR"
echo ""

# Results storage
declare -A RESULTS

# ============================================
# TEST 1: is_app_installed() - Original vs Optimized
# ============================================

echo -e "${GREEN}TEST 1: App Installation Check${NC}"
echo "────────────────────────────────────────────"
echo "Testing: is_app_installed() lookup performance"
echo ""

# Test apps to check
TEST_APPS=("Safari" "Chrome" "Firefox" "Slack" "VSCode" "Docker" "Xcode" "Terminal" "NotAnApp" "RandomApp123")

# Original implementation (inline for testing)
original_is_app_installed() {
    local name="$1"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    if ls /Applications/ 2>/dev/null | grep -qi "$name"; then
        return 0
    fi
    if [[ "$name_lower" == *"apple"* ]] || [[ "$name_lower" == *"com.apple"* ]]; then
        return 0
    fi
    if command -v "$name_lower" &> /dev/null; then
        return 0
    fi
    return 1
}

# Run original benchmark
echo -n "  Original (grep-based): "
original_times=()
for ((i=1; i<=ITERATIONS; i++)); do
    start=$(get_time_ms)
    for app in "${TEST_APPS[@]}"; do
        original_is_app_installed "$app" || true
    done
    end=$(get_time_ms)
    duration=$(echo "scale=2; $end - $start" | bc)
    original_times+=("$duration")
done
original_stats=$(calc_stats "${original_times[@]}")
original_avg=$(echo "$original_stats" | cut -d'|' -f1)
echo "${original_avg}ms avg"

# Source optimized library
source "$LIB_DIR/optimized-patterns.sh"
init_apps_cache

# Run optimized benchmark
echo -n "  Optimized (hash-based): "
optimized_times=()
for ((i=1; i<=ITERATIONS; i++)); do
    start=$(get_time_ms)
    for app in "${TEST_APPS[@]}"; do
        is_app_installed_fast "$app" || true
    done
    end=$(get_time_ms)
    duration=$(echo "scale=2; $end - $start" | bc)
    optimized_times+=("$duration")
done
optimized_stats=$(calc_stats "${optimized_times[@]}")
optimized_avg=$(echo "$optimized_stats" | cut -d'|' -f1)
echo "${optimized_avg}ms avg"

# Calculate improvement
if (( $(echo "$original_avg > 0" | bc -l) )); then
    improvement=$(echo "scale=1; (($original_avg - $optimized_avg) / $original_avg) * 100" | bc)
    speedup=$(echo "scale=2; $original_avg / $optimized_avg" | bc)
    echo -e "  ${YELLOW}Improvement: ${improvement}% (${speedup}x faster)${NC}"
fi
echo ""

RESULTS["app_check_original"]="$original_avg"
RESULTS["app_check_optimized"]="$optimized_avg"

# ============================================
# TEST 2: Parasite Detection
# ============================================

echo -e "${GREEN}TEST 2: Parasite Pattern Matching${NC}"
echo "────────────────────────────────────────────"
echo "Testing: Known parasite detection performance"
echo ""

# Test patterns
TEST_PATTERNS=("com.google.keystone" "com.adobe.agsservice" "com.random.app" "us.zoom.xos" "com.microsoft.update.agent")

# Original implementation
declare -A KNOWN_PARASITES_ORIG
KNOWN_PARASITES_ORIG["com.google.keystone"]="Google Keystone"
KNOWN_PARASITES_ORIG["com.adobe.agsservice"]="Adobe"
KNOWN_PARASITES_ORIG["us.zoom"]="Zoom"
KNOWN_PARASITES_ORIG["com.microsoft.update"]="Microsoft"

original_check_parasite() {
    local name="$1"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    for pattern in "${!KNOWN_PARASITES_ORIG[@]}"; do
        if [[ "$name_lower" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Benchmark original
echo -n "  Original (loop-based): "
original_times=()
for ((i=1; i<=ITERATIONS; i++)); do
    start=$(get_time_ms)
    for pattern in "${TEST_PATTERNS[@]}"; do
        original_check_parasite "$pattern" || true
    done
    end=$(get_time_ms)
    duration=$(echo "scale=2; $end - $start" | bc)
    original_times+=("$duration")
done
original_stats=$(calc_stats "${original_times[@]}")
original_avg=$(echo "$original_stats" | cut -d'|' -f1)
echo "${original_avg}ms avg"

# Benchmark optimized
echo -n "  Optimized (hash-based): "
optimized_times=()
for ((i=1; i<=ITERATIONS; i++)); do
    start=$(get_time_ms)
    for pattern in "${TEST_PATTERNS[@]}"; do
        is_known_parasite_fast "$pattern" || true
    done
    end=$(get_time_ms)
    duration=$(echo "scale=2; $end - $start" | bc)
    optimized_times+=("$duration")
done
optimized_stats=$(calc_stats "${optimized_times[@]}")
optimized_avg=$(echo "$optimized_stats" | cut -d'|' -f1)
echo "${optimized_avg}ms avg"

if (( $(echo "$original_avg > 0" | bc -l) )); then
    improvement=$(echo "scale=1; (($original_avg - $optimized_avg) / $original_avg) * 100" | bc)
    speedup=$(echo "scale=2; $original_avg / $optimized_avg" | bc 2>/dev/null || echo "N/A")
    echo -e "  ${YELLOW}Improvement: ${improvement}% (${speedup}x faster)${NC}"
fi
echo ""

RESULTS["parasite_original"]="$original_avg"
RESULTS["parasite_optimized"]="$optimized_avg"

# ============================================
# TEST 3: Directory Size Calculation
# ============================================

echo -e "${GREEN}TEST 3: Size Calculation${NC}"
echo "────────────────────────────────────────────"
echo "Testing: Directory size calculation with caching"
echo ""

# Get some test directories
TEST_DIRS=(~/Library/Caches ~/Library/Logs ~/Library/Preferences)

# Original (no cache)
echo -n "  Original (no cache): "
original_times=()
for ((i=1; i<=ITERATIONS; i++)); do
    start=$(get_time_ms)
    for dir in "${TEST_DIRS[@]}"; do
        du -sh "$dir" 2>/dev/null | cut -f1 > /dev/null
    done
    end=$(get_time_ms)
    duration=$(echo "scale=2; $end - $start" | bc)
    original_times+=("$duration")
done
original_stats=$(calc_stats "${original_times[@]}")
original_avg=$(echo "$original_stats" | cut -d'|' -f1)
echo "${original_avg}ms avg"

# Clear size cache
SIZE_CACHE=()

# Optimized with cache (first run populates cache)
echo -n "  Optimized (with cache): "
optimized_times=()
for ((i=1; i<=ITERATIONS; i++)); do
    start=$(get_time_ms)
    for dir in "${TEST_DIRS[@]}"; do
        get_size_cached "$dir" > /dev/null
    done
    end=$(get_time_ms)
    duration=$(echo "scale=2; $end - $start" | bc)
    optimized_times+=("$duration")
done
optimized_stats=$(calc_stats "${optimized_times[@]}")
optimized_avg=$(echo "$optimized_stats" | cut -d'|' -f1)
echo "${optimized_avg}ms avg (after cache warm-up)"

if (( $(echo "$original_avg > 0" | bc -l) )); then
    improvement=$(echo "scale=1; (($original_avg - $optimized_avg) / $original_avg) * 100" | bc)
    echo -e "  ${YELLOW}Improvement with cache: ${improvement}%${NC}"
fi
echo ""

RESULTS["size_original"]="$original_avg"
RESULTS["size_optimized"]="$optimized_avg"

# ============================================
# TEST 4: Cache Initialization
# ============================================

echo -e "${GREEN}TEST 4: Cache Initialization${NC}"
echo "────────────────────────────────────────────"
echo "Testing: One-time cost of cache initialization"
echo ""

# Reset cache
CACHE_INITIALIZED=false
INSTALLED_APPS_CACHE=()
INSTALLED_APPS_HASH=()

echo -n "  Cache initialization time: "
init_times=()
for ((i=1; i<=ITERATIONS; i++)); do
    # Reset cache for each iteration
    CACHE_INITIALIZED=false
    INSTALLED_APPS_CACHE=()
    INSTALLED_APPS_HASH=()

    start=$(get_time_ms)
    init_apps_cache
    end=$(get_time_ms)
    duration=$(echo "scale=2; $end - $start" | bc)
    init_times+=("$duration")
done
init_stats=$(calc_stats "${init_times[@]}")
init_avg=$(echo "$init_stats" | cut -d'|' -f1)
echo "${init_avg}ms avg"
echo "  Apps cached: ${#INSTALLED_APPS_CACHE[@]}"
echo ""

RESULTS["cache_init"]="$init_avg"

# ============================================
# COMPLEXITY ANALYSIS
# ============================================

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}        Complexity Analysis                 ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

echo "Algorithm                    | Before    | After      | Improvement"
echo "────────────────────────────────────────────────────────────────────"
echo "is_app_installed()           | O(n)      | O(1)       | n lookups eliminated"
echo "Known parasite check         | O(k)      | O(1)*      | Hash lookup"
echo "Size calculation (cached)    | O(disk)   | O(1)**     | Memory lookup"
echo "Directory scanning           | 4 passes  | 1 pass     | 4x fewer I/O ops"
echo ""
echo "* Falls back to O(k) for partial matches"
echo "** After first calculation"
echo ""

# ============================================
# SUMMARY REPORT
# ============================================

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}           Performance Summary              ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

echo "Benchmark Results (${ITERATIONS} iterations, times in ms)"
echo "────────────────────────────────────────────────────────"
printf "%-30s %10s %10s %10s\n" "Test" "Original" "Optimized" "Speedup"
echo "────────────────────────────────────────────────────────"

# App check
orig="${RESULTS[app_check_original]}"
opt="${RESULTS[app_check_optimized]}"
speedup=$(echo "scale=2; $orig / $opt" | bc 2>/dev/null || echo "N/A")
printf "%-30s %10s %10s %10sx\n" "App Installation Check" "${orig}ms" "${opt}ms" "$speedup"

# Parasite check
orig="${RESULTS[parasite_original]}"
opt="${RESULTS[parasite_optimized]}"
speedup=$(echo "scale=2; $orig / $opt" | bc 2>/dev/null || echo "N/A")
printf "%-30s %10s %10s %10sx\n" "Parasite Detection" "${orig}ms" "${opt}ms" "$speedup"

# Size calculation
orig="${RESULTS[size_original]}"
opt="${RESULTS[size_optimized]}"
speedup=$(echo "scale=2; $orig / $opt" | bc 2>/dev/null || echo "N/A")
printf "%-30s %10s %10s %10sx\n" "Size Calculation (cached)" "${orig}ms" "${opt}ms" "$speedup"

echo "────────────────────────────────────────────────────────"
echo ""
echo "Cache initialization overhead: ${RESULTS[cache_init]}ms (one-time cost)"
echo ""

# ============================================
# OUTPUT TO FILE
# ============================================

if [ -n "$OUTPUT_FILE" ]; then
    {
        echo "# CClean-Killer Benchmark Results"
        echo "# Date: $(date)"
        echo "# Iterations: $ITERATIONS"
        echo ""
        echo "test,original_ms,optimized_ms,speedup"
        echo "app_check,${RESULTS[app_check_original]},${RESULTS[app_check_optimized]},$(echo "scale=2; ${RESULTS[app_check_original]} / ${RESULTS[app_check_optimized]}" | bc 2>/dev/null || echo "N/A")"
        echo "parasite_check,${RESULTS[parasite_original]},${RESULTS[parasite_optimized]},$(echo "scale=2; ${RESULTS[parasite_original]} / ${RESULTS[parasite_optimized]}" | bc 2>/dev/null || echo "N/A")"
        echo "size_calc,${RESULTS[size_original]},${RESULTS[size_optimized]},$(echo "scale=2; ${RESULTS[size_original]} / ${RESULTS[size_optimized]}" | bc 2>/dev/null || echo "N/A")"
        echo "cache_init,${RESULTS[cache_init]},N/A,N/A"
    } > "$OUTPUT_FILE"
    echo -e "${GREEN}Results saved to: $OUTPUT_FILE${NC}"
fi

echo -e "${GREEN}Benchmark complete!${NC}"
