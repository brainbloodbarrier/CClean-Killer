#!/bin/bash
# CClean-Killer - macOS System Scanner
# Analyzes disk usage and identifies cleanup opportunities

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CClean-Killer - System Scanner       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Disk Overview
echo -e "${GREEN}📊 Disk Overview${NC}"
echo "────────────────────────────────────────────"
df -h / | tail -1 | awk '{print "Total: "$2"  Used: "$3"  Available: "$4"  ("$5" used)"}'
echo ""

# User Library Analysis
echo -e "${GREEN}📁 ~/Library Analysis (Top 15)${NC}"
echo "────────────────────────────────────────────"
du -sh ~/Library/*/ 2>/dev/null | sort -hr | head -15
echo ""

# Application Support Details
echo -e "${GREEN}📦 Application Support (Top 15)${NC}"
echo "────────────────────────────────────────────"
du -sh ~/Library/Application\ Support/*/ 2>/dev/null | sort -hr | head -15
echo ""

# Caches
echo -e "${GREEN}🗑️  Caches (Top 10)${NC}"
echo "────────────────────────────────────────────"
du -sh ~/Library/Caches/*/ 2>/dev/null | sort -hr | head -10
echo ""

# Containers (Sandboxed Apps)
echo -e "${GREEN}📦 Containers - Sandboxed Apps (Top 10)${NC}"
echo "────────────────────────────────────────────"
du -sh ~/Library/Containers/*/ 2>/dev/null | sort -hr | head -10
echo ""

# Group Containers
echo -e "${GREEN}👥 Group Containers (Top 10)${NC}"
echo "────────────────────────────────────────────"
du -sh ~/Library/Group\ Containers/*/ 2>/dev/null | sort -hr | head -10
echo ""

# Home Directory Hidden Files
echo -e "${GREEN}🔍 Home Directory Hidden (Top 15)${NC}"
echo "────────────────────────────────────────────"
du -sh ~/.[!.]* 2>/dev/null | sort -hr | head -15
echo ""

# Developer Tools
echo -e "${GREEN}🛠️  Developer Caches${NC}"
echo "────────────────────────────────────────────"
echo -n "npm cache:     "; du -sh ~/.npm 2>/dev/null | cut -f1 || echo "Not found"
echo -n "pnpm cache:    "; du -sh ~/Library/pnpm 2>/dev/null | cut -f1 || echo "Not found"
echo -n "Homebrew:      "; du -sh /opt/homebrew 2>/dev/null | cut -f1 || du -sh /usr/local/Homebrew 2>/dev/null | cut -f1 || echo "Not found"
echo -n "Cargo:         "; du -sh ~/.cargo 2>/dev/null | cut -f1 || echo "Not found"
echo -n "pip cache:     "; du -sh ~/Library/Caches/pip 2>/dev/null | cut -f1 || echo "Not found"
echo ""

# Docker (if installed)
if command -v docker &> /dev/null; then
    echo -e "${GREEN}🐳 Docker${NC}"
    echo "────────────────────────────────────────────"
    docker system df 2>/dev/null || echo "Docker not running"
    echo ""
fi

# System Library (requires sudo for accurate size)
echo -e "${YELLOW}⚠️  System Library (may require sudo for accuracy)${NC}"
echo "────────────────────────────────────────────"
du -sh /Library/Application\ Support/*/ 2>/dev/null | sort -hr | head -10
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${BLUE}            Quick Actions Available          ${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""
echo "  /clean           - Clean caches and orphaned data"
echo "  /parasites       - Hunt zombie LaunchAgents/Daemons"
echo "  /report          - Generate full report"
echo ""
