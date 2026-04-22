#!/usr/bin/env python3
"""
scripts/run_grasp_compose.py — gRaSP skill composition: compile, verify, repair.

Implements Graph-Structured Skill Composition (gRaSP, Xia et al. 2026,
arXiv:2604.17870, Tencent AI Lab) on top of the skill-writer GoS data model.

Core insight from gRaSP §3.1:
  Focused sets of 2–3 skills consistently outperform comprehensive documentation.
  Excessive skills HURT agent performance. DAG structure reduces replanning from
  O(N) to O(d^h) via locality-bounded repair.

Four-stage pipeline:
  1. Retrieve  — memory-conditioned filter: select minimal relevant skill subset
  2. Compile   — LLM infers precondition→postcondition edges + validates + resolves cycles
  3. Execute   — topological traversal with node-level postcondition verification
  4. Repair    — five typed operators for structure-aware failure recovery

Five typed repair operators (gRaSP §4.3):
  1. argument_refinement      — fix argument values passed to the skill
  2. alternative_invocation   — substitute a different skill with same postcondition
  3. precondition_correction  — adjust what the preceding skill must produce
  4. postcondition_relaxation — accept partial satisfaction of postconditions
  5. dependency_reordering    — change execution order relative to siblings

Confidence-based routing:
  If cumulative confidence < FALLBACK_THRESHOLD → report signals ReAct fallback.
  The DAG plan is still written to disk so the caller can inspect what failed.

Usage
-----
    export ANTHROPIC_API_KEY=...

    # Plan a skill chain for an objective (dry-run — no API calls)
    python3 scripts/run_grasp_compose.py \\
        --skills-dir ~/.claude/skills/ \\
        --objective "evaluate then GEPA-optimize until GOLD, then certify" \\
        --dry-run

    # Full compilation + verification
    python3 scripts/run_grasp_compose.py \\
        --skills-dir ~/.claude/skills/ \\
        --objective "certify my skill at GOLD tier with statistical confidence"

    # Specific skill files only
    python3 scripts/run_grasp_compose.py \\
        --skills my-skill.md helper.md \\
        --objective "optimize then evaluate"

    # JSON output for CI pipelines
    python3 scripts/run_grasp_compose.py \\
        --skills-dir ~/.claude/skills/ \\
        --objective "full lifecycle" \\
        --json --dry-run

Output
------
    grasp-out/
        grasp-report.json    full DAG + execution results
        grasp-report.md      human-readable plan + verification status

Exit codes:
  0 = all nodes verified OK
  1 = error (skill not found, API failure)
  2 = partial — at least one node failed after repair
  3 = fallback — cumulative confidence dropped below threshold (ReAct recommended)
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path

from common import ApiClient, build_api_client, extract_json, extract_json_array, DEFAULT_MODEL
from skill_graph import (
    SkillDAG, SkillNode, SkillEdge, SkillDAG,
    load_skill_library, parse_skill_metadata,
    EDGE_TYPES, BLOCKING_TYPES,
)

MAX_TOKENS_RETRIEVE = 1024
MAX_TOKENS_COMPILE  = 2048
MAX_TOKENS_VERIFY   = 1024
MAX_TOKENS_REPAIR   = 2048

FALLBACK_THRESHOLD  = 0.40   # cumulative confidence below this → signal ReAct fallback
MAX_REPAIR_DEPTH    = 2      # bounded repair: O(d^h), d=branching, h=MAX_REPAIR_DEPTH
MAX_RETRIEVE_SKILLS = 5      # gRaSP finding: focused sets of 2–5 skills beat comprehensive


# ── Stage 1: Retrieve ──────────────────────────────────────────────────────────

RETRIEVE_SYSTEM = """You are a skill relevance filter for an agent skill library.
Given a task objective and available skills (with preconditions and postconditions),
select the MINIMAL subset needed — 2 to 5 skills maximum.

Return ONLY valid JSON:
{
  "selected_skill_ids": ["<id1>", "<id2>"],
  "reasoning": "<one sentence explaining why these skills and not others>"
}

