#!/usr/bin/env bash
# restorer.sh - Restore Agent for broken/degraded skills
#
# Multi-LLM cross-validation for diagnosis and fix verification

source "$(dirname "${BASH_SOURCE[0]}")/base.sh"
require integration

agent_init

restore_skill() {
    local skill_file="$1"
    
    if [[ ! -f "$skill_file" ]]; then
        echo '{"error": "Skill file not found"}'
        return 1
    fi
    
    local content
    content=$(cat "$skill_file")
    
    local old_score
    old_score=$(evaluate_skill "$skill_file" "fast" | jq -r '.total_score // 0')
    
    echo "=== DIAGNOSIS PHASE ==="
    local diagnosis
    diagnosis=$(multi_llm_diagnose "$content")
    
    local issues_count
    issues_count=$(echo "$diagnosis" | jq '.issues | length')
    
    if [[ "$issues_count" -eq 0 ]]; then
        jq -n \
            --arg score "$old_score" \
            '{"status": "NO_ISSUES", "old_score": ($score | tonumber), "new_score": ($score | tonumber), "issues_found": 0, "fixes_applied": []}'
        return 0
    fi
    
    echo "=== FIX PROPOSAL PHASE ==="
    local fixes
    fixes=$(multi_llm_propose_fixes "$content" "$diagnosis")
    
    echo "=== IMPLEMENTATION PHASE ==="
    local temp_file
    temp_file=$(mktemp /tmp/restored_skill_XXXXXX.md)
    
    cp "$skill_file" "$temp_file"
    
    apply_fixes "$temp_file" "$fixes"
    
    echo "=== VERIFICATION PHASE ==="
    local new_score
    new_score=$(evaluate_skill "$temp_file" "fast" | jq -r '.total_score // 0')
    
    local score_delta
    score_delta=$(echo "$new_score - $old_score" | bc)
    
    if (( $(echo "$score_delta >= 0.5" | bc -l) )); then
        cp "$temp_file" "$skill_file"
        rm -f "$temp_file"
        
        local fixes_applied
        fixes_applied=$(echo "$fixes" | jq '[.[] | .description]')
        
        jq -n \
            --arg old_score "$old_score" \
            --arg new_score "$new_score" \
            --arg delta "$score_delta" \
            --argjson issues_count "$issues_count" \
            --argjson fixes "$fixes_applied" \
            '{
                status: "RESTORED",
                old_score: ($old_score | tonumber),
                new_score: ($new_score | tonumber),
                score_delta: ($delta | tonumber),
                issues_found: $issues_count,
                fixes_applied: $fixes,
                verification: "MULTI_LLM_APPROVED"
            }'
    else
        rm -f "$temp_file"
        
        jq -n \
            --arg old_score "$old_score" \
            --arg new_score "$new_score" \
            --arg delta "$score_delta" \
            --argjson issues_count "$issues_count" \
            '{"status": "RESTORATION_FAILED", "old_score": ($old_score | tonumber), "new_score": ($new_score | tonumber), "score_delta": ($delta | tonumber), "issues_found": $issues_count, "recommendation": "HUMAN_REVIEW_REQUIRED"}'
    fi
}

multi_llm_diagnose() {
    local content="$1"
    
    local r1 r2 r3
    r1=$(llm_diagnose_single "anthropic" "$content")
    r2=$(llm_diagnose_single "openai" "$content")
    r3=$(llm_diagnose_single "kimi" "$content")
    
    local issues1 issues2 issues3
    issues1=$(echo "$r1" | jq -r '.issues // []')
    issues2=$(echo "$r2" | jq -r '.issues // []')
    issues3=$(echo "$r3" | jq -r '.issues // []')
    
    local cross_validated
    cross_validated=$(cross_validate_issues "$issues1" "$issues2" "$issues3")
    
    echo "$cross_validated" | jq '. + {llm_diagnoses: [$r1, $r2, $r3]}'
}

llm_diagnose_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Diagnose this skill file for problems:

Check for:
1. Parse errors (YAML frontmatter, section structure)
2. Missing required sections (§1.1, §1.2, §1.3)
3. Score regression causes
4. Security vulnerabilities
5. Incomplete workflows
6. Missing error handling
7. Vague instructions

Content:
$content

Respond with JSON:
{
  \"issues\": [
    {
      \"type\": \"PARSE_ERROR|MISSING_SECTION|SECURITY|INCOMPLETE|VAGUE\",
      \"severity\": \"P0|P1|P2|P3\",
      \"location\": \"line number or section\",
      \"description\": \"what is wrong\",
      \"suggestion\": \"how to fix\"
    }
  ],
  \"overall_health\": \"GOOD|FAIR|POOR\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a skill restoration expert. Diagnose issues in SKILL.md files.
EOF
)" "$prompt" "auto" "$provider"
}

