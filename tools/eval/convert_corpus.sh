#!/usr/bin/env bash
# convert_corpus.sh - Convert corpus format to trigger_analyzer expected format
# Input: corpus JSON with test_cases array
# Output: JSON array with expected_trigger, predicted_triggers, rank fields

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 <input_corpus.json> [output_file]"
    echo "  Converts corpus JSON to trigger_analyzer expected format"
    echo "  If output_file is not specified, outputs to stdout"
    exit 1
}

convert_corpus() {
    local input_file="$1"
    local output_file="${2:-}"

    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file not found: $input_file" >&2
        return 1
    fi

    local total_cases
    total_cases=$(jq '.test_cases | length' "$input_file" 2>/dev/null || echo "0")

    if [[ "$total_cases" -eq 0 ]]; then
        echo "Error: No test_cases found in corpus" >&2
        return 1
    fi

    local converted
    converted=$(jq '[.test_cases[] | {
        expected_trigger: .expected_mode,
        predicted_triggers: [.mode],
        rank: (if .mode == .expected_mode then 1 else 0 end),
        should_trigger: .should_trigger,
        id: .id
    }]' "$input_file")

    if [[ -n "$output_file" ]]; then
        echo "$converted" > "$output_file"
        echo "Converted $total_cases cases to $output_file"
    else
        echo "$converted"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        usage
    fi
    convert_corpus "$@"
fi
