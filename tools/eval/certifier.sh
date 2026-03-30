#!/usr/bin/env bash
# certifier.sh - Phase 4: Certification determination (100pts)
# Calculates certification score and tier based on all evaluation metrics

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/constants.sh"

determine_tier() {
    local total="$1"
    local text_score="$2"
    local runtime_score="$3"
    local variance="$4"
    
    local lt_10 lt_15 lt_20 lt_30
    lt_10=$(echo "$variance < 10" | bc -l)
    lt_15=$(echo "$variance < 15" | bc -l)
    lt_20=$(echo "$variance < 20" | bc -l)
    lt_30=$(echo "$variance < 30" | bc -l)
    
    if [[ $(echo "$total >= $PLATINUM_MIN" | bc -l) -eq 1 ]] && \
       [[ $(echo "$text_score >= 330" | bc -l) -eq 1 ]] && \
       [[ $(echo "$runtime_score >= 430" | bc -l) -eq 1 ]] && \
       [[ "$lt_10" -eq 1 ]]; then
        echo "PLATINUM"
    elif [[ $(echo "$total >= $GOLD_MIN" | bc -l) -eq 1 ]] && \
         [[ $(echo "$text_score >= 315" | bc -l) -eq 1 ]] && \
         [[ $(echo "$runtime_score >= 405" | bc -l) -eq 1 ]] && \
         [[ "$lt_15" -eq 1 ]]; then
        echo "GOLD"
    elif [[ $(echo "$total >= $SILVER_MIN" | bc -l) -eq 1 ]] && \
         [[ $(echo "$text_score >= 280" | bc -l) -eq 1 ]] && \
         [[ $(echo "$runtime_score >= 360" | bc -l) -eq 1 ]] && \
         [[ "$lt_20" -eq 1 ]]; then
        echo "SILVER"
    elif [[ $(echo "$total >= $BRONZE_MIN" | bc -l) -eq 1 ]] && \
         [[ $(echo "$text_score >= 245" | bc -l) -eq 1 ]] && \
         [[ $(echo "$runtime_score >= 315" | bc -l) -eq 1 ]] && \
         [[ "$lt_30" -eq 1 ]]; then
        echo "BRONZE"
    else
        echo "NOT_CERTIFIED"
    fi
}

get_tier_points() {
    local tier="$1"
    case "$tier" in
        PLATINUM) echo "30" ;;
        GOLD) echo "25" ;;
        SILVER) echo "20" ;;
        BRONZE) echo "15" ;;
        *) echo "0" ;;
    esac
}

get_tier_badge() {
    local tier="$1"
    case "$tier" in
        PLATINUM) echo "💎 PLATINUM" ;;
        GOLD) echo "🥇 GOLD" ;;
        SILVER) echo "🥈 SILVER" ;;
        BRONZE) echo "🥉 BRONZE" ;;
        *) echo "❌ NOT CERTIFIED" ;;
    esac
}

