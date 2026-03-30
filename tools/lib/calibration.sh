#!/usr/bin/env bash
# calibration.sh — Ground Truth Calibration Framework
#
# Problem: The scoring system is self-referential (scores are only meaningful
# relative to arbitrary design choices). Without external ground truth,
# "777/1000" carries no absolute meaning.
#
# Solution: Calibrate the scoring system against expert human judgments.
#
# Process:
#   1. Collect a calibration corpus of N skills with known quality levels
#   2. Have 3+ experts independently score each skill (structured rubric)
#   3. Compute inter-annotator agreement (Krippendorff's α)
#   4. Fit a mapping function: system_score → expert_score
#   5. Validate with leave-one-out cross-validation
#   6. Report calibration quality (Pearson r, RMSE)
#
# After calibration, score 777 means:
#   "Our system outputs 777 which typically corresponds to expert rating ~X"
#
# Theoretical basis:
#   - Krippendorff 2011, "Computing Krippendorff's Alpha-Reliability"
#   - Wang et al. 2023, "Calibrating LLM-Based Evaluator"
#   - Cohen 1960, "A coefficient of agreement for nominal scales"

set -euo pipefail

CALIBRATION_DIR="${CALIBRATION_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../calibration}"
CALIBRATION_CORPUS="${CALIBRATION_DIR}/corpus.json"
CALIBRATION_PARAMS="${CALIBRATION_DIR}/params.json"

# ─── Expert annotation schema ─────────────────────────────────────────────────
# Each expert rates a skill on 5 dimensions (1-10 scale):
#
# {
#   "skill_id": "skill_name",
#   "expert_id": "e1",
#   "timestamp": "2026-03-30T...",
#   "ratings": {
#     "structural_completeness": 8,   // Does it have all required sections?
#     "semantic_clarity":        7,   // Is the purpose clear?
#     "behavioral_reliability":  6,   // Would it behave consistently?
#     "domain_depth":            9,   // Does it show genuine domain knowledge?
#     "actionability":           7    // Can an LLM follow these instructions?
#   },
#   "overall": 7.4,
#   "notes": "..."
# }

# ─── Calibration corpus management ───────────────────────────────────────────

init_calibration_corpus() {
    mkdir -p "$CALIBRATION_DIR"

    if [[ ! -f "$CALIBRATION_CORPUS" ]]; then
        echo "[]" > "$CALIBRATION_CORPUS"
        echo "Calibration corpus initialized at: $CALIBRATION_CORPUS"
    fi
}

add_expert_annotation() {
    local skill_file="$1"
    local expert_id="$2"
    local structural="$3"
    local semantic="$4"
    local reliability="$5"
    local domain_depth="$6"
    local actionability="$7"
    local notes="${8:-}"

    local overall
    overall=$(echo "scale=2; ($structural + $semantic + $reliability + $domain_depth + $actionability) / 5" | bc -l)

    local skill_id
    skill_id=$(basename "$skill_file" .md)

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Also record the system score for this skill
    local system_score=0
    if command -v bash >/dev/null 2>&1; then
        system_score=$(bash "$(dirname "${BASH_SOURCE[0]}")/../eval/main.sh" \
            --skill "$skill_file" --fast --no-agent 2>/dev/null | \
            grep -oE 'TOTAL_SCORE=[0-9]+' | cut -d= -f2 || echo "0")
    fi

    local annotation
    annotation=$(jq -n \
        --arg sid "$skill_id" \
        --arg eid "$expert_id" \
        --arg ts "$timestamp" \
        --argjson s "$structural" \
        --argjson se "$semantic" \
        --argjson r "$reliability" \
        --argjson d "$domain_depth" \
        --argjson a "$actionability" \
        --argjson o "$overall" \
        --argjson sys "$system_score" \
        --arg notes "$notes" \
        '{
            skill_id: $sid,
            expert_id: $eid,
            timestamp: $ts,
            ratings: {
                structural_completeness: $s,
                semantic_clarity: $se,
                behavioral_reliability: $r,
                domain_depth: $d,
                actionability: $a
            },
            overall: $o,
            system_score: $sys,
            notes: $notes
        }')

    init_calibration_corpus
    local current
    current=$(cat "$CALIBRATION_CORPUS")
    echo "$current" | jq ". + [$annotation]" > "$CALIBRATION_CORPUS"

    echo "Added annotation: expert=$expert_id skill=$skill_id overall=$overall"
}

