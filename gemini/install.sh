#!/usr/bin/env bash
# install.sh — Install skill-writer to Gemini (~/.gemini/)
#
# Usage:
#   ./gemini/install.sh              # install everything
#   ./gemini/install.sh --dry-run    # preview only, no changes
#
# Installs:
#   ~/.gemini/skills/skill-writer.md   ← main skill file
#   ~/.gemini/GEMINI.md                ← agent routing rules (merge)
#   ~/.gemini/refs/                    ← companion reference files
#   ~/.gemini/templates/               ← skill creation templates
#   ~/.gemini/eval/                    ← evaluation rubrics
#   ~/.gemini/optimize/                ← optimization strategies

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

GEMINI_HOME="${HOME}/.gemini"
SKILLS_DIR="${GEMINI_HOME}/skills"

# ── Create directories ──────────────────────────────────────────────────────
for dir in "$SKILLS_DIR" "$GEMINI_HOME/refs" "$GEMINI_HOME/templates" \
           "$GEMINI_HOME/eval" "$GEMINI_HOME/optimize"; do
  if ! $DRY_RUN; then
    mkdir -p "$dir"
  fi
  info "dir: $dir"
done

# ── Copy main skill file ────────────────────────────────────────────────────
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

# ── Copy companion files ────────────────────────────────────────────────────
for dir in refs templates eval optimize; do
  SRC="$PROJECT_ROOT/$dir"
  DST="$GEMINI_HOME/$dir"
  if [[ -d "$SRC" ]]; then
    if ! $DRY_RUN; then
      cp -r "$SRC/." "$DST/"
    fi
    success "$dir/ → $DST/"
  else
    warn "$dir/ not found at $SRC — skipped"
  fi
done

# ── Merge GEMINI.md (routing rules) ────────────────────────────────────────
GEMINI_MD="$GEMINI_HOME/GEMINI.md"
GEMINI_MD_SRC="$SCRIPT_DIR/GEMINI.md"
BLOCK_START="<!-- skill-writer:start -->"

if [[ -f "$GEMINI_MD" ]] && grep -q "$BLOCK_START" "$GEMINI_MD"; then
  if ! $DRY_RUN; then
    python3 -c "
import re
with open('$GEMINI_MD', 'r') as f: content = f.read()
with open('$GEMINI_MD_SRC', 'r') as f: block = f.read().strip()
pattern = r'<!-- skill-writer:start -->.*?<!-- skill-writer:end -->'
new = re.sub(pattern, block, content, flags=re.DOTALL)
with open('$GEMINI_MD', 'w') as f: f.write(new)
"
  fi
  success "GEMINI.md → updated skill-writer block"
else
  if ! $DRY_RUN; then
    echo "" >> "$GEMINI_MD"
    cat "$GEMINI_MD_SRC" >> "$GEMINI_MD"
  fi
  success "GEMINI.md → appended skill-writer block"
fi

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "  ✓ skill-writer installed to Gemini"
echo ""
echo "  Paths:"
echo "    Skill:      $SKILL_DST"
echo "    Refs:       $GEMINI_HOME/refs/"
echo "    Templates:  $GEMINI_HOME/templates/"
echo "    GEMINI.md:  $GEMINI_MD"
echo ""
echo "  Next: Restart Gemini, then type 'create a skill' to test."
echo ""
