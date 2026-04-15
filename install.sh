#!/usr/bin/env bash
# install.sh — Install skill-writer to AI platforms.
#
# Usage:
#   ./install.sh                          # auto-detect installed platforms
#   ./install.sh --platform claude        # Claude only
#   ./install.sh --platform openclaw      # OpenClaw only
#   ./install.sh --platform opencode      # OpenCode only
#   ./install.sh --platform cursor        # Cursor (project-level .cursor/rules/)
#   ./install.sh --platform cursor --global  # Cursor user-level ~/.cursor/rules/
#   ./install.sh --platform gemini        # Gemini (~/.gemini/)
#   ./install.sh --platform openai [DIR]  # OpenAI Agents SDK (project dir)
#   ./install.sh --platform kimi          # Kimi / Moonshot AI (~/.config/kimi/)
#   ./install.sh --platform hermes        # Hermes (~/.hermes/)
#   ./install.sh --all                    # all 8 platforms
#   ./install.sh --dry-run                # preview only, no changes
#
# Supported platforms: claude, openclaw, opencode, cursor, gemini, openai, kimi, hermes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM=""
INSTALL_ALL=false
DRY_RUN=false
EXTRA_ARGS=()

info()    { echo "  $*"; }
success() { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*" >&2; }
err()     { echo "  ✗ $*" >&2; }

# ── Parse arguments ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform|-p)
      PLATFORM="${2:?--platform requires a value}"
      shift 2 ;;
    --all|-a)
      INSTALL_ALL=true
      shift ;;
    --dry-run)
      DRY_RUN=true
      EXTRA_ARGS+=(--dry-run)
      shift ;;
    --global)
      EXTRA_ARGS+=(--global)
      shift ;;
    -h|--help)
      awk '/^[^#]/{exit} /^# /{sub(/^# /,""); print}' "$0"
      exit 0 ;;
    *)
      # Pass unknown args to platform scripts (e.g. TARGET_DIR for openai)
      EXTRA_ARGS+=("$1")
      shift ;;
  esac
done

# ── Platform detection ────────────────────────────────────────────────────────

detect_platforms() {
  local detected=()
  [[ -d "${HOME}/.claude" ]]               && detected+=(claude)
  [[ -d "${HOME}/.openclaw" ]]             && detected+=(openclaw)
  [[ -d "${HOME}/.config/opencode" ]]      && detected+=(opencode)
  [[ -d "${HOME}/.cursor" ]]               && detected+=(cursor)
  [[ -d "${HOME}/.gemini" ]]               && detected+=(gemini)
  [[ -d "${HOME}/.config/kimi" ]]          && detected+=(kimi)
  [[ -d "${HOME}/.hermes" ]]               && detected+=(hermes)
  # OpenAI: no standard home dir to detect; skipped in auto-detect
  echo "${detected[@]:-}"
}

# Determine target platform list
declare -a TARGETS
if [[ "${INSTALL_ALL}" == "true" ]]; then
  TARGETS=(claude openclaw opencode cursor gemini openai kimi hermes)
elif [[ -n "${PLATFORM}" ]]; then
  TARGETS=("${PLATFORM}")
else
  TARGETS=()
  while IFS= read -r _line; do
    [[ -n "${_line}" ]] && TARGETS+=("${_line}")
  done < <(detect_platforms | tr ' ' '\n')
  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    info "No AI platforms detected. Defaulting to Claude."
    TARGETS=(claude)
  fi
fi

# ── Main ──────────────────────────────────────────────────────────────────────

echo ""
echo "skill-writer installer"
echo "──────────────────────"
info "Targets: ${TARGETS[*]}"
if $DRY_RUN; then
  info "[DRY RUN] No files will be written."
fi
echo ""

INSTALLED=0
FAILED=0