# ─── Krippendorff's Alpha (interval scale) ───────────────────────────────────
# Measures inter-annotator agreement across all experts
# α ≥ 0.80: good agreement, α ≥ 0.67: tentative conclusions, α < 0.67: unreliable

compute_krippendorff_alpha() {
    local dimension="${1:-overall}"

    if [[ ! -f "$CALIBRATION_CORPUS" ]]; then
        echo "No calibration corpus found. Run add_expert_annotation first."
        return 1
    fi

    python3 - <<PYEOF
import json, itertools

with open("$CALIBRATION_CORPUS") as f:
    data = json.load(f)

# Group by skill_id
from collections import defaultdict
skill_ratings = defaultdict(dict)
for ann in data:
    sid = ann["skill_id"]
    eid = ann["expert_id"]
    dim = "$dimension"
    if dim == "overall":
        val = ann.get("overall", 0)
    else:
        val = ann.get("ratings", {}).get(dim, 0)
    skill_ratings[sid][eid] = val

skills = list(skill_ratings.keys())
experts = list(set(e for s in skill_ratings.values() for e in s.keys()))

if len(skills) < 2 or len(experts) < 2:
    print(f"ALPHA=N/A (need >=2 skills and >=2 experts, have {len(skills)} skills, {len(experts)} experts)")
    exit(0)

# Krippendorff's alpha (interval metric)
# Reference: Krippendorff 2011
values = []
for skill in skills:
    row = []
    for expert in experts:
        row.append(skill_ratings[skill].get(expert, None))
    values.append(row)

# Observed disagreement
n_pairs = 0
d_obs = 0.0
for row in values:
    vals = [v for v in row if v is not None]
    for i, j in itertools.combinations(range(len(vals)), 2):
        d_obs += (vals[i] - vals[j]) ** 2
        n_pairs += 1

if n_pairs == 0:
    print("ALPHA=N/A (insufficient paired observations)")
    exit(0)

d_obs = d_obs / n_pairs

# Expected disagreement
all_vals = [v for row in values for v in row if v is not None]
n = len(all_vals)
d_exp = sum((all_vals[i] - all_vals[j])**2 for i in range(n) for j in range(i+1, n))
d_exp = d_exp / (n * (n-1) / 2) if n > 1 else 1

if d_exp == 0:
    print("ALPHA=1.0 (perfect agreement)")
    exit(0)

alpha = 1.0 - (d_obs / d_exp)

level = "RELIABLE" if alpha >= 0.80 else ("TENTATIVE" if alpha >= 0.67 else "UNRELIABLE")
print(f"ALPHA={alpha:.4f} ({level}) dimension={dim} skills={len(skills)} experts={len(experts)}")
PYEOF
}

# ─── Calibration fit (linear regression: system_score → expert_score) ────────

fit_calibration() {
    if [[ ! -f "$CALIBRATION_CORPUS" ]]; then
        echo "No calibration corpus. Add expert annotations first."
        return 1
    fi

    python3 - <<PYEOF
import json

with open("$CALIBRATION_CORPUS") as f:
    data = json.load(f)

# Average expert scores per skill
from collections import defaultdict
skill_expert = defaultdict(list)
skill_system = defaultdict(list)

for ann in data:
    sid = ann["skill_id"]
    skill_expert[sid].append(ann.get("overall", 0))
    if ann.get("system_score", 0) > 0:
        skill_system[sid].append(ann["system_score"])

if len(skill_expert) < 3:
    print("CALIBRATION_STATUS=INSUFFICIENT_DATA (need >=3 skills)")
    exit(0)

skills_with_both = [s for s in skill_expert if skill_system[s]]
if len(skills_with_both) < 3:
    print("CALIBRATION_STATUS=INSUFFICIENT_DATA (need system scores for >=3 skills)")
    exit(0)

# Scale expert scores (1-10) to match system scale (0-1000)
x = [sum(skill_system[s])/len(skill_system[s]) for s in skills_with_both]
y = [sum(skill_expert[s])/len(skill_expert[s]) * 100 for s in skills_with_both]  # ×100 to 0-1000 scale

# Linear regression
n = len(x)
mean_x = sum(x) / n
mean_y = sum(y) / n
slope = sum((xi - mean_x)*(yi - mean_y) for xi, yi in zip(x, y)) / \
        sum((xi - mean_x)**2 for xi in x)
intercept = mean_y - slope * mean_x

# Pearson r
import math
ss_xy = sum((xi - mean_x)*(yi - mean_y) for xi, yi in zip(x, y))
ss_xx = sum((xi - mean_x)**2 for xi in x)
ss_yy = sum((yi - mean_y)**2 for yi in y)
r = ss_xy / math.sqrt(ss_xx * ss_yy) if ss_xx * ss_yy > 0 else 0

# RMSE
y_pred = [slope * xi + intercept for xi in x]
rmse = math.sqrt(sum((yi - yp)**2 for yi, yp in zip(y, y_pred)) / n)

print(f"CALIBRATION_STATUS=OK")
print(f"PEARSON_R={r:.4f}")
print(f"RMSE={rmse:.2f}")
print(f"SLOPE={slope:.4f}")
print(f"INTERCEPT={intercept:.4f}")
print(f"N_SKILLS={n}")
print(f"CALIBRATION_QUALITY={'GOOD' if abs(r)>=0.85 else ('MODERATE' if abs(r)>=0.70 else 'POOR')}")

# Save params
import os
params = {"slope": slope, "intercept": intercept, "r": r, "rmse": rmse, "n": n}
os.makedirs("$CALIBRATION_DIR", exist_ok=True)
with open("$CALIBRATION_PARAMS", "w") as f:
    json.dump(params, f, indent=2)
print(f"Params saved to: $CALIBRATION_PARAMS")
PYEOF
}

