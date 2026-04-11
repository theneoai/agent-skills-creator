#!/usr/bin/env bash
# install.sh — Install skill-writer to AI platforms.
#
# Works as both a local installer and a no-clone curl one-liner:
#
#   One-liner (no git clone needed):
#     curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/install.sh | bash
#
#   Local (from cloned repo):
#     ./install.sh                    # auto-detect installed platforms
#     ./install.sh --platform claude  # specific platform only
#     ./install.sh --all              # every supported platform
#     ./install.sh --url <URL>        # use a custom skill-framework URL
#
# Supported platforms: claude, opencode, openclaw, cursor, gemini, mcp
# (openai requires manual setup via platform dashboard)

set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────

GITHUB_RAW="https://raw.githubusercontent.com/theneoai/skill-writer/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-install.sh}")" 2>/dev/null && pwd || echo "${PWD}")"
PLATFORMS_DIR="${SCRIPT_DIR}/platforms"

PLATFORM=""        # empty = auto-detect
INSTALL_ALL=false
FETCH_URL=""
VERBOSE=false

# ── Helpers ───────────────────────────────────────────────────────────────────

info()    { echo "  $*"; }
success() { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*" >&2; }
err()     { echo "  ✗ $*" >&2; }

fetch() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "${url}" -o "${dest}"
  elif command -v wget &>/dev/null; then
    wget -qO "${dest}" "${url}"
  else
    err "curl or wget is required but neither was found."
    exit 1
  fi
}

# Resolve the best available source file for a given platform.
# Priority: local release build → local dev build → GitHub release → skill-framework.md
# Prints the resolved file path to stdout.
resolve_source() {
  local platform="$1"
  local ext="${2:-md}"

  # 1. Local release build (no -dev suffix — highest quality, built without debug flags)
  local local_release="${PLATFORMS_DIR}/skill-writer-${platform}.${ext}"
  if [[ -f "${local_release}" ]]; then
    echo "${local_release}"
    return
  fi

  # 2. Local dev build (also valid, slightly larger debug output)
  local local_dev="${PLATFORMS_DIR}/skill-writer-${platform}-dev.${ext}"
  if [[ -f "${local_dev}" ]]; then
    echo "${local_dev}"
    return
  fi

  # 2. Local skill-framework.md (only meaningful for Markdown platforms)
  if [[ "${ext}" == "md" && -f "${SCRIPT_DIR}/skill-framework.md" ]]; then
    echo "${SCRIPT_DIR}/skill-framework.md"
    return
  fi

  # 3. Fetch from GitHub (try release first, then dev)
  local tmp
  tmp="$(mktemp /tmp/skill-writer-XXXXXX.${ext})"
  # shellcheck disable=SC2064
  trap "rm -f '${tmp}'" EXIT

  for suffix in "" "-dev"; do
    local github_url="${GITHUB_RAW}/platforms/skill-writer-${platform}${suffix}.${ext}"
    if [[ "${VERBOSE}" == "true" ]]; then
      info "Fetching ${github_url} ..."
    fi
    if fetch "${github_url}" "${tmp}" 2>/dev/null && [[ -s "${tmp}" ]]; then
      echo "${tmp}"
      return
    fi
  done

  # 4. For markdown, fall back to raw skill-framework.md from GitHub
  if [[ "${ext}" == "md" ]]; then
    local fw_url="${GITHUB_RAW}/skill-framework.md"
    if [[ "${VERBOSE}" == "true" ]]; then
      info "Falling back to ${fw_url} ..."
    fi
    fetch "${fw_url}" "${tmp}"
    echo "${tmp}"
    return
  fi

  err "Could not find source file for platform '${platform}'."
  exit 1
}

# ── Parse arguments ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform|-p)
      PLATFORM="${2:?--platform requires a value}"
      shift 2 ;;
    --all|-a)
      INSTALL_ALL=true
      shift ;;
    --url|-u)
      FETCH_URL="${2:?--url requires a value}"
      shift 2 ;;
    --verbose|-v)
      VERBOSE=true
      shift ;;
    -h|--help)
      grep '^#' "$0" | head -20 | sed 's/^# \?//'
      exit 0 ;;
    *)
      err "Unknown option: $1"
      exit 1 ;;
  esac
done

# ── Handle --url (override source for Markdown platforms) ────────────────────

CUSTOM_FILE=""
if [[ -n "${FETCH_URL}" ]]; then
  CUSTOM_FILE="$(mktemp /tmp/skill-writer-custom-XXXXXX.md)"
  trap "rm -f '${CUSTOM_FILE}'" EXIT
  info "Fetching ${FETCH_URL} ..."
  fetch "${FETCH_URL}" "${CUSTOM_FILE}"
  if ! grep -q 'name: skill-writer' "${CUSTOM_FILE}" 2>/dev/null; then
    err "Fetched file does not appear to be skill-writer (missing 'name: skill-writer')."
    exit 1
  fi
  success "Downloaded and verified."
fi

# ── Platform detection ────────────────────────────────────────────────────────

