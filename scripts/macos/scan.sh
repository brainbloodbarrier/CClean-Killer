#!/bin/bash
# CClean-Killer - macOS System Scanner
# Analyzes disk usage and identifies cleanup opportunities
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

# Default scan limits
TOP_N=15
SCAN_DOCKER=true
SCAN_SYSTEM=false  # Requires elevated permissions

# =============================================================================
# HELP
# =============================================================================

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Analyzes disk usage and identifies cleanup opportunities on macOS.

Options:
  -t, --top N         Show top N items in each category (default: 15)
  --include-docker    Include Docker analysis (default: enabled)
  --skip-docker       Skip Docker analysis
  --include-system    Include system library analysis (may need sudo)
  --skip-system       Skip system library analysis (default)

$(print_common_options)

Examples:
  $(basename "$0")                    # Basic scan
  $(basename "$0") --top 20           # Show top 20 items
  $(basename "$0") --json             # Output as JSON
  $(basename "$0") -v --include-system  # Verbose with system scan

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
        -t|--top)
            TOP_N="${2:-15}"
            shift 2
            ;;
        --include-docker)
            SCAN_DOCKER=true
            shift
            ;;
        --skip-docker)
            SCAN_DOCKER=false
            shift
            ;;
        --include-system)
            SCAN_SYSTEM=true
            shift
            ;;
        --skip-system)
            SCAN_SYSTEM=false
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

# Validate TOP_N
if ! [[ "$TOP_N" =~ ^[0-9]+$ ]] || [[ "$TOP_N" -lt 1 ]]; then
    log_error "Invalid value for --top: $TOP_N"
    exit $EXIT_USAGE
fi

# =============================================================================
# SCANNING FUNCTIONS
# =============================================================================

# Scan a directory and return top items by size
scan_directory() {
    local path="$1"
    local description="$2"
    local limit="${3:-$TOP_N}"
    local icon="${4:-#}"

    if [[ ! -d "$path" ]]; then
        log_verbose "Directory not found: $path"
        return
    fi

    print_section "$description" "$icon"

    if $JSON_OUTPUT; then
        local items=()
        while IFS= read -r line; do
            local size full_path item_name

            # du output is tab-separated: <size>\t<path>
            size=$(printf '%s' "$line" | cut -f1)
            full_path=$(printf '%s' "$line" | cut -f2-)
            [[ -z "$full_path" ]] && continue

            item_name=$(basename "$full_path")

            local size_kb
            size_kb=$(parse_size_to_kb "$size")
            local item
            item=$(json_object "name" "$item_name" "size" "$size" "size_kb" "$size_kb" "path" "$full_path")
            items+=("$item")
        done < <(du -sh "$path"/*/ 2>/dev/null | sort -hr | head -n "$limit")

        local items_json json_section
        items_json=$(json_array "${items[@]}")
        json_section=$(json_object "category" "$description" "path" "$path" "items" "$items_json")
        json_add_item "$json_section"
    else
        local count=0
        while IFS= read -r line; do
            echo "$line"
            ((count++)) || true
        done < <(du -sh "$path"/*/ 2>/dev/null | sort -hr | head -n "$limit")

        if [[ $count -eq 0 ]]; then
            echo "  (empty or inaccessible)"
        fi
    fi
}

# Scan hidden files in a directory
scan_hidden() {
    local path="$1"
    local description="$2"
    local limit="${3:-$TOP_N}"

    if [[ ! -d "$path" ]]; then
        log_verbose "Directory not found: $path"
        return
    fi

    print_section "$description" "[.]"

    if $JSON_OUTPUT; then
        local items=()
        while IFS= read -r line; do
            local size full_path

            size=$(printf '%s' "$line" | cut -f1)
            full_path=$(printf '%s' "$line" | cut -f2-)
            [[ -z "$full_path" ]] && continue

            local size_kb
            size_kb=$(parse_size_to_kb "$size")
            local item
            item=$(json_object "name" "$(basename "$full_path")" "size" "$size" "size_kb" "$size_kb" "path" "$full_path")
            items+=("$item")
        done < <(du -sh "$path"/.[!.]* 2>/dev/null | sort -hr | head -n "$limit")

        local items_json json_section
        items_json=$(json_array "${items[@]}")
        json_section=$(json_object "category" "$description" "path" "$path" "items" "$items_json")
        json_add_item "$json_section"
    else
        du -sh "$path"/.[!.]* 2>/dev/null | sort -hr | head -n "$limit" || echo "  (none found)"
    fi
}