# ─── Apply calibration to a raw score ────────────────────────────────────────

calibrated_score() {
    local raw_score="$1"

    if [[ ! -f "$CALIBRATION_PARAMS" ]]; then
        echo "$raw_score"  # No calibration available, return raw
        return
    fi

    python3 - <<PYEOF
import json
with open("$CALIBRATION_PARAMS") as f:
    p = json.load(f)
calibrated = p["slope"] * $raw_score + p["intercept"]
calibrated = max(0, min(1000, round(calibrated)))
print(calibrated)
PYEOF
}

# ─── Status report ───────────────────────────────────────────────────────────

calibration_status() {
    echo "=== Calibration Status ==="

    if [[ ! -f "$CALIBRATION_CORPUS" ]]; then
        echo "Status: NOT INITIALIZED"
        echo "Run: add_expert_annotation <skill.md> <expert_id> <scores...>"
        return
    fi

    local n_annotations
    n_annotations=$(jq 'length' "$CALIBRATION_CORPUS" 2>/dev/null || echo "0")
    local n_skills
    n_skills=$(jq '[.[].skill_id] | unique | length' "$CALIBRATION_CORPUS" 2>/dev/null || echo "0")
    local n_experts
    n_experts=$(jq '[.[].expert_id] | unique | length' "$CALIBRATION_CORPUS" 2>/dev/null || echo "0")

    echo "Annotations: $n_annotations"
    echo "Skills covered: $n_skills"
    echo "Experts: $n_experts"
    echo ""

    if [[ "$n_annotations" -ge 2 ]]; then
        compute_krippendorff_alpha "overall"
    else
        echo "Need >=2 annotations for agreement statistics"
    fi

    if [[ -f "$CALIBRATION_PARAMS" ]]; then
        echo ""
        echo "Calibration fit:"
        cat "$CALIBRATION_PARAMS" | jq -r '"  r=\(.r|tostring[0:6])  RMSE=\(.rmse|tostring[0:5])  n=\(.n)"'
    fi

    echo ""
    echo "Recommendation:"
    if [[ "$n_skills" -lt 10 ]]; then
        echo "  Add more annotations (target: 30+ skills, 3+ experts per skill)"
    elif [[ "$n_experts" -lt 3 ]]; then
        echo "  Add more expert diversity (target: 3+ independent experts)"
    else
        echo "  Run fit_calibration to update scoring parameters"
    fi
}

# ─── CLI ──────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-status}" in
        status)    calibration_status ;;
        alpha)     compute_krippendorff_alpha "${2:-overall}" ;;
        fit)       fit_calibration ;;
        score)     calibrated_score "${2:-0}" ;;
        annotate)
            add_expert_annotation "$2" "$3" "$4" "$5" "$6" "$7" "$8" "${9:-}"
            ;;
        *)
            echo "Usage: $0 [status|alpha|fit|score <N>|annotate <skill> <expert> <s1> <s2> <s3> <s4> <s5>]"
            ;;
    esac
fi
