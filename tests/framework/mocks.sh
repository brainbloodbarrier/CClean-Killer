#!/bin/bash
# CClean-Killer Test Framework - Mock Utilities
# Provides mock filesystem and environment for safe testing

# =============================================================================
# Mock Environment Configuration
# =============================================================================

# Base directory for all mocks (in temp directory for safety)
MOCK_BASE_DIR=""
MOCK_HOME=""
MOCK_APPLICATIONS=""
MOCK_LIBRARY=""
MOCK_SYSTEM_LIBRARY=""
MOCK_LAUNCH_AGENTS=""
MOCK_LAUNCH_DAEMONS=""

# Original HOME (preserved for restoration)
ORIGINAL_HOME=""

# =============================================================================
# Mock Environment Setup/Teardown
# =============================================================================

# Setup mock environment
setup_mock_environment() {
    # Create unique temp directory
    MOCK_BASE_DIR=$(mktemp -d -t cclean-killer-tests.XXXXXX)

    if [ -z "$MOCK_BASE_DIR" ] || [ ! -d "$MOCK_BASE_DIR" ]; then
        echo "ERROR: Failed to create mock base directory"
        exit 1
    fi

    # Save original HOME
    ORIGINAL_HOME="$HOME"

    # Create mock directory structure
    MOCK_HOME="$MOCK_BASE_DIR/home"
    MOCK_APPLICATIONS="$MOCK_BASE_DIR/Applications"
    MOCK_LIBRARY="$MOCK_HOME/Library"
    MOCK_SYSTEM_LIBRARY="$MOCK_BASE_DIR/Library"
    MOCK_LAUNCH_AGENTS="$MOCK_HOME/Library/LaunchAgents"
    MOCK_LAUNCH_DAEMONS="$MOCK_BASE_DIR/Library/LaunchDaemons"

    mkdir -p "$MOCK_HOME"
    mkdir -p "$MOCK_APPLICATIONS"
    mkdir -p "$MOCK_LIBRARY/Application Support"
    mkdir -p "$MOCK_LIBRARY/Caches"
    mkdir -p "$MOCK_LIBRARY/Containers"
    mkdir -p "$MOCK_LIBRARY/Group Containers"
    mkdir -p "$MOCK_LIBRARY/Logs"
    mkdir -p "$MOCK_LIBRARY/Saved Application State"
    mkdir -p "$MOCK_LAUNCH_AGENTS"
    mkdir -p "$MOCK_SYSTEM_LIBRARY/LaunchAgents"
    mkdir -p "$MOCK_LAUNCH_DAEMONS"
    mkdir -p "$MOCK_SYSTEM_LIBRARY/PrivilegedHelperTools"

    # Linux-style directories (for Linux tests)
    mkdir -p "$MOCK_HOME/.config"
    mkdir -p "$MOCK_HOME/.local/share"
    mkdir -p "$MOCK_HOME/.local/share/Trash/files"
    mkdir -p "$MOCK_HOME/.local/share/Trash/info"
    mkdir -p "$MOCK_HOME/.cache"
    mkdir -p "$MOCK_HOME/.npm/_cacache"
    mkdir -p "$MOCK_HOME/.cargo/registry/cache"

    # Export for tests
    export MOCK_BASE_DIR
    export MOCK_HOME
    export MOCK_APPLICATIONS
    export MOCK_LIBRARY
    export MOCK_SYSTEM_LIBRARY
    export MOCK_LAUNCH_AGENTS
    export MOCK_LAUNCH_DAEMONS
}

# Cleanup mock environment
cleanup_mock_environment() {
    if [ -n "$MOCK_BASE_DIR" ] && [ -d "$MOCK_BASE_DIR" ]; then
        # Safety check: only remove if it's in temp directory
        case "$MOCK_BASE_DIR" in
            /tmp/*|/var/folders/*|*/cclean-killer-tests.*)
                rm -rf "$MOCK_BASE_DIR"
                ;;
            *)
                echo "WARNING: Refusing to delete suspicious mock directory: $MOCK_BASE_DIR"
                ;;
        esac
    fi

    # Restore original HOME
    if [ -n "$ORIGINAL_HOME" ]; then
        export HOME="$ORIGINAL_HOME"
    fi
}

# =============================================================================
# Mock Data Creation Functions
# =============================================================================

# Create a mock application
# Usage: create_mock_app "AppName"
create_mock_app() {
    local app_name="$1"

    if [ -z "$MOCK_APPLICATIONS" ]; then
        echo "Warning: MOCK_APPLICATIONS not set" >&2
        return 1
    fi

    local app_dir="$MOCK_APPLICATIONS/${app_name}.app"
    mkdir -p "$app_dir/Contents"
    echo "Mock app: $app_name" > "$app_dir/Contents/Info.plist"
}

