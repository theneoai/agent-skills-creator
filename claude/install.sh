#!/usr/bin/env bash
# install.sh — Install skill-writer to Claude (~/.claude/)
#
# Usage:
#   ./claude/install.sh              # install everything
#   ./claude/install.sh --dry-run    # preview only, no changes
#
# Installs:
#   ~/.claude/skills/skill-writer.md   ← main skill file
#   ~/.claude/CLAUDE.md                ← agent routing rules (merge)
#   ~/.claude/refs/                    ← companion reference files
#   ~/.claude/templates/               ← skill creation templates
#   ~/.claude/eval/                    ← evaluation rubrics
#   ~/.claude/optimize/                ← optimization strategies
#   ~/.claude/settings.json            ← Hook config (merge)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN=false

# Colors
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

CLAUDE_HOME="${HOME}/.claude"
SKILLS_DIR="${CLAUDE_HOME}/skills"

# ── Create directories ────────────────────────────────────────────────────────
for dir in "$SKILLS_DIR" "$CLAUDE_HOME/refs" "$CLAUDE_HOME/templates" \
           "$CLAUDE_HOME/eval" "$CLAUDE_HOME/optimize"; do
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
  DST="$CLAUDE_HOME/$dir"
  if [[ -d "$SRC" ]]; then
    if ! $DRY_RUN; then
      cp -r "$SRC/." "$DST/"
    fi
    success "$dir/ → $DST/"
  else
    warn "$dir/ not found at $SRC — skipped"
  fi
done

# ── Merge CLAUDE.md (routing rules) ──────────────────────────────────────────
CLAUDE_MD="$CLAUDE_HOME/CLAUDE.md"
CLAUDE_MD_SRC="$SCRIPT_DIR/CLAUDE.md"
BLOCK_START="<!-- skill-writer:start -->"
BLOCK_END="<!-- skill-writer:end -->"

if [[ -f "$CLAUDE_MD" ]] && grep -q "$BLOCK_START" "$CLAUDE_MD"; then
  # Replace existing block (idempotent update)
  if ! $DRY_RUN; then
    python3 -c "
import re, sys
with open('$CLAUDE_MD', 'r') as f: content = f.read()
with open('$CLAUDE_MD_SRC', 'r') as f: block = f.read().strip()
pattern = r'<!-- skill-writer:start -->.*?<!-- skill-writer:end -->'
new = re.sub(pattern, block, content, flags=re.DOTALL)
with open('$CLAUDE_MD', 'w') as f: f.write(new)
"
  fi
  success "CLAUDE.md → updated skill-writer block"
else
  # Append block
  if ! $DRY_RUN; then
    echo "" >> "$CLAUDE_MD"
    cat "$CLAUDE_MD_SRC" >> "$CLAUDE_MD"
  fi
  success "CLAUDE.md → appended skill-writer block"
fi

# ── Merge settings.json (UserPromptSubmit Hook) ───────────────────────────────
SETTINGS="$CLAUDE_HOME/settings.json"
HOOK_CMD="echo '[skill-writer] Check installed skills before creating new ones: type /share to search.'"

if [[ -f "$SETTINGS" ]]; then
  # Check if hook already present
  if grep -q "skill-writer" "$SETTINGS" 2>/dev/null; then
    info "settings.json: skill-writer hook already present — skipped"
  else
    warn "settings.json exists — add UserPromptSubmit hook manually if needed"
    info "Hook command: $HOOK_CMD"
  fi
else
  # Create minimal settings.json with hook
  if ! $DRY_RUN; then
    cat > "$SETTINGS" <<'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[skill-writer] Check installed skills before creating new ones: type /share to search.'"
          }
        ]
      }
    ]
  }
}
EOF
  fi
  success "settings.json → created with UserPromptSubmit hook"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "  ✓ skill-writer installed to Claude"
echo ""
echo "  Paths:"
echo "    Skill:      $SKILL_DST"
echo "    Refs:       $CLAUDE_HOME/refs/"
echo "    Templates:  $CLAUDE_HOME/templates/"
echo "    Eval:       $CLAUDE_HOME/eval/"
echo "    Optimize:   $CLAUDE_HOME/optimize/"
echo "    CLAUDE.md:  $CLAUDE_MD"
echo ""
echo "  Next: Restart Claude Code, then type 'create a skill' to test."
echo ""
