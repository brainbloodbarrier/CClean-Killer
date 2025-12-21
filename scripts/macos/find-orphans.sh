#!/bin/bash
# CClean-Killer - Orphan Finder for macOS
# Finds application data for apps that are no longer installed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CClean-Killer - Orphan Hunter        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Get list of installed apps
INSTALLED_APPS=$(ls /Applications/ 2>/dev/null | sed 's/\.app$//' | tr '[:upper:]' '[:lower:]')

# Function to check if app is installed
is_app_installed() {
    local name="$1"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Check in /Applications
    if ls /Applications/ 2>/dev/null | grep -qi "$name"; then
        return 0
    fi

    # Check if it's a system/Apple app
    if [[ "$name_lower" == *"apple"* ]] || [[ "$name_lower" == *"com.apple"* ]]; then
        return 0
    fi

    # Check if binary exists
    if command -v "$name_lower" &> /dev/null; then
        return 0
    fi

    return 1
}

# Function to get size of directory
get_size() {
    du -sh "$1" 2>/dev/null | cut -f1
}

echo -e "${GREEN}🔍 Scanning Application Support...${NC}"
echo "────────────────────────────────────────────"

orphan_count=0
total_size=0

for dir in ~/Library/Application\ Support/*/; do
    if [ -d "$dir" ]; then
        name=$(basename "$dir")

        # Skip system directories
        if [[ "$name" == "." ]] || [[ "$name" == ".." ]] || [[ "$name" == "AddressBook" ]] || \
           [[ "$name" == "com.apple."* ]] || [[ "$name" == "Apple" ]] || [[ "$name" == "iCloud" ]] || \
           [[ "$name" == "CloudDocs" ]] || [[ "$name" == "Knowledge" ]]; then
            continue
        fi

        if ! is_app_installed "$name"; then
            size=$(get_size "$dir")
            echo -e "${YELLOW}⚠️  $name${NC} ($size)"
            echo "   Path: $dir"
            ((orphan_count++)) || true
        fi
    fi
done

echo ""
echo -e "${GREEN}🔍 Scanning Containers...${NC}"
echo "────────────────────────────────────────────"

for dir in ~/Library/Containers/*/; do
    if [ -d "$dir" ]; then
        bundle_id=$(basename "$dir")

        # Skip Apple containers
        if [[ "$bundle_id" == "com.apple."* ]]; then
            continue
        fi

        # Extract app name from bundle ID
        app_name=$(echo "$bundle_id" | rev | cut -d. -f1 | rev)

        if ! is_app_installed "$app_name"; then
            size=$(get_size "$dir")
            echo -e "${YELLOW}⚠️  $bundle_id${NC} ($size)"
            ((orphan_count++)) || true
        fi
    fi
done

echo ""
echo -e "${GREEN}🔍 Scanning Group Containers...${NC}"
echo "────────────────────────────────────────────"

for dir in ~/Library/Group\ Containers/*/; do
    if [ -d "$dir" ]; then
        group_id=$(basename "$dir")

        # Skip Apple groups
        if [[ "$group_id" == *"apple"* ]] || [[ "$group_id" == *"Apple"* ]]; then
            continue
        fi

        # Try to extract app name
        app_name=$(echo "$group_id" | rev | cut -d. -f1 | rev)

        if ! is_app_installed "$app_name"; then
            size=$(get_size "$dir")
            echo -e "${YELLOW}⚠️  $group_id${NC} ($size)"
            ((orphan_count++)) || true
        fi
    fi
done

echo ""
echo -e "${GREEN}🔍 Scanning Saved Application State...${NC}"
echo "────────────────────────────────────────────"

for dir in ~/Library/Saved\ Application\ State/*/; do
    if [ -d "$dir" ]; then
        bundle_id=$(basename "$dir" .savedState)

        # Skip Apple
        if [[ "$bundle_id" == "com.apple."* ]]; then
            continue
        fi

        app_name=$(echo "$bundle_id" | rev | cut -d. -f1 | rev)

        if ! is_app_installed "$app_name"; then
            size=$(get_size "$dir")
            echo -e "${YELLOW}⚠️  $bundle_id${NC} ($size)"
            ((orphan_count++)) || true
        fi
    fi
done

echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${BLUE}Summary: Found $orphan_count potential orphans${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""
echo "Run '/clean' to remove orphaned data safely"
