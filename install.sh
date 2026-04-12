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
# Supported platforms: claude, opencode, openclaw, cursor, gemini, mcp, a2a
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

# Check that a directory is writable (or creatable).
# Returns 1 and prints an error if an existing directory is not writable.
check_writable() {
  local dir="$1"
  if [[ -d "${dir}" && ! -w "${dir}" ]]; then
    err "Directory '${dir}' exists but is not writable. Check permissions (try: chmod u+w '${dir}')."
    return 1
  fi
  return 0
}

# Create a timestamped backup of an existing file before overwriting.
# No-op if the file does not exist.
backup_if_exists() {
  local dest="$1"
  if [[ -f "${dest}" ]]; then
    local backup="${dest}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "${dest}" "${backup}"
    info "Backed up existing file → ${backup}"
  fi
}

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
  [[ -d "${HOME}/.a2a" ]]                  && detected+=(a2a)
  echo "${detected[@]:-}"
}

# Determine target platform list
declare -a TARGETS
if [[ "${INSTALL_ALL}" == "true" ]]; then
  TARGETS=(claude opencode openclaw cursor gemini mcp a2a)
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
  check_writable "${dest_dir}" || return 1
  mkdir -p "${dest_dir}"
  backup_if_exists "${dest_dir}/skill-writer.md"
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
  check_writable "${dest_dir}" || return 1
  mkdir -p "${dest_dir}"
  backup_if_exists "${dest_dir}/skill-writer.md"
  cp "${src}" "${dest_dir}/skill-writer.md"
  success "[${platform}] ${dest_dir}/skill-writer.md"
}

install_mcp() {
  local mcp_dir="${HOME}/.mcp/servers/skill-writer"
  local src
  src="$(resolve_source mcp json)"
  check_writable "${mcp_dir}" || return 1
  mkdir -p "${mcp_dir}"
  backup_if_exists "${mcp_dir}/mcp-manifest.json"
  cp "${src}" "${mcp_dir}/mcp-manifest.json"
  success "[mcp] ${mcp_dir}/mcp-manifest.json"

  # ── MCP Server Card (.well-known/mcp-server-card.json) ──────────────────────
  # Server Cards enable passive discovery by MCP registries (2026 roadmap feature).
  # The card lives at .well-known/mcp-server-card.json relative to the server dir.
  local card_dir="${mcp_dir}/.well-known"
  local card_file="${card_dir}/mcp-server-card.json"
  mkdir -p "${card_dir}"

  # Extract name/version/description from the installed manifest using node or python3,
  # then write a compact Server Card JSON alongside the manifest.
  if command -v node &>/dev/null; then
    node - "${mcp_dir}/mcp-manifest.json" "${card_file}" <<'NODEJS'
const fs = require('fs');
const [,, manifestPath, cardPath] = process.argv;
const m = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const card = {
  card_schema_version: '2026-draft',
  name: m.name || 'skill-writer',
  description: m.description || '',
  version: m.version || '1.0.0',
  author: m.author || 'theneoai',
  provider: { name: m.author || 'theneoai', url: 'https://github.com/theneoai/skill-writer' },
  capabilities: m.capabilities || {},
  tools: (m.tools || []).map(t => ({ name: t.name, description: t.description })),
  ...(m.skill_tier ? { skill_tier: m.skill_tier } : {}),
  ...(m.triggers ? { triggers: m.triggers } : {}),
  generated_at: new Date().toISOString(),
  generated_by: 'skill-writer-builder/install.sh',
};
fs.writeFileSync(cardPath, JSON.stringify(card, null, 2));
NODEJS
    success "[mcp] ${card_file} (Server Card for registry discovery)"
  elif command -v python3 &>/dev/null; then
    python3 - "${mcp_dir}/mcp-manifest.json" "${card_file}" <<'PYEOF'
import json, sys
from datetime import datetime, timezone
manifest_path, card_path = sys.argv[1], sys.argv[2]
m = json.loads(open(manifest_path).read())
card = {
  "card_schema_version": "2026-draft",
  "name": m.get("name", "skill-writer"),
  "description": m.get("description", ""),
  "version": m.get("version", "1.0.0"),
  "author": m.get("author", "theneoai"),
  "provider": {"name": m.get("author", "theneoai"), "url": "https://github.com/theneoai/skill-writer"},
  "capabilities": m.get("capabilities", {}),
  "tools": [{"name": t["name"], "description": t.get("description", "")} for t in m.get("tools", [])],
  "generated_at": datetime.now(timezone.utc).isoformat(),
  "generated_by": "skill-writer-builder/install.sh",
}
if "skill_tier" in m: card["skill_tier"] = m["skill_tier"]
if "triggers" in m: card["triggers"] = m["triggers"]
open(card_path, "w").write(json.dumps(card, indent=2))
PYEOF
    success "[mcp] ${card_file} (Server Card for registry discovery)"
  else
    warn "[mcp] Server Card skipped — node or python3 required to generate .well-known/mcp-server-card.json"
  fi
}

