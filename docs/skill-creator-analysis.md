# skill-writer: Architecture Analysis & Refactoring Guide

> Analysis date: 2026-04-15 | Version: v3.4.0 | Branch: skill-creator-analysis

---

## 1. Executive Summary

This document captures the key design principles of skill-writer, a gap analysis against the Anthropic skills design philosophy, and the rationale behind the v3.3.0 refactoring to a simplified 8-platform direct-file architecture, updated through v3.4.0.

**Key outcome (v3.3.0)**: Removed 2,400+ lines of Node.js build pipeline (builder/), replaced with 8 self-contained platform directories (claude, openclaw, opencode, cursor, gemini, openai, kimi, hermes) — each a direct-usable skill document + companion files + install script. Zero build steps required.

**v3.4.0 additions**: Honest Skill Labeling (`generation_method` + `validation_status` YAML fields), Behavioral Verifier (Phase 4 generator-bias elimination), Pragmatic Test Phase (`/eval --pragmatic`), Failure-Driven CREATE (`--from-failures`), Supply Chain Trust Verification (SHA-256 + trust tiers), GoS Minimum Viable Runtime [CORE], optimization strategies S13/S14, and anti-pattern categories G (auto-generated) + H (supply chain).

---

## 2. Original Architecture (Pre-Refactor)

```
skill-writer/
├── builder/              ← Node.js build pipeline (~2,400 lines)
│   ├── src/
│   │   ├── commands/     ← build, validate, lean, evaluate
│   │   ├── platforms/    ← 7 platform generators (openclaw.js, cursor.js, ...)
│   │   └── sections/     ← platform-specific Markdown snippets
│   ├── bin/skill-writer  ← CLI entry point
│   ├── tests/            ← Jest test suite
│   └── package.json
├── platforms/            ← Build output (generated files, not source)
│   ├── skill-writer-claude.md
│   ├── skill-writer-openclaw.md
│   └── ...
├── skill-framework.md    ← Master specification (source of truth)
├── refs/                 ← Companion reference files
├── templates/            ← Skill creation templates (4 types)
├── eval/                 ← Evaluation rubrics
├── optimize/             ← Optimization strategies
└── install.sh            ← Complex multi-platform installer
```

**Supported platforms**: claude, opencode, openclaw, cursor, gemini, openai, mcp, a2a (8 total)

**Build flow**: `npm run build` → builder reads skill-framework.md → generates platform-specific outputs in platforms/ → install.sh copies from platforms/ to user's system

---

## 3. Problems with the Original Architecture

### 3.1 Unnecessary Build Complexity

The Node.js builder added 2,400+ lines of code for a task that is essentially: "copy Markdown files to platform-specific directories with minor header additions." This violated the principle of minimal complexity.

**Root cause**: The builder was designed for maximum configurability (7 platforms, multiple output formats, per-platform transformations) before the platform set was stable.

### 3.2 Anthropic Alignment Gap