# Create mock application support data
# Usage: create_mock_app_support "AppName" [size_kb]
create_mock_app_support() {
    local app_name="$1"
    local size_kb="${2:-100}"

    if [ -z "$MOCK_LIBRARY" ]; then
        echo "Warning: MOCK_LIBRARY not set" >&2
        return 1
    fi

    local support_dir="$MOCK_LIBRARY/Application Support/$app_name"
    mkdir -p "$support_dir"
    dd if=/dev/zero of="$support_dir/data.bin" bs=1024 count="$size_kb" 2>/dev/null
}

# Create mock cache
# Usage: create_mock_cache "CacheName" [size_kb]
create_mock_cache() {
    local cache_name="$1"
    local size_kb="${2:-50}"

    if [ -z "$MOCK_LIBRARY" ]; then
        echo "Warning: MOCK_LIBRARY not set" >&2
        return 1
    fi

    local cache_dir="$MOCK_LIBRARY/Caches/$cache_name"
    mkdir -p "$cache_dir"
    dd if=/dev/zero of="$cache_dir/cache.bin" bs=1024 count="$size_kb" 2>/dev/null
}

# Create mock container
# Usage: create_mock_container "com.example.app" [size_kb]
create_mock_container() {
    local bundle_id="$1"
    local size_kb="${2:-50}"

    if [ -z "$MOCK_LIBRARY" ]; then
        echo "Warning: MOCK_LIBRARY not set" >&2
        return 1
    fi

    local container_dir="$MOCK_LIBRARY/Containers/$bundle_id"
    mkdir -p "$container_dir/Data"
    dd if=/dev/zero of="$container_dir/Data/container.bin" bs=1024 count="$size_kb" 2>/dev/null
}

# Create mock group container
# Usage: create_mock_group_container "group.com.example" [size_kb]
create_mock_group_container() {
    local group_id="$1"
    local size_kb="${2:-50}"

    if [ -z "$MOCK_LIBRARY" ]; then
        echo "Warning: MOCK_LIBRARY not set" >&2
        return 1
    fi

    local container_dir="$MOCK_LIBRARY/Group Containers/$group_id"
    mkdir -p "$container_dir"
    dd if=/dev/zero of="$container_dir/group.bin" bs=1024 count="$size_kb" 2>/dev/null
}

# Create mock LaunchAgent plist
# Usage: create_mock_launch_agent "com.example.agent" [location]
# location: "user" or "system" (default: user)
create_mock_launch_agent() {
    local label="$1"
    local location="${2:-user}"
    local target_dir

    if [ "$location" = "user" ]; then
        if [ -z "$MOCK_LAUNCH_AGENTS" ]; then
            echo "Warning: MOCK_LAUNCH_AGENTS not set" >&2
            return 1
        fi
        target_dir="$MOCK_LAUNCH_AGENTS"
    else
        if [ -z "$MOCK_SYSTEM_LIBRARY" ]; then
            echo "Warning: MOCK_SYSTEM_LIBRARY not set" >&2
            return 1
        fi
        target_dir="$MOCK_SYSTEM_LIBRARY/LaunchAgents"
    fi

    mkdir -p "$target_dir"
    cat > "$target_dir/${label}.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/true</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
}

# Create mock LaunchDaemon plist
# Usage: create_mock_launch_daemon "com.example.daemon"
create_mock_launch_daemon() {
    local label="$1"

    if [ -z "$MOCK_LAUNCH_DAEMONS" ]; then
        echo "Warning: MOCK_LAUNCH_DAEMONS not set" >&2
        return 1
    fi

    mkdir -p "$MOCK_LAUNCH_DAEMONS"
    cat > "$MOCK_LAUNCH_DAEMONS/${label}.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/true</string>
    </array>
</dict>
</plist>
EOF
}

# Create mock saved application state
# Usage: create_mock_saved_state "com.example.app"
create_mock_saved_state() {
    local bundle_id="$1"

    if [ -z "$MOCK_LIBRARY" ]; then
        echo "Warning: MOCK_LIBRARY not set" >&2
        return 1
    fi

    local state_dir="$MOCK_LIBRARY/Saved Application State/${bundle_id}.savedState"
    mkdir -p "$state_dir"
    echo "mock state" > "$state_dir/state.data"
}

# Create mock log directory
# Usage: create_mock_logs "AppName" [size_kb]
create_mock_logs() {
    local app_name="$1"
    local size_kb="${2:-10}"

    if [ -z "$MOCK_LIBRARY" ]; then
        echo "Warning: MOCK_LIBRARY not set" >&2
        return 1
    fi

    local log_dir="$MOCK_LIBRARY/Logs/$app_name"
    mkdir -p "$log_dir"
    dd if=/dev/zero of="$log_dir/app.log" bs=1024 count="$size_kb" 2>/dev/null
}

