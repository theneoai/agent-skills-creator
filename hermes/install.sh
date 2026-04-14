#!/usr/bin/env bash
# install.sh — Install skill-writer to Hermes (~/.hermes/)
#
# Usage:
#   ./hermes/install.sh              # install everything
#   ./hermes/install.sh --dry-run    # preview only, no changes
#
# Installs:
#   ~/.hermes/skills/skill-writer.md   ← main skill file
#   ~/.hermes/AGENTS.md                ← agent routing rules (merge)
#   ~/.hermes/refs/                    ← companion reference files
#   ~/.hermes/templates/               ← skill creation templates
#   ~/.hermes/eval/                    ← evaluation rubrics
#   ~/.hermes/optimize/                ← optimization strategies

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

HERMES_HOME="${HOME}/.hermes"
SKILLS_DIR="${HERMES_HOME}/skills"

# ── Create directories ────────────────────────────────────────────────────────
for dir in "$SKILLS_DIR" "$HERMES_HOME/refs" "$HERMES_HOME/templates" \
           "$HERMES_HOME/eval" "$HERMES_HOME/optimize"; do
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
  DST="$HERMES_HOME/$dir"
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
AGENTS_MD="$HERMES_HOME/AGENTS.md"
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
echo "  ✓ skill-writer installed to Hermes"
echo ""
echo "  Paths:"
echo "    Skill:      $SKILL_DST"
echo "    Refs:       $HERMES_HOME/refs/"
echo "    Templates:  $HERMES_HOME/templates/"
echo "    Eval:       $HERMES_HOME/eval/"
echo "    Optimize:   $HERMES_HOME/optimize/"
echo "    AGENTS.md:  $AGENTS_MD"
echo ""
echo "  Next: Restart Hermes, then type 'create a skill' to test."
echo ""
