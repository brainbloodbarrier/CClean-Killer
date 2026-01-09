#!/bin/bash
# CClean-Killer - Safe Cleanup Script for macOS
# Removes caches, orphaned data, and parasites safely
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

# Cleanup targets
CLEAN_CACHES=false
CLEAN_LOGS=false
CLEAN_ORPHANS=false
CLEAN_DEV=false
CLEAN_PARASITES=false
CLEAN_ALL=false

# Tracking
TOTAL_FREED_KB=0
ITEMS_CLEANED=0
ERRORS_COUNT=0

# Safety
CONFIRM_DESTRUCTIVE=true
BACKUP_BEFORE_CLEAN=false
BACKUP_DIR=""

# Skip patterns for caches that should not be cleaned
declare -a CACHE_SKIP_PATTERNS=(
    "CloudKit"
    "com.apple.HomeKit"
    "com.apple.Safari"
    "GeoServices"
    "com.apple.iCloud"
)

# =============================================================================
# HELP
# =============================================================================

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Safely removes caches, orphaned data, and parasites from macOS.

Cleanup Targets:
  --caches          Clean user caches (~/Library/Caches)
  --logs            Clean log files (~/Library/Logs)
  --orphans         Clean orphaned application data
  --dev             Clean developer tool caches (npm, pip, brew, etc.)
  --parasites       Remove orphan LaunchAgents/Daemons (interactive)
  --all             Clean all of the above

Safety Options:
  --no-confirm      Skip confirmation for destructive operations
  --backup          Create backup before cleaning (to ~/.cclean-backup)
  --backup-dir DIR  Specify backup directory

$(print_common_options)

Examples:
  $(basename "$0") --caches                    # Clean caches only
  $(basename "$0") --all --dry-run             # Preview all cleanup
  $(basename "$0") --dev --no-confirm          # Clean dev caches, no prompts
  $(basename "$0") --all --backup              # Full clean with backup
  $(basename "$0") --json --all                # JSON output for automation

Notes:
  - System caches and critical files are never touched
  - Use --dry-run first to see what would be cleaned
  - Some operations may require manual app restart

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
        --caches)
            CLEAN_CACHES=true
            shift
            ;;
        --logs)
            CLEAN_LOGS=true
            shift
            ;;
        --orphans)
            CLEAN_ORPHANS=true
            shift
            ;;
        --dev)
            CLEAN_DEV=true
            shift
            ;;
        --parasites)
            CLEAN_PARASITES=true
            shift
            ;;
        --all)
            CLEAN_ALL=true
            shift
            ;;
        --no-confirm)
            CONFIRM_DESTRUCTIVE=false
            shift
            ;;
        --backup)
            BACKUP_BEFORE_CLEAN=true
            BACKUP_DIR="$HOME/.cclean-backup/$(date +%Y%m%d_%H%M%S)"
            shift
            ;;
        --backup-dir)
            BACKUP_BEFORE_CLEAN=true
            BACKUP_DIR="${2:-}"
            if [[ -z "$BACKUP_DIR" ]]; then
                log_error "--backup-dir requires a directory path"
                exit $EXIT_USAGE
            fi
            shift 2
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

# If no specific target, require explicit flag
if ! $CLEAN_CACHES && ! $CLEAN_LOGS && ! $CLEAN_ORPHANS && ! $CLEAN_DEV && ! $CLEAN_PARASITES && ! $CLEAN_ALL; then
    log_error "No cleanup target specified"
    echo "Use --caches, --logs, --orphans, --dev, --parasites, or --all"
    echo "Run with --help for more information"
    exit $EXIT_USAGE
fi

# If --all, enable everything
if $CLEAN_ALL; then
    CLEAN_CACHES=true
    CLEAN_LOGS=true
    CLEAN_ORPHANS=true
    CLEAN_DEV=true
    CLEAN_PARASITES=true