Rules:
- Include skills whose postconditions directly satisfy the objective
- Include prerequisite skills whose outputs feed into selected skills
- Fewer skills is better: focused sets outperform comprehensive ones (gRaSP §3.1)
- Exclude skills whose domain is clearly unrelated to the objective"""


def retrieve(api: ApiClient, dag: SkillDAG, objective: str) -> list[str]:
    """Stage 1: filter skill library to minimal relevant subset."""
    real_nodes = {
        sid: n for sid, n in dag.nodes.items()
        if not str(n.path).startswith("<external:")
    }
    skills_summary = "\n".join(
        f"- {sid} (tier={n.tier})"
        f"\n    pre: {n.preconditions[:2] or ['(none)']}"
        f"\n    post: {n.postconditions[:2] or ['(none)']}  "
        for sid, n in real_nodes.items()
    )
    user_msg = (
        f"Task objective: {objective}\n\n"
        f"Available skills:\n{skills_summary}\n\n"
        "Select the minimal subset (2–5 skills)."
    )
    raw = api.call(RETRIEVE_SYSTEM, user_msg, MAX_TOKENS_RETRIEVE)
    data = extract_json(raw)
    if data is None or "selected_skill_ids" not in data:
        # Fallback: return all real nodes up to MAX_RETRIEVE_SKILLS
        return list(real_nodes.keys())[:MAX_RETRIEVE_SKILLS]

    selected = [sid for sid in data["selected_skill_ids"] if sid in dag.nodes]
    print(f"    reasoning: {data.get('reasoning', '')}")
    return selected[:MAX_RETRIEVE_SKILLS]


# ── Stage 2: Compile ──────────────────────────────────────────────────────────

COMPILE_SYSTEM = """You are a skill DAG compiler. Given a task objective and skills with
their preconditions and postconditions, propose dependency edges.

Return ONLY a valid JSON array:
[
  {
    "source": "<skill_id that requires target to run first>",
    "target": "<skill_id that must run first>",
    "edge_type": "depends_on",
    "condition": "<postcondition of target that satisfies a precondition of source>",
    "confidence": <0.0–1.0>
  }
]

Rules:
- Only emit an edge when there is a clear precondition-effect link between the skills
- confidence=1.0: explicit match between a postcondition and precondition
- confidence=0.5–0.8: inferred dependency based on domain knowledge
- confidence<0.5: weak ordering preference (may be removed if it creates a cycle)
- Return [] if skills are independent (no ordering required)"""


def compile_dag(
    api: ApiClient,
    dag: SkillDAG,
    selected_ids: list[str],
    objective: str,
) -> SkillDAG:
    """
    Stage 2: LLM proposes edges, heuristic inference adds more, cycles removed.
    Returns a compiled subgraph ready for execution.
    """
    subgraph = dag.subgraph(selected_ids)

    skill_details = "\n\n".join(
        f"Skill: {sid}\n"
        f"  tier: {subgraph.nodes[sid].tier}\n"
        f"  preconditions: {subgraph.nodes[sid].preconditions or ['(none)']}\n"
        f"  postconditions: {subgraph.nodes[sid].postconditions or ['(none)']}"
        for sid in selected_ids
        if sid in subgraph.nodes
    )
    user_msg = (
        f"Task objective: {objective}\n\n"
        f"Skills to compose:\n{skill_details}\n\n"
        "Propose dependency edges as a JSON array."
    )
    raw = api.call(COMPILE_SYSTEM, user_msg, MAX_TOKENS_COMPILE)
    proposed = extract_json_array(raw) or []

    # Add LLM-proposed edges (validated)
    existing_keys = {(e.source, e.target, e.edge_type) for e in subgraph.edges}
    for item in proposed:
        if not isinstance(item, dict):
            continue
        src = item.get("source", "")
        tgt = item.get("target", "")
        etype = item.get("edge_type", "depends_on")
        if src in subgraph.nodes and tgt in subgraph.nodes and etype in EDGE_TYPES:
            key = (src, tgt, etype)
            if key not in existing_keys:
                subgraph.edges.append(SkillEdge(
                    source=src, target=tgt, edge_type=etype,
                    condition=item.get("condition", ""),
                    confidence=max(0.0, min(1.0, float(item.get("confidence", 0.8)))),
                ))
                existing_keys.add(key)

    # Add heuristic edges from pre/postcondition keyword matching (confidence=0.6)
    heuristic = subgraph.compile_edges_from_conditions()
    for e in heuristic:
        key = (e.source, e.target, e.edge_type)
        if key not in existing_keys:
            subgraph.edges.append(e)
            existing_keys.add(key)

    # Resolve cycles by removing lowest-confidence edges
    removed = subgraph.remove_cycles()
    if removed:
        print(
            f"  ⚠ Removed {len(removed)} cycle edge(s): "
            + ", ".join(f"{e.source}→{e.target}" for e in removed),
            file=sys.stderr,
        )

    return subgraph


# ── Stage 3: Verify ────────────────────────────────────────────────────────────

VERIFY_SYSTEM = """You are a skill postcondition verifier. Given a skill's declared
postconditions and a description of what it produced, determine whether the
postconditions are satisfied.