detect_platforms() {
  local detected=()
  [[ -d "${HOME}/.claude" ]]               && detected+=(claude)
  [[ -d "${HOME}/.config/opencode" ]]      && detected+=(opencode)
  [[ -d "${HOME}/.openclaw" ]]             && detected+=(openclaw)
  [[ -d "${HOME}/.cursor" ]]               && detected+=(cursor)
  [[ -d "${HOME}/.gemini" ]]               && detected+=(gemini)
  [[ -d "${HOME}/.mcp" ]]                  && detected+=(mcp)
  echo "${detected[@]:-}"
}

# Determine target platform list
declare -a TARGETS
if [[ "${INSTALL_ALL}" == "true" ]]; then
  TARGETS=(claude opencode openclaw cursor gemini mcp)
elif [[ -n "${PLATFORM}" ]]; then
  TARGETS=("${PLATFORM}")
else
  # Auto-detect: install only to platforms that appear to be set up.
  # Use a while-read loop instead of mapfile for bash 3.x compatibility (macOS default).
  TARGETS=()
  while IFS= read -r _line; do
    [[ -n "${_line}" ]] && TARGETS+=("${_line}")
  done < <(detect_platforms | tr ' ' '\n')
  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    info "No AI platforms detected. Defaulting to Claude."
    TARGETS=(claude)
  fi
fi

# ── Install functions ─────────────────────────────────────────────────────────

INSTALLED=0
FAILED=0

install_claude() {
  local src
  src="${CUSTOM_FILE:-$(resolve_source claude md)}"
  local dest_dir="${HOME}/.claude/skills"
  mkdir -p "${dest_dir}"
  cp "${src}" "${dest_dir}/skill-writer.md"
  success "[claude] ${dest_dir}/skill-writer.md"

  # Companion files — only available from a local clone
  local companions_copied=false
  if [[ -z "${CUSTOM_FILE}" && -d "${SCRIPT_DIR}/refs" ]]; then
    local claude_dir="${HOME}/.claude"
    for sub in refs templates eval optimize; do
      if [[ -d "${SCRIPT_DIR}/${sub}" ]]; then
        mkdir -p "${claude_dir}/${sub}"
        cp "${SCRIPT_DIR}/${sub}/"*.md "${claude_dir}/${sub}/" 2>/dev/null || true
      fi
    done
    companions_copied=true
    success "[claude] companion files → ${HOME}/.claude/{refs,templates,eval,optimize}/"
  fi

  if [[ "${companions_copied}" == "false" ]]; then
    info "  Tip: clone the repo and re-run to also install companion files (refs/, templates/, etc.)"
  fi
}

install_md_platform() {
  local platform="$1"
  local dest_dir="$2"
  local src
  src="${CUSTOM_FILE:-$(resolve_source "${platform}" md)}"
  mkdir -p "${dest_dir}"
  cp "${src}" "${dest_dir}/skill-writer.md"
  success "[${platform}] ${dest_dir}/skill-writer.md"
}

install_mcp() {
  local mcp_dir="${HOME}/.mcp/servers/skill-writer"
  local src
  src="$(resolve_source mcp json)"
  mkdir -p "${mcp_dir}"
  cp "${src}" "${mcp_dir}/mcp-manifest.json"
  success "[mcp] ${mcp_dir}/mcp-manifest.json"
}

install_platform() {
  local p="$1"
  case "${p}" in
    claude)   install_claude ;;
    opencode) install_md_platform opencode "${HOME}/.config/opencode/skills" ;;
    openclaw) install_md_platform openclaw "${HOME}/.openclaw/skills" ;;
    cursor)   install_md_platform cursor   "${HOME}/.cursor/skills" ;;
    gemini)   install_md_platform gemini   "${HOME}/.gemini/skills" ;;
    mcp)      install_mcp ;;
    openai)
      warn "[openai] OpenAI requires manual installation via the platform dashboard."
      return 0 ;;
    *)
      err "Unknown platform: ${p}"
      return 1 ;;
  esac
}

# ── Main ──────────────────────────────────────────────────────────────────────

if [[ ${#TARGETS[@]} -gt 0 ]]; then
  first="${TARGETS[0]}"
  if [[ "${first}" == "" ]]; then
    TARGETS=()
  fi
fi

echo ""
echo "skill-writer installer"
echo "──────────────────────"
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  warn "No platforms to install. Use --all or --platform <name>."
  exit 0
fi
info "Targets: ${TARGETS[*]}"
echo ""

for p in "${TARGETS[@]}"; do
  if install_platform "${p}"; then
    INSTALLED=$((INSTALLED + 1))
  else
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "──────────────────────"
if [[ ${FAILED} -eq 0 ]]; then
  echo "✓ Installed to ${INSTALLED} platform(s)."
else
  echo "⚠ Installed to ${INSTALLED} platform(s). ${FAILED} failed — see warnings above."
fi
echo ""
echo "Next step: restart each platform to activate skill-writer."
echo "Then try: /create a skill that summarises git diffs"
echo ""
