#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "⚒  Claude Forge Installer"
echo ""

# Check source directories exist
for dir in agents commands skills rules; do
  if [ ! -d "${SCRIPT_DIR}/${dir}" ]; then
    echo "Error: ${dir}/ not found. Run this from the claude-forge directory."
    exit 1
  fi
done

# Install globally or to a project
if [ "${1:-}" = "--project" ]; then
  TARGET="${2:-.}/.claude"
  echo "Installing to project: ${TARGET}"
else
  TARGET="${CLAUDE_DIR}"
  echo "Installing globally to: ${TARGET}"
fi

# Copy each directory
for dir in agents commands skills rules; do
  mkdir -p "${TARGET}/${dir}"
  cp -r "${SCRIPT_DIR}/${dir}/"* "${TARGET}/${dir}/"
  count=$(find "${SCRIPT_DIR}/${dir}" -type f | wc -l | tr -d ' ')
  echo -e "  ${GREEN}✓${NC} ${dir} (${count} files)"
done

# Hooks reminder
echo ""
echo -e "${YELLOW}Note:${NC} Hooks require manual setup."
echo "  Merge hooks/hooks.json into your .claude/settings.json"
echo ""
echo -e "${GREEN}Done!${NC} Restart Claude Code to pick up changes."
echo ""
