#!/usr/bin/env bash
# semantic_coherence.sh — Embedding-based Semantic Cohesion Scorer
#
# Measures whether all sections of a SKILL.md describe the same semantic topic.
# A high-quality skill should have consistent semantic space across:
#   §1.1 Identity → §1.2 Framework → §3.x Workflow → §4.x Examples
#
# Method:
#   1. Extract text of each major section
#   2. Compute embedding vector for each section (via LLM embedding API)
#   3. Compute mean pairwise cosine similarity → "cohesion score"
#   4. Detect identity drift: distance(§1.1, §4.x) > threshold
#
# Score contribution (Phase 2 extension, 50pts):
#   cohesion ≥ 0.85 → 50pts  (highly consistent)
#   cohesion ≥ 0.70 → 35pts  (mostly consistent)
#   cohesion ≥ 0.55 → 20pts  (some inconsistency)
#   cohesion  < 0.55 → 0pts  (identity drift detected)
#
# Theoretical basis:
#   Sentence-BERT (Reimers & Gurevych 2019)
#   Document cohesion via semantic similarity (Lapata 2003)
#   Identity drift detection analogous to distribution shift in ML models
#
# Fallback: if embedding API unavailable, returns heuristic estimate
# based on overlapping vocabulary between sections (Jaccard similarity)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/agent_executor.sh" 2>/dev/null || true

# ─── Section extraction ───────────────────────────────────────────────────────

extract_section() {
    local skill_file="$1"
    local section_pattern="$2"  # e.g. "§1\.1|1\.1 Identity"

    awk -v pat="$section_pattern" '
        /^#{1,4}[[:space:]]/ {
            if (in_section) { in_section=0 }
            if ($0 ~ pat) { in_section=1; next }
        }
        in_section { print }
    ' "$skill_file" | head -50  # limit to first 50 lines per section
}

extract_all_sections() {
    local skill_file="$1"
    declare -A sections

    sections["identity"]=$(extract_section "$skill_file" "§1\.1|1\.1 Identity|1\.1[[:space:]]")
    sections["framework"]=$(extract_section "$skill_file" "§1\.2|1\.2 Framework|1\.2[[:space:]]")
    sections["workflow"]=$(extract_section "$skill_file" "§3\.|3\.[0-9] |Workflow|workflow")
    sections["examples"]=$(extract_section "$skill_file" "§4\.|4\.[0-9] |Example|example")

    echo "${sections[@]}"
}

# ─── Cosine similarity computation ───────────────────────────────────────────

# Compute cosine similarity between two embedding vectors (JSON arrays)
cosine_similarity() {
    local vec_a="$1"  # JSON array of floats
    local vec_b="$2"

    python3 - <<EOF 2>/dev/null || echo "0.5"
import json, math
a = json.loads('$vec_a')
b = json.loads('$vec_b')
dot = sum(x*y for x,y in zip(a,b))
na = math.sqrt(sum(x*x for x in a))
nb = math.sqrt(sum(x*x for x in b))
if na == 0 or nb == 0:
    print(0.5)
else:
    print(round(dot / (na * nb), 4))
EOF
}

# ─── Embedding API calls ──────────────────────────────────────────────────────

