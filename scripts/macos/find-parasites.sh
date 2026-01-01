#!/usr/bin/env bash
# CClean-Killer - Parasite Finder for macOS
# Finds zombie LaunchAgents/Daemons from uninstalled apps
# Version: 2.0.0
# Requires: Bash 4.0+ (for associative arrays)

# Check Bash version
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "Warning: This script works best with Bash 4.0+. Using compatibility mode." >&2
    USE_COMPAT_MODE=true
else
    USE_COMPAT_MODE=false
fi

set -euo pipefail

# =============================================================================
# INITIALIZATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_common

# =============================================================================
# SCRIPT-SPECIFIC CONFIGURATION
# =============================================================================

# Tracking
declare -a PARASITES=()
PARASITE_COUNT=0

# Scan locations
SCAN_USER_AGENTS=true
SCAN_SYSTEM_AGENTS=true
SCAN_DAEMONS=true
SCAN_HELPERS=true
SCAN_CLONES=true

# Known parasites database with descriptions
# Using parallel arrays for Bash 3.x compatibility
# Format: PARASITE_PATTERNS[i] matches PARASITE_INFO[i] = "Company|Description|Severity"
PARASITE_PATTERNS=(
    "google.keystone"
    "google.GoogleUpdater"
    "adobe.agsservice"
    "adobe.GC.Invoker"
    "adobe.ARMDC"
    "adobe.ARMDCHelper"
    "adobe.AdobeCreativeCloud"
    "adobe.acc"
    "piriform.ccleaner"
    "us.zoom"
    "spotify.webhelper"
    "microsoft.update"
    "microsoft.autoupdate"
    "dropbox"
    "valvesoftware"
    "skype"
    "teamviewer"
    "logmein"
    "io.keybase"
    "oracle.java"
    "nvidia"
)

PARASITE_INFO=(
    "Google|Chrome/Drive updater (persists after app removal)|medium"
    "Google|Google software updater|medium"
    "Adobe|Genuine Software license check|high"
    "Adobe|Analytics and telemetry collection|high"
    "Adobe|Application Resource Manager telemetry|high"
    "Adobe|ARMDC Helper process|medium"
    "Adobe|Creative Cloud background services|medium"
    "Adobe|Creative Cloud component|medium"
    "Piriform|CCleaner daemons (ironic)|high"
    "Zoom|Background video services|medium"
    "Spotify|Web helper and integration|low"
    "Microsoft|AutoUpdate service|medium"
    "Microsoft|Office AutoUpdate|medium"
    "Dropbox|Sync and helper services|medium"
    "Valve|Steam client services|low"
    "Skype|Background services|medium"
    "TeamViewer|Remote access daemon|high"
    "LogMeIn|Remote access services|high"
    "Keybase|KBFS and helper services|medium"
    "Oracle|Java auto-updater|medium"
    "NVIDIA|GPU driver services|low"
)

# =============================================================================
# HELP
# =============================================================================

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Finds zombie LaunchAgents/Daemons from uninstalled or unwanted applications.

Options:
  --skip-user-agents      Skip ~/Library/LaunchAgents
  --skip-system-agents    Skip /Library/LaunchAgents
  --skip-daemons          Skip /Library/LaunchDaemons
  --skip-helpers          Skip /Library/PrivilegedHelperTools
  --skip-clones           Skip code_sign_clone remnants
  --known-only            Only show known parasites (skip orphan detection)

$(print_common_options)

Examples:
  $(basename "$0")                    # Full parasite scan
  $(basename "$0") --json             # Output as JSON
  $(basename "$0") --known-only       # Only known parasites
  $(basename "$0") -v                 # Verbose output with details

Severity Levels:
  HIGH   - Known telemetry/tracking or security concern
  MEDIUM - Updaters and background services that may be unwanted
  LOW    - Generally benign but consumes resources

EOF
    exit 0
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

KNOWN_ONLY=false

parse_common_args "$@"
$SHOW_HELP && show_help
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-user-agents)
            SCAN_USER_AGENTS=false
            shift
            ;;
        --skip-system-agents)
            SCAN_SYSTEM_AGENTS=false
            shift
            ;;
        --skip-daemons)
            SCAN_DAEMONS=false
            shift
            ;;
        --skip-helpers)
            SCAN_HELPERS=false
            shift
            ;;
        --skip-clones)
            SCAN_CLONES=false
            shift
            ;;
        --known-only)
            KNOWN_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit $EXIT_USAGE
            ;;
    esac
done

# =============================================================================
# PARASITE DETECTION FUNCTIONS
# =============================================================================

# Get parasite info if it's a known one
# Returns: "company|description|severity" or empty
get_known_parasite_info() {
    local name="$1"
    local i

    for i in "${!PARASITE_PATTERNS[@]}"; do
        if [[ "$name" == *"${PARASITE_PATTERNS[$i]}"* ]]; then
            echo "${PARASITE_INFO[$i]}"
            return 0
        fi
    done
    return 1
}

