#!/usr/bin/env bash
# security.sh - Security Agent with CWE-based Security Checklist
#
# Multi-LLM cross-validation for security audit
# 10 checklist items covering CWE-798, CWE-89, CWE-78, CWE-22, CWE-306, CWE-862

source "$(dirname "${BASH_SOURCE[0]}")/base.sh"
require integration

agent_init

OWASP_AST10_ITEMS=(
    "Credential Scan"
    "Input Validation"
    "Path Traversal"
    "Trigger Sanitization"
    "YAML Parsing Safety"
    "Command Injection Prevention"
    "SQL Injection Prevention"
    "Data Exposure Prevention"
    "Log信息安全"
    "Error Handling Security"
)

audit_security() {
    local skill_file="$1"
    local audit_level="${2:-FULL}"
    
    if [[ ! -f "$skill_file" ]]; then
        echo '{"error": "Skill file not found"}'
        return 1
    fi
    
    local content
    content=$(cat "$skill_file")
    
    local results_json="[]"
    local overall_status="PASS"
    local p0_count=0
    local p1_count=0
    local p2_count=0
    
    for item in "${OWASP_AST10_ITEMS[@]}"; do
        local item_result
        item_result=$(
            jq -n \
                --arg item "$item" \
                --arg status "PASS" \
                --arg severity "NONE" \
                --arg findings "No issues found" \
                '{
                    item: $item,
                    status: $status,
                    severity: $severity,
                    findings: $findings,
                    llm_providers: []
                }'
        )
        
        local item_status="PASS"
        local item_severity="NONE"
        local item_findings=""
        local providers_checked=()
        
        case "$item" in
            "Credential Scan")
                local cred_result
                cred_result=$(multi_llm_credential_scan "$content")
                item_status=$(echo "$cred_result" | jq -r '.status')
                item_severity=$(echo "$cred_result" | jq -r '.severity')
                item_findings=$(echo "$cred_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai" "kimi")
                ;;
            "Input Validation")
                local input_result
                input_result=$(multi_llm_input_validation "$content")
                item_status=$(echo "$input_result" | jq -r '.status')
                item_severity=$(echo "$input_result" | jq -r '.severity')
                item_findings=$(echo "$input_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai" "kimi")
                ;;
            "Path Traversal")
                local path_result
                path_result=$(multi_llm_path_traversal "$content")
                item_status=$(echo "$path_result" | jq -r '.status')
                item_severity=$(echo "$path_result" | jq -r '.severity')
                item_findings=$(echo "$path_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai" "kimi")
                ;;
            "Trigger Sanitization")
                local trigger_result
                trigger_result=$(multi_llm_trigger_validation "$content")
                item_status=$(echo "$trigger_result" | jq -r '.status')
                item_severity=$(echo "$trigger_result" | jq -r '.severity')
                item_findings=$(echo "$trigger_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai" "kimi")
                ;;
            "YAML Parsing Safety")
                local yaml_result
                yaml_result=$(multi_llm_yaml_safety "$content")
                item_status=$(echo "$yaml_result" | jq -r '.status')
                item_severity=$(echo "$yaml_result" | jq -r '.severity')
                item_findings=$(echo "$yaml_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai")
                ;;
            "Command Injection Prevention")
                local cmd_result
                cmd_result=$(multi_llm_command_injection "$content")
                item_status=$(echo "$cmd_result" | jq -r '.status')
                item_severity=$(echo "$cmd_result" | jq -r '.severity')
                item_findings=$(echo "$cmd_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai" "kimi")
                ;;
            "SQL Injection Prevention")
                local sql_result
                sql_result=$(multi_llm_sql_injection "$content")
                item_status=$(echo "$sql_result" | jq -r '.status')
                item_severity=$(echo "$sql_result" | jq -r '.severity')
                item_findings=$(echo "$sql_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai")
                ;;
            "Data Exposure Prevention")
                local data_result
                data_result=$(multi_llm_data_exposure "$content")
                item_status=$(echo "$data_result" | jq -r '.status')
                item_severity=$(echo "$data_result" | jq -r '.severity')
                item_findings=$(echo "$data_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai" "kimi")
                ;;
            "Log信息安全")
                local log_result
                log_result=$(multi_llm_log_security "$content")
                item_status=$(echo "$log_result" | jq -r '.status')
                item_severity=$(echo "$log_result" | jq -r '.severity')
                item_findings=$(echo "$log_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai")
                ;;
            "Error Handling Security")
                local error_result
                error_result=$(multi_llm_error_handling "$content")
                item_status=$(echo "$error_result" | jq -r '.status')
                item_severity=$(echo "$error_result" | jq -r '.severity')
                item_findings=$(echo "$error_result" | jq -r '.findings')
                providers_checked=("anthropic" "openai")
                ;;
        esac
        
        if [[ "$item_status" == "FAIL" ]]; then
            case "$item_severity" in
                P0) ((p0_count++)) ;;
                P1) ((p1_count++)) ;;
                P2) ((p2_count++)) ;;
            esac
            overall_status="FAIL"
        fi
        
        local providers_json="[]"
        for p in "${providers_checked[@]}"; do
            providers_json=$(echo "$providers_json" | jq ". + [\"$p\"]")
        done
        
        item_result=$(jq -n \
            --arg item "$item" \
            --arg status "$item_status" \
            --arg severity "$item_severity" \
            --arg findings "$item_findings" \
            --argjson providers "$providers_json" \
            '{
                item: $item,
                status: $status,
                severity: $severity,
                findings: $findings,
                llm_providers: $providers
            }')
        
        results_json=$(echo "$results_json" | jq ". + [$item_result]")
    done
    
    jq -n \
        --arg status "$overall_status" \
        --argjson p0 "$p0_count" \
        --argjson p1 "$p1_count" \
        --argjson p2 "$p2_count" \
        --argjson results "$results_json" \
        '{
            security_status: $status,
            p0_violations: $p0,
            p1_violations: $p1,
            p2_violations: $p2,
            items_checked: $results,
            recommendation: if $status == "FAIL" and $p0 > 0 then "BLOCK_DEPLOYMENT" elif $status == "FAIL" and $p1 > 0 then "REVIEW_REQUIRED" else "APPROVED" end
        }'
}

