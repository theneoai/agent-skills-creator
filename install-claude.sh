#!/usr/bin/env bash
# DEPRECATED: install-claude.sh is superseded by install.sh
#
# Use instead:
#   ./install.sh --platform claude
#   curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/install.sh | bash -s -- --platform claude
#
# install.sh supports all 6 platforms (claude, opencode, openclaw, cursor, gemini, mcp),
# auto-detects installed platforms, works without a git clone, and handles companion files.

echo ""
echo "  ⚠  install-claude.sh is deprecated."
echo "     Please use: ./install.sh --platform claude"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/install.sh" --platform claude "$@"
