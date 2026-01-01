#!/bin/bash
# CClean-Killer - Common Library
# Shared functions for all macOS cleanup scripts
# Version: 2.0.0

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly CCLEAN_VERSION="2.0.0"
readonly CCLEAN_NAME="CClean-Killer"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_USAGE=2
readonly EXIT_PERMISSION=3
readonly EXIT_INTERRUPTED=130

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================

# Check if stdout is a terminal for color support
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
    readonly COLOR_ENABLED=true
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly MAGENTA='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly BOLD='\033[1m'
    readonly DIM='\033[2m'
    readonly NC='\033[0m'
else
    readonly COLOR_ENABLED=false
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly MAGENTA=''
    readonly CYAN=''
    readonly WHITE=''
    readonly BOLD=''
    readonly DIM=''
    readonly NC=''
fi

# =============================================================================
# GLOBAL FLAGS
# =============================================================================

VERBOSE=false
JSON_OUTPUT=false
QUIET=false
DRY_RUN=false

# JSON accumulator for structured output
declare -a JSON_ITEMS=()

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

_cleanup_handler() {
    local exit_code=$?

    # Restore cursor if hidden
    printf '\033[?25h' 2>/dev/null || true

    # Clear any in-progress indicators
    if [[ "${_SPINNER_PID:-}" ]]; then
        kill "$_SPINNER_PID" 2>/dev/null || true
        wait "$_SPINNER_PID" 2>/dev/null || true
    fi

    # Finalize JSON output if needed
    if $JSON_OUTPUT && [[ ${#JSON_ITEMS[@]} -gt 0 ]]; then
        json_finalize
    fi

    exit "$exit_code"
}

_interrupt_handler() {
    echo ""
    log_warn "Operation interrupted by user"
    exit $EXIT_INTERRUPTED
}

# Setup signal handlers
setup_signal_handlers() {
    trap _cleanup_handler EXIT
    trap _interrupt_handler INT TERM
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Log with timestamp (verbose mode)
log_verbose() {
    if $VERBOSE && ! $JSON_OUTPUT; then
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${DIM}[$timestamp]${NC} $*" >&2
    fi
}

# Standard info message
log_info() {
    if ! $QUIET && ! $JSON_OUTPUT; then
        echo -e "${GREEN}[INFO]${NC} $*"
    fi
}

# Warning message
log_warn() {
    if ! $JSON_OUTPUT; then
        echo -e "${YELLOW}[WARN]${NC} $*" >&2
    fi
}

# Error message
log_error() {
    if ! $JSON_OUTPUT; then
        echo -e "${RED}[ERROR]${NC} $*" >&2
    fi
}

# Debug message (only in verbose mode)
log_debug() {
    if $VERBOSE && ! $JSON_OUTPUT; then
        echo -e "${DIM}[DEBUG]${NC} $*" >&2
    fi
}

# Success message
log_success() {
    if ! $QUIET && ! $JSON_OUTPUT; then
        echo -e "${GREEN}[OK]${NC} $*"
    fi
}

# =============================================================================
# UI COMPONENTS
# =============================================================================

# Print header banner
print_header() {
    local title="$1"
    if ! $JSON_OUTPUT; then
        echo -e "${BLUE}+$(printf '=%.0s' {1..50})+${NC}"
        printf "${BLUE}|${NC} %-48s ${BLUE}|${NC}\n" "$CCLEAN_NAME - $title"
        echo -e "${BLUE}+$(printf '=%.0s' {1..50})+${NC}"
        echo ""
    fi
}

# Print section header
print_section() {
    local title="$1"
    local icon="${2:-#}"
    if ! $JSON_OUTPUT; then
        echo ""
        echo -e "${GREEN}${icon} ${title}${NC}"
        printf '%s\n' "$(printf -- '-%.0s' {1..50})"
    fi
}

# Print summary footer
print_summary() {
    local message="$1"
    if ! $JSON_OUTPUT; then
        echo ""
        echo -e "${BLUE}$(printf '=%.0s' {1..50})${NC}"
        echo -e "${BLUE}${message}${NC}"
        echo -e "${BLUE}$(printf '=%.0s' {1..50})${NC}"
    fi
}

# =============================================================================
# PROGRESS INDICATORS
# =============================================================================

# Spinner characters
readonly SPINNER_CHARS='|/-\'

# Start a spinner in background
# Usage: start_spinner "Processing..."
_SPINNER_PID=""
start_spinner() {
    local message="${1:-Processing...}"

    if $QUIET || $JSON_OUTPUT || ! $COLOR_ENABLED; then
        return
    fi

    (
        local i=0
        while true; do
            printf "\r${CYAN}%s${NC} %s " "${SPINNER_CHARS:i++%4:1}" "$message"
            sleep 0.1
        done
    ) &
    _SPINNER_PID=$!
    disown "$_SPINNER_PID" 2>/dev/null || true
}

# Stop the spinner
stop_spinner() {
    local success="${1:-true}"
    local message="${2:-}"

    if [[ "${_SPINNER_PID:-}" ]]; then
        kill "$_SPINNER_PID" 2>/dev/null || true
        wait "$_SPINNER_PID" 2>/dev/null || true
        _SPINNER_PID=""
    fi

    if ! $QUIET && ! $JSON_OUTPUT && $COLOR_ENABLED; then
        printf "\r\033[K"  # Clear the line
        if [[ -n "$message" ]]; then
            if $success; then
                echo -e "${GREEN}[DONE]${NC} $message"
            else
                echo -e "${RED}[FAIL]${NC} $message"
            fi
        fi
    fi
}

# Progress bar
# Usage: progress_bar current total "message"
progress_bar() {
    local current=$1
    local total=$2
    local message="${3:-}"

    if $QUIET || $JSON_OUTPUT || ! $COLOR_ENABLED; then
        return
    fi

    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "${CYAN}]${NC} %3d%% %s" "$percentage" "$message"

    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# =============================================================================
# SIZE UTILITIES
# =============================================================================

# Get size in kilobytes
# Returns 0 if path doesn't exist
get_size_kb() {
    local path="$1"
    if [[ -e "$path" ]]; then
        du -sk "$path" 2>/dev/null | cut -f1 || echo "0"
    else
        echo "0"
    fi
}

# Get human-readable size
get_size_human() {
    local path="$1"
    if [[ -e "$path" ]]; then
        du -sh "$path" 2>/dev/null | cut -f1 || echo "0B"
    else
        echo "0B"
    fi
}

# Format kilobytes to human readable
format_size() {
    local kb=$1
    local value

    if [[ $kb -ge 1073741824 ]]; then
        value=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $kb/1073741824}")
        echo "${value} TB"
    elif [[ $kb -ge 1048576 ]]; then
        value=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $kb/1048576}")
        echo "${value} GB"
    elif [[ $kb -ge 1024 ]]; then
        value=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $kb/1024}")
        echo "${value} MB"
    else
        echo "${kb} KB"
    fi
}

# Parse human-readable size to kilobytes
parse_size_to_kb() {
    local size="$1"
    local num unit

    num=$(echo "$size" | sed 's/[^0-9.]//g')
    unit=$(echo "$size" | sed 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')

    case "$unit" in
        T|TB) LC_NUMERIC=C awk "BEGIN {printf \"%d\", $num * 1073741824}" ;;
        G|GB) LC_NUMERIC=C awk "BEGIN {printf \"%d\", $num * 1048576}" ;;
        M|MB) LC_NUMERIC=C awk "BEGIN {printf \"%d\", $num * 1024}" ;;
        K|KB) LC_NUMERIC=C awk "BEGIN {printf \"%d\", $num}" ;;
        B|"") LC_NUMERIC=C awk "BEGIN {printf \"%d\", $num / 1024}" ;;
        *) echo "0" ;;
    esac
}

