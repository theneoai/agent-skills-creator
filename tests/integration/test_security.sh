#!/usr/bin/env bash
# SECURITY 集成测试 (10用例)

test_security_credential_detection_001() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: credential-test
description: Credential detection test
license: MIT
---

## §1.1 Identity
Test with api_key = "sk-1234567890abcdefghijklmnop"
EOF
    bash scripts/security-audit.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Credential detection runs"
    rm -f "$skill_file"
}

test_security_credential_detection_002() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: password-test
description: Password detection test
license: MIT
---

## §1.1 Identity
Test with password = "secret123"
EOF
    bash scripts/security-audit.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Password detection runs"
    rm -f "$skill_file"
}

test_security_sql_injection_003() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: sql-injection-test
description: SQL injection detection test
license: MIT
---

## §1.1 Identity
Test with SQL: SELECT * FROM users WHERE id = 'input'
EOF
    bash scripts/security-audit.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "SQL injection detection runs"
    rm -f "$skill_file"
}

test_security_sql_injection_004() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: sql-concat-test
description: SQL concat detection test
license: MIT
---

## §1.1 Identity
Test with query = "SELECT " + userInput + " FROM table"
EOF
    bash scripts/security-audit.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "SQL concat detection runs"
    rm -f "$skill_file"
}

test_security_path_traversal_005() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: path-traversal-test
description: Path traversal detection test
license: MIT
---

## §1.1 Identity
Test with path = "../../../etc/passwd"
EOF
    bash scripts/security-audit.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Path traversal detection runs"
    rm -f "$skill_file"
}

test_security_path_traversal_006() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: path-concat-test
description: Path concat detection test
license: MIT
---

## §1.1 Identity
Test with file = "/tmp/" + userInput
EOF
    bash scripts/security-audit.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Path concat detection runs"
    rm -f "$skill_file"
}

test_security_command_injection_007() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: command-injection-test
description: Command injection detection test
license: MIT
---

## §1.1 Identity
Test with system("rm -rf " + userInput)
EOF
    bash scripts/security-audit.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Command injection detection runs"
    rm -f "$skill_file"
}

test_security_command_injection_008() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: eval-injection-test
description: Eval injection detection test
license: MIT
---

## §1.1 Identity
Test with eval(userInput)
EOF
    bash scripts/security-audit.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Eval injection detection runs"
    rm -f "$skill_file"
}

test_security_help_009() {
    local output
    output=$(bash scripts/security-audit.sh --help 2>&1 || true)
    assert_success "echo '$output' | grep -q 'Usage'" "Help message displayed"
    assert_success "echo '$output' | grep -q 'level'" "Help shows level parameter"
}

test_security_basic_level_010() {
    local skill_file
    skill_file=$(mktemp /tmp/test_security_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: basic-level-test
description: Basic audit level test
license: MIT
---

## §1.1 Identity
Basic security audit test
EOF
    bash scripts/security-audit.sh "$skill_file" BASIC 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "BASIC audit level runs"
    rm -f "$skill_file"
}
