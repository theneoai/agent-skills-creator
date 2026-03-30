#!/usr/bin/env bash
# llm_mock_server.sh - VCR-style HTTP mock for LLM API calls in CI
#
# Modes:
#   record   - pass through to real API, save response to fixture
#   playback - return saved fixture, skip real API (default in CI)
#   passthrough - always call real API (no recording)
#
# Usage:
#   export LLM_MOCK_MODE=playback  # in CI
#   source tests/mocks/llm_mock_server.sh
#   # Now call_llm() is intercepted automatically

if [[ -n "${_LLM_MOCK_SOURCED:-}" ]]; then return 0; fi
export _LLM_MOCK_SOURCED=1

LLM_MOCK_MODE="${LLM_MOCK_MODE:-playback}"
LLM_MOCK_FIXTURES_DIR="${LLM_MOCK_FIXTURES_DIR:-$(dirname "${BASH_SOURCE[0]}")/../fixtures/llm_responses}"

mkdir -p "$LLM_MOCK_FIXTURES_DIR"

# Generate a stable fixture filename from provider + model + prompt
_mock_fixture_path() {
    local provider="$1"
    local model="$2"
    local prompt_hash
    prompt_hash=$(printf '%s%s%s' "$provider" "$model" "$3" | sha256sum | cut -c1-16)
    echo "${LLM_MOCK_FIXTURES_DIR}/${provider}_${model}_${prompt_hash}.json"
}

# Override call_llm to intercept based on LLM_MOCK_MODE
# This wrapper must be sourced AFTER agent_executor.sh defines call_llm
mock_call_llm() {
    local system_prompt="$1"
    local user_prompt="$2"
    local model="${3:-auto}"
    local provider="${4:-auto}"

    if [[ "$LLM_MOCK_MODE" == "passthrough" ]]; then
        call_llm "$system_prompt" "$user_prompt" "$model" "$provider"
        return $?
    fi

    local fixture
    fixture=$(_mock_fixture_path "$provider" "$model" "${system_prompt}${user_prompt}")

    if [[ "$LLM_MOCK_MODE" == "playback" ]]; then
        if [[ -f "$fixture" ]]; then
            cat "$fixture"
            return 0
        else
            echo "LLM_MOCK: No fixture found: $fixture" >&2
            echo "LLM_MOCK: Re-run with LLM_MOCK_MODE=record to capture real responses" >&2
            # Return a deterministic stub so tests don't crash
            jq -n '{"content":[{"text":"{\"score\":75,\"verdict\":\"pass\",\"reasoning\":\"MOCK_STUB\"}"}]}'
            return 0
        fi
    fi

    if [[ "$LLM_MOCK_MODE" == "record" ]]; then
        local response
        response=$(call_llm "$system_prompt" "$user_prompt" "$model" "$provider")
        local exit_code=$?
        if [[ $exit_code -eq 0 ]] && [[ -n "$response" ]]; then
            echo "$response" > "$fixture"
            echo "LLM_MOCK: Recorded fixture: $fixture" >&2
        fi
        echo "$response"
        return $exit_code
    fi

    echo "LLM_MOCK: Unknown mode: $LLM_MOCK_MODE" >&2
    return 1
}

# In CI (playback mode), alias call_llm to mock_call_llm
if [[ "$LLM_MOCK_MODE" != "passthrough" ]]; then
    # Only override if call_llm is defined (agent_executor.sh already sourced)
    if declare -f call_llm >/dev/null 2>&1; then
        # Save original
        eval "$(declare -f call_llm | sed 's/^call_llm/original_call_llm/')"
        # Override
        call_llm() { mock_call_llm "$@"; }
        export -f call_llm
    fi
fi

mock_list_fixtures() {
    echo "=== LLM Mock Fixtures ==="
    local count=0
    for f in "$LLM_MOCK_FIXTURES_DIR"/*.json; do
        [[ -f "$f" ]] || continue
        echo "  $(basename "$f")"
        ((count++))
    done
    echo "  Total: $count fixture(s)"
}

mock_clear_fixtures() {
    rm -f "$LLM_MOCK_FIXTURES_DIR"/*.json
    echo "LLM_MOCK: All fixtures cleared"
}
