#!/usr/bin/env bash
# Install skill-writer for Claude platform.
# Copies skill-framework.md and all companion reference files to ~/.claude/

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing skill-writer to ${CLAUDE_DIR} ..."

# 1. Main skill file
mkdir -p "${CLAUDE_DIR}/skills"
cp "${SCRIPT_DIR}/skill-framework.md" "${CLAUDE_DIR}/skills/skill-writer.md"
echo "  ✓ ${CLAUDE_DIR}/skills/skill-writer.md"

# 2. Companion reference files (claude/refs/)
mkdir -p "${CLAUDE_DIR}/refs"
cp "${SCRIPT_DIR}/refs/"*.md "${CLAUDE_DIR}/refs/"
echo "  ✓ ${CLAUDE_DIR}/refs/ ($(ls "${SCRIPT_DIR}/refs/"*.md | wc -l | tr -d ' ') files)"

# 3. Skill creation templates (claude/templates/)
mkdir -p "${CLAUDE_DIR}/templates"
cp "${SCRIPT_DIR}/templates/"*.md "${CLAUDE_DIR}/templates/"
echo "  ✓ ${CLAUDE_DIR}/templates/ ($(ls "${SCRIPT_DIR}/templates/"*.md | wc -l | tr -d ' ') files)"

# 4. Evaluation rubrics (claude/eval/)
mkdir -p "${CLAUDE_DIR}/eval"
cp "${SCRIPT_DIR}/eval/"*.md "${CLAUDE_DIR}/eval/"
echo "  ✓ ${CLAUDE_DIR}/eval/ ($(ls "${SCRIPT_DIR}/eval/"*.md | wc -l | tr -d ' ') files)"

# 5. Optimization strategies (claude/optimize/)
mkdir -p "${CLAUDE_DIR}/optimize"
cp "${SCRIPT_DIR}/optimize/"*.md "${CLAUDE_DIR}/optimize/"
echo "  ✓ ${CLAUDE_DIR}/optimize/ ($(ls "${SCRIPT_DIR}/optimize/"*.md | wc -l | tr -d ' ') files)"

echo ""
echo "Installation complete. Restart Claude to activate skill-writer."