# =============================================================================
# APPLICATION DETECTION
# =============================================================================

# Check if an application is installed
# Args: app_name_or_pattern
# Returns: 0 if installed, 1 if not
is_app_installed() {
    local pattern="$1"
    local pattern_lower
    pattern_lower=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')

    # Check /Applications
    if ls /Applications/ 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -qi "$pattern_lower"; then
        return 0
    fi

    # Check ~/Applications
    if ls ~/Applications/ 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -qi "$pattern_lower"; then
        return 0
    fi

    # Check if it's a system/Apple component
    if [[ "$pattern_lower" == *"apple"* ]] || [[ "$pattern_lower" == "com.apple."* ]]; then
        return 0
    fi

    # Check if binary exists in PATH
    if command -v "$pattern_lower" &>/dev/null; then
        return 0
    fi

    return 1
}

# Extract app name from bundle identifier
# Args: bundle_id (e.g., "com.company.AppName")
# Returns: app name
extract_app_name() {
    local bundle_id="$1"
    echo "$bundle_id" | rev | cut -d. -f1 | rev
}

# Extract company from bundle identifier
extract_company() {
    local bundle_id="$1"
    echo "$bundle_id" | cut -d. -f2
}

# =============================================================================
# FILE OPERATIONS
# =============================================================================

