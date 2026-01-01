#!/usr/bin/env bash
# Requires bash 4+ for associative arrays
# On macOS, install with: brew install bash
# CClean-Killer - Optimized Pattern Matching Library
# Performance-optimized functions for orphan/parasite detection
#
# PERFORMANCE IMPROVEMENTS:
# - Caching: Installed apps list cached once at startup
# - Single-pass scanning: All directories scanned in one traversal
# - Parallel processing: xargs -P for concurrent operations
# - Trie-like pattern matching: Hash-based O(1) lookups
# - Lazy size calculation: Only compute when needed
# - Stream processing: Avoid loading all data to memory

set -e

# ============================================
# GLOBAL CACHE VARIABLES
# ============================================

# Cache for installed applications (populated once at startup)
declare -a INSTALLED_APPS_CACHE=()
declare -A INSTALLED_APPS_HASH=()  # O(1) lookup
declare -A BUNDLE_ID_CACHE=()      # Cache bundle ID -> app name mappings
declare -A SIZE_CACHE=()           # Lazy size calculation cache

# Cache state tracking
CACHE_INITIALIZED=false
CACHE_TIMESTAMP=0

# Parallel processing settings
MAX_PARALLEL_JOBS=${MAX_PARALLEL_JOBS:-4}
ENABLE_PARALLEL=${ENABLE_PARALLEL:-true}

# ============================================
# INITIALIZATION FUNCTIONS
# ============================================

# Initialize the installed apps cache - O(n) one-time cost
# This replaces multiple ls/grep calls with a single scan
init_apps_cache() {
    if $CACHE_INITIALIZED; then
        return 0
    fi

    # Clear existing cache
    INSTALLED_APPS_CACHE=()
    INSTALLED_APPS_HASH=()

    # Scan /Applications once and cache all app names
    local app_name
    while IFS= read -r -d '' app; do
        # Extract app name without .app extension
        app_name=$(basename "$app" .app)
        local app_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')

        # Store in array and hash for different lookup methods
        INSTALLED_APPS_CACHE+=("$app_lower")
        INSTALLED_APPS_HASH["$app_lower"]=1

        # Also add common variations
        # Remove spaces for matching
        local no_spaces=$(echo "$app_lower" | tr -d ' ')
        INSTALLED_APPS_HASH["$no_spaces"]=1

    done < <(find /Applications -maxdepth 1 -name "*.app" -print0 2>/dev/null)

    # Also scan ~/Applications if it exists
    if [ -d ~/Applications ]; then
        while IFS= read -r -d '' app; do
            app_name=$(basename "$app" .app)
            local app_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')
            INSTALLED_APPS_CACHE+=("$app_lower")
            INSTALLED_APPS_HASH["$app_lower"]=1
        done < <(find ~/Applications -maxdepth 1 -name "*.app" -print0 2>/dev/null)
    fi

    CACHE_INITIALIZED=true
    CACHE_TIMESTAMP=$(date +%s)
}

# ============================================
# KNOWN PARASITES DATABASE (Hash-based O(1) lookup)
# ============================================

declare -A PARASITES_DB
declare -A PARASITES_DESC