The [Anthropic skills repo](https://github.com/anthropics/skills) uses:
- **Minimal frontmatter**: only `name` + `description` fields
- **No build pipeline**: skills are direct `.md` files, hand-maintained
- **Description-driven triggering**: the `description` field is the primary routing signal
- **File-per-skill**: one skill = one Markdown file, no compilation

skill-writer v3.2.0 had complex frontmatter (20+ fields), a build pipeline, and 8 platform generators — all inconsistent with Anthropic's philosophy.

### 3.3 SKILL.md Spec Conformance Gaps

Gaps found in skill-framework.md against the agentskills.io SKILL.md spec:

| Field | Required | Status (pre-refactor) |
|-------|----------|----------------------|
| `skill_tier` | Required | Missing |
| `triggers.en` (≥3) | Required | Missing |
| `triggers.zh` (≥2) | Required | Missing |
| `use_to_evolve` (11 fields) | Required | Had only 3 fields |
| `## Skill Summary` section | Required | Missing |
| `## §N Negative Boundaries` | Required | Missing |

### 3.4 Progressive Disclosure Violation (Platforms)

Platforms like OpenClaw and Cursor had fewer companion files than Claude, violating the Progressive Disclosure principle: every platform should offer the same depth of capability, with companion files loaded on demand.

---

## 4. Design Principles Extracted

### 4.1 Progressive Disclosure

Skills load context in layers:
- **Layer 0** (frontmatter): Routing metadata — name, description, triggers, skill_tier
- **Layer 1** (skill body): Core behavior — Identity, Negative Boundaries, Mode Router, LoongFlow
- **Layer 2** (refs/ on demand): Deep specs — security-patterns.md, self-review.md, convergence.md
- **Layer 3** (examples/): User-facing examples for bootstrapping

A skill file REFERENCES companion files; it does not embed them. This keeps the skill body scannable while enabling depth.

### 4.2 Negative Boundaries (Anti-Pattern Prevention)

Design heuristic: Negative Boundaries heuristic (2026) — negation reduces false trigger rate significantly when semantically similar requests could mis-trigger a skill.

Required format: ≥3 "Do NOT use for `<scenario>`" entries, each with an alternative skill or escalation path. These prevent skill-writer from being activated for:
- General coding help (use native code assistance)
- Skill evaluation without prior LEAN baseline
- Ad-hoc prompts that don't need lifecycle management

### 4.3 Skill Summary (Routing Optimization)

Design heuristic: Skill Summary heuristic — a large share of router attention (empirical, unpublished) focuses on the skill body (not triggers) for routing. The Skill Summary (≤5 dense sentences encoding WHAT/WHEN/WHO/NOT-FOR) is the decisive routing signal when multiple skills exist in a large pool.

### 4.4 Use-to-Evolve (Self-Improvement Protocol)

11 required YAML fields enable the UTE self-evolution loop:
- `enabled`, `injected_by`, `injected_at` — identity + timestamp
- `check_cadence` — {lightweight: 10, full_recompute: 50, tier_drift: 100}
- `micro_patch_enabled`, `feedback_detection` — capability flags
- `certified_lean_score`, `last_ute_check` — certification state
- `pending_patches`, `total_micro_patches_applied`, `cumulative_invocations` — counters

### 4.5 Three-Tier Skill Hierarchy (three-tier skill hierarchy)

Design heuristic: three-tier skill hierarchy — skills form a planning-functional-atomic hierarchy:
- **planning**: Orchestrates other skills (skill-writer is planning tier)
- **functional**: Reusable subroutine with clear I/O (e.g., lean-eval)
- **atomic**: Single execution-oriented operation (e.g., validate-yaml)

### 4.6 Graph of Skills (Optional)

Design heuristic: typed-dependency Graph of Skills design — typed dependency edges between skills enable:
- Dependency resolution during install
- Bundle retrieval (GRAPH mode)
- D8 Composability scoring (+20 LEAN pts)

---

## 5. New Architecture (Post-Refactor)

```
skill-writer/
├── claude/
│   ├── skill-writer.md    ← Direct-use skill (SKILL.md v3.4.0 compliant)
│   ├── CLAUDE.md          ← Routing rules (idempotent skill-writer:start/end block)
│   └── install.sh         ← Installs to ~/.claude/{skills,refs,templates,eval,optimize}/
│
├── openclaw/
│   ├── skill-writer.md    ← Same content + metadata.openclaw YAML block
│   ├── AGENTS.md          ← Routing rules
│   └── install.sh         ← Installs to ~/.openclaw/{skills,refs,templates,eval,optimize}/
│
├── opencode/
│   ├── skill-writer.md    ← Same content + **Triggers**: footer
│   ├── AGENTS.md          ← Routing rules
│   └── install.sh         ← Installs to ~/.config/opencode/{skills,refs,templates,eval,optimize}/
│
├── refs/                  ← Shared companion files (source for all platforms)
├── templates/             ← Skill creation templates (4 types)
├── eval/                  ← Evaluation rubrics
├── optimize/              ← Optimization strategies
├── examples/              ← User-facing skill examples
├── skill-framework.md     ← Complete specification (reference document)
├── install.sh             ← Top-level dispatcher → delegates to platform install.sh
└── README.md              ← Updated: 8-platform ecosystem overview
```

**Removed**: `builder/` (Node.js), `platforms/` (generated output), `package.json`, `install-claude.sh`

---

## 6. Platform-Specific Differences

| Feature | Claude | OpenClaw | OpenCode | Cursor | Gemini | OpenAI | Kimi | Hermes |
|---------|--------|----------|----------|--------|--------|--------|------|--------|
| Routing file | CLAUDE.md | AGENTS.md | AGENTS.md | `.mdc` alwaysApply | (in-skill) | (in-skill) | (in-skill) | (in-skill) |
| Install path | ~/.claude/ | ~/.openclaw/ | ~/.config/opencode/ | .cursor/rules/ | ~/.gemini/ | project dir | ~/.config/kimi/ | ~/.hermes/ |
| Platform metadata | — | `metadata.openclaw` YAML | Triggers footer | MDC header | — | — | — | — |
| UTE tracking | Full 13 fields | Full 13 fields | Full 13 fields | Full 13 fields | Full 13 fields | Full 13 fields | Full 13 fields | Full 13 fields |
| Hook routing | UserPromptSubmit + settings.json | AGENTS.md block | AGENTS.md block | alwaysApply | — | — | — | — |
| Companion files | refs/ templates/ eval/ optimize/ | Same | Same | Same | Same | Same | Same | Same |

All 8 platforms are functionally equivalent (v3.4.0). Platform differences are minimal and contained to frontmatter additions and routing file format.

---

## 7. SKILL.md Compliance (Post-Refactor)

| Check | Status | Notes |
|-------|--------|-------|
| `skill_tier: planning` | ✓ | Added to frontmatter |
| `triggers.en` ≥ 3 phrases | ✓ | 8 EN triggers (one per mode) |
| `triggers.zh` ≥ 2 phrases | ✓ | 5 ZH triggers |
| `use_to_evolve` 13 fields | ✓ | Full 13-field format (incl. generation_method + validation_status, v3.4.0) |
| `## Skill Summary` | ✓ | ≤8 dense sentences, WHAT/WHEN/WHO/NOT-FOR |
| `## §2 Negative Boundaries` | ✓ | 5 anti-cases with alternatives |
| Content < 500 lines | ✗ | Framework is a meta-document; 700+ lines justified |
| `name` pattern [a-z0-9-] | ✓ | `skill-writer` |
| `description` ≤ 1024 chars | ✓ | |
| LEAN score ≥ 350/500 | Expected ✓ | Identity + Summary + Boundaries + triggers present |
| EVALUATE score ≥ 700/1000 | Expected ✓ | BRONZE threshold |

---

## 8. Key Design Decisions

### Decision 1: No build step
**Rationale**: Platform differences are minimal (frontmatter additions, routing file format). A build pipeline adds 2,400 lines of complexity for ~50 lines of actual customization. Direct files are simpler, more auditable, and easier to maintain.

### Decision 2: All platforms get all companion files
**Rationale**: Progressive Disclosure applies equally to all platforms. Giving Claude more companion files than OpenClaw would create unequal capability without justification.

### Decision 3: skill-framework.md kept as specification
**Rationale**: The complete specification remains as the authoritative reference document. Platform skill files are derived from it. Users who need the full spec can read skill-framework.md; day-to-day use only requires the platform skill file.

### Decision 4: OpenClaw uses metadata.openclaw YAML block
**Rationale**: OpenClaw's AgentSkills format requires this block for compatibility detection. It's a 10-line addition to the frontmatter — no other changes needed.

### Decision 5: skill_tier = planning (not functional)
**Rationale**: skill-writer orchestrates all other modes (CREATE, LEAN, EVALUATE, OPTIMIZE, etc.) and coordinates sub-skills. This matches the `planning` tier definition in three-tier skill hierarchy.

---

## 9. v3.4.0 Additions (April 2026)

The v3.4.0 release built on the v3.3.0 simplified architecture with quality and security improvements:

### 9.1 Honest Skill Labeling

**Problem**: Auto-generated skills were being deployed to production with no indication of their validation level. Research (industry observations on unvalidated skills) showed 39/49 auto-generated skills had zero real-world benefit despite passing internal evaluations.

**Solution**: Two new YAML fields in `use_to_evolve`:
- `generation_method`: `auto-generated | human-authored | hybrid` — provenance tracking
- `validation_status`: `unvalidated | lean-only | full-eval | pragmatic-verified` — evaluation milestone

These affect Skill Summary heuristic ranking (lower source_quality_score for unvalidated skills) and SHARE gate (hard block on unvalidated, warning on lean-only).

### 9.2 Behavioral Verifier (Generator Bias Elimination)

**Problem**: LLM self-evaluation creates generator bias — the same model that created the skill evaluates it, inflating scores.

**Solution**: EVALUATE Phase 4 auto-generates 5 test cases (3 positive + 2 negative) from the Skill Summary in informational isolation from optimization history. Pass_rate ≥ 0.80 → +20 pts BEHAVIORAL_VERIFIED bonus. See `eval/rubrics.md §6.4`.

### 9.3 Pragmatic Test Phase

**New mode**: `/eval --pragmatic` — tests against 3–5 real user tasks, producing `pragmatic_success_rate` independent of theoretical LEAN/EVALUATE scores. WEAK (<60%) or FAIL (<40%) results block SHARE. See `eval/rubrics.md §6.5`.

### 9.4 Failure-Driven CREATE

**New mode variant**: `/create --from-failures` — uses observed failure trajectories as input to generate skills targeting specific failure patterns (Failure-Driven CREATE heuristic:).

### 9.5 Supply Chain Trust

**Problem**: supply-chain threat model/supply-chain threat model research shows a material fraction of public skills have OWASP vulnerabilities (industry audits).

**Solution**: SHA-256 signature verification + trust tier system (TRUSTED/VERIFIED/UNVERIFIED/LOW_TRUST/UNTRUSTED) in `refs/security-patterns.md §6`. INSTALL mode runs security scan before loading external skills.

### 9.6 GoS Minimum Viable Runtime [CORE]

**Problem**: `builder/src/core/graph.js` was referenced in docs but never implemented (v4.0+ roadmap). This created a false impression that GoS features were functional.

**Solution**: A [CORE] 5-step MVR algorithm was documented in `refs/skill-graph.md §2a` — an LLM can execute depends_on chain resolution from YAML reading alone, without any builder infrastructure. All full-graph features are annotated as [EXTENDED].

---

## 10. Migration Guide

If you had skill-writer installed from v3.2.0 or earlier:

```bash
# Re-run install to get updated files
./install.sh --platform claude    # or openclaw / opencode

# The install script is idempotent:
# - Backs up existing skill file with timestamp
# - Replaces the skill-writer block in CLAUDE.md/AGENTS.md
# - Merges settings.json (Claude only)
```

No manual cleanup required. Old companion files in ~/.claude/refs/ are overwritten with newer versions.

---

## 10. References

- Skill Summary heuristic: — trigger phrase coverage as routing signal
- three-tier skill hierarchy: — three-tier skill hierarchy
- typed-dependency Graph of Skills design: — Graph of Skills typed dependency edges
- SKILL.md Pattern: agentskills.io — skill file specification
- Negative Boundaries heuristic: 2026 — negation reduces false trigger rates
- Anthropic skills design: github.com/anthropics/skills