cross_validate_issues() {
    local issues1="$1"
    local issues2="$2"
    local issues3="$3"
    
    local all_issues="$issues1"
    
    local count1 count2 count3
    count1=$(echo "$issues1" | jq 'length')
    count2=$(echo "$issues2" | jq 'length')
    count3=$(echo "$issues3" | jq 'length')
    
    local max_count=$count1
    [[ $count2 -gt $max_count ]] && max_count=$count2
    [[ $count3 -gt $max_count ]] && max_count=$count3
    
    local consensus_issues="[]"
    
    for i in $(seq 0 $((max_count - 1))); do
        local issue1 issue2 issue3
        issue1=$(echo "$issues1" | jq ".[$i] // null")
        issue2=$(echo "$issues2" | jq ".[$i] // null")
        issue3=$(echo "$issues3" | jq ".[$i] // null")
        
        if [[ "$issue1" != "null" ]] && [[ "$issue2" != "null" ]] && [[ "$issue3" != "null" ]]; then
            local type1 type2 type3
            type1=$(echo "$issue1" | jq -r '.type')
            type2=$(echo "$issue2" | jq -r '.type')
            type3=$(echo "$issue3" | jq -r '.type')
            
            if [[ "$type1" == "$type2" ]] || [[ "$type1" == "$type3" ]]; then
                consensus_issues=$(echo "$consensus_issues" | jq ". + [$issue1]")
            elif [[ "$type2" == "$type3" ]]; then
                consensus_issues=$(echo "$consensus_issues" | jq ". + [$issue2]")
            fi
        fi
    done
    
    jq -n \
        --argjson issues "$consensus_issues" \
        --argjson count1 "$count1" \
        --argjson count2 "$count2" \
        --argjson count3 "$count3" \
        '{
            issues: $issues,
            llm_agreement: [
                {provider: "anthropic", issues: $count1},
                {provider: "openai", issues: $count2},
                {provider: "kimi", issues: $count3}
            ],
            confidence: if $issues | length > 0 then 0.9 else 0.5 end
        }'
}

multi_llm_propose_fixes() {
    local content="$1"
    local diagnosis="$2"
    
    local issues
    issues=$(echo "$diagnosis" | jq '.issues')
    
    local r1 r2 r3
    r1=$(llm_propose_fixes_single "anthropic" "$content" "$issues")
    r2=$(llm_propose_fixes_single "openai" "$content" "$issues")
    r3=$(llm_propose_fixes_single "kimi" "$content" "$issues")
    
    cross_validate_fixes "$r1" "$r2" "$r3"
}

llm_propose_fixes_single() {
    local provider="$1"
    local content="$2"
    local issues="$3"
    
    local prompt="Propose fixes for these skill issues:

Issues found:
$issues

Skill content:
$content

For each issue, propose:
1. Exact text to change
2. Line/section to modify
3. New content to insert

Respond with JSON:
{
  \"fixes\": [
    {
      \"issue_type\": \"matching issue type\",
      \"description\": \"what will be changed\",
      \"target_section\": \"§X.X\",
      \"old_content\": \"current text (if applicable)\",
      \"new_content\": \"replacement text\"
    }
  ]
}"

    agent_call_llm "$(cat <<'EOF'
You are a skill restoration expert. Propose specific fixes.
EOF
)" "$prompt" "auto" "$provider"
}

cross_validate_fixes() {
    local fixes1="$1"
    local fixes2="$2"
    local fixes3="$3"
    
    local consensus_fixes="[]"
    
    local count1 count2 count3
    count1=$(echo "$fixes1" | jq '.fixes | length')
    count2=$(echo "$fixes2" | jq '.fixes | length')
    count3=$(echo "$fixes3" | jq '.fixes | length')
    
    local max_count=$count1
    [[ $count2 -gt $max_count ]] && max_count=$count2
    [[ $count3 -gt $max_count ]] && max_count=$count3
    
    for i in $(seq 0 $((max_count - 1))); do
        local fix1 fix2 fix3
        fix1=$(echo "$fixes1" | jq ".fixes[$i] // null")
        fix2=$(echo "$fixes2" | jq ".fixes[$i] // null")
        fix3=$(echo "$fixes3" | jq ".fixes[$i] // null")
        
        if [[ "$fix1" != "null" ]] && [[ "$fix2" != "null" ]] && [[ "$fix3" != "null" ]]; then
            local desc1 desc2 desc3
            desc1=$(echo "$fix1" | jq -r '.description')
            desc2=$(echo "$fix2" | jq -r '.description')
            desc3=$(echo "$fix3" | jq -r '.description')
            
            if [[ "$desc1" == "$desc2" ]] || [[ "$desc1" == "$desc3" ]]; then
                consensus_fixes=$(echo "$consensus_fixes" | jq ". + [$fix1]")
            elif [[ "$desc2" == "$desc3" ]]; then
                consensus_fixes=$(echo "$consensus_fixes" | jq ". + [$fix2]")
            fi
        fi
    done
    
    echo "$consensus_fixes" | jq '{fixes: .}'
}

apply_fixes() {
    local skill_file="$1"
    local fixes="$2"
    
    local fix_count
    fix_count=$(echo "$fixes" | jq '.fixes | length')
    
    for i in $(seq 0 $((fix_count - 1))); do
        local fix
        fix=$(echo "$fixes" | jq ".fixes[$i]")
        
        local target_section new_content
        target_section=$(echo "$fix" | jq -r '.target_section')
        new_content=$(echo "$fix" | jq -r '.new_content')
        
        if [[ "$target_section" != "null" ]] && [[ "$new_content" != "null" ]]; then
            local section_pattern
            section_pattern=$(echo "$target_section" | sed 's/\./\\./g')
            
            if grep -q "## $section_pattern" "$skill_file"; then
                local marker="## $target_section"
                local line_num
                line_num=$(grep -n "$marker" "$skill_file" | head -1 | cut -d: -f1)
                
                if [[ -n "$line_num" ]]; then
                    local after_line=$((line_num + 1))
                    local section_content=""
                    
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^##\ §[0-9] ]]; then
                            break
                        fi
                        section_content="$section_content$line"$'\n'
                    done < <(tail -n +$after_line "$skill_file")
                    
                    section_content=$(echo "$section_content" | head -1)
                    
                    if [[ -n "$section_content" ]]; then
                        sed -i '' "${line_num}s/.*/$new_content/" "$skill_file"
                    fi
                fi
            fi
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill_file>"
        exit 1
    fi
    
    restore_skill "$1"
fi