# Initialize parasites database
init_parasites_db() {
    # Google
    PARASITES_DB["com.google.keystone"]=1
    PARASITES_DESC["com.google.keystone"]="Google Keystone - Chrome updater (persists after Chrome removal)"
    PARASITES_DB["com.google.googleupdater"]=1
    PARASITES_DESC["com.google.googleupdater"]="Google Updater"

    # Adobe
    PARASITES_DB["com.adobe.agsservice"]=1
    PARASITES_DESC["com.adobe.agsservice"]="Adobe Genuine Software - License check telemetry"
    PARASITES_DB["com.adobe.gc.invoker"]=1
    PARASITES_DESC["com.adobe.gc.invoker"]="Adobe GC Invoker - Analytics collection"
    PARASITES_DB["com.adobe.armdc"]=1
    PARASITES_DESC["com.adobe.armdc"]="Adobe ARMDC - Telemetry relay"
    PARASITES_DB["com.adobe.armdchelper"]=1
    PARASITES_DESC["com.adobe.armdchelper"]="Adobe ARMDC Helper"

    # Other common parasites
    PARASITES_DB["com.piriform.ccleaner"]=1
    PARASITES_DESC["com.piriform.ccleaner"]="CCleaner - The irony: 6 daemons for a 'cleaner'"
    PARASITES_DB["us.zoom"]=1
    PARASITES_DESC["us.zoom"]="Zoom - Background daemons"
    PARASITES_DB["com.spotify.webhelper"]=1
    PARASITES_DESC["com.spotify.webhelper"]="Spotify Web Helper"
    PARASITES_DB["com.microsoft.update"]=1
    PARASITES_DESC["com.microsoft.update"]="Microsoft AutoUpdate"
}

# ============================================
# OPTIMIZED LOOKUP FUNCTIONS
# ============================================

# O(1) check if app is installed using hash lookup
# BEFORE: O(n) - grepped through all apps each time
# AFTER: O(1) - hash table lookup
is_app_installed_fast() {
    local name="$1"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Initialize cache if needed
    if ! $CACHE_INITIALIZED; then
        init_apps_cache
    fi

    # O(1) hash lookup instead of O(n) grep
    if [[ -n "${INSTALLED_APPS_HASH[$name_lower]}" ]]; then
        return 0
    fi

    # Check for Apple/system apps
    if [[ "$name_lower" == *"apple"* ]] || [[ "$name_lower" == "com.apple."* ]]; then
        return 0
    fi

    # Check in bundle ID cache
    if [[ -n "${BUNDLE_ID_CACHE[$name_lower]}" ]]; then
        return 0
    fi

    return 1
}

# O(1) check if pattern is a known parasite
# Uses prefix-based matching for efficiency
# BEFORE: O(k) where k = number of known parasites, checked with string matching
# AFTER: O(1) for exact matches, O(p) for prefix checks where p = number of prefix patterns
declare -A PARASITE_PREFIXES=()

init_parasite_prefixes() {
    # Pre-compute common prefixes for faster matching
    PARASITE_PREFIXES["com.google"]=1
    PARASITE_PREFIXES["com.adobe"]=1
    PARASITE_PREFIXES["com.piriform"]=1
    PARASITE_PREFIXES["us.zoom"]=1
    PARASITE_PREFIXES["com.spotify"]=1
    PARASITE_PREFIXES["com.microsoft.update"]=1
}

is_known_parasite_fast() {
    local name="$1"
    local name_lower="${name,,}"  # Bash 4+ lowercase conversion (faster than tr)

    # O(1) exact match check
    if [[ -n "${PARASITES_DB[$name_lower]}" ]]; then
        return 0
    fi

    # O(1) prefix check using common prefixes
    local prefix
    # Extract first 2-3 components of bundle ID
    prefix=$(echo "$name_lower" | cut -d. -f1-2)
    if [[ -n "${PARASITE_PREFIXES[$prefix]}" ]]; then
        return 0
    fi

    prefix=$(echo "$name_lower" | cut -d. -f1-3)
    if [[ -n "${PARASITE_PREFIXES[$prefix]}" ]]; then
        return 0
    fi

    return 1
}

# Get parasite description (O(1))
get_parasite_desc() {
    local name="$1"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    echo "${PARASITES_DESC[$name_lower]:-Unknown parasite}"
}

# ============================================
# LAZY SIZE CALCULATION
# ============================================

# Only calculate size when actually needed
# Uses cache to avoid recalculating
get_size_cached() {
    local path="$1"

    # Check cache first
    if [[ -n "${SIZE_CACHE[$path]}" ]]; then
        echo "${SIZE_CACHE[$path]}"
        return
    fi

    # Calculate and cache
    local size=$(du -sh "$path" 2>/dev/null | cut -f1)
    SIZE_CACHE["$path"]="$size"
    echo "$size"
}