# Scan developer tools and caches
scan_dev_tools() {
    print_section "Developer Caches" "[DEV]"

    local dev_items=()

    # Bash 3.x compatible "name|path" pairs (avoid associative arrays)
    local dev_pairs=(
        "npm cache|$HOME/.npm"
        "pnpm cache|$HOME/Library/pnpm"
        "Homebrew|/opt/homebrew"
        "Homebrew (Intel)|/usr/local/Homebrew"
        "Cargo|$HOME/.cargo"
        "pip cache|$HOME/Library/Caches/pip"
        "Gradle|$HOME/.gradle"
        "Maven|$HOME/.m2"
        "CocoaPods|$HOME/Library/Caches/CocoaPods"
        "Xcode DerivedData|$HOME/Library/Developer/Xcode/DerivedData"
        "Android SDK|$HOME/Library/Android/sdk"
    )

    for pair in "${dev_pairs[@]}"; do
        local name="${pair%%|*}"
        local path="${pair#*|}"

        if [[ -d "$path" ]]; then
            local size
            size=$(get_size_human "$path")
            local size_kb
            size_kb=$(get_size_kb "$path")

            if $JSON_OUTPUT; then
                local item
                item=$(json_object "name" "$name" "size" "$size" "size_kb" "$size_kb" "path" "$path")
                dev_items+=("$item")
            else
                printf "%-20s %s\n" "$name:" "$size"
            fi
        else
            if ! $JSON_OUTPUT && $VERBOSE; then
                printf "%-20s %s\n" "$name:" "Not found"
            fi
        fi
    done

    if $JSON_OUTPUT; then
        local items_json json_section
        items_json=$(json_array "${dev_items[@]}")
        json_section=$(json_object "category" "Developer Caches" "items" "$items_json")
        json_add_item "$json_section"
    fi
}

# Scan Docker if installed
scan_docker() {
    if ! $SCAN_DOCKER; then
        return
    fi

    if ! command -v docker &>/dev/null; then
        log_verbose "Docker not installed"
        return
    fi

    print_section "Docker" "[DOCKER]"

    if $JSON_OUTPUT; then
        if docker_info=$(docker system df --format '{{json .}}' 2>/dev/null); then
            # docker outputs one JSON object per line; convert to a proper JSON array.
            local docker_array="["
            local first=true
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                if ! $first; then
                    docker_array+=","
                fi
                first=false
                docker_array+="$line"
            done <<< "$docker_info"
            docker_array+="]"

            local json_section
            json_section=$(json_object "category" "Docker" "available" "true" "data" "$docker_array")
            json_add_item "$json_section"
        else
            local json_section
            json_section=$(json_object "category" "Docker" "available" "false" "error" "Docker not running")
            json_add_item "$json_section"
        fi
    else
        if ! docker system df 2>/dev/null; then
            echo "  Docker daemon not running"
        fi
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_verbose "Starting system scan with TOP_N=$TOP_N"

    if ! $JSON_OUTPUT; then
        print_header "System Scanner"

        # Disk Overview
        print_section "Disk Overview" "[DISK]"
        get_disk_info
    else
        # Add disk info to JSON
        local disk_json
        disk_json=$(get_disk_info json)
        json_add_item "{\"category\":\"Disk Overview\",\"data\":$disk_json}"
    fi

    # Start spinner for long operations
    start_spinner "Scanning directories..."

    # User Library Analysis
    scan_directory "$HOME/Library" "~/Library Analysis (Top $TOP_N)" "$TOP_N" "[LIB]"

    # Application Support
    scan_directory "$HOME/Library/Application Support" "Application Support (Top $TOP_N)" "$TOP_N" "[APP]"

    # Caches
    scan_directory "$HOME/Library/Caches" "Caches (Top $TOP_N)" "$TOP_N" "[CACHE]"

    # Containers
    scan_directory "$HOME/Library/Containers" "Containers - Sandboxed Apps (Top $TOP_N)" "$TOP_N" "[BOX]"

    # Group Containers
    scan_directory "$HOME/Library/Group Containers" "Group Containers (Top $TOP_N)" "$TOP_N" "[GRP]"

    # Hidden files in home
    scan_hidden "$HOME" "Home Directory Hidden (Top $TOP_N)" "$TOP_N"

    stop_spinner true "Directory scan complete"

    # Developer tools
    scan_dev_tools

    # Docker
    scan_docker

    # System Library (optional, may need sudo)
    if $SCAN_SYSTEM; then
        if ! $JSON_OUTPUT; then
            echo ""
            log_warn "Scanning system library (may require elevated permissions)"
        fi
        scan_directory "/Library/Application Support" "System Application Support (Top $TOP_N)" "$TOP_N" "[SYS]"
    fi

    # Finalize output
    if $JSON_OUTPUT; then
        json_finalize
    else
        print_summary "Scan complete. Run with --json for structured output."
        echo ""
        echo "Quick Actions:"
        echo "  $SCRIPT_DIR/clean.sh --all      - Clean caches and orphaned data"
        echo "  $SCRIPT_DIR/find-parasites.sh   - Hunt zombie LaunchAgents/Daemons"
        echo "  $SCRIPT_DIR/find-orphans.sh     - Find orphaned application data"
        echo ""
    fi

    log_verbose "Scan completed successfully"
}

main "$@"