get_embedding_openai() {
    local text="$1"
    local model="${2:-text-embedding-3-small}"

    if [[ -z "${OPENAI_API_KEY:-}" ]]; then return 1; fi

    local escaped_text
    escaped_text=$(echo "$text" | head -c 2000 | jq -Rs '.')

    local response
    response=$(curl -s --max-time 15 https://api.openai.com/v1/embeddings \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$model\",\"input\":$escaped_text}" 2>/dev/null) || return 1

    echo "$response" | jq -c '.data[0].embedding // empty' 2>/dev/null
}

get_embedding_anthropic() {
    # Anthropic doesn't have a public embedding API yet (as of 2026-03).
    # Fallback: use voyage-3 via Anthropic-compatible endpoint if available.
    return 1
}

get_embedding() {
    local text="$1"
    local vec

    vec=$(get_embedding_openai "$text" 2>/dev/null) && echo "$vec" && return 0
    return 1
}

# ─── Heuristic fallback (Jaccard vocabulary overlap) ─────────────────────────

jaccard_similarity() {
    local text_a="$1"
    local text_b="$2"

    # Extract unique significant words (length > 4, lowercase)
    local words_a words_b
    words_a=$(echo "$text_a" | tr '[:upper:]' '[:lower:]' | \
        grep -oE '[a-z]{5,}' | sort -u)
    words_b=$(echo "$text_b" | tr '[:upper:]' '[:lower:]' | \
        grep -oE '[a-z]{5,}' | sort -u)

    local intersection
    intersection=$(comm -12 <(echo "$words_a") <(echo "$words_b") | wc -l | tr -d ' ')

    local union
    union=$(sort -u <(echo "$words_a") <(echo "$words_b") | wc -l | tr -d ' ')

    if [[ "${union:-0}" -eq 0 ]]; then
        echo "0.5"
        return
    fi

    echo "scale=4; $intersection / $union" | bc -l
}

# ─── Mean pairwise cosine similarity ─────────────────────────────────────────

mean_pairwise_similarity() {
    local -n _texts=$1  # nameref to array of text strings
    local use_embeddings="${2:-auto}"

    local n=${#_texts[@]}
    if [[ $n -lt 2 ]]; then
        echo "1.0"  # trivially coherent if only one section
        return
    fi

    # Try embedding API first; fall back to Jaccard
    local embeddings=()
    local use_jaccard=false

    if [[ "$use_embeddings" != "false" ]]; then
        for text in "${_texts[@]}"; do
            local vec
            vec=$(get_embedding "$text" 2>/dev/null) || { use_jaccard=true; break; }
            embeddings+=("$vec")
        done
    else
        use_jaccard=true
    fi

    local total_sim=0
    local pair_count=0

    if ! $use_jaccard && [[ ${#embeddings[@]} -eq $n ]]; then
        # Use cosine similarity on embeddings
        for ((i=0; i<n; i++)); do
            for ((j=i+1; j<n; j++)); do
                local sim
                sim=$(cosine_similarity "${embeddings[$i]}" "${embeddings[$j]}")
                total_sim=$(echo "$total_sim + $sim" | bc -l)
                ((pair_count++))
            done
        done
    else
        # Jaccard fallback
        for ((i=0; i<n; i++)); do
            for ((j=i+1; j<n; j++)); do
                local sim
                sim=$(jaccard_similarity "${_texts[$i]}" "${_texts[$j]}")
                total_sim=$(echo "$total_sim + $sim" | bc -l)
                ((pair_count++))
            done
        done
    fi

    if [[ $pair_count -eq 0 ]]; then echo "1.0"; return; fi
    echo "scale=4; $total_sim / $pair_count" | bc -l
}

# ─── Identity drift detection ─────────────────────────────────────────────────

# Detects if §1.1 Identity and §4.x Examples describe different domains
detect_identity_drift() {
    local identity_text="$1"
    local examples_text="$2"

    if [[ -z "$identity_text" ]] || [[ -z "$examples_text" ]]; then
        echo "UNKNOWN"
        return
    fi

    local sim
    sim=$(jaccard_similarity "$identity_text" "$examples_text")

    local drift
    drift=$(echo "$sim < 0.2" | bc -l)

    if [[ "$drift" -eq 1 ]]; then
        echo "DRIFT_DETECTED(sim=$sim)"
    else
        echo "COHERENT(sim=$sim)"
    fi
}

# ─── Main scorer ──────────────────────────────────────────────────────────────

semantic_coherence_score() {
    local skill_file="$1"

    if [[ ! -f "$skill_file" ]]; then
        echo "Error: File not found: $skill_file" >&2
        return 1
    fi

    # Extract sections
    local sec_identity sec_framework sec_workflow sec_examples
    sec_identity=$(extract_section "$skill_file" "§1\.1|1\.1 Identity|1\.1[[:space:]]")
    sec_framework=$(extract_section "$skill_file" "§1\.2|1\.2 Framework|1\.2[[:space:]]")
    sec_workflow=$(extract_section "$skill_file" "§3\.|3\.[[:digit:]] |[Ww]orkflow")
    sec_examples=$(extract_section "$skill_file" "§4\.|4\.[[:digit:]] |[Ee]xample")

    local sections_found=0
    local texts=()
    [[ -n "$sec_identity" ]]  && { texts+=("$sec_identity");  ((sections_found++)); }
    [[ -n "$sec_framework" ]] && { texts+=("$sec_framework"); ((sections_found++)); }
    [[ -n "$sec_workflow" ]]  && { texts+=("$sec_workflow");  ((sections_found++)); }
    [[ -n "$sec_examples" ]]  && { texts+=("$sec_examples");  ((sections_found++)); }

    if [[ $sections_found -lt 2 ]]; then
        echo "SEMANTIC_COHERENCE: N/A (fewer than 2 sections found)"
        echo "COHESION_SCORE: 0"
        echo "SCORE_CONTRIBUTION: 0/50"
        return 0
    fi

    # Compute mean pairwise similarity
    local cohesion
    cohesion=$(mean_pairwise_similarity texts)

    # Identity drift check
    local drift_status="N/A"
    if [[ -n "$sec_identity" ]] && [[ -n "$sec_examples" ]]; then
        drift_status=$(detect_identity_drift "$sec_identity" "$sec_examples")
    fi

    # Map cohesion to score (50pts max)
    local score
    if [[ $(echo "$cohesion >= 0.85" | bc -l) -eq 1 ]]; then
        score=50
    elif [[ $(echo "$cohesion >= 0.70" | bc -l) -eq 1 ]]; then
        score=35
    elif [[ $(echo "$cohesion >= 0.55" | bc -l) -eq 1 ]]; then
        score=20
    else
        score=0
    fi

    echo "=== Semantic Coherence ==="
    echo "Sections analyzed: $sections_found"
    echo "Mean pairwise similarity: $cohesion"
    echo "Identity drift: $drift_status"
    echo "Score: $score/50"

    # Machine-readable output
    echo "COHESION=$cohesion"
    echo "DRIFT=$drift_status"
    echo "SEMANTIC_SCORE=$score"

    export SEMANTIC_SCORE=$score
    export COHESION_SCORE=$cohesion
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill.md>"
        exit 1
    fi
    semantic_coherence_score "$1"
fi