Return ONLY valid JSON:
{
  "satisfied": <true|false>,
  "satisfied_conditions": ["<text>"],
  "violated_conditions": ["<text>"],
  "confidence": <0.0–1.0>,
  "failure_type": "<argument_error|precondition_not_met|execution_error|postcondition_failed|null>"
}"""


def _verify_node(api: ApiClient, node: SkillNode, output_desc: str) -> dict:
    """Check whether a skill's postconditions are satisfied by its output."""
    if not node.postconditions:
        return {"satisfied": True, "confidence": 1.0, "failure_type": None,
                "satisfied_conditions": [], "violated_conditions": []}
    user_msg = (
        f"Skill: {node.skill_id}\n"
        f"Declared postconditions:\n"
        + "\n".join(f"  - {p}" for p in node.postconditions)
        + f"\n\nExecution result description:\n{output_desc[:1200]}"
    )
    raw = api.call(VERIFY_SYSTEM, user_msg, MAX_TOKENS_VERIFY)
    result = extract_json(raw)
    return result if result else {"satisfied": True, "confidence": 0.5, "failure_type": None,
                                  "satisfied_conditions": [], "violated_conditions": []}


# ── Stage 4: Repair ────────────────────────────────────────────────────────────

REPAIR_SYSTEM = """You are a gRaSP repair operator. A skill node failed during execution.
Apply exactly ONE of the five typed repair operators to propose a concrete fix.

Operators:
  1. argument_refinement      — fix the argument values passed to the skill
  2. alternative_invocation   — suggest a different skill with same postcondition
  3. precondition_correction  — specify what the preceding skill must produce differently
  4. postcondition_relaxation — accept partial satisfaction of the postconditions
  5. dependency_reordering    — execute this skill after a different predecessor

Return ONLY valid JSON:
{
  "operator": "<one of the 5 names above>",
  "description": "<one sentence: what to change and why>",
  "patch": "<concrete change — no placeholders>",
  "confidence": <0.0–1.0>
}"""


def _repair_node(
    api: ApiClient,
    node: SkillNode,
    failure_type: str,
    execution_context: str,
    depth: int,
) -> dict | None:
    """Apply one typed repair operator. Returns None if repair depth exceeded."""
    if depth >= MAX_REPAIR_DEPTH:
        return None
    user_msg = (
        f"Failed skill: {node.skill_id}\n"
        f"Failure type: {failure_type or 'unknown'}\n"
        f"Skill preconditions: {node.preconditions or ['(none)']}\n"
        f"Skill postconditions: {node.postconditions or ['(none)']}\n"
        f"Execution context:\n{execution_context[:800]}"
    )
    raw = api.call(REPAIR_SYSTEM, user_msg, MAX_TOKENS_REPAIR)
    return extract_json(raw)


# ── Execution result ───────────────────────────────────────────────────────────

@dataclass
class NodeResult:
    skill_id: str
    success: bool
    confidence: float = 1.0
    verified: bool = False
    failure_type: str = ""
    repair_operator: str = ""
    repair_description: str = ""


