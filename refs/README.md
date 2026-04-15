# Companion Document Index

This directory contains reference documents that extend `skill-framework.md`.
Each file is loaded on-demand when its associated framework section is accessed —
they are not loaded at startup to keep context lean.

## Core Evaluation

| File | Purpose | Load When |
|------|---------|-----------|
| `security-patterns.md` | CWE regex patterns, OWASP Agentic Top 10 checks, severity levels, ABORT protocol, and resume conditions | §11 (Security) is accessed or a security scan runs |
| `self-review.md` | Multi-pass self-review protocol: DRAFT → CRITIQUE → REVISE → RECONCILE cycle | §4 (LoongFlow) or §12 (Self-Review) is accessed |

## Optimization

| File | Purpose | Load When |
|------|---------|-----------|
| `convergence.md` | Three-signal convergence algorithm (volatility, plateau, trend) used to stop OPTIMIZE loops early | §9 (OPTIMIZE Loop) is accessed |
| `edit-audit.md` | Edit Audit Guard — prevents destructive rewrites during OPTIMIZE and UTE micro-patch cycles; blocks ≥50% section modifications | §9 (OPTIMIZE) or §15 (UTE Injection) is accessed |
| `use-to-evolve.md` | UTE 2.0 spec: L1 session-scoped micro-patches and L2 collective evolution via Session Artifacts | §15 (UTE Injection) is accessed or UTE bootstrap runs pre-OPTIMIZE |

## Evolution & History

| File | Purpose | Load When |
|------|---------|-----------|
| `evolution.md` | 6-trigger evolution system, decision thresholds, staleness review, and deprecation logic (v3.4.0: added Trigger 6 — Validation Status Drift) | §10 (Self-Evolution) is accessed |
| `session-artifact.md` | Session Artifact canonical format: schema fields, prm_signal scoring, lesson classification (strategic/failure/neutral), AGGREGATE protocol | §18 (COLLECT Mode) is accessed or COLLECT fires automatically |
| `skill-registry.md` | Skill Registry spec: deterministic IDs, version history, push/pull API, tier-based tags | §16 (INSTALL/SHARE) is accessed or a registry operation runs |

## Routing & Graph

| File | Purpose | Load When |
|------|---------|-----------|
| `progressive-disclosure.md` | Five-layer context loading architecture (Layer -1 Hook Injection through Layer 3 Resources); three-tier routing model; token budget rules | §16 (INSTALL) or §2 (Mode Router) is accessed |
| `skill-graph.md` | Graph of Skills spec: depends_on chain resolution, GoS Minimum Viable Runtime [CORE] (§2a), bundle composition, edge types, health check rules | §19 (GRAPH Mode) is accessed |

## Usage Notes

- **All 8 platforms**: Each platform directory (`claude/`, `openclaw/`, `opencode/`, `cursor/`,
  `gemini/`, `openai/`, `kimi/`, `hermes/`) includes a platform-specific `install.sh` that
  copies companion files to the correct platform directories.
- **Claude platform**: Companion files are copied to `~/.claude/refs/` during installation.
  The framework references them as `claude/refs/<filename>`.
- **File authority**: These files are the authoritative specs for their subsystem.
  When `skill-framework.md` and a refs file conflict, the refs file wins for its subsystem.
