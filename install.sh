#!/usr/bin/env bash
# install.sh — Install skill-writer to AI platforms.
#
# Usage:
#   ./install.sh                         # auto-detect installed platforms
#   ./install.sh --platform claude       # Claude only
#   ./install.sh --platform openclaw     # OpenClaw only
#   ./install.sh --platform opencode     # OpenCode only
#   ./install.sh --all                   # all three platforms
#   ./install.sh --dry-run               # preview only, no changes
#
# Supported platforms: claude, openclaw, opencode

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM=""
INSTALL_ALL=false
DRY_RUN=false

info()    { echo "  $*"; }
success() { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*" >&2; }
err()     { echo "  ✗ $*" >&2; }

# ── Parse arguments ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform|-p)
      PLATFORM="${2:?--platform requires a value (claude|openclaw|opencode)}"
      shift 2 ;;
    --all|-a)
      INSTALL_ALL=true
      shift ;;
    --dry-run)
      DRY_RUN=true
      shift ;;
    -h|--help)
      grep '^#' "$0" | head -15 | sed 's/^# \?//'
      exit 0 ;;
    *)
      err "Unknown option: $1"
      exit 1 ;;
  esac
done

# ── Platform detection ────────────────────────────────────────────────────────

detect_platforms() {
  local detected=()
  [[ -d "${HOME}/.claude" ]]               && detected+=(claude)
  [[ -d "${HOME}/.openclaw" ]]             && detected+=(openclaw)
  [[ -d "${HOME}/.config/opencode" ]]      && detected+=(opencode)
  echo "${detected[@]:-}"
}

# Determine target platform list
declare -a TARGETS
if [[ "${INSTALL_ALL}" == "true" ]]; then
  TARGETS=(claude openclaw opencode)
elif [[ -n "${PLATFORM}" ]]; then
  TARGETS=("${PLATFORM}")
else
  # Auto-detect: install only to platforms that appear to be set up
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

  echo "── Installing to ${p} ───────────────────────────────────────────────────────"
  if $DRY_RUN; then
    bash "${PLATFORM_SCRIPT}" --dry-run
  else
    bash "${PLATFORM_SCRIPT}"
  fi
  INSTALLED=$((INSTALLED + 1))
done

echo "──────────────────────"
if [[ ${FAILED} -eq 0 ]]; then
  success "Installed to ${INSTALLED} platform(s)."
else
  warn "Installed to ${INSTALLED} platform(s). ${FAILED} failed — see warnings above."
fi
echo ""
echo "Quick reference: create a skill | lean eval | evaluate | optimize | graph view"
echo "  (or: 创建技能 | 快评 | 评测 | 优化 | 技能图)"
echo ""
