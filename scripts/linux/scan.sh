#!/bin/bash
# CClean-Killer - Linux System Scanner
# Analyzes disk usage following XDG directories

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CClean-Killer - Linux Scanner        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Disk Overview
echo -e "${GREEN}📊 Disk Overview${NC}"
echo "────────────────────────────────────────────"
df -h / | tail -1 | awk '{print "Total: "$2"  Used: "$3"  Available: "$4"  ("$5" used)"}'
echo ""

# XDG Directories
XDG_CONFIG=${XDG_CONFIG_HOME:-~/.config}
XDG_DATA=${XDG_DATA_HOME:-~/.local/share}
XDG_CACHE=${XDG_CACHE_HOME:-~/.cache}
XDG_STATE=${XDG_STATE_HOME:-~/.local/state}

# Config directory
echo -e "${GREEN}📁 XDG Config (~/.config) - Top 15${NC}"
echo "────────────────────────────────────────────"
du -sh "$XDG_CONFIG"/*/ 2>/dev/null | sort -hr | head -15
echo ""

# Data directory
echo -e "${GREEN}📦 XDG Data (~/.local/share) - Top 15${NC}"
echo "────────────────────────────────────────────"
du -sh "$XDG_DATA"/*/ 2>/dev/null | sort -hr | head -15
echo ""

# Cache directory
echo -e "${GREEN}🗑️  XDG Cache (~/.cache) - Top 15${NC}"
echo "────────────────────────────────────────────"
du -sh "$XDG_CACHE"/*/ 2>/dev/null | sort -hr | head -15
echo ""

# Hidden home directories
echo -e "${GREEN}🔍 Home Hidden Files - Top 15${NC}"
echo "────────────────────────────────────────────"
du -sh ~/.[!.]* 2>/dev/null | sort -hr | head -15
echo ""

# Development tools
echo -e "${GREEN}🛠️  Developer Tools${NC}"
echo "────────────────────────────────────────────"
echo -n "npm:       "; du -sh ~/.npm 2>/dev/null | cut -f1 || echo "Not found"
echo -n "nvm:       "; du -sh ~/.nvm 2>/dev/null | cut -f1 || echo "Not found"
echo -n "Cargo:     "; du -sh ~/.cargo 2>/dev/null | cut -f1 || echo "Not found"
echo -n "Rustup:    "; du -sh ~/.rustup 2>/dev/null | cut -f1 || echo "Not found"
echo -n "Go:        "; du -sh ~/go 2>/dev/null | cut -f1 || echo "Not found"
echo -n "Maven:     "; du -sh ~/.m2 2>/dev/null | cut -f1 || echo "Not found"
echo -n "Gradle:    "; du -sh ~/.gradle 2>/dev/null | cut -f1 || echo "Not found"
echo -n "pip cache: "; du -sh ~/.cache/pip 2>/dev/null | cut -f1 || echo "Not found"
echo ""

# Containers
echo -e "${GREEN}📦 Container Data${NC}"
echo "────────────────────────────────────────────"

# Flatpak
if [ -d ~/.var/app ]; then
    echo "Flatpak apps:"
    du -sh ~/.var/app/*/ 2>/dev/null | sort -hr | head -5
fi

# Snap
if [ -d ~/snap ]; then
    echo ""
    echo "Snap apps:"
    du -sh ~/snap/*/ 2>/dev/null | sort -hr | head -5
fi

# Docker
if command -v docker &> /dev/null; then
    echo ""
    echo "Docker:"
    docker system df 2>/dev/null || echo "Docker not running"
fi

# Podman
if command -v podman &> /dev/null; then
    echo ""
    echo "Podman:"
    podman system df 2>/dev/null || echo "Podman not available"
fi

echo ""

# Package manager cache
echo -e "${GREEN}📦 Package Manager Cache${NC}"
echo "────────────────────────────────────────────"

# apt
if [ -d /var/cache/apt ]; then
    echo -n "apt cache: "
    sudo du -sh /var/cache/apt 2>/dev/null | cut -f1 || du -sh /var/cache/apt 2>/dev/null | cut -f1 || echo "Access denied"
fi

# dnf/yum
if [ -d /var/cache/dnf ]; then
    echo -n "dnf cache: "
    sudo du -sh /var/cache/dnf 2>/dev/null | cut -f1 || echo "Access denied"
fi

# pacman
if [ -d /var/cache/pacman ]; then
    echo -n "pacman cache: "
    du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1 || echo "Not found"
fi

echo ""

# Trash
echo -e "${GREEN}🗑️  Trash${NC}"
echo "────────────────────────────────────────────"
if [ -d ~/.local/share/Trash ]; then
    du -sh ~/.local/share/Trash 2>/dev/null || echo "Empty"
fi
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${BLUE}            Quick Actions                    ${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""
echo "  ./clean.sh --caches    - Clean all caches"
echo "  ./clean.sh --dev       - Clean dev tool caches"
echo "  ./clean.sh --all       - Full cleanup"
echo ""
