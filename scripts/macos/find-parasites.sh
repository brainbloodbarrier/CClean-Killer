#!/bin/bash
# CClean-Killer - Parasite Finder for macOS
# Finds zombie LaunchAgents/Daemons from uninstalled apps

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    CClean-Killer - Parasite Hunter       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Known parasites database
declare -A KNOWN_PARASITES
KNOWN_PARASITES["com.google.keystone"]="Google Keystone - Chrome updater (persists after Chrome removal)"
KNOWN_PARASITES["com.google.GoogleUpdater"]="Google Updater"
KNOWN_PARASITES["com.adobe.agsservice"]="Adobe Genuine Software - License check telemetry"
KNOWN_PARASITES["com.adobe.GC.Invoker"]="Adobe GC Invoker - Analytics collection"
KNOWN_PARASITES["com.adobe.ARMDC"]="Adobe ARMDC - Telemetry relay"
KNOWN_PARASITES["com.adobe.ARMDCHelper"]="Adobe ARMDC Helper"
KNOWN_PARASITES["com.piriform.ccleaner"]="CCleaner - The irony: 6 daemons for a 'cleaner'"
KNOWN_PARASITES["us.zoom"]="Zoom - Background daemons"
KNOWN_PARASITES["com.spotify.webhelper"]="Spotify Web Helper"
KNOWN_PARASITES["com.microsoft.update"]="Microsoft AutoUpdate"

# Function to check if app is installed
is_app_installed() {
    local pattern="$1"
    if ls /Applications/ 2>/dev/null | grep -qi "$pattern"; then
        return 0
    fi
    return 1
}

# Function to analyze a plist
analyze_plist() {
    local plist="$1"
    local location="$2"
    local name=$(basename "$plist" .plist)

    # Skip Apple plists
    if [[ "$name" == "com.apple."* ]]; then
        return
    fi

    # Check if it's a known parasite
    for pattern in "${!KNOWN_PARASITES[@]}"; do
        if [[ "$name" == *"$pattern"* ]]; then
            echo -e "${RED}🦠 KNOWN PARASITE: $name${NC}"
            echo -e "   ${MAGENTA}${KNOWN_PARASITES[$pattern]}${NC}"
            echo "   Location: $location/$plist"

            # Check if loaded
            if launchctl list 2>/dev/null | grep -q "$name"; then
                echo -e "   Status: ${RED}RUNNING${NC}"
            else
                echo -e "   Status: ${YELLOW}Loaded but not running${NC}"
            fi
            echo ""
            return
        fi
    done

    # For unknown plists, check if parent app exists
    # Try to extract app name from bundle ID
    local company=$(echo "$name" | cut -d. -f2)
    local app=$(echo "$name" | rev | cut -d. -f1 | rev)

    # Check various patterns
    if ! is_app_installed "$app" && ! is_app_installed "$company"; then
        echo -e "${YELLOW}⚠️  Potential orphan: $name${NC}"
        echo "   Location: $location"

        # Check if loaded
        if launchctl list 2>/dev/null | grep -q "$name"; then
            echo -e "   Status: ${YELLOW}RUNNING${NC}"
        fi
        echo ""
    fi
}

echo -e "${GREEN}🔍 Scanning User LaunchAgents...${NC}"
echo "────────────────────────────────────────────"

for plist in ~/Library/LaunchAgents/*.plist; do
    if [ -f "$plist" ]; then
        analyze_plist "$(basename "$plist")" "~/Library/LaunchAgents"
    fi
done

echo -e "${GREEN}🔍 Scanning System LaunchAgents...${NC}"
echo "────────────────────────────────────────────"

for plist in /Library/LaunchAgents/*.plist; do
    if [ -f "$plist" ]; then
        analyze_plist "$(basename "$plist")" "/Library/LaunchAgents"
    fi
done

echo -e "${GREEN}🔍 Scanning LaunchDaemons (system-wide)...${NC}"
echo "────────────────────────────────────────────"

for plist in /Library/LaunchDaemons/*.plist; do
    if [ -f "$plist" ]; then
        name=$(basename "$plist" .plist)

        # Skip Apple
        if [[ "$name" == "com.apple."* ]]; then
            continue
        fi

        # Check against known parasites
        for pattern in "${!KNOWN_PARASITES[@]}"; do
            if [[ "$name" == *"$pattern"* ]]; then
                echo -e "${RED}🦠 DAEMON: $name${NC}"
                echo -e "   ${MAGENTA}${KNOWN_PARASITES[$pattern]}${NC}"
                echo "   Location: /Library/LaunchDaemons/"
                echo -e "   ${YELLOW}(Requires sudo to remove)${NC}"
                echo ""
            fi
        done
    fi
done

echo -e "${GREEN}🔍 Scanning PrivilegedHelperTools...${NC}"
echo "────────────────────────────────────────────"

for helper in /Library/PrivilegedHelperTools/*; do
    if [ -f "$helper" ]; then
        name=$(basename "$helper")

        # Skip Apple
        if [[ "$name" == "com.apple."* ]]; then
            continue
        fi

        echo -e "${YELLOW}⚙️  Helper: $name${NC}"
        echo "   Path: $helper"
        echo ""
    fi
done

echo -e "${GREEN}🔍 Checking for code_sign_clone remnants...${NC}"
echo "────────────────────────────────────────────"

# Find var/folders location
TMPDIR_BASE=$(dirname "$(dirname "$TMPDIR")")
if [ -d "$TMPDIR_BASE" ]; then
    # Look for X directory (code signing clones)
    X_DIR="$TMPDIR_BASE/X"
    if [ -d "$X_DIR" ]; then
        for clone in "$X_DIR"/*.code_sign_clone/; do
            if [ -d "$clone" ]; then
                name=$(basename "$clone")
                size=$(du -sh "$clone" 2>/dev/null | cut -f1)
                echo -e "${YELLOW}📦 Clone: $name${NC} ($size)"
                echo "   Path: $clone"
                echo ""
            fi
        done
    fi
fi

echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${BLUE}Removal Commands${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""
echo "To remove a LaunchAgent:"
echo "  launchctl unload <path-to-plist>"
echo "  rm <path-to-plist>"
echo ""
echo "To remove a LaunchDaemon (requires sudo):"
echo "  sudo launchctl unload <path-to-plist>"
echo "  sudo rm <path-to-plist>"
echo ""
echo "Or use: /clean --parasites"