# Safely remove a file or directory
# Args: path description [--force]
# Returns: size in KB freed (or 0)
safe_remove() {
    local path="$1"
    local desc="${2:-$path}"
    local force=false

    [[ "${3:-}" == "--force" ]] && force=true

    if [[ ! -e "$path" ]]; then
        log_debug "Path does not exist: $path"
        return 0
    fi

    local size_kb
    size_kb=$(get_size_kb "$path")
    local size_human
    size_human=$(format_size "$size_kb")

    if $DRY_RUN; then
        log_info "Would remove: $desc ($size_human)"
        log_verbose "  Path: $path"
        echo "$size_kb"
        return 0
    fi

    log_info "Removing: $desc ($size_human)"
    log_verbose "  Path: $path"

    # Capture actual error message instead of suppressing
    local rm_output
    rm_output=$(rm -rf "$path" 2>&1)
    local rm_result=$?

    if [[ $rm_result -eq 0 ]]; then
        log_success "Removed: $desc"
        echo "$size_kb"
    else
        local error_msg="${rm_output:-Unknown error (exit code: $rm_result)}"
        log_error "Failed to remove: $path"
        log_error "  Reason: $error_msg"
        echo "0"
        return 1  # Signal failure to caller
    fi
}

# Check if path is safe to modify (not system critical)
is_safe_path() {
    local path="$1"

    # Reject system paths
    case "$path" in
        /System/*|/usr/*|/bin/*|/sbin/*|/private/var/*)
            return 1
            ;;
        /Library/Apple*|/Library/CoreServices/*)
            return 1
            ;;
    esac

    # Reject critical user paths
    local home_path="${path#$HOME/}"
    case "$home_path" in
        .ssh/*|.gnupg/*|Library/Keychains/*|Library/Safari/*)
            return 1
            ;;
        Documents/*|Desktop/*|Pictures/*|Music/*|Movies/*)
            return 1
            ;;
    esac

    return 0
}

# =============================================================================
# JSON OUTPUT UTILITIES
# =============================================================================

# Initialize JSON output
json_init() {
    if $JSON_OUTPUT; then
        JSON_ITEMS=()
    fi
}

# Add item to JSON array
json_add_item() {
    local json_obj="$1"
    JSON_ITEMS+=("$json_obj")
}

# Build a JSON object from key-value pairs
# Usage: json_object "key1" "value1" "key2" "value2"
json_object() {
    local result="{"
    local first=true

    while [[ $# -ge 2 ]]; do
        local key="$1"
        local value="$2"
        shift 2

        if ! $first; then
            result+=","
        fi
        first=false

        # Escape special characters in value
        value=$(echo "$value" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g')

        # Check if value is a number, boolean, null, or already JSON
        if [[ "$value" =~ ^-?[0-9]+\.?[0-9]*$ ]] || \
           [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || \
           [[ "$value" == "null" ]] || \
           [[ "$value" =~ ^\[.*\]$ ]] || [[ "$value" =~ ^\{.*\}$ ]]; then
            result+="\"$key\":$value"
        else
            result+="\"$key\":\"$value\""
        fi
    done

    result+="}"
    echo "$result"
}

# Finalize and print JSON output
json_finalize() {
    if $JSON_OUTPUT; then
        echo "{"
        echo "  \"version\": \"$CCLEAN_VERSION\","
        echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"items\": ["

        local first=true
        for item in "${JSON_ITEMS[@]}"; do
            if ! $first; then
                echo ","
            fi
            first=false
            printf "    %s" "$item"
        done

        echo ""
        echo "  ]"
        echo "}"
    fi
}

# =============================================================================
# ARGUMENT PARSING HELPERS
# =============================================================================

# Parse common arguments
# Updates global flags: VERBOSE, JSON_OUTPUT, QUIET, DRY_RUN
# Returns remaining args via REMAINING_ARGS array
declare -a REMAINING_ARGS=()

SHOW_HELP=false

parse_common_args() {
    REMAINING_ARGS=()
    SHOW_HELP=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -j|--json)
                JSON_OUTPUT=true
                QUIET=true  # Suppress normal output when using JSON
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-color)
                # Colors already disabled via NO_COLOR env or non-tty
                shift
                ;;
            -h|--help)
                SHOW_HELP=true
                shift
                ;;
            --version)
                echo "$CCLEAN_NAME v$CCLEAN_VERSION"
                exit 0
                ;;
            *)
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done
}

# Print common usage options
print_common_options() {
    cat << EOF
Common Options:
  -v, --verbose     Enable verbose output with timestamps
  -j, --json        Output results in JSON format
  -q, --quiet       Suppress non-essential output
  -n, --dry-run     Show what would be done without making changes
  --no-color        Disable colored output
  -h, --help        Show this help message
  --version         Show version information
EOF
}

# =============================================================================
# DISK INFO UTILITIES
# =============================================================================

# Get disk usage info for root volume
get_disk_info() {
    local format="${1:-human}"

    if [[ "$format" == "json" ]]; then
        df -k / | tail -1 | awk '{
            printf "{\"total_kb\":%s,\"used_kb\":%s,\"available_kb\":%s,\"percent_used\":\"%s\"}",
            $2, $3, $4, $5
        }'
    else
        df -h / | tail -1 | awk '{print "Total: "$2"  Used: "$3"  Available: "$4"  ("$5" used)"}'
    fi
}

# =============================================================================
# LAUNCHCTL UTILITIES
# =============================================================================

# Check if a launch agent/daemon is loaded
is_launchctl_loaded() {
    local label="$1"
    launchctl list 2>/dev/null | grep -q "$label"
}

# Unload a launch agent/daemon
unload_launchctl() {
    local plist_path="$1"
    local sudo_required=false

    [[ "$plist_path" == /Library/* ]] && sudo_required=true

    if $sudo_required; then
        log_warn "Requires sudo to unload: $plist_path"
        return 1
    fi

    if $DRY_RUN; then
        log_info "Would unload: $plist_path"
        return 0
    fi

    if launchctl unload "$plist_path" 2>/dev/null; then
        log_success "Unloaded: $plist_path"
        return 0
    else
        log_error "Failed to unload: $plist_path"
        return 1
    fi
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Call this at the start of each script
init_common() {
    setup_signal_handlers
    json_init

    # Set strict mode
    set -o errexit
    set -o nounset
    set -o pipefail

    # Check for bc (required for size calculations)
    if ! command -v bc &>/dev/null; then
        log_warn "bc not found, some size calculations may be imprecise"
    fi
}