# Check if a LaunchAgent/Daemon is loaded
get_launchctl_status() {
    local label="$1"

    if launchctl list 2>/dev/null | grep -q "$label"; then
        echo "running"
    elif [[ -f "$HOME/Library/LaunchAgents/$label.plist" ]] || \
         [[ -f "/Library/LaunchAgents/$label.plist" ]] || \
         [[ -f "/Library/LaunchDaemons/$label.plist" ]]; then
        echo "loaded"
    else
        echo "unknown"
    fi
}

# Report a parasite found
report_parasite() {
    local name="$1"
    local path="$2"
    local category="$3"
    local parasite_info="${4:-}"
    local requires_sudo="${5:-false}"

    local company=""
    local description=""
    local severity="unknown"
    local is_known=false

    if [[ -n "$parasite_info" ]]; then
        is_known=true
        company=$(echo "$parasite_info" | cut -d'|' -f1)
        description=$(echo "$parasite_info" | cut -d'|' -f2)
        severity=$(echo "$parasite_info" | cut -d'|' -f3)
    fi

    local status
    status=$(get_launchctl_status "$name")

    ((PARASITE_COUNT++)) || true

    if $JSON_OUTPUT; then
        local item
        item=$(json_object \
            "name" "$name" \
            "path" "$path" \
            "category" "$category" \
            "is_known" "$is_known" \
            "company" "$company" \
            "description" "$description" \
            "severity" "$severity" \
            "status" "$status" \
            "requires_sudo" "$requires_sudo")
        PARASITES+=("$item")
    else
        if $is_known; then
            case "$severity" in
                high)   echo -e "${RED}[PARASITE]${NC} $name" ;;
                medium) echo -e "${YELLOW}[PARASITE]${NC} $name" ;;
                low)    echo -e "${CYAN}[PARASITE]${NC} $name" ;;
            esac
            echo -e "    ${MAGENTA}$company: $description${NC}"
        else
            echo -e "${YELLOW}[ORPHAN]${NC} $name"
            echo "    Potential orphan (app not found)"
        fi

        if $VERBOSE; then
            echo "    Path: $path"
            echo "    Category: $category"
        fi

        case "$status" in
            running) echo -e "    Status: ${RED}RUNNING${NC}" ;;
            loaded)  echo -e "    Status: ${YELLOW}Loaded${NC}" ;;
        esac

        if [[ "$requires_sudo" == "true" ]]; then
            echo -e "    ${DIM}(Requires sudo to remove)${NC}"
        fi
        echo ""
    fi
}

# Analyze a plist file
analyze_plist() {
    local plist="$1"
    local location="$2"
    local requires_sudo="${3:-false}"

    [[ ! -f "$plist" ]] && return

    local name
    name=$(basename "$plist" .plist)

    # Skip Apple plists
    if [[ "$name" == "com.apple."* ]]; then
        log_debug "Skipping Apple plist: $name"
        return
    fi

    # Check if it's a known parasite
    local parasite_info
    if parasite_info=$(get_known_parasite_info "$name"); then
        report_parasite "$name" "$plist" "$location" "$parasite_info" "$requires_sudo"
        return
    fi

    # If not known-only mode, check if it's an orphan
    if ! $KNOWN_ONLY; then
        local app_name
        app_name=$(extract_app_name "$name")
        local company
        company=$(extract_company "$name")

        if ! is_app_installed "$app_name" && ! is_app_installed "$company"; then
            report_parasite "$name" "$plist" "$location" "" "$requires_sudo"
        fi
    fi
}

