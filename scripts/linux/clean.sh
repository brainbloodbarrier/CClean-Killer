#!/bin/bash
# CClean-Killer - Linux Cleanup Script
# Safely removes caches and orphaned data

set -e

# Source common library for safety functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib/common.sh" ]] && source "$SCRIPT_DIR/lib/common.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
DRY_RUN=false
CLEAN_CACHES=false
CLEAN_DEV=false
CLEAN_TRASH=false
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
        --dev)
            CLEAN_DEV=true
            shift
            ;;
        --trash)
            CLEAN_TRASH=true
            shift
            ;;
        --all)
            CLEAN_ALL=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--caches] [--dev] [--trash] [--all]"
            exit 1
            ;;
    esac
done

if ! $CLEAN_CACHES && ! $CLEAN_DEV && ! $CLEAN_TRASH; then
    CLEAN_ALL=true
fi

if $CLEAN_ALL; then
    CLEAN_CACHES=true
    CLEAN_DEV=true
    CLEAN_TRASH=true
fi

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    CClean-Killer - Linux Cleanup         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}⚠️  DRY RUN MODE - No files will be deleted${NC}"
    echo ""
fi

# XDG directories
XDG_CACHE=${XDG_CACHE_HOME:-~/.cache}

# Track freed space
total_freed=0

format_size() {
    local kb=$1
    if [ $kb -gt 1048576 ]; then
        echo "$(echo "scale=2; $kb/1048576" | bc) GB"
    elif [ $kb -gt 1024 ]; then
        echo "$(echo "scale=2; $kb/1024" | bc) MB"
    else
        echo "${kb} KB"
    fi
}

safe_remove() {
    local path="$1"
    local desc="$2"

    # Skip if path doesn't exist
    [[ ! -e "$path" ]] && return 0

    # Normalize and validate path
    local normalized
    normalized=$(normalize_path "$path")

    # Reject empty or root paths
    if [[ -z "$normalized" ]] || [[ "$normalized" == "/" ]]; then
        echo -e "${RED}✗ Refusing empty/root path${NC}"
        return 1
    fi

    # Reject symlinks - never follow links
    if [[ -L "$normalized" ]]; then
        echo -e "${RED}✗ Refusing symlink: $normalized${NC}"
        return 1
    fi

    # Validate against protected system paths
    if ! is_safe_path "$normalized"; then
        echo -e "${RED}✗ Refusing unsafe path: $normalized${NC}"
        return 1
    fi

    local size=$(du -sk "$normalized" 2>/dev/null | cut -f1 || echo "0")
    local size_formatted=$(format_size $size)

    if $DRY_RUN; then
        echo -e "${YELLOW}Would remove:${NC} $desc ($size_formatted)"
    else
        echo -e "${GREEN}Removing:${NC} $desc ($size_formatted)"
        rm -rf -- "$normalized"
        total_freed=$((total_freed + size))
    fi
}

# ============================================
# CACHES
# ============================================
if $CLEAN_CACHES; then
    echo -e "${GREEN}🗑️  Cleaning XDG Cache...${NC}"
    echo "────────────────────────────────────────────"

    # Skip critical caches
    for cache in "$XDG_CACHE"/*/; do
        if [ -d "$cache" ]; then
            name=$(basename "$cache")
            # Skip fontconfig (causes font issues if removed)
            if [[ "$name" != "fontconfig" ]] && [[ "$name" != "mesa_shader_cache" ]]; then
                safe_remove "$cache" "Cache: $name"
            fi
        fi
    done

    # Thumbnails
    safe_remove "$XDG_CACHE/thumbnails" "Thumbnails cache"

    echo ""
fi

# ============================================
# DEV TOOLS
# ============================================
if $CLEAN_DEV; then
    echo -e "${GREEN}🛠️  Cleaning Developer Caches...${NC}"
    echo "────────────────────────────────────────────"

    # npm cache
    if command -v npm &> /dev/null; then
        if $DRY_RUN; then
            echo -e "${YELLOW}Would run:${NC} npm cache clean --force"
        else
            echo "Running: npm cache clean --force"
            npm cache clean --force 2>/dev/null || true
        fi
    fi

    safe_remove ~/.npm/_cacache "npm cache"

    # pip cache
    if command -v pip &> /dev/null; then
        if $DRY_RUN; then
            echo -e "${YELLOW}Would run:${NC} pip cache purge"
        else
            echo "Running: pip cache purge"
            pip cache purge 2>/dev/null || true
        fi
    fi

    safe_remove ~/.cache/pip "pip cache"

    # Cargo registry cache
    safe_remove ~/.cargo/registry/cache "Cargo registry cache"

    # Go build cache
    if command -v go &> /dev/null; then
        if $DRY_RUN; then
            echo -e "${YELLOW}Would run:${NC} go clean -cache"
        else
            echo "Running: go clean -cache"
            go clean -cache 2>/dev/null || true
        fi
    fi

    # Gradle caches
    safe_remove ~/.gradle/caches "Gradle caches"

    # nvm cache
    safe_remove ~/.nvm/.cache "nvm cache"

    echo ""
fi

# ============================================
# TRASH
# ============================================
if $CLEAN_TRASH; then
    echo -e "${GREEN}🗑️  Emptying Trash...${NC}"
    echo "────────────────────────────────────────────"

    if [ -d ~/.local/share/Trash/files ]; then
        safe_remove ~/.local/share/Trash/files "Trash files"
        safe_remove ~/.local/share/Trash/info "Trash metadata"
    fi

    echo ""
fi

# ============================================
# SUMMARY
# ============================================
echo -e "${BLUE}════════════════════════════════════════════${NC}"
if $DRY_RUN; then
    echo -e "${BLUE}Dry run complete. No files were deleted.${NC}"
else
    echo -e "${BLUE}Cleanup complete!${NC}"
    echo -e "${BLUE}Total freed: $(format_size $total_freed)${NC}"
fi
echo -e "${BLUE}════════════════════════════════════════════${NC}"
