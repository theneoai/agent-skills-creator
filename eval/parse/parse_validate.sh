#!/usr/bin/env bash
set -euo pipefail

parse_validate() {
    local skill_file="$1"
    
    local YAML_SCORE=0
    local SECTIONS_SCORE=0
    local TRIGGER_SCORE=0
    local PLACEHOLDER_SCORE=0
    local SECURITY_VIOLATION=0
    
    if [[ ! -f "$skill_file" ]]; then
        echo "Error: File not found: $skill_file" >&2
        return 1
    fi
    
    local content
    content=$(cat "$skill_file")
    
    # ========== YAML Frontmatter Check (30pts) ==========
    local yaml_frontmatter=""
    if [[ "$content" =~ ^[[:space:]]*--- ]]; then
        local end_marker
        end_marker=$(echo "$content" | grep -n '^[[:space:]]*---' | head -2 | tail -1 | cut -d: -f1)
        if [[ -n "$end_marker" ]]; then
            yaml_frontmatter=$(echo "$content" | sed -n "2,${end_marker}p")
        fi
    fi
    
    local has_name=0
    local has_description=0
    local has_license=0
    
    if echo "$yaml_frontmatter" | grep -qE '^[[:space:]]*name:[[:space:]]*.+'; then
        has_name=1
        ((YAML_SCORE+=10))
    fi
    if echo "$yaml_frontmatter" | grep -qE '^[[:space:]]*description:[[:space:]]*.+'; then
        has_description=1
        ((YAML_SCORE+=10))
    fi
    if echo "$yaml_frontmatter" | grep -qE '^[[:space:]]*license:[[:space:]]*.+'; then
        has_license=1
        ((YAML_SCORE+=10))
    fi
    
    # ========== Three Sections Check (30pts) ==========
    if echo "$content" | grep -qE '§1\.1[[:space:]]'; then
        ((SECTIONS_SCORE+=10))
    fi
    if echo "$content" | grep -qE '§1\.2[[:space:]]'; then
        ((SECTIONS_SCORE+=10))
    fi
    if echo "$content" | grep -qE '§1\.3[[:space:]]'; then
        ((SECTIONS_SCORE+=10))
    fi
    
    # ========== Trigger List Check (25pts) ==========
    local create_count=0
    local evaluate_count=0
    local restore_count=0
    local tune_count=0
    
    create_count=$(echo "$content" | grep -oi 'CREATE' | wc -l | tr -d ' ' || true)
    evaluate_count=$(echo "$content" | grep -oi 'EVALUATE' | wc -l | tr -d ' ' || true)
    restore_count=$(echo "$content" | grep -oi 'RESTORE' | wc -l | tr -d ' ' || true)
    tune_count=$(echo "$content" | grep -oi 'TUNE' | wc -l | tr -d ' ' || true)
    
    if [[ "$create_count" -ge 5 ]]; then
        ((TRIGGER_SCORE+=7))
    fi
    if [[ "$evaluate_count" -ge 5 ]]; then
        ((TRIGGER_SCORE+=6))
    fi
    if [[ "$restore_count" -ge 5 ]]; then
        ((TRIGGER_SCORE+=6))
    fi
    if [[ "$tune_count" -ge 5 ]]; then
        ((TRIGGER_SCORE+=6))
    fi
    
    # ========== No Placeholders Check (15pts) ==========
    local placeholder_count=0
    placeholder_count=$(echo "$content" | grep -cE '\[TODO\]|\[FIXME\]|TBD|undefined|null' || true)
    placeholder_count=$(echo "$placeholder_count" | tr -d ' ')
    
    if [[ "$placeholder_count" -eq 0 ]]; then
        PLACEHOLDER_SCORE=15
    elif [[ "$placeholder_count" -le 2 ]]; then
        PLACEHOLDER_SCORE=10
    elif [[ "$placeholder_count" -le 5 ]]; then
        PLACEHOLDER_SCORE=5
    fi
    
    # ========== Security Check (CWE-798, CWE-22) ==========
    if echo "$content" | grep -qE 'sk-[a-zA-Z0-9]{20,}|api_key|password[[:space:]]*=|token[[:space:]]*='; then
        SECURITY_VIOLATION=1
    fi
    
    if echo "$content" | grep -qE '\.\.|\%00'; then
        SECURITY_VIOLATION=1
    fi
    
    # ========== Calculate Total ==========
    local PARSE_SCORE=$((YAML_SCORE + SECTIONS_SCORE + TRIGGER_SCORE + PLACEHOLDER_SCORE))
    local security_status="PASS"
    if [[ "$SECURITY_VIOLATION" -eq 1 ]]; then
        security_status="FAIL"
    fi
    
    # ========== Print Results ==========
    echo "=== Parse & Validate Results ==="
    echo "YAML Frontmatter: ${YAML_SCORE}/30"
    echo "Three Sections: ${SECTIONS_SCORE}/30"
    echo "Trigger List: ${TRIGGER_SCORE}/25"
    echo "No Placeholders: ${PLACEHOLDER_SCORE}/15"
    echo "Security Check: ${security_status}"
    echo "TOTAL: ${PARSE_SCORE}/100"
    
    return 0
}

parse_validate "$@"
