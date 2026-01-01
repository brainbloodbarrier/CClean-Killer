#!/bin/bash
# CClean-Killer - Orphan Finder for macOS
# Finds application data for apps that are no longer installed
# Version: 2.0.0

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
declare -a ORPHANS=()
ORPHAN_COUNT=0
TOTAL_SIZE_KB=0

# Scan locations
SCAN_APP_SUPPORT=true
SCAN_CONTAINERS=true
SCAN_GROUP_CONTAINERS=true
SCAN_SAVED_STATE=true
SCAN_PREFERENCES=false  # More aggressive

# Known safe directories to skip (bundle IDs and names)
declare -a SAFE_PATTERNS=(
    "com.apple."
    "Apple"
    "AddressBook"
    "iCloud"
    "CloudDocs"
    "Knowledge"
    "MobileSync"
    "Dock"
    "Finder"
    "Safari"
    "Mail"
    "Notes"
    "Photos"
    "iTunes"
    "Music"
)

# =============================================================================
# HELP
# =============================================================================

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Finds application data for apps that are no longer installed on macOS.

Options:
  --skip-app-support       Skip Application Support directory
  --skip-containers        Skip Containers directory
  --skip-group-containers  Skip Group Containers directory
  --skip-saved-state       Skip Saved Application State
  --include-preferences    Also scan Preferences (more aggressive)
  --all                    Scan all locations including Preferences

$(print_common_options)

Examples:
  $(basename "$0")                    # Basic orphan scan
  $(basename "$0") --json             # Output as JSON
  $(basename "$0") --all -v           # Aggressive scan with verbose output
  $(basename "$0") --dry-run          # Just show what would be found

Output:
  Lists potential orphaned data with sizes. Use ./clean.sh --orphans to remove.

EOF
    exit 0
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_common_args "$@"
$SHOW_HELP && show_help
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-app-support)
            SCAN_APP_SUPPORT=false
            shift
            ;;
        --skip-containers)
            SCAN_CONTAINERS=false
            shift
            ;;
        --skip-group-containers)
            SCAN_GROUP_CONTAINERS=false
            shift
            ;;
        --skip-saved-state)
            SCAN_SAVED_STATE=false
            shift
            ;;
        --include-preferences)
            SCAN_PREFERENCES=true
            shift
            ;;
        --all)
            SCAN_APP_SUPPORT=true
            SCAN_CONTAINERS=true
            SCAN_GROUP_CONTAINERS=true
            SCAN_SAVED_STATE=true
            SCAN_PREFERENCES=true
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
# ORPHAN DETECTION FUNCTIONS
# =============================================================================

# Check if a name matches any safe pattern
is_safe_name() {
    local name="$1"
    local name_lower
    name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    for pattern in "${SAFE_PATTERNS[@]}"; do
        local pattern_lower
        pattern_lower=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
        if [[ "$name_lower" == "$pattern_lower"* ]] || [[ "$name_lower" == *"$pattern_lower"* ]]; then
            return 0
        fi
    done
    return 1
}

# Check if an orphan entry should be reported
# Enhanced detection beyond simple app name matching
is_orphan() {
    local name="$1"
    local bundle_id="${2:-}"

    # Skip safe patterns
    if is_safe_name "$name"; then
        log_debug "Skipping safe pattern: $name"
        return 1
    fi

    if [[ -n "$bundle_id" ]] && is_safe_name "$bundle_id"; then
        log_debug "Skipping safe bundle ID: $bundle_id"
        return 1
    fi

    # Check if app is installed
    if is_app_installed "$name"; then
        log_debug "App installed: $name"
        return 1
    fi

    # Try company name from bundle ID
    if [[ -n "$bundle_id" ]]; then
        local company
        company=$(extract_company "$bundle_id")
        if [[ -n "$company" ]] && is_app_installed "$company"; then
            log_debug "Company app installed: $company"
            return 1
        fi
    fi

    return 0
}

# Report an orphan found
report_orphan() {
    local name="$1"
    local path="$2"
    local category="$3"

    local size_kb
    size_kb=$(get_size_kb "$path")
    local size_human
    size_human=$(format_size "$size_kb")

    ((ORPHAN_COUNT++)) || true
    TOTAL_SIZE_KB=$((TOTAL_SIZE_KB + size_kb))

    if $JSON_OUTPUT; then
        local item
        item=$(json_object \
            "name" "$name" \
            "path" "$path" \
            "category" "$category" \
            "size" "$size_human" \
            "size_kb" "$size_kb")
        ORPHANS+=("$item")
    else
        echo -e "${YELLOW}[!]${NC} $name ${DIM}($size_human)${NC}"
        if $VERBOSE; then
            echo "    Path: $path"
            echo "    Category: $category"
        fi
    fi
}