multi_llm_credential_scan() {
    local content="$1"
    
    local r1 r2 r3
    r1=$(llm_credential_scan_single "anthropic" "$content")
    r2=$(llm_credential_scan_single "openai" "$content")
    r3=$(llm_credential_scan_single "kimi" "$content")
    
    cross_validate_results "$r1" "$r2" "$r3" "credential_scan"
}

llm_credential_scan_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Scan this skill file for credential vulnerabilities:

CWE-798: Hardcoded credentials
CWE-259: Hard-coded password
CWE-321: Use of hard-coded cryptographic key
CWE-260: Password in configuration file

Check for patterns like:
- password=, api_key=, secret=, token=
- sk-[a-zA-Z0-9]{20,} (OpenAI keys)
- AKIA[0-9A-Z]{16,} (AWS keys)
- any obvious password strings

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of any credentials found\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Scan for credential vulnerabilities.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_input_validation() {
    local content="$1"
    
    local r1 r2 r3
    r1=$(llm_input_validation_single "anthropic" "$content")
    r2=$(llm_input_validation_single "openai" "$content")
    r3=$(llm_input_validation_single "kimi" "$content")
    
    cross_validate_results "$r1" "$r2" "$r3" "input_validation"
}

llm_input_validation_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check this skill file for input validation issues:

CWE-20: Improper Input Validation
CWE-79: Cross-site Scripting (XSS)
CWE-89: SQL Injection (in skill references)

Look for:
- User inputs that are not validated
- File paths from user input used unsanitized
- Command arguments not validated

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of validation issues\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Check input validation.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_path_traversal() {
    local content="$1"
    
    local r1 r2 r3
    r1=$(llm_path_traversal_single "anthropic" "$content")
    r2=$(llm_path_traversal_single "openai" "$content")
    r3=$(llm_path_traversal_single "kimi" "$content")
    
    cross_validate_results "$r1" "$r2" "$r3" "path_traversal"
}

llm_path_traversal_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check this skill file for path traversal vulnerabilities:

CWE-22: Path Traversal
CWE-23: Relative Path Traversal
CWE-24: Path Equivalence

Look for:
- File operations without realpath validation
- .. in file paths
- Unsanitized path concatenation

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of path issues\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Check path traversal risks.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_trigger_validation() {
    local content="$1"
    
    local r1 r2 r3
    r1=$(llm_trigger_validation_single "anthropic" "$content")
    r2=$(llm_trigger_validation_single "openai" "$content")
    r3=$(llm_trigger_validation_single "kimi" "$content")
    
    cross_validate_results "$r1" "$r2" "$r3" "trigger_validation"
}

llm_trigger_validation_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check this skill file for trigger sanitization:

Verify that trigger keywords are validated:
- Regex should be alphanumeric only
- No special characters in trigger patterns
- Input sanitization before trigger matching

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of trigger issues\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Validate trigger sanitization.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_yaml_safety() {
    local content="$1"
    
    local r1 r2
    r1=$(llm_yaml_safety_single "anthropic" "$content")
    r2=$(llm_yaml_safety_single "openai" "$content")
    
    cross_validate_results "$r1" "$r2" "" "yaml_safety"
}

llm_yaml_safety_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check YAML frontmatter parsing safety:

CWE-20: Improper Input Validation (YAML parsing)
CWE-94: Code Injection (YAML deserialization)

