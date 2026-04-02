#!/usr/bin/env bash
# install.sh — Install skill-writer to one or all supported platforms.
#
# Usage:
#   ./install.sh                          # install to all detected platforms
#   ./install.sh --platform claude        # install to Claude only
#   ./install.sh --platform all           # install to all platforms (explicit)
#   ./install.sh --url <URL>              # download skill-framework.md from URL first
#   ./install.sh --platform cursor --url <URL>
#
# Supported platforms: claude, opencode, openclaw, cursor, gemini, openai (info only)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="${SCRIPT_DIR}/skill-framework.md"
PLATFORM="all"
FETCH_URL=""

# ── Parse arguments ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      PLATFORM="${2:?--platform requires a value}"
      shift 2
      ;;
    --url)
      FETCH_URL="${2:?--url requires a value}"
      shift 2
      ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ── Download from URL if requested ───────────────────────────────────────────
if [[ -n "${FETCH_URL}" ]]; then
  TMP_FILE="$(mktemp /tmp/skill-writer-XXXXXX.md)"
  trap 'rm -f "${TMP_FILE}"' EXIT

  echo "Fetching ${FETCH_URL} ..."
  if command -v curl &>/dev/null; then
    curl -fsSL "${FETCH_URL}" -o "${TMP_FILE}"
  elif command -v wget &>/dev/null; then
    wget -qO "${TMP_FILE}" "${FETCH_URL}"
  else
    echo "Error: curl or wget is required to fetch a URL." >&2
    exit 1
  fi

  # Verify this looks like skill-writer
  if ! grep -q 'name: skill-writer' "${TMP_FILE}"; then
    echo "Error: fetched file does not appear to be skill-writer (missing 'name: skill-writer' in YAML)." >&2
    exit 1
  fi

  SKILL_FILE="${TMP_FILE}"
  echo "  ✓ Downloaded to ${TMP_FILE}"
fi

if [[ ! -f "${SKILL_FILE}" ]]; then
  echo "Error: skill file not found: ${SKILL_FILE}" >&2
  exit 1
fi

# ── Platform install function ─────────────────────────────────────────────────
install_to() {
  local name="$1"
  local dest_dir="$2"
  local dest_file="${dest_dir}/skill-writer.md"

  mkdir -p "${dest_dir}"
  cp "${SKILL_FILE}" "${dest_file}"
  echo "  ✓ [${name}] ${dest_file}"
}

echo "Installing skill-writer ..."
echo ""

INSTALLED=0

install_platform() {
  local p="$1"
  case "${p}" in
    claude)
      install_to "claude"   "${HOME}/.claude/skills"
      # Claude also gets companion reference files from local clone
      if [[ "${SKILL_FILE}" != /tmp/skill-writer-* ]]; then
        local claude_dir="${HOME}/.claude"
        for sub in refs templates eval optimize; do
          if [[ -d "${SCRIPT_DIR}/${sub}" ]]; then
            mkdir -p "${claude_dir}/${sub}"
            cp "${SCRIPT_DIR}/${sub}/"*.md "${claude_dir}/${sub}/" 2>/dev/null || true
          fi
        done
        echo "  ✓ [claude] companion files → ${HOME}/.claude/{refs,templates,eval,optimize}/"
      fi
      ;;
    opencode)
      install_to "opencode" "${HOME}/.config/opencode/skills"
      ;;
    openclaw)
      install_to "openclaw" "${HOME}/.openclaw/skills"
      ;;
    cursor)
      install_to "cursor"   "${HOME}/.cursor/skills"
      ;;
    gemini)
      install_to "gemini"   "${HOME}/.gemini/skills"
      ;;
    openai)
      echo "  ℹ [openai] OpenAI platform requires manual installation via platform settings."
      return 0
      ;;
    *)
      echo "  ! Unknown platform: ${p}" >&2
      return 1
      ;;
  esac
  INSTALLED=$((INSTALLED + 1))
}

if [[ "${PLATFORM}" == "all" ]]; then
  for p in claude opencode openclaw cursor gemini; do
    install_platform "${p}"
  done
else
  install_platform "${PLATFORM}"
fi

echo ""
echo "Installation complete (${INSTALLED} platform(s))."
echo "Restart each platform to activate skill-writer."
