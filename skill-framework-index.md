# skill-framework.md — Navigation Index

> **Purpose**: Lightweight TOC + loader map for the canonical `skill-framework.md`.
> **Status**: v3.5.0 introduces this index so readers (human and LLM) can
>   navigate the 2772-line framework doc without loading all of it into context.
>   This is the first step toward the v3.6.0 split into meta-skill.md (core,
>   ≤500 lines) + per-mode companion files.
> **Load strategy**: LLMs SHOULD read this index first, then fetch only the
>   specific §N section they need via Read with `offset=...` and a small
>   `limit=...`.

---

## §0  How to use this index

Every section of `skill-framework.md` is listed below with:

1. **Line range** (start line from v3.5.0; may drift slightly after edits — grep `^## §N` to confirm)
2. **Load trigger** — when an LLM/human SHOULD fetch this section
3. **External ref** — which `refs/*.md` file holds the deep spec (if any)

If you're answering a user question, skim this index, decide which one or two
sections apply, and `Read(path, offset=START, limit=120)` only those. This
preserves ~80% of your context window vs. reading the whole file.

---

## §1  Table of Contents

| §  | Title | Lines | Load when... | External ref |
|----|-------|-------|---|---|
| §0 | Quick Start — 5 Common Workflows | 113–260 | User asks "how do I start" | README.md |
| §1 | Identity | 261–292 | First-time orientation | — |
| §2 | Negative Boundaries | 293–321 | User asks "what isn't this for" | — |
| §3 | Mode Router | 322–522 | Before dispatching any user intent | — |
| §4 | Graceful Degradation | 523–566 | When [EXTENDED] feature absent | — |
| §5 | LoongFlow Orchestration | 567–661 | Multi-mode pipeline planning | `refs/self-review.md` |
| §6 | CREATE Mode | 662–815 | User wants to author a new skill | `templates/*.md` |
| §7 | LEAN Mode | 816–990 | Fast triage (≤5s) | `eval/rubrics.md §10` |
| §8 | Inversion — Requirement Elicitation | 991–1061 | CREATE mode Q&A phase | — |
| §9 | EVALUATE Mode — 4-Phase Pipeline | 1062–1158 | Full certification | `eval/rubrics.md` |
| §10 | OPTIMIZE Mode — Dimension Loop | 1159–1389 | Iterative improvement | `optimize/strategies.md`, `refs/convergence.md` |
| §11 | Self-Evolution (3-Trigger System) | 1390–1410 | Usage-based auto-improvement | `refs/evolution.md` |
| §12 | Security | 1411–1450 | Threat model + scan baseline | `refs/security-patterns.md`, `docs/supply-chain-security.md` |
| §13 | Self-Review Protocol | 1451–1466 | Generator-bias mitigation | `refs/self-review.md` |
| §14 | Audit Trail | 1467–1506 | `[EXTENDED]` persistence | — |
| §15 | Usage Examples | 1507–1598 | Demo scripts | `examples/` |
| §16 | UTE Injection | 1599–1662 | Use-to-Evolve bootstrap | `refs/use-to-evolve.md` |
| §17 | INSTALL Mode | 1663–2036 | Install + platform routing | `install.sh` |
| §17b | MCP Integration Guide | 2037–2280 | Claude Code MCP hook | `experimental/mcp-integration.md` |
| §18 | Memory Architecture | 2281–2340 | `[EXTENDED]` backend design | — |
| §19 | COLLECT + AGGREGATE Mode | 2341–2625 | Session Artifact pipeline | `refs/session-artifact.md` |
| §20 | GRAPH Mode (v3.2.0) | 2626–end | Skill graph operations | `refs/skill-graph.md` |

---

## §2  Progressive disclosure per mode

The following table tells a reader/LLM which sections + ref files to load for
each mode. For most tasks, 2–4 sections of ≤200 lines each is sufficient.

| Mode     | Required sections | Optional refs |
|----------|--------------------|---------------|
| CREATE   | §6, §8             | `templates/base.md` (or api/data/workflow variant) |
| LEAN     | §7                 | `eval/rubrics.md §10` |
| EVALUATE | §9                 | `eval/rubrics.md` full, `eval/benchmarks.md` |
| OPTIMIZE | §10                | `optimize/strategies.md`, `refs/convergence.md`, `refs/self-review.md` |
| INSTALL  | §17                | `install.sh`, `spec/agent-skills-compat.md` |
| SHARE    | §19 (part)         | `refs/skill-registry.md`, `docs/supply-chain-security.md` |
| COLLECT  | §19                | `refs/session-artifact.md` |
| GRAPH    | §20                | `refs/skill-graph.md` |

---

## §3  Minimum-viable orientation (< 60 lines to read)

For an LLM entering cold with no prior context, read **only**:

1. `skill-framework.md §1` (Identity — 32 lines)
2. `skill-framework.md §3` (Mode Router — skim headers, ~40 lines)
3. This index

That's enough to dispatch any request correctly. Depth comes from the referenced
refs/*.md files, loaded on demand.

---

## §4  v3.6.0 split plan

In v3.6.0 `skill-framework.md` will be refactored into:

| Future file                  | Content |
|------------------------------|---|
| `meta-skill.md`              | Identity, Mode Router, Quick Start (§§1, 3, 0) — ≤500 lines |
| `refs/modes/create.md`       | §§6, 8 + CREATE-specific details |
| `refs/modes/evaluate.md`     | §9 (was already partly in eval/) |
| `refs/modes/optimize.md`     | §10 (was already partly in optimize/) |
| `refs/modes/install.md`      | §§17, 17b |
| `refs/modes/collect.md`      | §19 |
| `refs/modes/graph.md`        | §20 |
| `refs/memory-architecture.md`| §18 |
| `refs/audit-trail.md`        | §14 |

Until then, treat this index as the navigation layer. The canonical file
remains `skill-framework.md` for now.