for p in "${TARGETS[@]}"; do
  PLATFORM_SCRIPT="${SCRIPT_DIR}/${p}/install.sh"
  if [[ ! -f "${PLATFORM_SCRIPT}" ]]; then
    err "Unknown platform '${p}' — no installer found at ${PLATFORM_SCRIPT}"
    FAILED=$((FAILED + 1))
    continue
  fi

  echo "── Installing to ${p} ──────────────────────────────────────────────────────"
  if bash "${PLATFORM_SCRIPT}" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"; then
    INSTALLED=$((INSTALLED + 1))
  else
    warn "${p} install reported errors — continuing"
    FAILED=$((FAILED + 1))
  fi
done

echo "──────────────────────"
if [[ ${FAILED} -eq 0 ]]; then
  success "Installed to ${INSTALLED} platform(s)."
else
  warn "Installed to ${INSTALLED} platform(s). ${FAILED} had errors — see warnings above."
fi
echo ""

# ── UTE Cross-Session Hooks (Claude only) ─────────────────────────────────────
# UTE L1 in-session feedback detection works on all platforms without any setup.
# UTE L1 cross-session tracking (persistent invocation counts + cadence gates)
# requires Claude Code hooks. This section offers to install them.

if [[ " ${TARGETS[*]} " =~ " claude " ]] && [[ "${DRY_RUN}" != "true" ]]; then
  CLAUDE_HOOKS_DIR="${HOME}/.claude/hooks"
  CLAUDE_SKILLS_UTE_DIR="${HOME}/.claude/skills/.ute-state"
  UTE_TRACKER="${CLAUDE_HOOKS_DIR}/ute-tracker.js"

  echo "── UTE Cross-Session Hooks (Claude) ────────────────────────────────────────"
  echo ""
  echo "  UTE L1 (in-session feedback detection) is ACTIVE by default — no setup needed."
  echo "  UTE L1 cross-session tracking (persistent invocation counts, cadence gates,"
  echo "  and audit trail) requires Claude Code hooks. This is OPTIONAL."
  echo ""
  echo "  With hooks enabled:"
  echo "    - cumulative_invocations counter persists across sessions"
  echo "    - Cadence checks fire at exactly 10/50/100 invocations (not approximate)"
  echo "    - Audit trail written to ~/.claude/.skill-audit/sessions.jsonl"
  echo ""

  if [[ -t 0 ]]; then
    # Interactive terminal: ask user
    read -r -p "  Enable UTE cross-session hooks for Claude? [y/N]: " ENABLE_UTE_HOOKS
  else
    # Non-interactive (piped install): skip hooks
    ENABLE_UTE_HOOKS="N"
  fi

  if [[ "${ENABLE_UTE_HOOKS,,}" == "y" ]]; then
    # Install ute-tracker.js
    mkdir -p "${CLAUDE_HOOKS_DIR}" "${CLAUDE_SKILLS_UTE_DIR}"
    cp "${SCRIPT_DIR}/claude/hooks/ute-tracker.js" "${UTE_TRACKER}" 2>/dev/null || {
      # Inline the tracker if the source file doesn't exist yet
      cat > "${UTE_TRACKER}" << 'TRACKER_EOF'
#!/usr/bin/env node
// UTE state persistence hook for Claude Code (installed by skill-writer install.sh)
// See: refs/use-to-evolve.md §8 for full specification.

const fs = require('fs');
const path = require('path');

const STATE_DIR = path.join(process.env.HOME, '.claude', 'skills', '.ute-state');
const AUDIT_DIR = path.join(process.env.HOME, '.claude', '.skill-audit');
const cmd        = process.argv[2];        // 'post-use' | 'session-end'
const skillName  = process.argv[3] || '';  // skill identifier

function readState(name) {
  const file = path.join(STATE_DIR, `${name}.json`);
  if (!fs.existsSync(file)) return { cumulative_invocations: 0, session_log: [] };
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function writeState(name, state) {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(path.join(STATE_DIR, `${name}.json`), JSON.stringify(state, null, 2));
}

if (cmd === 'post-use' && skillName) {
  const state = readState(skillName);
  state.cumulative_invocations = (state.cumulative_invocations || 0) + 1;
  const inv = state.cumulative_invocations;
  if (!state.session_log) state.session_log = [];
  if (inv % 10  === 0) state.session_log.push({ at: new Date().toISOString(), event: 'lightweight_check_due',    inv });
  if (inv % 50  === 0) state.session_log.push({ at: new Date().toISOString(), event: 'quality_assessment_due',   inv });
  if (inv % 100 === 0) state.session_log.push({ at: new Date().toISOString(), event: 'tier_drift_check_due',      inv });
  state.last_updated = new Date().toISOString();
  writeState(skillName, state);
}

if (cmd === 'session-end') {
  fs.mkdirSync(AUDIT_DIR, { recursive: true });
  const entry = { session_end: new Date().toISOString(), skill: skillName || 'unknown' };
  fs.appendFileSync(path.join(AUDIT_DIR, 'sessions.jsonl'), JSON.stringify(entry) + '\n');
}
TRACKER_EOF
    }
    chmod +x "${UTE_TRACKER}"

    # Merge hooks into ~/.claude/settings.json
    SETTINGS_FILE="${HOME}/.claude/settings.json"
    if [[ -f "${SETTINGS_FILE}" ]]; then
      # Check if PostToolUse hook already present
      if grep -q "ute-tracker" "${SETTINGS_FILE}" 2>/dev/null; then
        info "UTE hooks already present in settings.json — skipping merge."
      else
        # Insert hooks using Node.js (available if Claude Code is installed)
        node - "${SETTINGS_FILE}" "${UTE_TRACKER}" << 'MERGE_EOF' 2>/dev/null && \
          success "Merged UTE hooks into ~/.claude/settings.json" || \
          warn    "Could not auto-merge settings.json. Add hooks manually — see refs/use-to-evolve.md §8."
const fs = require('fs');
const [,, settingsPath, trackerPath] = process.argv;
const s = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
if (!s.hooks) s.hooks = {};
if (!s.hooks.PostToolUse) s.hooks.PostToolUse = [];
if (!s.hooks.Stop) s.hooks.Stop = [];
const trackerPostUse = { matcher: 'Bash', hooks: [{ type: 'command', command: `node ${trackerPath} post-use "$CLAUDE_SKILL_NAME"` }] };
const trackerStop    = { hooks: [{ type: 'command', command: `node ${trackerPath} session-end` }] };
if (!s.hooks.PostToolUse.some(h => JSON.stringify(h).includes('ute-tracker'))) s.hooks.PostToolUse.push(trackerPostUse);
if (!s.hooks.Stop.some(h => JSON.stringify(h).includes('ute-tracker'))) s.hooks.Stop.push(trackerStop);
fs.writeFileSync(settingsPath, JSON.stringify(s, null, 2));
MERGE_EOF
      fi
    else
      # Create minimal settings.json with hooks
      cat > "${SETTINGS_FILE}" << SETTINGS_EOF
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "node ${UTE_TRACKER} post-use \"\$CLAUDE_SKILL_NAME\"" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "node ${UTE_TRACKER} session-end" }
        ]
      }
    ]
  }
}
SETTINGS_EOF
      success "Created ~/.claude/settings.json with UTE hooks."
    fi

    success "UTE cross-session tracking enabled."
    echo "    State files: ${CLAUDE_SKILLS_UTE_DIR}/<skill-name>.json"
    echo "    Audit trail: ~/.claude/.skill-audit/sessions.jsonl"
    echo "    Restart Claude Code to activate hooks."
  else
    info "Skipped UTE hooks. UTE L1 in-session detection still active."
    info "To enable later: see refs/use-to-evolve.md §8"
  fi
  echo ""
fi

echo "Quick reference: create a skill | lean eval | evaluate | optimize | graph view"
echo "  (or: 创建技能 | 快评 | 评测 | 优化 | 技能图)"
echo ""
