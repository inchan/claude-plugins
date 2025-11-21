#!/bin/bash
# Rollback script for multi-plugin migration
#
# This script restores the repository to pre-migration state
# using the backup branch created before migration

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Multi-Plugin Migration Rollback ===${NC}\n"

# Validate we're in the right directory
if [[ ! -f ".claude-plugin/marketplace.json" ]]; then
    echo -e "${RED}Error: Not in cc-skills repository root${NC}"
    exit 1
fi

# Check if backup branch exists
if ! git rev-parse --verify backup/pre-multi-plugin-refactor >/dev/null 2>&1; then
    echo -e "${RED}Error: Backup branch 'backup/pre-multi-plugin-refactor' not found${NC}"
    echo "Cannot perform rollback without backup."
    exit 1
fi

echo -e "${YELLOW}Current branch:${NC} $(git branch --show-current)"
echo -e "${YELLOW}Backup branch:${NC} backup/pre-multi-plugin-refactor"
echo ""

# Show what will be restored
echo -e "${YELLOW}Files that will be restored:${NC}"
git diff --name-only HEAD backup/pre-multi-plugin-refactor | head -20
TOTAL_CHANGES=$(git diff --name-only HEAD backup/pre-multi-plugin-refactor | wc -l)
echo "... (${TOTAL_CHANGES} total files)"
echo ""

# Confirm rollback
read -p "Are you sure you want to rollback? This will discard all migration changes. (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${YELLOW}Rollback cancelled.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Starting rollback...${NC}\n"

# Create safety checkpoint
CURRENT_BRANCH=$(git branch --show-current)
CHECKPOINT_BRANCH="rollback-checkpoint-$(date +%Y%m%d-%H%M%S)"
git branch "$CHECKPOINT_BRANCH"
echo -e "${GREEN}✓${NC} Created safety checkpoint: $CHECKPOINT_BRANCH"

# Perform rollback
echo -e "\n${YELLOW}Step 1: Removing plugins/ directory...${NC}"
if [[ -d "plugins" ]]; then
    rm -rf plugins/
    echo -e "${GREEN}✓${NC} Removed plugins/"
fi

echo -e "\n${YELLOW}Step 2: Restoring src/ directory...${NC}"
git checkout backup/pre-multi-plugin-refactor -- src/
echo -e "${GREEN}✓${NC} Restored src/"

echo -e "\n${YELLOW}Step 3: Restoring skill-rules.json...${NC}"
if git show backup/pre-multi-plugin-refactor:skills/skill-rules.json >/dev/null 2>&1; then
    git checkout backup/pre-multi-plugin-refactor -- skills/skill-rules.json
    echo -e "${GREEN}✓${NC} Restored skills/skill-rules.json"
fi

echo -e "\n${YELLOW}Step 4: Restoring marketplace.json...${NC}"
git checkout backup/pre-multi-plugin-refactor -- .claude-plugin/marketplace.json
echo -e "${GREEN}✓${NC} Restored .claude-plugin/marketplace.json"

echo -e "\n${YELLOW}Step 5: Restoring documentation...${NC}"
git checkout backup/pre-multi-plugin-refactor -- README.md CLAUDE.md
echo -e "${GREEN}✓${NC} Restored README.md and CLAUDE.md"

echo -e "\n${YELLOW}Step 6: Cleaning up migration scripts...${NC}"
if [[ -f "scripts/migrate-to-multi-plugin.sh" ]]; then
    rm scripts/migrate-to-multi-plugin.sh
    echo -e "${GREEN}✓${NC} Removed migration script"
fi
if [[ -f "scripts/split-skill-rules.js" ]]; then
    rm scripts/split-skill-rules.js
    echo -e "${GREEN}✓${NC} Removed split script"
fi

# Show current state
echo -e "\n${YELLOW}Rollback Summary:${NC}"
echo -e "Current branch: ${GREEN}$CURRENT_BRANCH${NC}"
echo -e "Safety checkpoint: ${GREEN}$CHECKPOINT_BRANCH${NC}"
echo ""
git status --short

echo -e "\n${GREEN}=== Rollback Complete ===${NC}\n"
echo "Next steps:"
echo "1. Review changes: git status"
echo "2. Commit rollback: git add . && git commit -m 'Rollback multi-plugin migration'"
echo "3. If needed, restore migration: git checkout $CHECKPOINT_BRANCH"
echo ""
echo -e "${YELLOW}Note:${NC} The checkpoint branch '$CHECKPOINT_BRANCH' contains your pre-rollback state."