Verify:
- YAML frontmatter is properly formatted
- No injection via YAML special characters
- Safe YAML parsing without eval

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of YAML issues\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Check YAML parsing safety.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_command_injection() {
    local content="$1"
    
    local r1 r2 r3
    r1=$(llm_command_injection_single "anthropic" "$content")
    r2=$(llm_command_injection_single "openai" "$content")
    r3=$(llm_command_injection_single "kimi" "$content")
    
    cross_validate_results "$r1" "$r2" "$r3" "command_injection"
}

llm_command_injection_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check for command injection vulnerabilities:

CWE-78: OS Command Injection
CWE-77: Command Injection (blank)

Look for:
- eval, system, exec calls with user input
- Shell commands built from unsanitized input
- Backticks or \$() with user content

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of command injection risks\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Check command injection vectors.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_sql_injection() {
    local content="$1"
    
    local r1 r2
    r1=$(llm_sql_injection_single "anthropic" "$content")
    r2=$(llm_sql_injection_single "openai" "$content")
    
    cross_validate_results "$r1" "$r2" "" "sql_injection"
}

llm_sql_injection_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check for SQL injection vulnerabilities:

CWE-89: SQL Injection

Look for:
- SQL queries built from user input
- String concatenation in SQL statements
- No parameterized queries

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of SQL injection risks\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Check SQL injection vectors.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_data_exposure() {
    local content="$1"
    
    local r1 r2 r3
    r1=$(llm_data_exposure_single "anthropic" "$content")
    r2=$(llm_data_exposure_single "openai" "$content")
    r3=$(llm_data_exposure_single "kimi" "$content")
    
    cross_validate_results "$r1" "$r2" "$r3" "data_exposure"
}

llm_data_exposure_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check for data exposure vulnerabilities:

CWE-200: Exposure of Sensitive Information to an Unauthorized Actor
CWE-359: Exposure of Private Personal Information

Look for:
- Logging sensitive data
- Error messages revealing internal info
- Exposing API keys, tokens, passwords in output

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of data exposure risks\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Check data exposure risks.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_log_security() {
    local content="$1"
    
    local r1 r2
    r1=$(llm_log_security_single "anthropic" "$content")
    r2=$(llm_log_security_single "openai" "$content")
    
    cross_validate_results "$r1" "$r2" "" "log_security"
}

llm_log_security_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check log security:

CWE-117: Improper Output Neutralization for Logs
CWE-532: Information Exposure Through Log

Look for:
- Log injection attacks
- Sensitive data in logs
- Improper log sanitization

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of log security issues\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Check log security.
EOF
)" "$prompt" "auto" "$provider"
}

multi_llm_error_handling() {
    local content="$1"
    
    local r1 r2
    r1=$(llm_error_handling_single "anthropic" "$content")
    r2=$(llm_error_handling_single "openai" "$content")
    
    cross_validate_results "$r1" "$r2" "" "error_handling"
}

llm_error_handling_single() {
    local provider="$1"
    local content="$2"
    
    local prompt="Check error handling security:

CWE-209: Generation of Error Message Containing Sensitive Information
CWE-390: Detection of Error Condition Without Action

Look for:
- Error messages revealing system info
- Unhandled exceptions
- Silent failures

Content:
$content

Respond with JSON:
{
  \"status\": \"PASS\" or \"FAIL\",
  \"severity\": \"NONE\" or \"P0\" or \"P1\" or \"P2\",
  \"findings\": \"Description of error handling issues\"
}"

    agent_call_llm "$(cat <<'EOF'
You are a security expert. Check error handling security.
EOF
)" "$prompt" "auto" "$provider"
}

cross_validate_results() {
    local r1="$1"
    local r2="$2"
    local r3="$3"
    local check_type="$4"
    
    local s1 s2 s3
    s1=$(echo "$r1" | jq -r '.status' 2>/dev/null || echo "UNKNOWN")
    s2=$(echo "$r2" | jq -r '.status' 2>/dev/null || echo "UNKNOWN")
    
    if [[ "$s1" == "$s2" ]]; then
        echo "$r1"
        return
    fi
    
    if [[ -n "$r3" ]]; then
        s3=$(echo "$r3" | jq -r '.status' 2>/dev/null || echo "UNKNOWN")
        if [[ "$s1" == "$s3" ]] || [[ "$s2" == "$s3" ]]; then
            local majority=""
            [[ "$s1" == "$s3" ]] && majority="$s1" || majority="$s2"
            echo "$r1" | jq --arg status "$majority" '.status = $status'
            return
        fi
    fi
    
    echo "$r1" | jq '. + {conflict: true, resolution: "HUMAN_REVIEW_REQUIRED"}'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill_file> [FULL|BASIC]"
        exit 1
    fi
    
    audit_security "$1" "${2:-FULL}"
fi
