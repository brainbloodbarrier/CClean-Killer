#!/bin/bash
# CClean-Killer Test Fixtures - Common Test Scenarios
# Provides reusable test scenario setup functions

# =============================================================================
# Scenario: Fresh macOS Install (minimal orphans)
# =============================================================================
setup_scenario_fresh_install() {
    # Create common Apple apps
    create_mock_app "Safari"
    create_mock_app "Mail"
    create_mock_app "Calendar"
    create_mock_app "Notes"

    # Create matching support data
    create_mock_app_support "com.apple.Safari"
    create_mock_app_support "com.apple.mail"
    create_mock_app_support "com.apple.iCal"

    # Create some caches
    create_mock_cache "com.apple.Safari"
    create_mock_cache "CloudKit"
}

# =============================================================================
# Scenario: Developer Machine (lots of dev tools)
# =============================================================================
setup_scenario_developer() {
    setup_scenario_fresh_install

    # Development apps
    create_mock_app "Visual Studio Code"
    create_mock_app "Xcode"
    create_mock_app "Docker"
    create_mock_app "iTerm"

    # Dev tool data
    create_mock_app_support "Code" 500
    create_mock_app_support "com.apple.dt.Xcode" 1000
    create_mock_app_support "Docker" 200

    # Caches
    create_mock_cache "com.microsoft.VSCode" 300
    create_mock_cache "com.apple.dt.Xcode" 500

    # Dev tool caches in home
    create_mock_npm_cache 200
    create_mock_pip_cache 150

    # Create ~/.npm, ~/.cargo, etc.
    mkdir -p "$MOCK_HOME/.cargo/registry/cache"
    mkdir -p "$MOCK_HOME/.gradle/caches"
    dd if=/dev/zero of="$MOCK_HOME/.cargo/registry/cache/cargo.bin" bs=1024 count=100 2>/dev/null
}

# =============================================================================
# Scenario: Orphan Heavy (many uninstalled apps left data)
# =============================================================================
setup_scenario_orphan_heavy() {
    setup_scenario_fresh_install

    # Orphaned apps (data without apps)
    create_orphan_scenario "RemovedApp1"
    create_orphan_scenario "UninstalledGame"
    create_orphan_scenario "OldEditor"
    create_orphan_scenario "TrialSoftware"
    create_orphan_scenario "DeprecatedTool"

    # Some orphans with large data
    create_mock_app_support "MassiveOrphan" 5000
    create_mock_cache "MassiveOrphan" 2000
}

# =============================================================================
# Scenario: Parasite Infestation (many zombie agents)
# =============================================================================
setup_scenario_parasite_infestation() {
    setup_scenario_fresh_install

    # Known parasites
    create_known_parasite_scenario

    # Additional parasites
    create_parasite_scenario "com.removed.updatehelper"
    create_parasite_scenario "com.oldapp.backgroundservice"
    create_parasite_scenario "net.uninstalled.daemon"

    # Some legitimate agents (for apps that exist)
    create_mock_app "Dropbox"
    create_mock_launch_agent "com.dropbox.DropboxMacUpdate.agent"

    create_mock_app "Slack"
    create_mock_launch_agent "com.tinyspeck.slackmacgap.helper"
}

# =============================================================================
# Scenario: Mixed (realistic production machine)
# =============================================================================
setup_scenario_mixed() {
    setup_scenario_developer

    # Add some orphans
    create_orphan_scenario "RemovedApp"
    create_orphan_scenario "OldTool"

    # Add some parasites
    create_parasite_scenario "com.uninstalled.helper"
    create_mock_launch_agent "com.google.keystone.agent"

    # Add legitimate agents
    create_mock_app "Spotify"
    create_mock_launch_agent "com.spotify.client.startuphelper"

    # Large caches
    create_mock_cache "com.spotify.client" 500
    create_mock_cache "com.apple.dt.Xcode" 1000

    # Logs
    create_mock_logs "DiagnosticReports" 50
    create_mock_logs "Homebrew" 20

    # Trash
    create_mock_trash 300
}

# =============================================================================
# Scenario: Linux Developer
# =============================================================================
setup_scenario_linux_developer() {
    # XDG directories
    mkdir -p "$MOCK_HOME/.config/Code"
    mkdir -p "$MOCK_HOME/.config/nvim"
    mkdir -p "$MOCK_HOME/.local/share/applications"

    # Caches
    mkdir -p "$MOCK_HOME/.cache/pip"
    mkdir -p "$MOCK_HOME/.cache/yarn"
    mkdir -p "$MOCK_HOME/.cache/go-build"

    dd if=/dev/zero of="$MOCK_HOME/.cache/pip/cache.bin" bs=1024 count=200 2>/dev/null
    dd if=/dev/zero of="$MOCK_HOME/.cache/yarn/cache.bin" bs=1024 count=300 2>/dev/null

    # Dev tools
    create_mock_npm_cache 250
    mkdir -p "$MOCK_HOME/.nvm/.cache"
    dd if=/dev/zero of="$MOCK_HOME/.nvm/.cache/nvm.bin" bs=1024 count=50 2>/dev/null

    # Flatpak/Snap dirs (for testing)
    mkdir -p "$MOCK_HOME/.var/app/org.example.App"
    mkdir -p "$MOCK_HOME/snap/example-snap"

    # Trash
    create_mock_trash 150
}

# =============================================================================
# Scenario: Empty/Clean System
# =============================================================================
setup_scenario_clean() {
    # Minimal setup - just the directory structure
    # Already created by setup_mock_environment
    :
}

# =============================================================================
# Scenario: Edge Cases
# =============================================================================
setup_scenario_edge_cases() {
    # App name with spaces
    create_mock_app "My Custom App"
    create_mock_app_support "My Custom App"

    # App name with special characters
    create_mock_app "App (Beta)"
    create_mock_app_support "App (Beta)"

    # Very long app name
    create_mock_app "ThisIsAVeryLongApplicationNameThatMightCauseIssues"
    create_mock_app_support "ThisIsAVeryLongApplicationNameThatMightCauseIssues"

    # Unicode app name
    create_mock_app "App-日本語"

    # Hidden files in app support
    mkdir -p "$MOCK_LIBRARY/Application Support/.hidden_app"
    echo "hidden" > "$MOCK_LIBRARY/Application Support/.hidden_app/data"

    # Empty directories
    mkdir -p "$MOCK_LIBRARY/Application Support/EmptyApp"
    mkdir -p "$MOCK_LIBRARY/Caches/EmptyCache"

    # Symlinks
    ln -s "$MOCK_LIBRARY/Application Support/EmptyApp" "$MOCK_LIBRARY/Application Support/SymlinkApp"

    # Permission edge cases (read-only)
    mkdir -p "$MOCK_LIBRARY/Application Support/ReadOnlyApp"
    echo "data" > "$MOCK_LIBRARY/Application Support/ReadOnlyApp/data"
    chmod 444 "$MOCK_LIBRARY/Application Support/ReadOnlyApp/data"
}
