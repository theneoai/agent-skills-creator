#!/usr/bin/env bash
set -euo pipefail

text_score() {
    local skill_file="$1"
    
    if [[ ! -f "$skill_file" ]]; then
        echo "Error: File not found: $skill_file" >&2
        return 1
    fi
    
    local content=$(cat "$skill_file")
    
    score_system_prompt() {
        local score=0
        local content="$1"
        
        if echo "$content" | grep -qE '(^|\n)#+\s+(§1\.1|1\.1 Identity|1\.1[[:space:]:.])'; then
            score=$((score + 20))
        fi
        if echo "$content" | grep -qE '(^|\n)#+\s+(§1\.2|1\.2 Framework|1\.2[[:space:]:.])'; then
            score=$((score + 20))
        fi
        if echo "$content" | grep -qE '(^|\n)#+\s+(§1\.3|1\.3 Thinking|1\.3[[:space:]:.])'; then
            score=$((score + 20))
        fi
        if echo "$content" | grep -qE '(never|always|forbidden|never\s+[Dd]o|always\s+[Mm]ust|do\s+not|must\s+not)'; then
            score=$((score + 10))
        fi
        
        echo $score
    }
    
    score_domain_knowledge() {
        local score=0
        local content="$1"
        local quantitative_count=$(echo "$content" | grep -cE '[0-9]+\.[0-9]+%|[0-9]+%|[0-9]+(x|倍|次|个|px|ms|s|min|hour|day|K|M|G|T|P)|\$[0-9]+|[0-9]+\.[0-9]+')
        local framework_count=$(echo "$content" | grep -cE '(ReAct|CoT|ToT|RAG|Chain|Agent|Prompt|Retrieval|框架|方法|范式|案例|标准)')
        local benchmark_count=$(echo "$content" | grep -cE '(NIST|OWASP|ISO|SECURITY|SANS|CVE|benchmark|standard|framework)')
        local case_study_count=$(echo "$content" | grep -cE '(case|study|example|实例|案例|例如|例子|示例)')
        
        if [[ $quantitative_count -ge 10 ]]; then
            score=$((score + 20))
        elif [[ $quantitative_count -ge 5 ]]; then
            score=$((score + 10))
        elif [[ $quantitative_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        # BUG-S001 fix: raised from 10→20 so DK max = 20+20+15+15 = 70 (matches declared max)
        if [[ $framework_count -ge 4 ]]; then
            score=$((score + 20))
        elif [[ $framework_count -ge 2 ]]; then
            score=$((score + 10))
        elif [[ $framework_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        if [[ $benchmark_count -ge 3 ]]; then
            score=$((score + 15))
        elif [[ $benchmark_count -ge 2 ]]; then
            score=$((score + 10))
        elif [[ $benchmark_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        if [[ $case_study_count -ge 3 ]]; then
            score=$((score + 15))
        elif [[ $case_study_count -ge 2 ]]; then
            score=$((score + 10))
        elif [[ $case_study_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        if echo "$content" | grep -qE '(best\s+practices|industry\s+leader|industry\s+standard)' && [[ $case_study_count -lt 2 ]]; then
            score=$((score - 10))
        fi
        
        if [[ $score -lt 0 ]]; then
            score=0
        fi
        
        echo $score
    }
    
    score_workflow() {
        local score=0
        local content="$1"
        
        if echo "$content" | grep -qE '(workflow|phase|step|阶段|流程|步骤)'; then
            score=$((score + 15))
        fi
        
        local phase_count=$(echo "$content" | grep -cE '(Phase|阶段|Step|步骤|Pipeline)')
        if [[ $phase_count -ge 4 ]] && [[ $phase_count -le 6 ]]; then
            score=$((score + 20))
        elif [[ $phase_count -ge 2 ]]; then
            score=$((score + 10))
        elif [[ $phase_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        local done_count=$(echo "$content" | grep -cE '(Done|完成|done|完成|success|成功)')
        if [[ $done_count -ge 4 ]]; then
            score=$((score + 15))
        elif [[ $done_count -ge 2 ]]; then
            score=$((score + 10))
        elif [[ $done_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        local fail_count=$(echo "$content" | grep -cE '(Fail|失败|fail|error|错误|abort|终止)')
        if [[ $fail_count -ge 4 ]]; then
            score=$((score + 15))
        elif [[ $fail_count -ge 2 ]]; then
            score=$((score + 10))
        elif [[ $fail_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        if echo "$content" | grep -qE '(decision|判断|if|else|switch|case|分支)'; then
            score=$((score + 5))
        fi
        
        echo $score
    }
    
    score_error_handling() {
        local score=0
        local content="$1"
        
        local failure_count=$(echo "$content" | grep -cE '(failure|Failure|error|Error|fail|Fail|exception|Exception|问题|失败|错误)')
        
        if [[ $failure_count -ge 5 ]]; then
            score=$((score + 20))
        elif [[ $failure_count -ge 3 ]]; then
            score=$((score + 12))
        elif [[ $failure_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        local recovery_count=$(echo "$content" | grep -cE '(retry|Retry|fallback|Fallback|circuit|breaker|recovery|recover|重试|恢复|回退|备选)')
        if [[ $recovery_count -ge 3 ]]; then
            score=$((score + 20))
        elif [[ $recovery_count -ge 2 ]]; then
            score=$((score + 12))
        elif [[ $recovery_count -ge 1 ]]; then
            score=$((score + 6))
        fi
        
        local antipattern_count=$(echo "$content" | grep -cE '(anti.?pattern|anti-pattern|avoid|不要|avoid|禁止|不要使用)')
        if [[ $antipattern_count -ge 3 ]]; then
            score=$((score + 10))
        elif [[ $antipattern_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        if echo "$content" | grep -qE '(risk|Risk|matrix|矩阵|severity|impact)'; then
            score=$((score + 5))
        fi
        
        echo $score
    }
    
    score_examples() {
        local score=0
        local content="$1"
        
        local example_count=$(echo "$content" | grep -cE '(example|Example|示例|例子|实例|case|Case|scenario|Scenario)')
        local table_example_count=$(echo "$content" | grep -E '\|.*\|.*\|' | grep -ciE '(example|示例|例子|实例|案例|case)')
        example_count=$((example_count + table_example_count))
        
        if [[ $example_count -ge 5 ]]; then
            score=$((score + 20))
        elif [[ $example_count -ge 3 ]]; then
            score=$((score + 12))
        elif [[ $example_count -ge 1 ]]; then
            score=$((score + 5))
        fi
        
        local input_count=$(echo "$content" | grep -cE '(input|Input|输入|参数|param|request)')
        if [[ $input_count -ge 5 ]]; then
            score=$((score + 10))
        elif [[ $input_count -ge 3 ]]; then
            score=$((score + 6))
        elif [[ $input_count -ge 1 ]]; then
            score=$((score + 3))
        fi
        
        local output_count=$(echo "$content" | grep -cE '(output|Output|输出|返回|result|Response)')
        if [[ $output_count -ge 5 ]]; then
            score=$((score + 10))
        elif [[ $output_count -ge 3 ]]; then
            score=$((score + 6))
        elif [[ $output_count -ge 1 ]]; then
            score=$((score + 3))
        fi
        
        local verify_count=$(echo "$content" | grep -cE '(verify|Verify|验证|check|Check|assert|Assert|test|Test|校验)')
        if [[ $verify_count -ge 5 ]]; then
            score=$((score + 10))
        elif [[ $verify_count -ge 3 ]]; then
            score=$((score + 6))
        elif [[ $verify_count -ge 1 ]]; then
            score=$((score + 3))
        fi
        
        if echo "$content" | grep -qE '(\{[a-z_]+\}|\[.*\]|\w+\s*:)'; then
            score=$((score + 5))
        fi
        
        echo $score
    }
    
    score_metadata() {
        local score=0
        local content="$1"
        
        if echo "$content" | grep -qE '^[[:space:]]*name:\s*['\''"]?[^'\''" ]'; then
            score=$((score + 5))
        fi
        
        if echo "$content" | grep -qE '^[[:space:]]*description:\s*['\''"]?[^'\''" ]'; then
            score=$((score + 5))
        fi
        
        if echo "$content" | grep -qE '^[[:space:]]*license:\s*['\''"]?[^'\''" ]'; then
            score=$((score + 5))
        fi
        
        if echo "$content" | grep -qE '^[[:space:]]*version:\s*['\''"]?[^'\''" ]'; then
            score=$((score + 5))
        fi
        
        if echo "$content" | grep -qE '^[[:space:]]*author:\s*['\''"]?[^'\''" ]'; then
            score=$((score + 5))
        fi
        
        if echo "$content" | grep -qE '(tags:|categories:|tags |categories )'; then
            score=$((score + 5))
        fi
        
        echo $score
    }
    
    local system_prompt_score=$(score_system_prompt "$content")
    local domain_knowledge_score=$(score_domain_knowledge "$content")
    local workflow_score=$(score_workflow "$content")
    local error_handling_score=$(score_error_handling "$content")
    local examples_score=$(score_examples "$content")
    local metadata_score=$(score_metadata "$content")
    
    local total=$((system_prompt_score + domain_knowledge_score + workflow_score + error_handling_score + examples_score + metadata_score))
    
    cat << EOF
=== Text Score Results ===
System Prompt: ${system_prompt_score}/70
Domain Knowledge: ${domain_knowledge_score}/70
Workflow: ${workflow_score}/70
Error Handling: ${error_handling_score}/55
Examples: ${examples_score}/55
Metadata: ${metadata_score}/30
TOTAL: ${total}/350
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    text_score "$@"
fi