certify() {
    local skill_file="$1"
    local text_score="$2"
    local runtime_score="$3"
    local variance="$4"
    local f1_score="$5"
    local mrr_score="$6"
    local trigger_acc="$7"
    # BUG-S004 fix: accept phase1_score so total reflects all 1000pts
    local phase1_score="${8:-0}"

    if [[ -z "$skill_file" ]] || [[ ! -f "$skill_file" ]]; then
        echo "Error: Valid skill file required" >&2
        return 1
    fi

    # BUG-S004 fix: include Phase 1 in total so tier thresholds (900/950) are reachable
    local total
    total=$(echo "scale=2; $phase1_score + $text_score + $runtime_score" | bc)

    local tier
    tier=$(determine_tier "$total" "$text_score" "$runtime_score" "$variance")

    # BUG-S005 fix: unified variance thresholds aligned with VARIANCE_MAX=20 in constants.sh
    # <10 → 40pts (PLATINUM), <15 → 30pts (GOLD), <20 → 20pts (SILVER), <30 → 10pts (BRONZE), else 0
    local variance_points
    local v_lt_10 v_lt_15 v_lt_20 v_lt_30
    v_lt_10=$(echo "$variance < 10" | bc -l)
    v_lt_15=$(echo "$variance < 15" | bc -l)
    v_lt_20=$(echo "$variance < 20" | bc -l)
    v_lt_30=$(echo "$variance < 30" | bc -l)

    if [[ "$v_lt_10" -eq 1 ]]; then
        variance_points=40
    elif [[ "$v_lt_15" -eq 1 ]]; then
        variance_points=30
    elif [[ "$v_lt_20" -eq 1 ]]; then
        variance_points=20
    elif [[ "$v_lt_30" -eq 1 ]]; then
        variance_points=10
    else
        variance_points=0
    fi

    local tier_points
    tier_points=$(get_tier_points "$tier")

    # BUG-S002 fix: F1/MRR now contribute to certification score (replaces circular report_points)
    # BUG-S003 fix: removed circular report_points (evaluator rewarding its own output)
    # F1 gate: 0-10pts; MRR gate: 0-10pts (total 20pts, same budget as old report_points)
    local f1_points=0 mrr_points=0
    if [[ -n "$f1_score" ]] && [[ "$f1_score" != "0" ]]; then
        local f1_meets_platinum f1_meets_gold f1_meets_silver
        f1_meets_platinum=$(echo "$f1_score >= 0.92" | bc -l)
        f1_meets_gold=$(echo "$f1_score >= 0.90" | bc -l)
        f1_meets_silver=$(echo "$f1_score >= 0.87" | bc -l)
        if [[ "$f1_meets_platinum" -eq 1 ]]; then
            f1_points=10
        elif [[ "$f1_meets_gold" -eq 1 ]]; then
            f1_points=7
        elif [[ "$f1_meets_silver" -eq 1 ]]; then
            f1_points=5
        fi
    fi
    if [[ -n "$mrr_score" ]] && [[ "$mrr_score" != "0" ]]; then
        local mrr_meets_platinum mrr_meets_gold mrr_meets_silver
        mrr_meets_platinum=$(echo "$mrr_score >= 0.88" | bc -l)
        mrr_meets_gold=$(echo "$mrr_score >= 0.85" | bc -l)
        mrr_meets_silver=$(echo "$mrr_score >= 0.82" | bc -l)
        if [[ "$mrr_meets_platinum" -eq 1 ]]; then
            mrr_points=10
        elif [[ "$mrr_meets_gold" -eq 1 ]]; then
            mrr_points=7
        elif [[ "$mrr_meets_silver" -eq 1 ]]; then
            mrr_points=5
        fi
    fi
    local quality_gate_points=$((f1_points + mrr_points))
    
    local security_violations=0
    local p0_violation=0
    
    if grep -E "$CWE_798_PATTERN" "$skill_file" >/dev/null 2>&1; then
        security_violations=$((security_violations + 1))
    fi
    
    if grep -E "$CWE_89_PATTERN" "$skill_file" >/dev/null 2>&1; then
        security_violations=$((security_violations + 1))
        p0_violation=1
    fi
    
    if grep -E "$CWE_78_PATTERN" "$skill_file" >/dev/null 2>&1; then
        security_violations=$((security_violations + 1))
        p0_violation=1
    fi
    
    if grep -E "$CWE_22_PATTERN" "$skill_file" >/dev/null 2>&1; then
        security_violations=$((security_violations + 1))
    fi
    
    if grep -E "$CWE_306_PATTERN" "$skill_file" >/dev/null 2>&1; then
        security_violations=$((security_violations + 1))
    fi
    
    if grep -E "$CWE_862_PATTERN" "$skill_file" >/dev/null 2>&1; then
        security_violations=$((security_violations + 1))
    fi
    
    local security_points=10
    if [[ "$p0_violation" -eq 1 ]]; then
        security_points=0
    elif [[ "$security_violations" -gt 0 ]]; then
        security_points=$((10 - security_violations * 3))
        if [[ "$security_points" -lt 0 ]]; then
            security_points=0
        fi
    fi
    
    local certify_total
    certify_total=$((variance_points + tier_points + quality_gate_points + security_points))

    local certified="NO"
    if [[ "$certify_total" -ge 50 ]] && [[ "$p0_violation" -eq 0 ]] && [[ "$tier" != "NOT_CERTIFIED" ]]; then
        certified="YES"
    fi

    echo "=== Certification Results ==="
    echo "Variance Control: ${variance_points}/40"
    echo "Tier Determination: ${tier_points}/30 (${tier})"
    echo "Quality Gates (F1/MRR): ${quality_gate_points}/20  [F1=${f1_score} MRR=${mrr_score}]"
    echo "Security Gates: ${security_points}/10"
    echo "TOTAL: ${certify_total}/100"
    echo "CERTIFIED: ${certified}"
    echo "TIER: ${tier}"
    echo "PHASE1_INCLUDED: ${phase1_score}pts (total=${total})"
    
    if [[ "$security_violations" -gt 0 ]]; then
        echo ""
        echo "Security Warnings: ${security_violations} issue(s) found"
        if [[ "$p0_violation" -eq 1 ]]; then
            echo "⚠️  P0 violation detected - certification blocked"
        fi
    fi
    
    export CERTIFY_SCORE="$certify_total"
    export TIER="$tier"
    export CERTIFIED_BOOL="$certified"
    
    return 0
}

certify_from_json() {
    local json_results="$1"
    
    local skill_file
    skill_file=$(echo "$json_results" | jq -r '.skill_file // "unknown"')
    local text_score
    text_score=$(echo "$json_results" | jq -r '.text_score // 0')
    local runtime_score
    runtime_score=$(echo "$json_results" | jq -r '.runtime_score // 0')
    local variance
    variance=$(echo "$json_results" | jq -r '.variance // 0')
    local f1_score
    f1_score=$(echo "$json_results" | jq -r '.f1_score // 0')
    local mrr_score
    mrr_score=$(echo "$json_results" | jq -r '.mrr_score // 0')
    local trigger_acc
    trigger_acc=$(echo "$json_results" | jq -r '.trigger_accuracy // 0')
    local phase1_score
    phase1_score=$(echo "$json_results" | jq -r '.phase1_score // 0')

    certify "$skill_file" "$text_score" "$runtime_score" "$variance" "$f1_score" "$mrr_score" "$trigger_acc" "$phase1_score"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 7 ]]; then
        echo "Usage: $0 <skill_file> <text_score> <runtime_score> <variance> <f1_score> <mrr_score> <trigger_accuracy>"
        echo ""
        echo "Example: $0 ./SKILL.md 280 360 15 0.92 0.88 0.95"
        exit 1
    fi
    certify "$1" "$2" "$3" "$4" "$5" "$6" "$7"
fi