# Create mock npm cache
# Usage: create_mock_npm_cache [size_kb]
create_mock_npm_cache() {
    local size_kb="${1:-100}"

    mkdir -p "$MOCK_HOME/.npm/_cacache/content-v2"
    dd if=/dev/zero of="$MOCK_HOME/.npm/_cacache/content-v2/cache.bin" bs=1024 count="$size_kb" 2>/dev/null
}

# Create mock pip cache
# Usage: create_mock_pip_cache [size_kb]
create_mock_pip_cache() {
    local size_kb="${1:-100}"

    mkdir -p "$MOCK_HOME/.cache/pip"
    dd if=/dev/zero of="$MOCK_HOME/.cache/pip/cache.bin" bs=1024 count="$size_kb" 2>/dev/null
}

# Create mock Trash content
# Usage: create_mock_trash [size_kb]
create_mock_trash() {
    local size_kb="${1:-100}"

    mkdir -p "$MOCK_HOME/.local/share/Trash/files"
    mkdir -p "$MOCK_HOME/.local/share/Trash/info"
    dd if=/dev/zero of="$MOCK_HOME/.local/share/Trash/files/deleted.bin" bs=1024 count="$size_kb" 2>/dev/null
    echo "[Trash Info]" > "$MOCK_HOME/.local/share/Trash/info/deleted.bin.trashinfo"
}

# =============================================================================
# Mock Command Overrides
# =============================================================================

# Create a mock command that returns specific output
# Usage: mock_command "command_name" "output"
mock_command() {
    local cmd_name="$1"
    local output="$2"
    local mock_bin_dir="$MOCK_BASE_DIR/bin"

    mkdir -p "$mock_bin_dir"

    cat > "$mock_bin_dir/$cmd_name" << EOF
#!/bin/bash
echo "$output"
EOF
    chmod +x "$mock_bin_dir/$cmd_name"

    export PATH="$mock_bin_dir:$PATH"
}

# Create a mock command that fails
# Usage: mock_command_fail "command_name" [exit_code]
mock_command_fail() {
    local cmd_name="$1"
    local exit_code="${2:-1}"
    local mock_bin_dir="$MOCK_BASE_DIR/bin"

    mkdir -p "$mock_bin_dir"

    cat > "$mock_bin_dir/$cmd_name" << EOF
#!/bin/bash
exit $exit_code
EOF
    chmod +x "$mock_bin_dir/$cmd_name"

    export PATH="$mock_bin_dir:$PATH"
}

# =============================================================================
# Utility Functions for Tests
# =============================================================================

# Get size of mock directory in KB
get_mock_size_kb() {
    local path="$1"
    du -sk "$path" 2>/dev/null | cut -f1 || echo "0"
}

# Count files in mock directory
count_mock_files() {
    local path="$1"
    find "$path" -type f 2>/dev/null | wc -l | tr -d ' '
}

# Check if mock file exists
mock_file_exists() {
    local path="$1"
    [ -f "$path" ]
}

# Check if mock directory exists
mock_dir_exists() {
    local path="$1"
    [ -d "$path" ]
}

# Create orphan scenario (app data without app)
# Usage: create_orphan_scenario "OrphanApp"
create_orphan_scenario() {
    local app_name="$1"

    # Create app data but NOT the app itself
    create_mock_app_support "$app_name"
    create_mock_cache "$app_name"
    create_mock_container "com.example.${app_name,,}"
    create_mock_saved_state "com.example.${app_name,,}"
}

# Create installed app scenario (app + data)
# Usage: create_installed_app_scenario "InstalledApp"
create_installed_app_scenario() {
    local app_name="$1"

    # Create both app and its data
    create_mock_app "$app_name"
    create_mock_app_support "$app_name"
    create_mock_cache "$app_name"
    create_mock_container "com.example.${app_name,,}"
}

# Create parasite scenario (launch agent without app)
# Usage: create_parasite_scenario "com.removed.app"
create_parasite_scenario() {
    local label="$1"

    # Create launch agent but NO app
    create_mock_launch_agent "$label"
}

# Create known parasite scenario
# Usage: create_known_parasite_scenario
create_known_parasite_scenario() {
    # Create known parasites from the database
    create_mock_launch_agent "com.google.keystone.agent"
    create_mock_launch_agent "com.adobe.GC.Invoker-1.0" "system"
    create_mock_launch_daemon "com.adobe.ARMDC.SMJobBlessHelper"
}