# Get size in bytes (for comparison)
get_size_bytes_cached() {
    local path="$1"
    local cache_key="${path}_bytes"

    if [[ -n "${SIZE_CACHE[$cache_key]}" ]]; then
        echo "${SIZE_CACHE[$cache_key]}"
        return
    fi

    local size=$(du -sk "$path" 2>/dev/null | cut -f1 || echo "0")
    SIZE_CACHE["$cache_key"]="$size"
    echo "$size"
}

# ============================================
# SINGLE-PASS DIRECTORY SCANNING
# ============================================

# Scan all orphan directories in a single pass
# BEFORE: 4 separate loops, each doing is_app_installed
# AFTER: 1 pass collecting all candidates, then batch checking
scan_all_orphan_dirs() {
    local output_file="${1:-/dev/stdout}"

    # Initialize cache
    init_apps_cache

    # Collect all directories in one pass using process substitution
    local -a all_dirs=()
    local -a dir_types=()

    # Application Support
    while IFS= read -r -d '' dir; do
        all_dirs+=("$dir")
        dir_types+=("application_support")
    done < <(find ~/Library/Application\ Support -maxdepth 1 -type d -print0 2>/dev/null)

    # Containers
    while IFS= read -r -d '' dir; do
        all_dirs+=("$dir")
        dir_types+=("container")
    done < <(find ~/Library/Containers -maxdepth 1 -type d -print0 2>/dev/null)

    # Group Containers
    while IFS= read -r -d '' dir; do
        all_dirs+=("$dir")
        dir_types+=("group_container")
    done < <(find ~/Library/Group\ Containers -maxdepth 1 -type d -print0 2>/dev/null)

    # Saved Application State
    while IFS= read -r -d '' dir; do
        all_dirs+=("$dir")
        dir_types+=("saved_state")
    done < <(find ~/Library/Saved\ Application\ State -maxdepth 1 -type d -print0 2>/dev/null)

    # Now process all directories (can be parallelized)
    local orphan_count=0
    for i in "${!all_dirs[@]}"; do
        local dir="${all_dirs[$i]}"
        local type="${dir_types[$i]}"
        local name=$(basename "$dir" | sed 's/\.savedState$//')

        # Skip system directories
        if [[ "$name" == "." ]] || [[ "$name" == ".." ]] || \
           [[ "$name" == "com.apple."* ]] || [[ "$name" == "Apple" ]] || \
           [[ "$name" == "AddressBook" ]] || [[ "$name" == "iCloud" ]] || \
           [[ "$name" == "CloudDocs" ]] || [[ "$name" == "Knowledge" ]] || \
           [[ "$name" == *"apple"* ]] || [[ "$name" == *"Apple"* ]]; then
            continue
        fi

        # Extract app name for checking
        local app_name
        case "$type" in
            application_support)
                app_name="$name"
                ;;
            container|saved_state)
                # Extract from bundle ID (last component)
                app_name=$(echo "$name" | rev | cut -d. -f1 | rev)
                ;;
            group_container)
                app_name=$(echo "$name" | rev | cut -d. -f1 | rev)
                ;;
        esac

        # Check if orphaned using fast lookup
        if ! is_app_installed_fast "$app_name"; then
            echo "${type}|${name}|${dir}" >> "$output_file"
            ((orphan_count++)) || true
        fi
    done

    echo "$orphan_count"
}

# ============================================
# PARALLEL PROCESSING UTILITIES
# ============================================

# Process directories in parallel using xargs
parallel_size_calculation() {
    local -a dirs=("$@")

    if $ENABLE_PARALLEL && command -v xargs &> /dev/null; then
        printf '%s\0' "${dirs[@]}" | xargs -0 -P "$MAX_PARALLEL_JOBS" -I {} du -sh "{}" 2>/dev/null
    else
        for dir in "${dirs[@]}"; do
            du -sh "$dir" 2>/dev/null
        done
    fi
}

