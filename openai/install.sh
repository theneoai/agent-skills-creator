#!/usr/bin/env bash
# install.sh — Install skill-writer for OpenAI (Responses API / Agents SDK)
#
# Usage:
#   ./openai/install.sh [TARGET_DIR]     # install to project directory
#   ./openai/install.sh --dry-run        # preview only
#
# OpenAI Agents SDK: copies skill-writer.md + AGENTS.md to target project
# Custom GPT: manual setup — see instructions printed at the end

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN=false
TARGET_DIR=""

info()    { echo "  $*"; }
success() { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*" >&2; }
err()     { echo "  ✗ $*" >&2; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      awk '/^[^#]/{exit} /^# /{sub(/^# /,""); print}' "$0"
      exit 0 ;;
    --*) ;;
    *)  TARGET_DIR="$arg" ;;
  esac
done

# Default TARGET_DIR after all args parsed (avoids --dry-run being mistaken as a path)
TARGET_DIR="${TARGET_DIR:-$(pwd)}"

if $DRY_RUN; then
  info "[DRY RUN] No files will be written."
fi

# ── Dependency check ──────────────────────────────────────────────────────────
if ! $DRY_RUN; then
  if ! command -v python3 &>/dev/null; then
    err "python3 is required for routing-file merge (AGENTS.md)."
    err "  macOS:  brew install python3"
    err "  Ubuntu: sudo apt install python3"
    exit 1
  fi
fi

SKILLS_DIR="${TARGET_DIR}/skills"

# ── Create directories ──────────────────────────────────────────────────────
for dir in "$SKILLS_DIR" "$TARGET_DIR/refs" "$TARGET_DIR/templates" \
           "$TARGET_DIR/eval" "$TARGET_DIR/optimize"; do
  if ! $DRY_RUN; then
    mkdir -p "$dir"
  fi
  info "dir: $dir"
done

# ── Copy skill file ─────────────────────────────────────────────────────────
SKILL_SRC="$SCRIPT_DIR/skill-writer.md"
SKILL_DST="$SKILLS_DIR/skill-writer.md"

if [[ -f "$SKILL_DST" ]]; then
  if ! $DRY_RUN; then
    cp "$SKILL_DST" "${SKILL_DST}.bak.$(date +%Y%m%d_%H%M%S)"
  fi
  info "Backed up existing skill file"
fi

if ! $DRY_RUN; then
  cp "$SKILL_SRC" "$SKILL_DST"
fi
success "skill-writer.md → $SKILL_DST"

# ── Copy AGENTS.md ──────────────────────────────────────────────────────────
AGENTS_SRC="$SCRIPT_DIR/AGENTS.md"
AGENTS_DST="$TARGET_DIR/AGENTS.md"
BLOCK_START="<!-- skill-writer:start -->"

if [[ -f "$AGENTS_DST" ]] && grep -q "$BLOCK_START" "$AGENTS_DST"; then
  if ! $DRY_RUN; then
    cp "$AGENTS_DST" "${AGENTS_DST}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    python3 -c "
import re
with open('$AGENTS_DST', 'r') as f: content = f.read()
with open('$AGENTS_SRC', 'r') as f: block = f.read().strip()
pattern = r'<!-- skill-writer:start -->.*?<!-- skill-writer:end -->'
new = re.sub(pattern, block, content, flags=re.DOTALL)
with open('$AGENTS_DST', 'w') as f: f.write(new)
" || { err "Routing file merge failed. Backup at ${AGENTS_DST}.bak.*"; exit 1; }
  fi
  success "AGENTS.md → updated skill-writer block"
else
  if ! $DRY_RUN; then
    echo "" >> "$AGENTS_DST"
    cat "$AGENTS_SRC" >> "$AGENTS_DST"
  fi
  success "AGENTS.md → appended skill-writer block"
fi

# ── Copy companion files ────────────────────────────────────────────────────
for dir in refs templates eval optimize; do
  SRC="$PROJECT_ROOT/$dir"
  DST="$TARGET_DIR/$dir"
  if [[ -d "$SRC" ]]; then
    if ! $DRY_RUN; then
      cp -r "$SRC/." "$DST/"
    fi
    success "$dir/ → $DST/"
  else
    warn "$dir/ not found at $SRC — skipped"
  fi
done

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "  ✓ skill-writer installed for OpenAI"
echo ""
echo "  For OpenAI Agents SDK:"
echo "    Skill:    $SKILL_DST"
echo "    AGENTS.md: $AGENTS_DST"
echo ""
echo "  For Custom GPT (manual setup):"
echo "    1. Go to platform.openai.com → My GPTs → Create a GPT → Configure"
echo "    2. In 'Instructions', paste the content of $SKILL_DST"
echo "    3. Add trigger phrases to 'Conversation starters'"
echo ""
