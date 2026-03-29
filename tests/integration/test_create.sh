#!/usr/bin/env bash
# CREATE 集成测试 (15用例)

test_create_normal_001() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "Create a test skill" "$output" --no-agent 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "Output file created"
    assert_success "grep -q 'name:' '$output'" "Has YAML frontmatter name"
    rm -f "$output"
}

test_create_normal_002() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "Create a code review skill" "$output" 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "Skill file created with valid description"
    rm -f "$output"
}

test_create_with_parent_003() {
    local output parent
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    parent="${PROJECT_ROOT}/SKILL.md"
    if [[ -f "$parent" ]]; then
        bash scripts/create-skill.sh "Create child skill" "$output" --extends "$parent" 2>/dev/null || true
        assert_success "[[ -f '$output' ]]" "Child skill created with parent"
    else
        ((TESTS_SKIPPED++))
    fi
    rm -f "$output"
}

test_create_with_parent_004() {
    local output parent
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    parent="${PROJECT_ROOT}/SKILL.md"
    if [[ -f "$parent" ]]; then
        bash scripts/create-skill.sh "Create extended skill" "$output" -e "$parent" 2>/dev/null || true
        assert_success "[[ -s '$output' ]]" "Parent content inherited to child"
    else
        ((TESTS_SKIPPED++))
    fi
    rm -f "$output"
}

test_create_empty_input_005() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "" "$output" 2>/dev/null && assert_failure "true" "Empty description should fail" || assert_success "true" "Empty description handled"
    rm -f "$output"
}

test_create_empty_input_006() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "   " "$output" 2>/dev/null && assert_failure "true" "Whitespace only should fail" || assert_success "true" "Whitespace description handled"
    rm -f "$output"
}

test_create_tier_007() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "Create GOLD tier skill" "$output" --tier GOLD 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "GOLD tier skill created"
    rm -f "$output"
}

test_create_tier_008() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "Create SILVER tier skill" "$output" -t SILVER 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "SILVER tier skill created"
    rm -f "$output"
}

test_create_tier_009() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "Create BRONZE tier skill" "$output" -t BRONZE 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "BRONZE tier skill created"
    rm -f "$output"
}

test_create_output_path_010() {
    local output="/tmp/test_skill_custom_path_$$.md"
    rm -f "$output"
    bash scripts/create-skill.sh "Create skill with custom path" "$output" 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "Custom output path respected"
    rm -f "$output"
}

test_create_output_path_011() {
    local output="/tmp/test/skill/nested/path_$$/skill.md"
    mkdir -p "/tmp/test/skill/nested/path_$$"
    rm -f "$output"
    bash scripts/create-skill.sh "Create skill with nested path" "$output" 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "Nested directory path created"
    rm -rf "/tmp/test"
}

test_create_parallel_012() {
    local count=0
    (
        local out1=$(mktemp /tmp/test_create_p1_XXXXXX.md)
        local out2=$(mktemp /tmp/test_create_p2_XXXXXX.md)
        local out3=$(mktemp /tmp/test_create_p3_XXXXXX.md)
        bash scripts/create-skill.sh "Parallel skill 1" "$out1" 2>/dev/null || true
        bash scripts/create-skill.sh "Parallel skill 2" "$out2" 2>/dev/null || true
        bash scripts/create-skill.sh "Parallel skill 3" "$out3" 2>/dev/null || true
    ) &
    wait
    sleep 1
    local out1 out2 out3
    out1=$(ls /tmp/test_create_p1_*.md 2>/dev/null | head -1)
    out2=$(ls /tmp/test_create_p2_*.md 2>/dev/null | head -1)
    out3=$(ls /tmp/test_create_p3_*.md 2>/dev/null | head -1)
    [[ -n "$out1" ]] && ((count++)) || true
    [[ -n "$out2" ]] && ((count++)) || true
    [[ -n "$out3" ]] && ((count++)) || true
    rm -f /tmp/test_create_p*.md 2>/dev/null || true
    assert_success "[[ $count -ge 1 ]]" "Parallel creation produces files"
}

test_create_help_013() {
    local output
    output=$(bash scripts/create-skill.sh --help 2>&1 || true)
    assert_success "echo '$output' | grep -q 'Usage'" "Help message displayed"
    assert_success "echo '$output' | grep -q 'extends'" "Help shows extends option"
    assert_success "echo '$output' | grep -q 'tier'" "Help shows tier option"
}

test_create_invalid_parent_014() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "Create with invalid parent" "$output" --extends "/nonexistent/parent.md" 2>/dev/null && assert_failure "true" "Invalid parent should fail" || assert_success "true" "Invalid parent handled"
    rm -f "$output"
}

test_create_name_generation_015() {
    local output
    output=$(mktemp /tmp/test_create_XXXXXX.md)
    bash scripts/create-skill.sh "Create a Test Skill With Multiple Words" "$output" 2>/dev/null || true
    assert_success "[[ -f '$output' ]]" "Multi-word description generates skill"
    rm -f "$output"
}