# Scan User LaunchAgents
scan_user_agents() {
    local base_path="$HOME/Library/LaunchAgents"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "User LaunchAgents not found"
        return
    fi

    print_section "User LaunchAgents" "[USER]"

    local count_before=$PARASITE_COUNT

    for plist in "$base_path"/*.plist; do
        [[ ! -f "$plist" ]] && continue
        analyze_plist "$plist" "User LaunchAgents" "false"
    done

    if [[ $PARASITE_COUNT -eq $count_before ]] && ! $JSON_OUTPUT; then
        echo "  No parasites found"
    fi
}

# Scan System LaunchAgents
scan_system_agents() {
    local base_path="/Library/LaunchAgents"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "System LaunchAgents not found"
        return
    fi

    print_section "System LaunchAgents" "[SYS]"

    local count_before=$PARASITE_COUNT

    for plist in "$base_path"/*.plist; do
        [[ ! -f "$plist" ]] && continue
        analyze_plist "$plist" "System LaunchAgents" "true"
    done

    if [[ $PARASITE_COUNT -eq $count_before ]] && ! $JSON_OUTPUT; then
        echo "  No parasites found"
    fi
}

# Scan LaunchDaemons
scan_daemons() {
    local base_path="/Library/LaunchDaemons"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "LaunchDaemons not found"
        return
    fi

    print_section "LaunchDaemons (System-wide)" "[DAEMON]"

    local count_before=$PARASITE_COUNT

    for plist in "$base_path"/*.plist; do
        [[ ! -f "$plist" ]] && continue
        analyze_plist "$plist" "LaunchDaemons" "true"
    done

    if [[ $PARASITE_COUNT -eq $count_before ]] && ! $JSON_OUTPUT; then
        echo "  No parasites found"
    fi
}

# Scan PrivilegedHelperTools
scan_helpers() {
    local base_path="/Library/PrivilegedHelperTools"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "PrivilegedHelperTools not found"
        return
    fi

    print_section "Privileged Helper Tools" "[HELPER]"

    local count=0

    for helper in "$base_path"/*; do
        [[ ! -f "$helper" ]] && continue

        local name
        name=$(basename "$helper")

        # Skip Apple helpers
        if [[ "$name" == "com.apple."* ]]; then
            continue
        fi

        local app_name
        app_name=$(extract_app_name "$name")

        # Check if related app exists
        if ! is_app_installed "$app_name"; then
            if $JSON_OUTPUT; then
                local item
                item=$(json_object \
                    "name" "$name" \
                    "path" "$helper" \
                    "category" "Privileged Helper Tools" \
                    "is_known" "false" \
                    "requires_sudo" "true")
                PARASITES+=("$item")
            else
                echo -e "${YELLOW}[HELPER]${NC} $name"
                if $VERBOSE; then
                    echo "    Path: $helper"
                fi
                echo -e "    ${DIM}(Requires sudo to remove)${NC}"
                echo ""
            fi
            ((count++))
            ((PARASITE_COUNT++)) || true
        fi
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No orphan helpers found"
    fi
}

# Scan code_sign_clone remnants
scan_clones() {
    print_section "Code Sign Clone Remnants" "[CLONE]"

    local tmpdir_base
    tmpdir_base=$(dirname "$(dirname "${TMPDIR:-/tmp}")" 2>/dev/null) || tmpdir_base="/private/var/folders"

    local x_dir="$tmpdir_base/X"

    if [[ ! -d "$x_dir" ]]; then
        log_verbose "No code_sign_clone directory found"
        if ! $JSON_OUTPUT; then
            echo "  No clones found"
        fi
        return
    fi

    local count=0

    for clone in "$x_dir"/*.code_sign_clone/; do
        [[ ! -d "$clone" ]] && continue

        local name
        name=$(basename "$clone")
        local size
        size=$(get_size_human "$clone")
        local size_kb
        size_kb=$(get_size_kb "$clone")

        if $JSON_OUTPUT; then
            local item
            item=$(json_object \
                "name" "$name" \
                "path" "$clone" \
                "category" "Code Sign Clones" \
                "size" "$size" \
                "size_kb" "$size_kb")
            PARASITES+=("$item")
        else
            echo -e "${YELLOW}[CLONE]${NC} $name ${DIM}($size)${NC}"
            if $VERBOSE; then
                echo "    Path: $clone"
            fi
            echo ""
        fi
        ((count++))
        ((PARASITE_COUNT++)) || true
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No clones found"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_verbose "Starting parasite scan"

    print_header "Parasite Hunter"

    if $KNOWN_ONLY && ! $JSON_OUTPUT; then
        echo "Mode: Known parasites only"
        echo ""
    fi

    start_spinner "Hunting for parasites..."

    # Run scans based on flags
    $SCAN_USER_AGENTS && scan_user_agents
    $SCAN_SYSTEM_AGENTS && scan_system_agents
    $SCAN_DAEMONS && scan_daemons
    $SCAN_HELPERS && scan_helpers
    $SCAN_CLONES && scan_clones

    stop_spinner true "Scan complete"

    # Output results
    if $JSON_OUTPUT; then
        echo "{"
        echo "  \"version\": \"$CCLEAN_VERSION\","
        echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"total_parasites\": $PARASITE_COUNT,"
        echo "  \"parasites\": ["

        local first=true
        for parasite in "${PARASITES[@]}"; do
            if ! $first; then
                echo ","
            fi
            first=false
            printf "    %s" "$parasite"
        done

        echo ""
        echo "  ]"
        echo "}"
    else
        print_summary "Found $PARASITE_COUNT parasites/orphans"
        echo ""

        if [[ $PARASITE_COUNT -gt 0 ]]; then
            echo "Removal Commands:"
            echo ""
            echo "  For User LaunchAgents:"
            echo "    launchctl unload <path-to-plist>"
            echo "    rm <path-to-plist>"
            echo ""
            echo "  For System items (requires sudo):"
            echo "    sudo launchctl unload <path-to-plist>"
            echo "    sudo rm <path-to-plist>"
            echo ""
            echo "Or use: ./clean.sh --parasites"
        else
            echo "No parasites found. Your system is clean!"
        fi
        echo ""
    fi

    log_verbose "Parasite scan completed: $PARASITE_COUNT found"
}

main "$@"