# Parallel plist analysis
parallel_plist_analysis() {
    local location="$1"
    shift
    local -a plists=("$@")

    if $ENABLE_PARALLEL && command -v xargs &> /dev/null; then
        printf '%s\0' "${plists[@]}" | xargs -0 -P "$MAX_PARALLEL_JOBS" -I {} bash -c '
            source "'"${BASH_SOURCE[0]}"'"
            analyze_plist_fast "{}" "'"$location"'"
        '
    else
        for plist in "${plists[@]}"; do
            analyze_plist_fast "$plist" "$location"
        done
    fi
}

# ============================================
# OPTIMIZED PLIST ANALYSIS
# ============================================

analyze_plist_fast() {
    local plist="$1"
    local location="$2"
    local name=$(basename "$plist" .plist)

    # Skip Apple plists immediately
    if [[ "$name" == "com.apple."* ]]; then
        return
    fi

    # O(1) parasite check
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    if [[ -n "${PARASITES_DB[$name_lower]}" ]]; then
        echo "PARASITE|$name|${PARASITES_DESC[$name_lower]}|$location"
        return
    fi

    # Check partial matches for parasites
    for key in "${!PARASITES_DB[@]}"; do
        if [[ "$name_lower" == *"$key"* ]]; then
            echo "PARASITE|$name|${PARASITES_DESC[$key]}|$location"
            return
        fi
    done

    # Extract app name components
    local company=$(echo "$name" | cut -d. -f2)
    local app=$(echo "$name" | rev | cut -d. -f1 | rev)

    # Check if orphaned
    if ! is_app_installed_fast "$app" && ! is_app_installed_fast "$company"; then
        echo "ORPHAN|$name|$location"
    fi
}

# ============================================
# BATCH OPERATIONS
# ============================================

# Batch check multiple items at once
batch_check_orphans() {
    local -a items=("$@")
    local -a orphans=()

    # Initialize cache once
    init_apps_cache

    for item in "${items[@]}"; do
        local name=$(basename "$item" | sed 's/\.app$//')
        if ! is_app_installed_fast "$name"; then
            orphans+=("$item")
        fi
    done

    printf '%s\n' "${orphans[@]}"
}

# ============================================
# INCREMENTAL SCANNING
# ============================================

# Only scan directories modified since last scan
LAST_SCAN_FILE="${TMPDIR:-/tmp}/cclean_last_scan"

get_last_scan_time() {
    if [ -f "$LAST_SCAN_FILE" ]; then
        cat "$LAST_SCAN_FILE"
    else
        echo "0"
    fi
}

save_scan_time() {
    date +%s > "$LAST_SCAN_FILE"
}

# Incremental scan - only new/modified directories
scan_incremental() {
    local last_scan=$(get_last_scan_time)
    local current_time=$(date +%s)

    # Find directories modified since last scan
    find ~/Library/Application\ Support ~/Library/Containers ~/Library/Caches \
        -maxdepth 1 -type d -newermt "@$last_scan" 2>/dev/null

    save_scan_time
}

# ============================================
# MEMORY-EFFICIENT STREAM PROCESSING
# ============================================

# Process directories as a stream without loading all to memory
stream_process_dirs() {
    local base_dir="$1"
    local callback="$2"

    # Use find with exec to process each directory as found
    find "$base_dir" -maxdepth 1 -type d -exec bash -c '
        source "'"${BASH_SOURCE[0]}"'"
        '"$callback"' "$1"
    ' _ {} \;
}

# ============================================
# INITIALIZATION
# ============================================

# Auto-initialize on source
init_parasites_db
init_parasite_prefixes

# Export functions for use in subshells
export -f is_app_installed_fast
export -f is_known_parasite_fast
export -f get_size_cached
export -f analyze_plist_fast
