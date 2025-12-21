#!/bin/bash
# CClean-Killer - Safe Cleanup Script for macOS
# Removes caches and orphaned data safely

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
DRY_RUN=false
CLEAN_CACHES=false
CLEAN_ORPHANS=false
CLEAN_DEV=false
CLEAN_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --caches)
            CLEAN_CACHES=true
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
        --all)
            CLEAN_ALL=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--caches] [--orphans] [--dev] [--all]"
            exit 1
            ;;
    esac
done

# If no specific flag, clean all
if ! $CLEAN_CACHES && ! $CLEAN_ORPHANS && ! $CLEAN_DEV; then
    CLEAN_ALL=true
fi

if $CLEAN_ALL; then
    CLEAN_CACHES=true
    CLEAN_ORPHANS=true
    CLEAN_DEV=true
fi

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       CClean-Killer - Safe Cleanup       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}⚠️  DRY RUN MODE - No files will be deleted${NC}"
    echo ""
fi

# Track total freed
total_freed=0

# Function to get directory size in bytes
get_size_bytes() {
    du -sk "$1" 2>/dev/null | cut -f1 || echo "0"
}

# Function to format size
format_size() {
    local bytes=$1
    if [ $bytes -gt 1048576 ]; then
        echo "$(echo "scale=2; $bytes/1048576" | bc) GB"
    elif [ $bytes -gt 1024 ]; then
        echo "$(echo "scale=2; $bytes/1024" | bc) MB"
    else
        echo "${bytes} KB"
    fi
}

# Function to safely remove
safe_remove() {
    local path="$1"
    local desc="$2"

    if [ -e "$path" ]; then
        local size=$(get_size_bytes "$path")
        local size_formatted=$(format_size $size)

        if $DRY_RUN; then
            echo -e "${YELLOW}Would remove:${NC} $desc ($size_formatted)"
            echo "  Path: $path"
        else
            echo -e "${GREEN}Removing:${NC} $desc ($size_formatted)"
            rm -rf "$path"
            total_freed=$((total_freed + size))
        fi
    fi
}

# ============================================
# CACHES
# ============================================
if $CLEAN_CACHES; then
    echo -e "${GREEN}🗑️  Cleaning Caches...${NC}"
    echo "────────────────────────────────────────────"

    # User caches (always safe)
    for cache in ~/Library/Caches/*/; do
        if [ -d "$cache" ]; then
            name=$(basename "$cache")
            # Skip critical caches
            if [[ "$name" != "CloudKit" ]] && [[ "$name" != "com.apple.HomeKit" ]]; then
                safe_remove "$cache" "Cache: $name"
            fi
        fi
    done

    # Logs (safe to remove old ones)
    echo ""
    echo -e "${GREEN}📝 Cleaning Logs...${NC}"
    echo "────────────────────────────────────────────"

    for log in ~/Library/Logs/*/; do
        if [ -d "$log" ]; then
            name=$(basename "$log")
            safe_remove "$log" "Logs: $name"
        fi
    done

    echo ""
fi

# ============================================
# DEV TOOLS
# ============================================
if $CLEAN_DEV; then
    echo -e "${GREEN}🛠️  Cleaning Developer Caches...${NC}"
    echo "────────────────────────────────────────────"

    # npm cache
    if [ -d ~/.npm/_cacache ]; then
        safe_remove ~/.npm/_cacache "npm cache"
    fi

    # pnpm cache
    if [ -d ~/Library/pnpm/store ]; then
        safe_remove ~/Library/pnpm/store "pnpm store"
    fi

    # Homebrew cleanup
    if command -v brew &> /dev/null; then
        if $DRY_RUN; then
            echo -e "${YELLOW}Would run:${NC} brew cleanup --prune=all"
        else
            echo "Running: brew cleanup --prune=all"
            brew cleanup --prune=all 2>/dev/null || true
        fi
    fi

    # pip cache
    if [ -d ~/Library/Caches/pip ]; then
        safe_remove ~/Library/Caches/pip "pip cache"
    fi

    # Cargo registry cache
    if [ -d ~/.cargo/registry/cache ]; then
        safe_remove ~/.cargo/registry/cache "Cargo registry cache"
    fi

    # Gradle cache
    if [ -d ~/.gradle/caches ]; then
        safe_remove ~/.gradle/caches "Gradle caches"
    fi

    # Maven cache
    if [ -d ~/.m2/repository ]; then
        echo -e "${YELLOW}Skipping:${NC} Maven repository (may contain needed dependencies)"
    fi

    echo ""
fi

# ============================================
# SUMMARY
# ============================================
echo -e "${BLUE}════════════════════════════════════════════${NC}"
if $DRY_RUN; then
    echo -e "${BLUE}Dry run complete. No files were deleted.${NC}"
    echo -e "${BLUE}Run without --dry-run to actually clean.${NC}"
else
    echo -e "${BLUE}Cleanup complete!${NC}"
    echo -e "${BLUE}Total freed: $(format_size $total_freed)${NC}"
fi
echo -e "${BLUE}════════════════════════════════════════════${NC}"