fi

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if path matches skip pattern
should_skip_cache() {
    local name="$1"
    for pattern in "${CACHE_SKIP_PATTERNS[@]}"; do
        if [[ "$name" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Confirm action with user
confirm_action() {
    local message="$1"

    if ! $CONFIRM_DESTRUCTIVE || $DRY_RUN || $QUIET; then
        return 0
    fi

    echo -e "${YELLOW}$message${NC}"
    read -r -p "Continue? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Backup a path before removal
backup_path() {
    local path="$1"

    if ! $BACKUP_BEFORE_CLEAN; then
        return 0  # No backup requested, proceed with deletion
    fi

    if [[ ! -e "$path" ]]; then
        return 0  # Nothing to backup
    fi

    local rel_path="${path#$HOME/}"
    local backup_dest="$BACKUP_DIR/$rel_path"
    local backup_parent
    backup_parent=$(dirname "$backup_dest")

    # Create backup directory with error checking
    local mkdir_output
    if ! mkdir_output=$(mkdir -p "$backup_parent" 2>&1); then
        log_error "Cannot create backup directory: $backup_parent"
        log_error "  Reason: ${mkdir_output:-Unknown error}"
        log_error "  REFUSING TO DELETE without successful backup"
        return 1  # Signal failure - caller should NOT proceed with deletion
    fi

    # Attempt backup with error capture
    local cp_output
    if cp_output=$(cp -R "$path" "$backup_dest" 2>&1); then
        log_verbose "Backed up: $path"
        return 0
    else
        log_error "Backup failed for: $path"
        log_error "  Reason: ${cp_output:-Unknown error}"
        log_error "  REFUSING TO DELETE without successful backup"
        return 1  # Signal failure - caller should NOT proceed with deletion
    fi
}

# Remove path with tracking
remove_with_tracking() {
    local path="$1"
    local description="${2:-$path}"

    if [[ ! -e "$path" ]]; then
        return 0
    fi

    # Normalize and enforce safety before ANY deletion.
    local normalized
    normalized=$(normalize_path "$path")

    if [[ -z "$normalized" ]] || [[ "$normalized" == "/" ]]; then
        log_error "Refusing to remove empty or root path"
        ((ERRORS_COUNT++)) || true
        json_add_action "skipped" "$path" "$description" "" "" "Refused unsafe path (empty/root)"
        return 0
    fi

    # Never follow symlinks (including symlinks that were passed with trailing /).
    if [[ -L "$normalized" ]]; then
        log_error "Refusing to remove symlink: $normalized"
        ((ERRORS_COUNT++)) || true
        json_add_action "skipped" "$normalized" "$description" "" "" "Refused symlink"
        return 0
    fi

    if ! is_safe_path "$normalized"; then
        log_error "Refusing to remove unsafe path: $normalized"
        ((ERRORS_COUNT++)) || true
        json_add_action "skipped" "$normalized" "$description" "" "" "Refused unsafe path"
        return 0
    fi

    path="$normalized"

    local size_kb
    size_kb=$(get_size_kb "$path")
    local size_human
    size_human=$(format_size "$size_kb")

    if $DRY_RUN; then
        log_info "Would remove: $description ($size_human)"
        TOTAL_FREED_KB=$((TOTAL_FREED_KB + size_kb))
        ((ITEMS_CLEANED++)) || true
        json_add_action "would_remove" "$path" "$description" "$size_human" "$size_kb"
        return 0
    fi

    # Backup if enabled - abort removal if backup fails
    if ! backup_path "$path"; then
        ((ERRORS_COUNT++)) || true
        json_add_action "skipped" "$path" "$description" "" "" "Backup failed, deletion aborted"
        return 1
    fi

    log_info "Removing: $description ($size_human)"

    # Capture actual error message instead of suppressing (avoid set -e abort on failure)
    local rm_output=""
    local rm_exit_code=0
    rm_output=$(rm -rf -- "$path" 2>&1) || rm_exit_code=$?

    if [[ $rm_exit_code -eq 0 ]]; then
        TOTAL_FREED_KB=$((TOTAL_FREED_KB + size_kb))
        ((ITEMS_CLEANED++)) || true
        log_success "Removed: $description"
        json_add_action "removed" "$path" "$description" "$size_human" "$size_kb"
    else
        ((ERRORS_COUNT++)) || true
        local error_reason="${rm_output:-Unknown error (exit code: $rm_exit_code)}"
        log_error "Failed to remove: $path"
        log_error "  Reason: $error_reason"
        json_add_action "failed" "$path" "$description" "" "" "$error_reason"
    fi
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

# Clean user caches
clean_caches() {
    print_section "Cleaning User Caches" "[CACHE]"

    local base_path="$HOME/Library/Caches"

    if [[ ! -d "$base_path" ]]; then
        log_warn "Caches directory not found"
        return
    fi

    local count=0

    for cache in "$base_path"/*/; do
        [[ ! -d "$cache" ]] && continue

        local name
        name=$(basename "$cache")

        if should_skip_cache "$name"; then
            log_verbose "Skipping protected cache: $name"
            continue
        fi

        remove_with_tracking "$cache" "Cache: $name"
        ((count++)) || true
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No caches to clean"
    fi
}

# Clean log files
clean_logs() {
    print_section "Cleaning Log Files" "[LOG]"

    local base_path="$HOME/Library/Logs"

    if [[ ! -d "$base_path" ]]; then
        log_warn "Logs directory not found"
        return
    fi

    local count=0

    for log in "$base_path"/*/; do
        [[ ! -d "$log" ]] && continue

        local name
        name=$(basename "$log")

        remove_with_tracking "$log" "Logs: $name"
        ((count++))
    done

    # Also clean individual log files
    for log_file in "$base_path"/*.log; do
        [[ ! -f "$log_file" ]] && continue

        local name
        name=$(basename "$log_file")

        remove_with_tracking "$log_file" "Log: $name"
        ((count++))
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No logs to clean"
    fi
}

# Clean orphaned application data (uses find-orphans.sh logic)
clean_orphans() {
    print_section "Cleaning Orphaned Data" "[ORPHAN]"

    if ! $QUIET && ! $JSON_OUTPUT; then
        log_warn "This will remove data for applications that are no longer installed"
        if ! confirm_action "Proceed with orphan cleanup?"; then
            echo "  Skipped"
            return
        fi
    fi

    # Source the common library's app detection
    local count=0

    # Application Support orphans
    for dir in "$HOME/Library/Application Support"/*/; do
        [[ ! -d "$dir" ]] && continue

        local name
        name=$(basename "$dir")

        # Skip safe names
        if [[ "$name" == "." ]] || [[ "$name" == ".." ]] || \
           [[ "$name" == "com.apple."* ]] || [[ "$name" == "Apple" ]] || \
           [[ "$name" == "AddressBook" ]] || [[ "$name" == "iCloud" ]] || \
           [[ "$name" == "CloudDocs" ]] || [[ "$name" == "Knowledge" ]]; then
            continue
        fi

        if ! is_app_installed "$name"; then
            remove_with_tracking "$dir" "Orphan (App Support): $name"
            ((count++))
        fi
    done

    # Container orphans
    for dir in "$HOME/Library/Containers"/*/; do
        [[ ! -d "$dir" ]] && continue

        local bundle_id
        bundle_id=$(basename "$dir")

        if [[ "$bundle_id" == "com.apple."* ]]; then
            continue
        fi

        local app_name
        app_name=$(extract_app_name "$bundle_id")

        if ! is_app_installed "$app_name"; then
            remove_with_tracking "$dir" "Orphan (Container): $bundle_id"
            ((count++))
        fi
    done

    # Saved Application State orphans
    for dir in "$HOME/Library/Saved Application State"/*/; do
        [[ ! -d "$dir" ]] && continue

        local bundle_id
        bundle_id=$(basename "$dir" .savedState)

        if [[ "$bundle_id" == "com.apple."* ]]; then
            continue
        fi

        local app_name
        app_name=$(extract_app_name "$bundle_id")

        if ! is_app_installed "$app_name"; then
            remove_with_tracking "$dir" "Orphan (Saved State): $bundle_id"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No orphans to clean"
    fi
}

# Clean developer caches
clean_dev() {
    print_section "Cleaning Developer Caches" "[DEV]"

    local count=0

    # npm cache
    if [[ -d "$HOME/.npm/_cacache" ]]; then
        remove_with_tracking "$HOME/.npm/_cacache" "npm cache"
        ((count++))
    fi

    # pnpm store
    if [[ -d "$HOME/Library/pnpm/store" ]]; then
        remove_with_tracking "$HOME/Library/pnpm/store" "pnpm store"
        ((count++))
    fi

    # pip cache
    if [[ -d "$HOME/Library/Caches/pip" ]]; then
        remove_with_tracking "$HOME/Library/Caches/pip" "pip cache"
        ((count++))
    fi

    # Cargo registry cache
    if [[ -d "$HOME/.cargo/registry/cache" ]]; then
        remove_with_tracking "$HOME/.cargo/registry/cache" "Cargo registry cache"
        ((count++))
    fi

    # Gradle caches
    if [[ -d "$HOME/.gradle/caches" ]]; then
        remove_with_tracking "$HOME/.gradle/caches" "Gradle caches"
        ((count++))
    fi

    # CocoaPods cache
    if [[ -d "$HOME/Library/Caches/CocoaPods" ]]; then
        remove_with_tracking "$HOME/Library/Caches/CocoaPods" "CocoaPods cache"
        ((count++))
    fi

    # Xcode DerivedData
    if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
        local size
        size=$(get_size_human "$HOME/Library/Developer/Xcode/DerivedData")
        if ! $QUIET && ! $JSON_OUTPUT; then
            log_warn "Xcode DerivedData ($size) - cleaning may slow next build"
        fi
        if $DRY_RUN || confirm_action "Clean Xcode DerivedData?"; then
            remove_with_tracking "$HOME/Library/Developer/Xcode/DerivedData" "Xcode DerivedData"
            ((count++))
        fi
    fi

    # Homebrew cleanup
    if command -v brew &>/dev/null; then
        if $DRY_RUN; then
            log_info "Would run: brew cleanup --prune=all"
        else
            log_info "Running: brew cleanup --prune=all"
            if brew cleanup --prune=all 2>/dev/null; then
                log_success "Homebrew cleanup complete"
                ((count++))
            else
                log_warn "Homebrew cleanup had issues"
            fi
        fi

        if $JSON_OUTPUT; then
            json_add_item "$(json_object \
                "action" "$(if $DRY_RUN; then echo "would_run"; else echo "ran"; fi)" \
                "command" "brew cleanup --prune=all" \
                "description" "Homebrew cleanup")"
        fi
    fi

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No developer caches to clean"
    fi
}

# Clean parasites (LaunchAgents/Daemons)
clean_parasites() {
    print_section "Cleaning Parasites" "[PARASITE]"

    if ! $QUIET && ! $JSON_OUTPUT; then
        log_warn "This will unload and remove orphan LaunchAgents/Daemons"
        log_warn "System LaunchDaemons require sudo (will be skipped)"
        if ! confirm_action "Proceed with parasite cleanup?"; then
            echo "  Skipped"
            return
        fi
    fi

    local count=0

    # User LaunchAgents only (no sudo required)
    local base_path="$HOME/Library/LaunchAgents"

    if [[ ! -d "$base_path" ]]; then
        log_verbose "No User LaunchAgents directory"
        return
    fi

    for plist in "$base_path"/*.plist; do
        [[ ! -f "$plist" ]] && continue

        local name
        name=$(basename "$plist" .plist)

        # Skip Apple
        if [[ "$name" == "com.apple."* ]]; then
            continue
        fi

        local app_name
        app_name=$(extract_app_name "$name")
        local company
        company=$(extract_company "$name")

        if ! is_app_installed "$app_name" && ! is_app_installed "$company"; then
            if $DRY_RUN; then
                log_info "Would unload and remove: $name"
                ((count++))
                json_add_action "would_remove" "$plist" "LaunchAgent: $name"
            else
                # Unload first with error checking
                local unload_output
                unload_output=$(launchctl unload "$plist" 2>&1)
                local unload_result=$?

                if [[ $unload_result -eq 0 ]]; then
                    log_verbose "Unloaded: $name"

                    # Only remove if unload succeeded
                    local rm_output
                    rm_output=$(rm -f -- "$plist" 2>&1)
                    if [[ $? -eq 0 ]]; then
                        log_success "Removed LaunchAgent: $name"
                        ((count++))
                        json_add_action "removed" "$plist" "LaunchAgent: $name"
                    else
                        log_error "Failed to remove plist: $plist"
                        log_error "  Reason: ${rm_output:-Unknown error}"
                        ((ERRORS_COUNT++)) || true
                        json_add_action "failed" "$plist" "LaunchAgent: $name" "" "" "${rm_output:-Unknown error}"
                    fi
                else
                    log_error "Failed to unload LaunchAgent: $name"
                    if [[ -n "$unload_output" ]]; then
                        log_error "  Reason: $unload_output"
                    fi
                    log_warn "Skipping removal to prevent inconsistent state"
                    ((ERRORS_COUNT++)) || true
                    json_add_action "failed" "$plist" "LaunchAgent: $name" "" "" "Failed to unload: ${unload_output:-Unknown error}"
                fi
            fi
        fi
    done

    if [[ $count -eq 0 ]] && ! $JSON_OUTPUT; then
        echo "  No user parasites to clean"
        echo "  (System parasites require sudo - run find-parasites.sh for details)"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_verbose "Starting cleanup"

    print_header "Safe Cleanup"

    if $DRY_RUN && ! $JSON_OUTPUT; then
        echo -e "${YELLOW}DRY RUN MODE - No files will be deleted${NC}"
        echo ""
    fi

    if $BACKUP_BEFORE_CLEAN && ! $DRY_RUN; then
        log_info "Backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi

    # Show what we're cleaning
    if ! $JSON_OUTPUT; then
        echo "Cleanup targets:"
        $CLEAN_CACHES && echo "  - User Caches"
        $CLEAN_LOGS && echo "  - Log Files"
        $CLEAN_ORPHANS && echo "  - Orphaned Data"
        $CLEAN_DEV && echo "  - Developer Caches"
        $CLEAN_PARASITES && echo "  - Parasites (User LaunchAgents)"
        echo ""
    fi

    start_spinner "Cleaning..."

    # Run cleanups based on flags
    $CLEAN_CACHES && clean_caches
    $CLEAN_LOGS && clean_logs
    $CLEAN_ORPHANS && clean_orphans
    $CLEAN_DEV && clean_dev
    $CLEAN_PARASITES && clean_parasites

    stop_spinner true "Cleanup complete"

    # Output results
    if $JSON_OUTPUT; then
        echo "{"
        echo "  \"version\": \"$CCLEAN_VERSION\","
        echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
        echo "  \"dry_run\": $DRY_RUN,"
        echo "  \"summary\": {"
        echo "    \"items_cleaned\": $ITEMS_CLEANED,"
        echo "    \"total_freed_kb\": $TOTAL_FREED_KB,"
        echo "    \"total_freed\": \"$(format_size $TOTAL_FREED_KB)\","
        echo "    \"errors\": $ERRORS_COUNT"
        echo "  },"
        echo "  \"actions\": ["

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
    else
        print_summary "Cleanup Summary"
        echo ""

        if $DRY_RUN; then
            echo "  Would clean: $ITEMS_CLEANED items"
            echo "  Would free:  $(format_size $TOTAL_FREED_KB)"
            echo ""
            echo "Run without --dry-run to actually clean."
        else
            echo "  Items cleaned: $ITEMS_CLEANED"
            echo "  Space freed:   $(format_size $TOTAL_FREED_KB)"

            if [[ $ERRORS_COUNT -gt 0 ]]; then
                echo -e "  ${YELLOW}Errors: $ERRORS_COUNT${NC}"
            fi

            if $BACKUP_BEFORE_CLEAN; then
                echo ""
                echo "Backup location: $BACKUP_DIR"
            fi
        fi
        echo ""
    fi

    log_verbose "Cleanup completed: $ITEMS_CLEANED items, $(format_size $TOTAL_FREED_KB) freed"
}

main "$@"