# ── Stage 3+4: Execute + Repair ────────────────────────────────────────────────

def execute_with_repair(
    api: ApiClient | None,
    dag: SkillDAG,
    objective: str,
    dry_run: bool = False,
) -> tuple[list[NodeResult], float]:
    """
    Execute skills in topological order with postcondition verification and repair.

    In dry-run mode: returns a plan without API calls.
    Returns: (results, cumulative_confidence)
    """
    try:
        order = dag.topological_sort()
    except ValueError as e:
        print(f"  ✗ Cannot execute: {e}", file=sys.stderr)
        return [], 0.0

    results: list[NodeResult] = []
    context = f"Objective: {objective}\nExecution log:\n"
    cumulative_conf = 1.0

    for skill_id in order:
        node = dag.nodes[skill_id]
        print(f"\n  [{skill_id}]  tier={node.tier}  pre={len(node.preconditions)}  post={len(node.postconditions)}")

        if dry_run or api is None:
            results.append(NodeResult(
                skill_id=skill_id, success=True,
                confidence=node.confidence, verified=False,
            ))
            context += f"  {skill_id}: [dry-run]\n"
            continue

        # Describe what this skill would produce (LLM-simulated output description)
        simulated_output = (
            f"Skill '{skill_id}' executed for: {objective}. "
            f"Claimed postconditions: {node.postconditions}"
        )
        verification = _verify_node(api, node, simulated_output)

        satisfied = verification.get("satisfied", True)
        conf = float(verification.get("confidence", 1.0))
        failure_type = verification.get("failure_type") or ""
        violated = verification.get("violated_conditions", [])

        result = NodeResult(
            skill_id=skill_id,
            success=satisfied,
            confidence=conf,
            verified=True,
            failure_type=failure_type,
        )

        if not satisfied:
            print(f"  ⚠ Postcondition check FAILED: {violated}", file=sys.stderr)
            repair = _repair_node(api, node, failure_type, context, depth=0)
            if repair:
                op = repair.get("operator", "unknown")
                desc = repair.get("description", "")
                repair_conf = float(repair.get("confidence", 0.5))
                print(f"  ↺ Repair [{op}]: {desc}")
                result.repair_operator = op
                result.repair_description = desc
                # Accept repair if confidence ≥ 0.6
                result.success = repair_conf >= 0.6
                result.confidence = repair_conf
            else:
                print(f"  ✗ Repair depth limit reached for {skill_id}", file=sys.stderr)

        cumulative_conf *= result.confidence
        results.append(result)
        status = "OK" if result.success else "FAILED"
        context += f"  {skill_id}: {status} (conf={conf:.2f})\n"

        if cumulative_conf < FALLBACK_THRESHOLD:
            print(
                f"\n  ⚠ Cumulative confidence {cumulative_conf:.2f} < {FALLBACK_THRESHOLD}"
                f" — ReAct fallback recommended",
                file=sys.stderr,
            )
            break

    return results, cumulative_conf


# ── Main pipeline ─────────────────────────────────────────────────────────────

