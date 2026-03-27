#!/usr/bin/env bash
# skill-type-detector.sh — Detects skill type for appropriate validation
# Usage: ./skill-type-detector.sh path/to/SKILL.md
# Types: manager, content, tool

SKILL_FILE="${1:-}"
if [[ -z "$SKILL_FILE" || ! -f "$SKILL_FILE" ]]; then
  echo "Usage: $0 path/to/SKILL.md"
  exit 1
fi

detect_skill_type() {
  local file="$1"
  
  # ── Manager-type detection ──────────────────────────────────────
  # Has explicit mode triggers (CREATE/EVALUATE/RESTORE/TUNE)
  local has_mode_section=$(grep -cE "## §2.*Triggers|## § 2.*Triggers|Mode Selection" "$file" || true)
  local has_create_mode=$(grep -cE "\*\*CREATE\*\*|CREATE Mode" "$file" || true)
  local has_evaluate_mode=$(grep -cE "\*\*EVALUATE\*\*|EVALUATE Mode" "$file" || true)
  local has_restore_mode=$(grep -cE "\*\*RESTORE\*\*|RESTORE Mode" "$file" || true)
  local has_tune_mode=$(grep -cE "\*\*TUNE\*\*|TUNE Mode" "$file" || true)
  local has_trigger_table=$(grep -cE "Mode.*Triggers.*EN.*ZH|\| Mode \|" "$file" || true)
  
  local manager_score=0
  [[ $has_mode_section -gt 0 ]] && manager_score=$((manager_score + 2))
  [[ $has_create_mode -gt 0 ]] && manager_score=$((manager_score + 1))
  [[ $has_evaluate_mode -gt 0 ]] && manager_score=$((manager_score + 1))
  [[ $has_restore_mode -gt 0 ]] && manager_score=$((manager_score + 1))
  [[ $has_tune_mode -gt 0 ]] && manager_score=$((manager_score + 1))
  [[ $has_trigger_table -gt 0 ]] && manager_score=$((manager_score + 2))
  
  if [[ $manager_score -ge 4 ]]; then
    echo "manager"
    return
  fi
  
  # ── Tool-type detection ─────────────────────────────────────────
  # Has many code blocks, commands, utilities
  local has_bash_blocks=$(grep -cE '```bash|```sh' "$file" || true)
  local has_commands=$(grep -cE '\$\(|bash |npm |pip |cargo |python |node ' "$file" || true)
  local has_usage_section=$(grep -ciE "Usage:|Commands:|Tools:|API|CLI" "$file" || true)
  
  local tool_score=0
  [[ $has_bash_blocks -ge 3 ]] && tool_score=$((tool_score + 2))
  [[ $has_commands -ge 5 ]] && tool_score=$((tool_score + 2))
  [[ $has_usage_section -gt 0 ]] && tool_score=$((tool_score + 1))
  
  if [[ $tool_score -ge 4 ]]; then
    echo "tool"
    return
  fi
  
  # ── Content-type (default) ──────────────────────────────────────
  # Domain-specific role, describes expertise, examples
  local has_role_definition=$(grep -ciE "You are a|role:|Identity:|expertise:" "$file" || true)
  local has_examples=$(grep -cE "^## .*[Ee]xample|^### .*[Ee]xample|Example [0-9]:" "$file" || true)
  local has_scenarios=$(grep -cE "^## .*[Ss]cenario|^### .*[Ss]cenario" "$file" || true)
  local has_trigger_words=$(grep -ciE "Use when|Trigger|When to use" "$file" || true)
  
  local content_score=0
  [[ $has_role_definition -gt 0 ]] && content_score=$((content_score + 2))
  [[ $has_examples -ge 2 ]] && content_score=$((content_score + 2))
  [[ $has_scenarios -ge 2 ]] && content_score=$((content_score + 1))
  [[ $has_trigger_words -gt 0 ]] && content_score=$((content_score + 1))
  
  if [[ $content_score -ge 3 ]]; then
    echo "content"
    return
  fi
  
  # Fallback: if nothing matches, check description
  local desc=$(grep "^description:" "$file" 2>/dev/null | head -1 || true)
  if echo "$desc" | grep -qiE "manager|lifecycle|optimizer|creator|builder|generator"; then
    echo "manager"
  elif echo "$desc" | grep -qiE "tool|command|utility|script|cli"; then
    echo "tool"
  else
    echo "content"
  fi
}

SKILL_TYPE=$(detect_skill_type "$SKILL_FILE")
echo "$SKILL_TYPE"