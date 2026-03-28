#!/usr/bin/env bash
# analyzer.sh - LLM日志分析

source "$(dirname "${BASH_SOURCE[0]}")/../lib/bootstrap.sh"
source "${EVAL_DIR}/lib/agent_executor.sh"

analyzer_system_prompt="You are an expert data analyst specializing in AI skill usage patterns and performance metrics.

Your task is to analyze usage logs and identify:
1. Common failure modes
2. Usage patterns that correlate with poor scores
3. Sections that are frequently problematic
4. Triggers that work well vs poorly
5. Edge cases that need better handling

Be thorough and identify specific, actionable patterns."

analyze_logs() {
    local skill_file="$1"
    
    local skill_name
    skill_name=$(basename "$skill_file" .md)
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo '{"error": "No usage logs found"}'
        return 1
    fi
    
    local logs_content
    logs_content=$(grep "\"skill_name\":\"${skill_name}\"" "$USAGE_LOG" 2>/dev/null || echo "")
    
    if [[ -z "$logs_content" ]]; then
        echo '{"error": "No logs for this skill"}'
        return 1
    fi
    
    local logs_json
    logs_json=$(echo "$logs_content" | jq -s '.' 2>/dev/null || echo "[]")
    
    local analysis_prompt="Analyze the following usage logs for skill '${skill_name}' and identify patterns:

${logs_json}

Provide a JSON analysis with:
1. common_failures: Array of failure patterns observed
2. score_trends: Description of score trends over time
3. problematic_sections: Array of section numbers that need improvement
4. successful_triggers: Array of trigger patterns that work well
5. recommendations: Array of specific improvement recommendations"
    
    local response
    response=$(call_llm "$analyzer_system_prompt" "$analysis_prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        return 1
    fi
    
    echo "$response"
}

analyze_score_distribution() {
    local skill_name="$1"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo '{"error": "No logs found"}'
        return 1
    fi
    
    local scores
    scores=$(grep "\"skill_name\":\"${skill_name}\"" "$USAGE_LOG" 2>/dev/null | jq -r '.score' 2>/dev/null || echo "")
    
    if [[ -z "$scores" ]]; then
        echo '{"avg": 0, "min": 0, "max": 0, "count": 0}'
        return
    fi
    
    local avg min max count
    avg=$(echo "$scores" | jq -s 'add / length' 2>/dev/null || echo 0)
    min=$(echo "$scores" | jq 'min' 2>/dev/null || echo 0)
    max=$(echo "$scores" | jq 'max' 2>/dev/null || echo 0)
    count=$(echo "$scores" | jq 'length' 2>/dev/null || echo 0)
    
    jq -n \
        --arg avg "$avg" \
        --arg min "$min" \
        --arg max "$max" \
        --arg count "$count" \
        '{
            avg: ($avg | tonumber),
            min: ($min | tonumber),
            max: ($max | tonumber),
            count: ($count | tonumber)
        }'
}

analyze_trigger_effectiveness() {
    local skill_name="$1"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo '{"error": "No logs found"}'
        return 1
    fi
    
    local entries
    entries=$(grep "\"skill_name\":\"${skill_name}\"" "$USAGE_LOG" 2>/dev/null | jq -s '.' 2>/dev/null || echo "[]")
    
    local analysis_prompt="Analyze trigger effectiveness for skill '${skill_name}':

${entries}

Identify which triggers lead to high scores vs low scores. Provide JSON with:
1. high_score_triggers: Array of trigger patterns with avg score
2. low_score_triggers: Array of trigger patterns with avg score
3. recommendations: How to improve trigger recognition"
    
    local response
    response=$(call_llm "$analyzer_system_prompt" "$analysis_prompt" "auto" "kimi-code")
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]] || [[ "$response" == ERROR:* ]]; then
        return 1
    fi
    
    echo "$response"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill_file>"
        exit 1
    fi
    
    analyze_logs "$1"
fi