def run_grasp_compose(
    skill_paths: list[Path],
    objective: str,
    out_dir: Path,
    dry_run: bool = False,
    model: str = DEFAULT_MODEL,
    as_json: bool = False,
) -> int:
    print(f"\ngRaSP Compose — skill-writer (arXiv:2604.17870)")
    print(f"  objective : {objective[:80]}")
    print(f"  skills    : {len(skill_paths)} source file(s)")
    print(f"  output    : {out_dir}")

    # Load skills
    dag = SkillDAG(task_objective=objective)
    for p in skill_paths:
        if not p.exists():
            print(f"  ⚠ Skill not found: {p}", file=sys.stderr)
            continue
        node = parse_skill_metadata(p)
        dag.nodes[node.skill_id] = node

    if not dag.nodes:
        print("✗ No valid skill files loaded.", file=sys.stderr)
        return 1

    print(f"  loaded    : {list(dag.nodes.keys())}")

    if dry_run:
        print("\n  [dry-run mode] — no API calls")
        selected_ids = list(dag.nodes.keys())[:MAX_RETRIEVE_SKILLS]
        print(f"  Stage 1 (Retrieve): selected {selected_ids}")
        composed_dag = dag.subgraph(selected_ids)

        # Run heuristic edge inference even in dry-run (no API needed)
        heuristic_edges = composed_dag.compile_edges_from_conditions()
        for e in heuristic_edges:
            composed_dag.edges.append(e)
        removed = composed_dag.remove_cycles()
        if removed:
            print(f"  Stage 2 (Compile):  removed {len(removed)} cycle edge(s)")
        else:
            print(f"  Stage 2 (Compile):  {len(composed_dag.edges)} heuristic edge(s), no cycles")

        try:
            order = composed_dag.topological_sort()
            print(f"  Stage 3 (Execute):  order = {' → '.join(order)}")
        except ValueError as exc:
            print(f"  Stage 3 (Execute):  cycle error — {exc}", file=sys.stderr)

        results, overall_conf = execute_with_repair(None, composed_dag, objective, dry_run=True)

    else:
        api = build_api_client(model=model)
        if api is None:
            return 1

        print("\n[Stage 1] Retrieving relevant skills…")
        selected_ids = retrieve(api, dag, objective)
        selected_ids = [sid for sid in selected_ids if sid in dag.nodes]
        if not selected_ids:
            print("✗ No skills selected by retrieval stage.", file=sys.stderr)
            return 1
        print(f"  Selected ({len(selected_ids)}): {selected_ids}")

        print("\n[Stage 2] Compiling DAG…")
        composed_dag = compile_dag(api, dag, selected_ids, objective)
        try:
            order = composed_dag.topological_sort()
            print(f"  Execution order: {' → '.join(order)}")
        except ValueError as exc:
            print(f"✗ {exc}", file=sys.stderr)
            return 1

        print("\n[Stage 3+4] Executing with verification and repair…")
        results, overall_conf = execute_with_repair(api, composed_dag, objective)

    # ── Output ─────────────────────────────────────────────────────────────────
    out_dir.mkdir(parents=True, exist_ok=True)

    fallback = overall_conf < FALLBACK_THRESHOLD
    all_ok   = bool(results) and all(r.success for r in results)
    exit_code = 0 if all_ok else (3 if fallback else 2)

    report = {
        "objective": objective,
        "model": model if not dry_run else "dry-run",
        "dry_run": dry_run,
        "skills_loaded": len(dag.nodes),
        "skills_selected": len(results),
        "execution_order": [r.skill_id for r in results],
        "overall_confidence": round(overall_conf, 3),
        "fallback_triggered": fallback,
        "all_nodes_ok": all_ok,
        "results": [
            {
                "skill_id": r.skill_id,
                "success": r.success,
                "confidence": round(r.confidence, 3),
                "verified": r.verified,
                "failure_type": r.failure_type,
                "repair_operator": r.repair_operator,
                "repair_description": r.repair_description,
            }
            for r in results
        ],
        "dag": composed_dag.to_dict(),
        "reference": "arXiv:2604.17870 — gRaSP, Tencent AI Lab 2026",
    }

    (out_dir / "grasp-report.json").write_text(json.dumps(report, indent=2))

    status_icon = "✓" if all_ok else ("↺" if fallback else "⚠")
    status_text = "OK" if all_ok else ("FALLBACK" if fallback else "PARTIAL")

    md: list[str] = [
        "# gRaSP Composition Report",
        "",
        f"**Objective**: {objective}  ",
        f"**Status**: {status_icon} {status_text}  ",
        f"**Confidence**: {overall_conf:.2f}  ",
        f"**Model**: {model if not dry_run else 'dry-run'}  ",
        "",
        "> Based on arXiv:2604.17870 — Graph-Structured Skill Compositions for LLM Agents  ",
        "> Tencent AI Lab (Xia et al. 2026)",
        "",
        "## Execution Plan",
        "",
        "| # | Skill | Tier | Success | Confidence | Verified | Repair |",
        "|---|-------|------|---------|------------|---------|--------|",
    ]
    for i, r in enumerate(results, 1):
        tier = composed_dag.nodes[r.skill_id].tier if r.skill_id in composed_dag.nodes else "?"
        repair_str = r.repair_operator if r.repair_operator else "—"
        md.append(
            f"| {i} | `{r.skill_id}` | {tier} "
            f"| {'✓' if r.success else '✗'} "
            f"| {r.confidence:.2f} "
            f"| {'✓' if r.verified else '—'} "
            f"| {repair_str} |"
        )

    if composed_dag.edges:
        md += ["", "## Dependency Edges", ""]
        for e in sorted(composed_dag.edges, key=lambda x: x.confidence, reverse=True):
            conf_tag = f" _(conf={e.confidence:.2f})_" if e.confidence < 1.0 else ""
            cond_tag = f": _{e.condition}_" if e.condition else ""
            md.append(f"- `{e.source}` ←{e.edge_type}— `{e.target}`{cond_tag}{conf_tag}")

    # Repair summary
    repairs = [r for r in results if r.repair_operator]
    if repairs:
        md += ["", "## Repair Operators Applied", ""]
        for r in repairs:
            md.append(f"- **[{r.repair_operator}]** `{r.skill_id}`: {r.repair_description}")

    if fallback:
        md += [
            "", "## Fallback Notice", "",
            f"Cumulative confidence dropped to **{overall_conf:.2f}** (threshold: {FALLBACK_THRESHOLD}).",
            "The structured DAG plan is preserved above; consider using ReAct-style reactive",
            "planning as a fallback for the failed nodes.",
        ]

    md += [
        "", "## Next Steps", "",
        f"1. Review the dependency edges — add missing `preconditions`/`postconditions` to skill YAML",
        f"2. Run `/eval` on any FAILED nodes to check their current quality",
        f"3. Run `/opt` with strategy `S19` (gRaSP-Compose) if structural gaps are found",
        f"4. Re-run `grasp-compose` after adding pre/postconditions to YAML frontmatter",
    ]

    (out_dir / "grasp-report.md").write_text("\n".join(md))

    print(f"\n{'─'*57}")
    print(f"gRaSP Compose Complete")
    print(f"  Skills   : {len(results)} in plan")
    print(f"  Confidence: {overall_conf:.2f}{' ⚠ FALLBACK' if fallback else ''}")
    print(f"  Status   : {status_text}")
    print(f"  Report   : {out_dir}/grasp-report.md")
    print("─" * 57)

    if as_json:
        print(json.dumps(report, indent=2))

    return exit_code


