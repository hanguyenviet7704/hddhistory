#!/bin/bash

# GitFlow Quick Reference Guide

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ${CYAN}GitFlow Quick Reference Guide${BLUE}                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📋 Common Commands:${NC}"
echo ""
echo -e "${YELLOW}Feature Development:${NC}"
echo "  ./tools/linux/git/workflow/feature.sh start TICKET-ID description"
echo "  ./tools/linux/git/workflow/feature.sh publish"
echo "  ./tools/linux/git/workflow/feature.sh finish"
echo ""

echo -e "${YELLOW}Bug Fixes:${NC}"
echo "  ./tools/linux/git/workflow/fix.sh start TICKET-ID description"
echo "  ./tools/linux/git/workflow/fix.sh publish"
echo "  ./tools/linux/git/workflow/fix.sh finish"
echo ""

echo -e "${YELLOW}Releases:${NC}"
echo "  ./tools/linux/git/workflow/release.sh start VERSION"
echo "  ./tools/linux/git/workflow/release.sh finish"
echo ""

echo -e "${YELLOW}Emergency Hotfixes:${NC}"
echo "  ./tools/linux/git/workflow/hotfix.sh start TICKET-ID description"
echo "  ./tools/linux/git/workflow/hotfix.sh finish"
echo ""

echo -e "${GREEN}🌿 Branch Naming:${NC}"
echo "  feature/TICKET-ID-description  (e.g., feature/ARTLEXIS-123-login)"
echo "  fix/TICKET-ID-description      (e.g., fix/ARTLEXIS-456-validation)"
echo "  release/VERSION                (e.g., release/1.2.0)"
echo "  hotfix/TICKET-ID-description   (e.g., hotfix/ARTLEXIS-789-crash)"
echo ""

echo -e "${GREEN}📝 Commit Format:${NC}"
echo "  type(scope): subject"
echo "  type-TICKET-ID: subject"
echo ""
echo "  Types: feature, fix, hotfix, release, docs, style, refactor, test, chore"
echo ""
echo "  Examples:"
echo "    feature(auth): Add social login"
echo "    fix-ARTLEXIS-456: Fix validation error"
echo ""

echo -e "${GREEN}🔍 Current Status:${NC}"
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "Not in a git repository")
echo "  Branch: ${CYAN}$CURRENT_BRANCH${NC}"
echo ""

echo -e "${BLUE}📚 For detailed help:${NC}"
echo "  ./tools/linux/git/workflow/feature.sh help"
echo "  ./tools/linux/git/workflow/commit-helper.sh   # Interactive commit message generator"
echo "  cat ./tools/linux/git/README.md"
echo "" 