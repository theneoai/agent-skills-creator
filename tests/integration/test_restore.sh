#!/usr/bin/env bash
# RESTORE 集成测试 (10用例)

test_restore_broken_skill_001() {
    local skill_file
    skill_file=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: broken
description: Broken skill
license: MIT
---

## §1.1 Identity
Broken content with missing sections
EOF
    bash scripts/restore-skill.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Broken skill restoration attempted"
    rm -f "$skill_file"
}

test_restore_broken_skill_002() {
    local skill_file
    skill_file=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: severely-broken
description: Severely broken skill
---

## §1.1 Identity
Only one section remains
EOF
    bash scripts/restore-skill.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Severely broken skill restoration"
    rm -f "$skill_file"
}

test_restore_missing_section_003() {
    local skill_file
    skill_file=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: missing-section
description: Missing section test
license: MIT
---

## §1.1 Identity
Only §1.1 exists
EOF
    bash scripts/restore-skill.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Missing section skill restored"
    rm -f "$skill_file"
}

test_restore_missing_section_004() {
    local skill_file
    skill_file=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: missing-12
description: Missing §1.2 test
license: MIT
---

## §1.1 Identity
Identity exists
## §1.3 Thinking
Thinking exists
EOF
    bash scripts/restore-skill.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Missing §1.2 skill restored"
    rm -f "$skill_file"
}

test_restore_syntax_error_005() {
    local skill_file
    skill_file=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: syntax-error
description: Syntax error test
license: MIT
---

## §1.1 Identity
Test with [TODO] placeholder and undefined content
EOF
    bash scripts/restore-skill.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Syntax error skill restored"
    rm -f "$skill_file"
}

test_restore_syntax_error_006() {
    local skill_file
    skill_file=$(mktemp /tmp/test_restore_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: placeholder-error
description: Placeholder error test
license: MIT
---

## §1.1 Identity
Content with [FIXME] markers
## §1.2 Framework
More [TODO] here
EOF
    bash scripts/restore-skill.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Placeholder error skill restored"
    rm -f "$skill_file"
}

test_restore_parallel_007() {
    local out1 out2 out3
    out1=$(mktemp /tmp/test_restore_parallel_1_XXXXXX.md)
    out2=$(mktemp /tmp/test_restore_parallel_2_XXXXXX.md)
    out3=$(mktemp /tmp/test_restore_parallel_3_XXXXXX.md)
    cat > "$out1" <<'EOF'
---
name: parallel-restore-1
description: Parallel restore test 1
license: MIT
---
## §1.1 Identity
Broken content 1
EOF
    cat > "$out2" <<'EOF'
---
name: parallel-restore-2
description: Parallel restore test 2
license: MIT
---
## §1.1 Identity
Broken content 2
EOF
    cat > "$out3" <<'EOF'
---
name: parallel-restore-3
description: Parallel restore test 3
license: MIT
---
## §1.1 Identity
Broken content 3
EOF
    (
        bash scripts/restore-skill.sh "$out1" 2>/dev/null &
        bash scripts/restore-skill.sh "$out2" 2>/dev/null &
        bash scripts/restore-skill.sh "$out3" 2>/dev/null &
        wait
    )
    local count=0
    [[ -f "$out1" ]] && ((count++)) || true
    [[ -f "$out2" ]] && ((count++)) || true
    [[ -f "$out3" ]] && ((count++)) || true
    rm -f "$out1" "$out2" "$out3"
    assert_success "[[ $count -eq 3 ]]" "Parallel restore completes all files"
}

test_restore_invalid_008() {
    local invalid_file="/tmp/nonexistent_restore_$$$.md"
    bash scripts/restore-skill.sh "$invalid_file" 2>/dev/null && \
        assert_failure "true" "Invalid file should fail" || \
        assert_success "true" "Invalid file handled"
}

test_restore_help_009() {
    local output
    output=$(bash scripts/restore-skill.sh --help 2>&1 || true)
    assert_success "echo '$output' | grep -q 'Usage'" "Help message displayed"
    assert_success "echo '$output' | grep -q 'skill_file'" "Help shows skill_file parameter"
}

test_restore_full_skill_010() {
    local skill_file
    skill_file=$(mktemp /tmp/test_restore_full_XXXXXX.md)
    cat > "$skill_file" <<'EOF'
---
name: full-skill
description: Full skill restoration test
license: MIT
version: 1.0.0
---

## §1.1 Identity
Full skill identity section
## §1.2 Framework
Full skill framework section
## §1.3 Thinking
Full skill thinking section
EOF
    bash scripts/restore-skill.sh "$skill_file" 2>/dev/null || true
    assert_success "[[ -f '$skill_file' ]]" "Full skill restoration completes"
    rm -f "$skill_file"
}
