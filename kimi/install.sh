#!/usr/bin/env bash
# install.sh — Install skill-writer to Kimi (~/.config/kimi/)
#
# Usage:
#   ./kimi/install.sh              # install everything
#   ./kimi/install.sh --dry-run    # preview only, no changes
#
# Installs:
#   ~/.config/kimi/skills/skill-writer.md   ← main skill file
#   ~/.config/kimi/AGENTS.md                ← agent routing rules (merge)
#   ~/.config/kimi/refs/                    ← companion reference files
#   ~/.config/kimi/templates/               ← skill creation templates
#   ~/.config/kimi/eval/                    ← evaluation rubrics
#   ~/.config/kimi/optimize/                ← optimization strategies

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN=false

info()    { echo "  $*"; }
success() { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*" >&2; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

if $DRY_RUN; then
  info "[DRY RUN] No files will be written."
fi

KIMI_HOME="${HOME}/.config/kimi"
SKILLS_DIR="${KIMI_HOME}/skills"

# ── Create directories ────────────────────────────────────────────────────────
for dir in "$SKILLS_DIR" "$KIMI_HOME/refs" "$KIMI_HOME/templates" \
           "$KIMI_HOME/eval" "$KIMI_HOME/optimize"; do
  if ! $DRY_RUN; then
    mkdir -p "$dir"
  fi
  info "dir: $dir"
done

# ── Copy main skill file ──────────────────────────────────────────────────────
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

# ── Copy companion files (refs, templates, eval, optimize) ────────────────────
for dir in refs templates eval optimize; do
  SRC="$PROJECT_ROOT/$dir"
  DST="$KIMI_HOME/$dir"
  if [[ -d "$SRC" ]]; then
    if ! $DRY_RUN; then
      cp -r "$SRC/." "$DST/"
    fi
    success "$dir/ → $DST/"
  else
    warn "$dir/ not found at $SRC — skipped"
  fi
done

# ── Merge AGENTS.md (routing rules) ──────────────────────────────────────────
AGENTS_MD="$KIMI_HOME/AGENTS.md"
AGENTS_MD_SRC="$SCRIPT_DIR/AGENTS.md"
BLOCK_START="<!-- skill-writer:start -->"
BLOCK_END="<!-- skill-writer:end -->"

if [[ -f "$AGENTS_MD" ]] && grep -q "$BLOCK_START" "$AGENTS_MD"; then
  # Replace existing block (idempotent update)
  if ! $DRY_RUN; then
    python3 -c "
import re, sys
with open('$AGENTS_MD', 'r') as f: content = f.read()
with open('$AGENTS_MD_SRC', 'r') as f: block = f.read().strip()
pattern = r'<!-- skill-writer:start -->.*?<!-- skill-writer:end -->'
new = re.sub(pattern, block, content, flags=re.DOTALL)
with open('$AGENTS_MD', 'w') as f: f.write(new)
"
  fi
  success "AGENTS.md → updated skill-writer block"
else
  # Append block
  if ! $DRY_RUN; then
    echo "" >> "$AGENTS_MD"
    cat "$AGENTS_MD_SRC" >> "$AGENTS_MD"
  fi
  success "AGENTS.md → appended skill-writer block"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "  ✓ skill-writer installed to Kimi"
echo ""
echo "  Paths:"
echo "    Skill:      $SKILL_DST"
echo "    Refs:       $KIMI_HOME/refs/"
echo "    Templates:  $KIMI_HOME/templates/"
echo "    Eval:       $KIMI_HOME/eval/"
echo "    Optimize:   $KIMI_HOME/optimize/"
echo "    AGENTS.md:  $AGENTS_MD"
echo ""
echo "  Next: Restart Kimi, then type 'create a skill' to test."
echo ""
