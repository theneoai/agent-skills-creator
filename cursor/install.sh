#!/usr/bin/env bash
# install.sh — Install skill-writer to Cursor (.cursor/rules/)
#
# Usage:
#   ./cursor/install.sh              # install to project-level .cursor/rules/ (default)
#   ./cursor/install.sh --global     # install to ~/.cursor/rules/ (user-level, Cursor 0.43+)
#   ./cursor/install.sh --dry-run    # preview only, no changes
#
# Installs:
#   .cursor/rules/skill-writer.mdc   ← Cursor rule file (alwaysApply: true)
#   .cursor/refs/                    ← companion reference files
#   .cursor/templates/               ← skill creation templates
#   .cursor/eval/                    ← evaluation rubrics
#   .cursor/optimize/                ← optimization strategies

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN=false
GLOBAL=false

info()    { echo "  $*"; }
success() { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*" >&2; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --global)  GLOBAL=true ;;
  esac
done

if $DRY_RUN; then
  info "[DRY RUN] No files will be written."
fi

if $GLOBAL; then
  CURSOR_HOME="${HOME}/.cursor"
  info "Installing to user-level ~/.cursor/rules/ (requires Cursor 0.43+)"
else
  CURSOR_HOME="$(pwd)/.cursor"
  info "Installing to project-level .cursor/rules/"
fi

RULES_DIR="${CURSOR_HOME}/rules"

# ── Create directories ──────────────────────────────────────────────────────
for dir in "$RULES_DIR" "$CURSOR_HOME/refs" "$CURSOR_HOME/templates" \
           "$CURSOR_HOME/eval" "$CURSOR_HOME/optimize"; do
  if ! $DRY_RUN; then
    mkdir -p "$dir"
  fi
  info "dir: $dir"
done

# ── Copy skill rule file ────────────────────────────────────────────────────
SKILL_SRC="$SCRIPT_DIR/skill-writer.mdc"
SKILL_DST="$RULES_DIR/skill-writer.mdc"

if [[ -f "$SKILL_DST" ]]; then
  if ! $DRY_RUN; then
    cp "$SKILL_DST" "${SKILL_DST}.bak.$(date +%Y%m%d_%H%M%S)"
  fi
  info "Backed up existing rule file"
fi

if ! $DRY_RUN; then
  cp "$SKILL_SRC" "$SKILL_DST"
fi
success "skill-writer.mdc → $SKILL_DST"

# ── Copy companion files ────────────────────────────────────────────────────
for dir in refs templates eval optimize; do
  SRC="$PROJECT_ROOT/$dir"
  DST="$CURSOR_HOME/$dir"
  if [[ -d "$SRC" ]]; then
    if ! $DRY_RUN; then
      cp -r "$SRC/." "$DST/"
    fi
    success "$dir/ → $DST/"
  else
    warn "$dir/ not found at $SRC — skipped"
  fi
done

# ── Done ──────────────────────────────────────────────────────────────────
echo ""
echo "  ✓ skill-writer installed to Cursor"
echo ""
if $GLOBAL; then
  echo "  Paths:"
  echo "    Rule:      $SKILL_DST"
  echo "    Refs:      $CURSOR_HOME/refs/"
else
  echo "  Paths (project-local):"
  echo "    Rule:      $SKILL_DST"
  echo "    Refs:      $CURSOR_HOME/refs/"
fi
echo ""
echo "  Next: Restart Cursor, then use keyword phrases:"
echo "    'create a skill that ...' (not /create)"
echo "    'lean eval'  'evaluate this skill'  'optimize this skill'"
echo ""
