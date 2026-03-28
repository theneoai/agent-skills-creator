#!/usr/bin/env bash
# certifier.sh - Phase 4: Certification determination (100pts)
# Calculates certification score and tier based on all evaluation metrics

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/constants.sh"

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
    
    if [[ -z "$skill_file" ]] || [[ ! -f "$skill_file" ]]; then
        echo "Error: Valid skill file required" >&2
        return 1
    fi
    
    local total
    total=$(echo "scale=2; $text_score + $runtime_score" | bc)
    
    local tier
    tier=$(determine_tier "$total" "$text_score" "$runtime_score" "$variance")
    
    local variance_points
    local lt_10 lt_20 lt_30
    lt_10=$(echo "$variance < 10" | bc -l)
    lt_20=$(echo "$variance < 20" | bc -l)
    lt_30=$(echo "$variance < 30" | bc -l)
    
    if [[ "$lt_10" -eq 1 ]]; then
        variance_points=40
    elif [[ "$lt_20" -eq 1 ]]; then
        variance_points=30
    elif [[ "$lt_30" -eq 1 ]]; then
        variance_points=15
    else
        variance_points=0
    fi
    
    local tier_points
    tier_points=$(get_tier_points "$tier")
    
    local json_report_exists=0
    local html_report_exists=0
    
    if [[ -f "report.json" ]] || [[ -f "${skill_file%.md}_report.json" ]] || [[ -f "eval_results/report.json" ]]; then
        json_report_exists=1
    fi
    
    if [[ -f "report.html" ]] || [[ -f "${skill_file%.md}_report.html" ]] || [[ -f "eval_results/report.html" ]]; then
        html_report_exists=1
    fi
    
    local report_points=0
    report_points=$((json_report_exists * 10 + html_report_exists * 10))
    
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
    certify_total=$((variance_points + tier_points + report_points + security_points))
    
    local certified="NO"
    if [[ "$certify_total" -ge 50 ]] && [[ "$p0_violation" -eq 0 ]] && [[ "$tier" != "NOT_CERTIFIED" ]]; then
        certified="YES"
    fi
    
    echo "=== Certification Results ==="
    echo "Variance Control: ${variance_points}/40"
    echo "Tier Determination: ${tier_points}/30 (${tier})"
    echo "Report Completeness: ${report_points}/20"
    echo "Security Gates: ${security_points}/10"
    echo "TOTAL: ${certify_total}/100"
    echo "CERTIFIED: ${certified}"
    echo "TIER: ${tier}"
    
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
    
    certify "$skill_file" "$text_score" "$runtime_score" "$variance" "$f1_score" "$mrr_score" "$trigger_acc"
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
