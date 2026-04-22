#!/usr/bin/env python3
"""
scripts/skill_graph.py — Graph-of-Skills (GoS) data model and YAML loader.

Implements the typed DAG for skill relationships defined in refs/skill-graph.md,
extended with precondition-effect semantics from gRaSP (arXiv:2604.17870).

Key additions over the existing GoS spec (skill-graph.md §2):
  - SkillNode.preconditions / postconditions — declarative condition strings that
    gRaSP uses to compile edges and verify execution at each node
  - SkillEdge.condition — the specific pre/postcondition that justifies this edge
    (enables structural repair targeting the right condition)
  - SkillDAG.compile_edges_from_conditions() — infers edges from pre/post matching
    (used by run_grasp_compose.py Stage 2)

Used by:
  - scripts/run_grasp_compose.py  (gRaSP composition pipeline)
  - scripts/monitor_skill_drift.py (batch topological ordering)

YAML frontmatter fields parsed:
  Standard GoS (skill-graph.md §2):
    graph.depends_on, graph.composes, graph.similar_to,
    graph.provides, graph.consumes, graph.uses_resource

  gRaSP extension (new):
    preconditions: [string, ...]   — what must hold before the skill executes
    postconditions: [string, ...]  — what the skill guarantees after execution

  Quick-reference example:
    ---
    name: run-multi-eval
    skill_tier: functional
    preconditions:
      - "ANTHROPIC_API_KEY is set"
      - "input skill.md file exists and is valid YAML"
    postconditions:
      - "multi-eval-report.json written to out directory"
      - "median LEAN score and CI computed across N runs"
    graph:
      depends_on:
        - id: "..."
          name: "skill-writer"
          required: false
      provides:
        - "certified-lean-score"
    ---
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path


# Edge types mirror refs/skill-graph.md §2.2
EDGE_TYPES = frozenset({
    "depends_on",    # target must execute before source; hard dependency
    "composes",      # source (planning) orchestrates target (functional/atomic)
    "similar_to",    # functionally equivalent; undirected substitution hint
    "provides_for",  # source output feeds target input (data-flow)
    "consumes_from", # source requires target output (data-flow, reverse of provides_for)
    "uses_resource", # source reads a companion resource managed by target
})

# Blocking edge types — used for topological sort and execution ordering
BLOCKING_TYPES = frozenset({"depends_on", "consumes_from"})


# ── Data model ────────────────────────────────────────────────────────────────

@dataclass
class SkillNode:
    """A single skill in the GoS graph."""
    skill_id: str                          # canonical name from YAML `name:`
    path: Path                             # absolute path to SKILL.md
    tier: str = "functional"               # planning / functional / atomic
    version: str = "unknown"
    certified_lean_score: int = 0

    # gRaSP extension: pre/postcondition semantics
    preconditions: list[str] = field(default_factory=list)
    postconditions: list[str] = field(default_factory=list)

    # GoS metadata
    triggers: list[str] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)
    provides: list[str] = field(default_factory=list)   # data types this skill outputs
    consumes: list[str] = field(default_factory=list)   # data types this skill needs

    # Runtime state (set during gRaSP execution)
    confidence: float = 1.0
    verified: bool = False
    content: str = ""                      # full SKILL.md text, loaded on demand


@dataclass
class SkillEdge:
    """A typed directed edge in the GoS graph."""
    source: str                            # skill_id of the dependent skill
    target: str                            # skill_id of the prerequisite skill
    edge_type: str                         # one of EDGE_TYPES
    condition: str = ""                    # linking pre/postcondition phrase
    confidence: float = 1.0
    required: bool = True
    learned: bool = False                  # True if inferred from UTE execution history


@dataclass
class SkillDAG:
    """Typed directed acyclic graph of skills."""
    nodes: dict[str, SkillNode] = field(default_factory=dict)
    edges: list[SkillEdge] = field(default_factory=list)
    task_objective: str = ""

    # ── Graph queries ──────────────────────────────────────────────────────────

    def predecessors(self, skill_id: str) -> list[str]:
        """Blocking predecessors: skills that must run before skill_id."""
        return [
            e.target for e in self.edges
            if e.source == skill_id and e.edge_type in BLOCKING_TYPES
        ]

    def successors(self, skill_id: str) -> list[str]:
        """Skills that depend on skill_id."""
        return [
            e.source for e in self.edges
            if e.target == skill_id and e.edge_type in BLOCKING_TYPES
        ]

    def topological_sort(self) -> list[str]:
        """
        Kahn's algorithm over blocking edges.
        Returns skill_ids in valid execution order (prerequisites first).
        Raises ValueError if a cycle remains.
        """
        in_degree: dict[str, int] = {sid: 0 for sid in self.nodes}
        for sid in self.nodes:
            for pred in self.predecessors(sid):
                if pred in in_degree:
                    in_degree[sid] += 1

        queue = sorted(sid for sid, deg in in_degree.items() if deg == 0)
        order: list[str] = []
        while queue:
            sid = queue.pop(0)
            order.append(sid)
            for succ in sorted(self.successors(sid)):
                if succ in in_degree:
                    in_degree[succ] -= 1
                    if in_degree[succ] == 0:
                        queue.append(succ)

        if len(order) != len(self.nodes):
            cycles = [sid for sid, deg in in_degree.items() if deg > 0]
            raise ValueError(f"Cycle in SkillDAG after remove_cycles(): {cycles}")
        return order

    def is_dag(self) -> bool:
        try:
            self.topological_sort()
            return True
        except ValueError:
            return False

    def remove_cycles(self) -> list[SkillEdge]:
        """
        Remove lowest-confidence blocking edges until the graph is acyclic.
        Returns the removed edges (logged by caller).
        This mirrors gRaSP §4 DAG compilation cycle resolution.
        """
        removed: list[SkillEdge] = []
        while not self.is_dag():
            blocking = [e for e in self.edges if e.edge_type in BLOCKING_TYPES]
            if not blocking:
                break
            weakest = min(blocking, key=lambda e: e.confidence)
            self.edges.remove(weakest)
            removed.append(weakest)
        return removed

    def subgraph(self, skill_ids: list[str]) -> "SkillDAG":
        """Return a subgraph restricted to the given skill_ids."""
        id_set = set(skill_ids)
        return SkillDAG(
            nodes={sid: n for sid, n in self.nodes.items() if sid in id_set},
            edges=[e for e in self.edges if e.source in id_set and e.target in id_set],
            task_objective=self.task_objective,
        )

    def average_confidence(self) -> float:
        if not self.nodes:
            return 0.0
        return sum(n.confidence for n in self.nodes.values()) / len(self.nodes)

    def compile_edges_from_conditions(self) -> list[SkillEdge]:
        """
        gRaSP Stage 2 heuristic: infer edges by matching postconditions of one skill
        against preconditions of another (no LLM required, lower confidence=0.6).

        Supplements LLM-proposed edges in run_grasp_compose.py.
        Returns the inferred edges (NOT automatically added to self.edges).
        """
        inferred: list[SkillEdge] = []
        node_list = list(self.nodes.values())
        for provider in node_list:
            for consumer in node_list:
                if provider.skill_id == consumer.skill_id:
                    continue
                for post in provider.postconditions:
                    for pre in consumer.preconditions:
                        # Simple substring match on condition keywords
                        post_words = set(post.lower().split())
                        pre_words = set(pre.lower().split())
                        overlap = post_words & pre_words - {"is", "a", "the", "and", "or"}
                        if len(overlap) >= 2:
                            already = any(
                                e.source == consumer.skill_id and e.target == provider.skill_id
                                for e in self.edges
                            )
                            if not already:
                                inferred.append(SkillEdge(
                                    source=consumer.skill_id,
                                    target=provider.skill_id,
                                    edge_type="depends_on",
                                    condition=f"{post!r} → {pre!r}",
                                    confidence=0.6,
                                    learned=False,
                                ))
        return inferred

    def to_dict(self) -> dict:
        return {
            "task_objective": self.task_objective,
            "nodes": [
                {
                    "skill_id": n.skill_id,
                    "path": str(n.path),
                    "tier": n.tier,
                    "version": n.version,
                    "preconditions": n.preconditions,
                    "postconditions": n.postconditions,
                    "provides": n.provides,
                    "consumes": n.consumes,
                    "confidence": n.confidence,
                    "verified": n.verified,
                }
                for n in self.nodes.values()
            ],
            "edges": [
                {
                    "source": e.source,
                    "target": e.target,
                    "type": e.edge_type,
                    "condition": e.condition,
                    "confidence": e.confidence,
                    "required": e.required,
                    "learned": e.learned,
                }
                for e in self.edges
            ],
        }


# ── YAML frontmatter parser ───────────────────────────────────────────────────

def _parse_scalar(fm: str, key: str, default: str = "") -> str:
    m = re.search(rf'^{re.escape(key)}:\s*["\']?([^\n"\']+)["\']?', fm, re.MULTILINE)
    return m.group(1).strip() if m else default


def _parse_list(fm: str, key: str) -> list[str]:
    """Parse a flat YAML list:  key:\\n  - item1\\n  - item2"""
    m = re.search(
        rf'^{re.escape(key)}:\s*\n((?:[ \t]+-[ \t]+.+\n?)*)',
        fm, re.MULTILINE,
    )
    if not m:
        return []
    return [
        re.sub(r'^[ \t]+-[ \t]+', '', line).strip().strip('"').strip("'")
        for line in m.group(1).splitlines()
        if re.match(r'^[ \t]+-', line)
    ]


def _parse_triggers(fm: str) -> list[str]:
    """Parse triggers.en nested list or flat triggers list."""
    # Try triggers:\n  en:\n    - item
    en_block = re.search(
        r'^triggers:\s*\n(?:[ \t]+\w+:\s*\n)*[ \t]+en:\s*\n((?:[ \t]+-[ \t]+.+\n?)*)',
        fm, re.MULTILINE,
    )
    if en_block:
        return [
            re.sub(r'^[ \t]+-[ \t]+', '', line).strip().strip('"').strip("'")
            for line in en_block.group(1).splitlines()
            if re.match(r'^[ \t]+-', line)
        ]
    return _parse_list(fm, "triggers")


def _parse_graph_depends_on(fm: str, source_id: str) -> list[SkillEdge]:
    """Parse graph.depends_on block (existing GoS spec format)."""
    edges: list[SkillEdge] = []
    block = re.search(r'graph:\s*\n((?:  .+\n)*)', fm)
    if not block:
        return edges
    graph_block = block.group(1)
    dep_section = re.search(
        r'  depends_on:\s*\n((?:    .+\n?)*)',
        graph_block,
    )
    if not dep_section:
        return edges
    for line in dep_section.group(1).splitlines():
        name_m = re.search(r'name:\s*["\']?([^"\'\n]+)["\']?', line)
        req_m = re.search(r'required:\s*(true|false)', line)
        if name_m:
            target_id = name_m.group(1).strip()
            required = req_m.group(1) != "false" if req_m else True
            edges.append(SkillEdge(
                source=source_id,
                target=target_id,
                edge_type="depends_on",
                required=required,
                confidence=1.0,
            ))
    return edges


def parse_skill_metadata(skill_path: Path) -> SkillNode:
    """
    Parse YAML frontmatter from a SKILL.md file into a SkillNode.
    Handles both legacy GoS `graph:` blocks and new gRaSP `preconditions:` fields.
    """
    text = skill_path.read_text()
    fm_match = re.match(r'^---\s*\n([\s\S]*?)\n---\s*\n', text)
    fm = fm_match.group(1) if fm_match else ""

    skill_id = _parse_scalar(fm, "name") or skill_path.stem

    lean_raw = _parse_scalar(fm, "certified_lean_score")
    try:
        certified_lean = int(lean_raw) if lean_raw else 0
    except ValueError:
        certified_lean = 0

    return SkillNode(
        skill_id=skill_id,
        path=skill_path.resolve(),
        tier=_parse_scalar(fm, "skill_tier", "functional"),
        version=_parse_scalar(fm, "version", "unknown"),
        certified_lean_score=certified_lean,
        preconditions=_parse_list(fm, "preconditions"),
        postconditions=_parse_list(fm, "postconditions"),
        triggers=_parse_triggers(fm),
        tags=_parse_list(fm, "tags"),
        provides=_parse_list(fm, "provides"),
        consumes=_parse_list(fm, "consumes"),
        content=text,
    )


def load_skill_library(directory: Path) -> SkillDAG:
    """
    Load all *.md files in directory as SkillNodes and build the DAG.

    Parses both:
    - `graph.depends_on` blocks (existing GoS format)
    - `preconditions`/`postconditions` fields (gRaSP extension)

    Stub nodes are added for referenced skills not found in the directory.
    """
    dag = SkillDAG()

    for skill_path in sorted(directory.glob("*.md")):
        node = parse_skill_metadata(skill_path)
        dag.nodes[node.skill_id] = node

    # Parse GoS edges from each skill's frontmatter
    for skill_path in sorted(directory.glob("*.md")):
        text = skill_path.read_text()
        fm_match = re.match(r'^---\s*\n([\s\S]*?)\n---\s*\n', text)
        if not fm_match:
            continue
        fm = fm_match.group(1)
        skill_id = _parse_scalar(fm, "name") or skill_path.stem
        edges = _parse_graph_depends_on(fm, skill_id)
        dag.edges.extend(edges)

    # Add stub nodes for referenced skills not in directory
    referenced = {e.target for e in dag.edges} | {e.source for e in dag.edges}
    for sid in referenced:
        if sid not in dag.nodes:
            dag.nodes[sid] = SkillNode(
                skill_id=sid,
                path=Path(f"<external:{sid}>"),
                tier="unknown",
            )

    return dag
