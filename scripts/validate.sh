#!/usr/bin/env bash
# scripts/validate.sh — Dry-run all platform installers to catch breakage early.
# Called by: make validate, ci.yml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PLATFORMS=(claude openclaw opencode cursor gemini openai kimi hermes)

failed=0
for p in "${PLATFORMS[@]}"; do
  script="$ROOT/$p/install.sh"
  if [[ -f "$script" ]]; then
    if bash "$script" --dry-run >/dev/null 2>&1; then
      echo "  ✓ $p/install.sh"
    else
      echo "  ✗ $p/install.sh --dry-run failed"
      failed=$((failed + 1))
    fi
  else
    echo "  ⚠ $p/install.sh missing (skipped)"
  fi
done

if [[ $failed -gt 0 ]]; then
  echo "  ✗ $failed installer(s) failed dry-run"
  exit 1
fi
echo "  ✓ all installers pass dry-run"