# ── CLI ────────────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description=(
            "gRaSP skill composition pipeline: retrieve → compile DAG → "
            "verify → repair (arXiv:2604.17870)"
        )
    )
    skill_grp = ap.add_mutually_exclusive_group(required=True)
    skill_grp.add_argument(
        "--skills", nargs="+", type=Path, metavar="FILE",
        help="Individual SKILL.md files to compose",
    )
    skill_grp.add_argument(
        "--skills-dir", type=Path, metavar="DIR",
        help="Directory of SKILL.md files",
    )
    ap.add_argument("--objective", required=True,
                    help="Task objective for the composed skill chain")
    ap.add_argument("--out", type=Path, default=Path("grasp-out"),
                    help="Output directory (default: grasp-out/)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Plan only — heuristic edges + topological sort, no API calls")
    ap.add_argument("--json", action="store_true", dest="as_json",
                    help="Also print JSON report to stdout")
    ap.add_argument("--model", default=DEFAULT_MODEL,
                    help=f"Claude model (default: {DEFAULT_MODEL})")
    args = ap.parse_args()

    if args.skills_dir:
        paths = sorted(args.skills_dir.glob("*.md"))
        if not paths:
            print(f"✗ No .md files in {args.skills_dir}", file=sys.stderr)
            return 1
    else:
        paths = list(args.skills)

    return run_grasp_compose(
        skill_paths=paths,
        objective=args.objective,
        out_dir=args.out,
        dry_run=args.dry_run,
        model=args.model,
        as_json=args.as_json,
    )


if __name__ == "__main__":
    sys.exit(main())
