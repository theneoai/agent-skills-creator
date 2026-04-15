#!/usr/bin/env bash
# scripts/lint.sh — Run shellcheck on all install scripts.
# Called by: make lint, ci.yml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PLATFORMS=(claude openclaw opencode cursor gemini openai kimi hermes)
SCRIPTS=("$ROOT/install.sh")

for p in "${PLATFORMS[@]}"; do
  [[ -f "$ROOT/$p/install.sh" ]] && SCRIPTS+=("$ROOT/$p/install.sh")
done

if ! command -v shellcheck &>/dev/null; then
  echo "  ⚠ shellcheck not found — skipping lint (install: apt/brew install shellcheck)"
  exit 0
fi

failed=0
for s in "${SCRIPTS[@]}"; do
  rel="${s#"$ROOT/"}"
  if shellcheck --severity=warning "$s"; then
    echo "  ✓ $rel"
  else
    echo "  ✗ $rel"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  echo "  ✗ shellcheck: $failed file(s) failed"
  exit 1
fi
echo "  ✓ all scripts pass shellcheck"