install_a2a() {
  local a2a_dir="${HOME}/.a2a/agents/skill-writer"
  local src
  src="$(resolve_source a2a json)"
  check_writable "${a2a_dir}" || return 1
  mkdir -p "${a2a_dir}"
  backup_if_exists "${a2a_dir}/agent-card.json"
  cp "${src}" "${a2a_dir}/agent-card.json"
  success "[a2a] ${a2a_dir}/agent-card.json"
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
    a2a)      install_a2a ;;
    openai)
      local openai_src
      openai_src="$(resolve_source openai json)"
      warn "[openai] OpenAI requires manual setup via the platform dashboard."
      info "  Generated file: ${openai_src}"
      info "  Upload it at: https://platform.openai.com (Custom GPT → Configure → Actions)"
      info "  Or use the agent install command:"
      info "    read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-openai.json and install to openai"
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
echo "Feature support:"
echo "  ✓ CREATE, LEAN, EVALUATE, OPTIMIZE, INSTALL, COLLECT, SHARE — all modes"
echo "  ✓ LEAN & EVALUATE scoring — full 500/1000-pt algorithms"
echo "  ✓ OPTIMIZE loop with VERIFY (up to 20 rounds)"
echo "  ✓ COLLECT JSON output (manual save)"
if [[ -d "${SCRIPT_DIR}/refs" ]]; then
  echo "  ✓ Companion files (refs/, templates/) — richer EVALUATE reports"
  echo "  ✓ COLLECT auto-persist available (requires UTE hooks, see refs/use-to-evolve.md §8)"
else
  echo "  ○ Companion files — not installed (curl install)"
  echo "    To add: git clone https://github.com/theneoai/skill-writer.git && cd skill-writer && ./install.sh"
  echo "    Adds: richer EVALUATE reports + COLLECT auto-persist for Claude"
fi
echo ""
echo "Next steps:"
echo ""

# Context-sensitive guidance — printed once per platform, no duplicate headers
for p in "${TARGETS[@]}"; do
  case "${p}" in
    claude)
      echo "  [Claude] Restart Claude, then try:"
      if [[ -z "${CUSTOM_FILE}" && -d "${SCRIPT_DIR}/refs" ]]; then
        echo "    /create a skill that summarises git diffs"
        echo "    ✓ Full feature set (companion files installed)"
      else
        echo "    All 6 modes work right now — full feature set installed:"
        echo "    • create a skill that summarises git diffs"
        echo "    • lean eval [paste skill content]"
        echo "    • evaluate / optimize / install / collect"
        echo ""
        echo "    ℹ Optionally add richer EVALUATE reports & auto-persist COLLECT:"
        echo "      (git clone install adds companion files for Claude only)"
        echo "      git clone https://github.com/theneoai/skill-writer.git"
        echo "      cd skill-writer && ./install.sh --platform claude"
        echo "      This is optional — not required for any core feature."
      fi
      ;;
    opencode)
      echo "  [OpenCode] Restart OpenCode, then try:"
      echo "    /create a skill that summarises git diffs"
      ;;
    openclaw)
      echo "  [OpenClaw] Restart OpenClaw, then try:"
      echo "    create a skill that summarises git diffs"
      ;;
    cursor)
      echo "  [Cursor] Restart Cursor, then use KEYWORD phrases (not /slash):"
      echo "    create a skill that summarises git diffs"
      echo "    lean eval  |  evaluate this skill  |  optimize this skill"
      echo "    (IDE command palette intercepts / — keywords always work)"
      echo ""
      echo "    Note: COLLECT auto-persist requires file system hooks (not"
      echo "    available in IDE context). Use 'collect session data' to get"
      echo "    JSON output in the chat, then save manually."
      ;;
    gemini)
      echo "  [Gemini] After install:"
      echo "    1. Skill file is at: ~/.gemini/skills/skill-writer.md"
      echo "    2. Restart Gemini (close and reopen the app or CLI session)"
      echo "    3. Test with a trigger phrase: create a skill that summarises git diffs"
      echo "    Note: Gemini reads skills from ~/.gemini/skills/ on startup."
      echo "    If skills don't activate, verify the path and restart once more."
      ;;
    mcp)
      echo "  [MCP] Restart your MCP host. Manifest at:"
      echo "    ~/.mcp/servers/skill-writer/mcp-manifest.json"
      echo "    Try: create a skill that summarises git diffs"
      ;;
  esac
done

echo ""
echo "Quick reference: create/lean/eval/opt/install/collect"
echo "  (or: 创建 / 快评 / 评测 / 优化 / 安装 / 采集)"
echo "Docs: https://github.com/theneoai/skill-writer#quick-start"
echo ""