# Scan Application Support
scan_app_support() {
    local base_path="$HOME/Library/Application Support"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "Application Support not found"
        return
    fi

    print_section "Scanning Application Support" "[APP]"

    local count=0
    for dir in "$base_path"/*/; do
        [[ ! -d "$dir" ]] && continue

        local name
        name=$(basename "$dir")

        # Skip . and ..
        [[ "$name" == "." ]] || [[ "$name" == ".." ]] && continue

        if is_orphan "$name" ""; then
            report_orphan "$name" "$dir" "Application Support"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No orphans found"
    fi
}

# Scan Containers
scan_containers() {
    local base_path="$HOME/Library/Containers"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "Containers not found"
        return
    fi

    print_section "Scanning Containers" "[BOX]"

    local count=0
    for dir in "$base_path"/*/; do
        [[ ! -d "$dir" ]] && continue

        local bundle_id
        bundle_id=$(basename "$dir")
        local app_name
        app_name=$(extract_app_name "$bundle_id")

        if is_orphan "$app_name" "$bundle_id"; then
            report_orphan "$bundle_id" "$dir" "Containers"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No orphans found"
    fi
}

# Scan Group Containers
scan_group_containers() {
    local base_path="$HOME/Library/Group Containers"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "Group Containers not found"
        return
    fi

    print_section "Scanning Group Containers" "[GRP]"

    local count=0
    for dir in "$base_path"/*/; do
        [[ ! -d "$dir" ]] && continue

        local group_id
        group_id=$(basename "$dir")
        local app_name
        app_name=$(extract_app_name "$group_id")

        if is_orphan "$app_name" "$group_id"; then
            report_orphan "$group_id" "$dir" "Group Containers"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No orphans found"
    fi
}

# Scan Saved Application State
scan_saved_state() {
    local base_path="$HOME/Library/Saved Application State"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "Saved Application State not found"
        return
    fi

    print_section "Scanning Saved Application State" "[STATE]"

    local count=0
    for dir in "$base_path"/*/; do
        [[ ! -d "$dir" ]] && continue

        local bundle_id
        bundle_id=$(basename "$dir" .savedState)
        local app_name
        app_name=$(extract_app_name "$bundle_id")

        if is_orphan "$app_name" "$bundle_id"; then
            report_orphan "$bundle_id" "$dir" "Saved Application State"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No orphans found"
    fi
}

# Scan Preferences (more aggressive)
scan_preferences() {
    local base_path="$HOME/Library/Preferences"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "Preferences not found"
        return
    fi

    print_section "Scanning Preferences (Aggressive)" "[PREF]"

    log_warn "Preference files are small but may affect app behavior if removed incorrectly"

    local count=0
    for plist in "$base_path"/*.plist; do
        [[ ! -f "$plist" ]] && continue

        local bundle_id
        bundle_id=$(basename "$plist" .plist)
        local app_name
        app_name=$(extract_app_name "$bundle_id")

        if is_orphan "$app_name" "$bundle_id"; then
            report_orphan "$bundle_id" "$plist" "Preferences"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No orphans found"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_verbose "Starting orphan scan"

    print_header "Orphan Hunter"

    # Show what we're scanning
    if $VERBOSE && ! $JSON_OUTPUT; then
        echo "Scan locations:"
        $SCAN_APP_SUPPORT && echo "  - Application Support"
        $SCAN_CONTAINERS && echo "  - Containers"
        $SCAN_GROUP_CONTAINERS && echo "  - Group Containers"
        $SCAN_SAVED_STATE && echo "  - Saved Application State"
        $SCAN_PREFERENCES && echo "  - Preferences (aggressive)"
        echo ""
    fi

    start_spinner "Scanning for orphaned data..."

    # Run scans based on flags
    $SCAN_APP_SUPPORT && scan_app_support
    $SCAN_CONTAINERS && scan_containers
    $SCAN_GROUP_CONTAINERS && scan_group_containers
    $SCAN_SAVED_STATE && scan_saved_state
    $SCAN_PREFERENCES && scan_preferences

    stop_spinner true "Scan complete"

    # Output results
    if $JSON_OUTPUT; then
        local summary
        summary=$(json_object \
            "total_orphans" "$ORPHAN_COUNT" \
            "total_size_kb" "$TOTAL_SIZE_KB" \
            "total_size" "$(format_size $TOTAL_SIZE_KB)")

        echo "{"
        echo "  \"version\": \"$CCLEAN_VERSION\","
        echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"summary\": $summary,"
        echo "  \"orphans\": ["

        local first=true
        for orphan in "${ORPHANS[@]}"; do
            if ! $first; then
                echo ","
            fi
            first=false
            printf "    %s" "$orphan"
        done

        echo ""
        echo "  ]"
        echo "}"
    else
        print_summary "Found $ORPHAN_COUNT potential orphans ($(format_size $TOTAL_SIZE_KB))"
        echo ""

        if [[ $ORPHAN_COUNT -gt 0 ]]; then
            echo "To remove orphaned data safely, run:"
            echo "  ./clean.sh --orphans"
            echo ""
            echo "To preview what would be removed:"
            echo "  ./clean.sh --orphans --dry-run"
        else
            echo "No orphaned data found. Your system is clean!"
        fi
        echo ""
    fi

    log_verbose "Orphan scan completed: $ORPHAN_COUNT orphans found"
}

main "$@"
