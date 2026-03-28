#!/usr/bin/env bash
# summarizer.sh - LLM总结提炼

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
source "${EVAL_DIR}/lib/agent_executor.sh"

summarizer_system_prompt="You are an expert AI skill architect specializing in synthesizing analysis findings into actionable improvement plans.

Your task is to take analysis results and create a clear, prioritized summary that can be used to improve a SKILL.md file."

summarize() {
    local analysis="$1"
    local skill_name="$2"
    
    local summary_prompt="Summarize the following analysis for skill '${skill_name}' into a prioritized improvement plan:

${analysis}

Provide a JSON summary with:
1. priority_issues: Array of {issue, section, severity} sorted by severity
2. key_findings: Array of main insights from the analysis
3. improvement_plan: Array of {action, section, rationale} in priority order
4. expected_impact: Description of how improvements will affect scores"
    
    local response
    response=$(call_llm "$summarizer_system_prompt" "$summary_prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        return 1
    fi
    
    echo "$response"
}

summarize_for_human() {
    local analysis="$1"
    local skill_name="$2"
    
    local summary_prompt="Create a human-readable summary of the analysis for skill '${skill_name}'.

Analysis:
${analysis}

Provide a concise summary covering:
1. Current state assessment
2. Top 3 priority improvements
3. Expected outcome"
    
    local response
    response=$(call_llm "$summarizer_system_prompt" "$summary_prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        return 1
    fi
    
    echo "$response"
}

extract_key_insights() {
    local analysis="$1"
    
    local insights_prompt="Extract the 3-5 most critical insights from this analysis:

${analysis}

Format as a JSON array of strings, each being one key insight."
    
    local response
    response=$(call_llm "$summarizer_system_prompt" "$insights_prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        return 1
    fi
    
    echo "$response"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <analysis_json> <skill_name>"
        exit 1
    fi
    
    summarize "$1" "$2"
fi