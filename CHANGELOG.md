# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [3.5.0-dev] - 2026-04-17 (in progress on `claude/research-architecture-review-pEXSL`)

### Added — Spec compatibility, supply-chain hardening, MCP, CLEAR, GEPA roadmap

#### agentskills.io v1.0 compatibility (`spec/agent-skills-compat.md`, `scripts/check-spec-compat.py`)
- New **compatibility spec** documents how skill-writer's schema maps to
  agentskills.io v1.0 (name/description/version/license/author/homepage/keywords)
  and declares `x-skill-writer:` as the reserved extension namespace.
- Three emission modes defined: native (current), spec (minimal v1.0), spec+ext
  (v1.0 fields + `x-skill-writer` extensions).
- **`scripts/check-spec-compat.py`** — stdlib-only validator that reads
  frontmatter across the 8 platforms + templates + examples. Handles the Cursor
  MDC dual-frontmatter case. Emits `SPEC-W###` warnings instead of hard failing
  to keep migration non-blocking. Status: 0 errors, body-length warnings only.
- `spec_version: "1.0"` added to all templates (base / api-integration /
  data-pipeline / workflow-automation) and new example skills.

#### Supply-chain: Ed25519 signing + trust tiers (`scripts/sign-release.sh`, `scripts/verify-signature.sh`, `docs/supply-chain-security.md`)
- **Dual-layer signing pipeline** — author signature + (future) registry
  counter-signature. Python `cryptography` primary path, OpenSSL fallback.
- Emits `.sig`, `.pubkey`, and `.provenance` JSON sidecars per release artifact.
- `verify-signature.sh` supports TOFU (first-use pinning) and a repo-level trust
  store.
- **Trust tiers** (TRUSTED / VERIFIED / LOW_TRUST / UNTRUSTED) documented,
  referencing the 2026 OpenClaw incident (1,184 malicious packages).

#### Sandboxing handbook (`docs/sandboxing.md`)
- Threat-model tiers T0–T4, Docker reference config (network-none, read-only,
  cap-drop=ALL, no-new-privileges, pids/memory/cpu caps), Firejail (Linux T1)
  and macOS seatbelt (T1) equivalents, verification tests, CI recipe.
- Recommendation: **T2 container is the production default** for third-party
  skills; T1 for local dev.

#### Single-source platform build (`platforms.yaml`, `scripts/build-platforms.py`)
- **`platforms.yaml`** — narrow-YAML manifest declaring per-platform
  transforms (prepend / replace / footer_append / frontmatter_append) so the 8
  platform files can regenerate from one canonical source.
- **`scripts/build-platforms.py`** — stdlib-only parser + transform engine.
  `--check` (strict) and `--check-warn` (migration mode, non-blocking)
  available; `--only PLATFORM` for single-target builds. Ships in v3.5.0 as
  migration mode — full sync flip is `[ROADMAP v3.6.0]`.

#### MCP-native integration (`mcp/server.py`, `mcp/README.md`, `docs/mcp-integration.md`)
- **Zero-LLM MCP server** — exposes 7 tools
  (`lean` / `evaluate` / `optimize` / `check_spec` / `build_platforms` /
  `verify_sig` / `list_skills`) that return structured *plans* for the host's
  LLM to execute. Stateless; no bundled model/provider.
- Detects the official MCP Python SDK; falls back to a stdlib stdio JSON-RPC
  loop (keeps zero-build promise).
- Install configs for Claude Desktop, Cursor, VS Code Copilot + MCP.
- `python3 mcp/server.py --selftest` validates the 7-tool handler table.

#### CLEAR production dimensions (`eval/rubrics.md §9a`)
- Opt-in (`/eval --clear`) D9 Cost (50 pts) + D10 Latency (50 pts) dimensions
  implementing the CLEAR framework (arXiv 2511.14136). Total ceiling rises to
  1100 when enabled; tier thresholds scale by 1.10.
- Production envelope fields added under `extends.production:` —
  `cost_budget_usd`, `est_tokens_p50/p95`, `latency_budget_ms`, `est_p95_ms`.

#### GEPA reflective optimization (`optimize/strategies.md §4a`, `scripts/gepa-optimize.py`)
- **S15 — Reflective Prompt Evolution** strategy added (arXiv 2507.19457):
  100–500 rollouts vs 10K+ RL; reflect-and-crossover loop on a Pareto frontier.
- `scripts/gepa-optimize.py` skeleton with stage stubs (seed/evaluate/reflect/
  crossover/select/verify). `--dry-run` prints the plan; real execution raises
  `NotImplementedError` until v3.6.0. Marked `[ROADMAP v3.6.0]` throughout.

#### Framework-index for 2772-line spec (`skill-framework-index.md`)
- Section-by-section TOC with line ranges, load triggers, and external cross-refs
  for `skill-framework.md`. Documents the v3.6.0 split plan (framework-core /
  framework-modes / framework-evolution).

#### Windows-native install (`scripts/merge-routing.ps1`)
- PowerShell idempotent marker-based routing-file merger — Windows users no
  longer need WSL2/Python to update `CLAUDE.md` / `GEMINI.md` / `AGENTS.md`.
  Parameters match the Python merger in `install.sh`.

#### New reference examples (`examples/data-pipeline-demo/`, `examples/mcp-bridge/`)
- **`data-pipeline-demo/`** — functional-tier `csv-to-json-validator` with
  schema-first validation, three-mode router, OWASP (ASI02/ASI07 + CWE-22)
  security baseline, and full CLEAR production fields.
- **`mcp-bridge/`** — atomic-tier `mcp-github-bridge` showing the
  thin-skill/delegation pattern: route intent to an MCP tool, render response
  in a blockquote, refuse write intents.

#### Cursor & roadmap polish
- README Cursor section: added explicit `.mdc` vs `.md` translation table and
  loader expectation warning.
- `refs/skill-graph.md`: three `builder/src/core/graph.js` references tagged
  `[ROADMAP v4.0+]` so readers don't expect a runtime that doesn't ship yet.
- README top-level feature table now uses a **CORE / EXTENDED / ROADMAP**
  legend so availability is unambiguous.

### Changed
- Templates: added `spec_version: "1.0"` to frontmatter across
  `templates/base.md`, `templates/api-integration.md`,
  `templates/data-pipeline.md`, `templates/workflow-automation.md`.
- `eval/rubrics.md` total-score math updated to reflect opt-in CLEAR (1100 max
  when `--clear`; default remains 1020 with Behavioral Verifier).
- `optimize/strategies.md` table of strategies now includes S15 (GEPA).

### Migration notes
- **No breaking changes**. CLEAR and GEPA are opt-in (`/eval --clear`,
  `/optimize --gepa`). Platform-build is migration-mode (`--check-warn`);
  existing platform files are untouched until v3.6.0.
- Recommend running `python3 scripts/check-spec-compat.py` once to see which
  skills are already agentskills.io-clean.

---

## [3.4.0] - 2026-04-15

### ✨ Added — Honest Skill Labeling, Behavioral Verifier, Pragmatic Test, Supply Chain Trust, GoS MVR

#### Honest Skill Labeling (`refs/skill-registry.md §12`, `eval/rubrics.md §1`, `skill-framework.md §6`)
- **`generation_method` + `validation_status` YAML fields** in all skills and templates
  - `generation_method`: `auto-generated | human-authored | hybrid` — provenance tracking
  - `validation_status`: `unvalidated | lean-only | full-eval | pragmatic-verified` — evaluation milestone
  - Source quality score now scales with validation_status (cold-start fix: lean-passed → 0.5 routing weight)
  - SHARE gate: warns on `lean-only`; hard blocks on `unvalidated`
- **DELIVER message updated** to include validation warning for auto-generated, lean-only skills
- **All templates upgraded** to v3.4.0 (base.md, api-integration.md, data-pipeline.md, workflow-automation.md)
  - Added `generation_method: "auto-generated"` and `validation_status: "lean-only"` to all template YAML frontmatter
  - Added `skill_tier`, `triggers`, Skill Summary, Negative Boundaries, `graph:` block to api-integration, data-pipeline, workflow-automation templates
  - All platform skill-writer files (claude, openclaw, opencode, cursor, gemini, openai, kimi, hermes) updated to v3.4.0

#### Behavioral Verifier (`eval/rubrics.md §6.4`)
- **Phase 4 sub-step**: Auto-generates 5 test cases (3 positive + 2 negative) from Skill Summary only
- Scoring: pass_rate ≥ 0.80 → +20 pts; 0.60–0.79 → +10 pts; <0.60 → 0 pts + WARNING
- Addresses generator bias: verifier is isolated from optimization history
- Total score ceiling rises to 1020 pts (1000 + 20 Behavioral Verifier bonus)

#### Pragmatic Test Phase (`eval/rubrics.md §6.5`, `skill-framework.md §9`)
- `/eval --pragmatic`: optional phase testing 3–5 real user tasks; produces `pragmatic_success_rate`
- Tier assignment: PRAGMATIC_GOOD (≥80%), ADEQUATE (60–79%), WEAK (40–59%), FAIL (<40%)
- Blocks SHARE if pragmatic_success_rate < 60%
- Independent of theoretical score — additive quality signal

#### Failure-Driven CREATE (`skill-framework.md §6`, `eval/benchmarks.md §8`)
- `/create --from-failures`: CREATE mode variant using failure trajectory inputs (Failure-Driven CREATE heuristic:)
- Generates skills with Negative Boundaries pre-populated from observed failure patterns
- Auto-sets `generation_method: "auto-generated"` and validation_status warning in DELIVER

#### Supply Chain Trust Verification (`refs/security-patterns.md §6`)
- **Trust tier system**: TRUSTED / VERIFIED / UNVERIFIED / LOW_TRUST / UNTRUSTED
- **SHA-256 signature verification** on INSTALL: FETCH→HASH→COMPARE→AUTHOR→SCAN→CONFIRM
- **Pull-time security scan**: P0-only for TRUSTED GOLD+; full scan for all others
- Motivated by supply-chain threat model/supply-chain threat model research: a material fraction of public skills have OWASP vulnerabilities (industry audits)

#### GoS Minimum Viable Runtime — MVR (`refs/skill-graph.md §2a`)
- **[CORE] 5-step algorithm** for LLM-executable dependency resolution from YAML only (no builder required)
  - SEED → EXPAND (DFS, max depth 5) → DEDUPLICATE → TOPOLOGICAL SORT → TOKEN BUDGET CHECK
- Clearly annotated: `builder/src/core/graph.js` is v4.0+ (not yet implemented); all full-graph features are [EXTENDED]
- Edge type availability table (CORE vs EXTENDED)

#### New Optimization Strategies (`optimize/strategies.md §4, §8`)
- **S13 — Pragmatic Failure Recovery**: targets real-world utility gaps; failure mode classification; pragmatic_success_rate targeting
- **S14 — Score History Analysis**: reads `.optimize-history.jsonl`; computes per-strategy ROI; triggers strategy switches; detects score exhaustion

#### New Anti-Patterns (`optimize/anti-patterns.md §G, §H`)
- **Category G — Auto-Generated Skill Anti-Patterns**: G1 validation status drift, G2 generator bias, G3 summary overfitting, G4 stale validation_status, G5 score confusion (LEAN vs EVALUATE)
- **Category H — Supply Chain Anti-Patterns**: H1 untrusted pull, H2 skill injection via external body, H3 unpinned dependency, H4 similarity hijack

#### Benchmarks expanded (`eval/benchmarks.md`)
- New §5 LEAN Mode Benchmarks (pass/fail cases + trigger cases)
- New §6 Pragmatic Test Benchmarks (execution cases, tier classification, triggers)
- New §7 Behavioral Verifier Benchmarks (case generation, score tiers, anti-gaming)
- New §8 Failure-Driven CREATE Benchmarks
- New §9 INSTALL/SHARE/COLLECT/GRAPH Mode Benchmarks (includes SHARE security gate cases)

#### Session Artifact updates (`refs/session-artifact.md`)
- `schema_version` bumped from `"1.0"` → `"1.1"`
- New `skill_provenance` object: `generation_method`, `validation_status`, `pragmatic_success_rate`, `behavioral_verifier_pass_rate`, `certified_lean_score`, `last_evaluated_at`
- **AGGREGATE Rule 5 — Provenance-Outcome Correlation**: flags auto-generated skills with low success rates for pragmatic re-evaluation

#### Score History Persistence (`refs/convergence.md §8`)
- `.optimize-history.jsonl` format documented with per-round fields
- Git commit integration (history file committed alongside skill at round 10)
- LLM reasoning fallback when file system unavailable

### 🔧 Changed

- **All platform skill-writer files** (claude, openclaw, opencode, cursor, gemini, openai, kimi, hermes): version 3.3.0 → 3.4.0; added `generation_method: "human-authored"` + `validation_status: "full-eval"`; platform count description updated 7 → 8 platforms
- **All example skills** (00-starter, api-tester, code-reviewer, doc-generator): `injected_by` updated to v3.4.0; added `generation_method` + `validation_status` fields; v2.0.0 footer references updated to v3.4.0
- **`optimize/strategies.md`** header: added v3.4.0 changelog entry; selection matrix extended with S13/S14 triggers
- **`refs/skill-graph.md`** header: `builder/src/core/graph.js` annotated as v4.0+ / not yet implemented; [CORE] vs [EXTENDED] feature boundary documented
- **`refs/session-artifact.md`** last updated timestamp updated; collective-evolution design interoperability table extended

---

## [3.3.0] - 2026-04-14

### ✨ Added — Three-Tier Hook Routing + Skill Summary heuristic Weighted Ranking + Trigger Discovery

- **Layer -1 Hook Injection** (`refs/progressive-disclosure.md §2 Layer -1`)
  - New lowest layer in the Progressive Disclosure stack — fires at `UserPromptSubmit` before the LLM sees the message
  - Token budget ≤ 50 tokens (per-message; always on, not counted against skill context budget)
  - Platform support: Claude ✅, OpenCode ✅, Cursor ❌ (IDE intercepts), Gemini 🔲 (planned v3.4.0)
  - **Three-tier routing model** (outer → inner): AGENTS.md (session-constant) → UserPromptSubmit Hook (per-message) → trigger phrases (in-skill keyword routing)
  - Solves "LLM forgets skills exist" — every message receives a skill-awareness nudge regardless of user phrasing

- **INSTALL steps 4e + 4f** (`skill-framework.md §16`)
  - **Step 4e — AGENTS.md generation**: After skill file install, generate or update `~/.claude/CLAUDE.md` / `~/.config/opencode/AGENTS.md` / etc. with skill registry routing rules block (idempotent `<!-- skill-writer:start/end -->` markers); Cursor gets `.mdc` with `alwaysApply: true`
  - **Step 4f — Hook injection**: Merge `UserPromptSubmit` hook entry into `~/.claude/settings.json` (Claude/OpenCode only); appends to existing hook array without overwriting; skipped with note for unsupported platforms

- **Skill Summary heuristic Weighted Ranking** (`refs/skill-registry.md §11`)
  - Multi-factor rank formula: `trigger_match × 0.40 + lean_score_normalized × 0.30 + usage_frequency × 0.20 + source_quality × 0.10`
  - **Quality threshold gate** (default 0.35): returns `noMatch` if best candidate is below threshold — prevents AI from "going with wrong result" (将错就错)
  - **Disambiguation**: if top-2 candidates differ by < 0.05, surface choice to user instead of auto-routing
  - **Source quality scoring**: GOLD/PLATINUM = 1.0, SILVER = 0.8, BRONZE = 0.6, registry-stable = 0.9, experimental = 0.4, unvalidated = 0.2
  - **`usage_stats` field** in `registry.json`: `total_invocations`, `successful_invocations`, `success_rate`, `trigger_phrase_counts`, `last_invoked`, `prm_distribution`

- **Trigger Discovery Pipeline** (`refs/session-artifact.md §8 Rule 4`)
  - New `trigger_signals` object in session artifact schema: `trigger_used`, `matched_trigger`, `match_type` (exact/fuzzy/acronym/semantic/none), `trigger_miss`, `candidate_triggers[]`
  - **AGGREGATE Rule 4** (v3.3.0): mines `candidate_triggers` across artifacts; when phrase count ≥ 5 and confidence ≥ 0.70, proposes adding phrase to `triggers.en/zh` (user confirms before registry update)
  - **`trigger_miss` signal**: set when skill activated via AGENTS.md/Hook but no trigger phrase matched — highest-priority signal for discovery (threshold reduced to count ≥ 3)
  - Closes the feedback loop: observed user language → confirmed canonical triggers → improved Skill Summary heuristic accuracy

- **Incremental Build Cache** (`builder/src/core/reader.js` + `builder/src/commands/build.js`)
  - `computeHash()`: SHA-256 first 16 hex chars per source file; `parseFile()` now returns `source_hash` field
  - `collectHashes()`: aggregates all file hashes into flat `{ relPath: hash }` map; `readAllCoreData()` returns `source_hashes` map
  - `.build-cache.json` (project root, gitignored): persists `{ source_hashes, built_platforms[] }` between runs
  - On incremental run: compares stored vs current hashes; skips platforms already built from identical sources; rebuild triggered by any source change
  - Release builds (`--release`) and dry-runs always bypass cache for reproducibility
  - Reduces multi-platform rebuild time from O(N) to O(changed) for common "edit one ref file → rebuild" workflows

### 🔧 Changed

- **`refs/progressive-disclosure.md`**: "Four-Layer Architecture (v3.2.0)" → "**Five-Layer Architecture (v3.3.0)**"
  - Layer -1 (HOOK INJECTION) prepended to existing Layer 0–3
  - New "Three-Tier Routing Model" diagram documents outer→inner routing tiers
  - §4 Implementation Checklist updated with Tier 1/2/3 routing checklist items
  - §5 Relationship table updated with Layer -1 spec entries

- **`skill-framework.md`**: version 3.2.0 → 3.3.0; `interface.modes` now includes `graph` (was missing)
  - §16 INSTALL: new steps 4e (AGENTS.md) and 4f (Hook injection) with full merge strategy, platform notes, and safety rules
  - REPORT step updated to confirm AGENTS.md path and three-tier model notice

- **`refs/skill-registry.md`**: new §11 (Skill Summary heuristic Weighted Ranking & Quality Gate)
  - §11.1 ranking formula, §11.2 source quality weights, §11.3 quality threshold gate, §11.4 trigger phrase discovery, §11.5 `usage_stats` spec

- **`refs/session-artifact.md`**: schema updated for v3.3.0
  - `trigger_signals` object added to §2 Schema and §3 Field Definitions
  - §8 AGGREGATE rules numbered (Rule 1–4); Rule 4 (Trigger Discovery) added

- **`builder/src/core/reader.js`**: version comment 3.1.1 → 3.3.0; `crypto` module imported; `computeHash`, `collectHashes` added; `parseFile` returns `source_hash`; `readAllCoreData` returns `source_hashes`; `computeHash` exported

- **`builder/src/commands/build.js`**: version comment 2.2.0 → 2.3.0; cache helpers and Step 1b incremental logic added; successful platform recorded in `built_platforms`; cache persisted after build

- **`.gitignore`**: added `.build-cache.json`

- **`package.json`**: version 3.2.0 → 3.3.0; description updated

- **`builder/package.json`**: version 2.2.0 → 2.3.0; description updated

### 📋 Background

v3.3.0 addresses two root causes of skill trigger instability identified in production AI Coding practices:

**Trigger instability** (solved by three-tier routing model): The four-layer disclosure model (v3.2.0) relied on trigger-phrase matching for Layer 1 → Layer 2 routing. Vercel benchmarks (2026) show default skill triggering via description matching alone does not improve task pass rates; explicit context injection is required. AGENTS.md provides a session-constant skill inventory; the UserPromptSubmit Hook provides a per-message nudge. Together they ensure skills are always "visible" to the LLM before it decides how to respond. Inspired by 得物 AI Coding component reuse practice (2026).

**Trigger vocabulary gap** (solved by Trigger Discovery pipeline): Skill trigger phrases are authored once at creation time but users develop natural phrasings through actual use. AGGREGATE Rule 4 mines `candidate_triggers` from session artifacts and promotes high-frequency phrases to canonical triggers at ≥70% confidence, continuously improving Skill Summary heuristic accuracy without manual curation.

---

## [3.2.0] - 2026-04-13

### ✨ Added — Graph of Skills (GoS)

- **`refs/skill-graph.md`** — Comprehensive GoS specification: typed edge schema (6 types), bundle retrieval protocol (BFS + PageRank diffusion), Progressive Disclosure Layer 0 (≤200 tokens), D8 Composability scoring, graph health checks GRAPH-001–008, graph visualization format, and dependency resolution workflow
- **`builder/src/core/graph.js`** — GoS algorithm library: `buildGraph`, `detectCycles` (Tarjan DFS), `topologicalSort` (Kahn BFS), `resolveBundle` (BFS + 0.85/hop decay), `findSimilarSkills`, `findMergeCandidates`, `checkGraphHealth`, `scoreD8Composability`
- **GRAPH Mode (§19 in `skill-framework.md`)** — 7th mode with sub-commands: `/graph view` (ASCII dependency graph), `/graph check` (GRAPH-001–008 health), `/graph plan` (decomposition planning), `/graph bundle` (bundle resolution), `/graph diff` (edge delta)
- **D8 Composability dimension** — Optional LEAN bonus dimension (+0–20 pts); skills without `graph:` block score 0 with no penalty; LEAN max = 520 with D8; validated by 3 checks: graph_block_present, skill_tier_graph_consistent, graph_edge_ids_valid_format
- **Graph strategies S10/S11/S12** in `optimize/strategies.md`:
  - S10 Graph Extraction: decompose monolithic skills into composable atomic/functional sub-skills
  - S11 Coupling Reduction: break circular A↔B dependencies via intermediate skill C
  - S12 Similarity Consolidation: merge/subsume near-duplicate skills with similarity ≥ 0.95
- **Registry schema v2.0** (`refs/skill-registry.md §10`) — top-level `graph: { edges[], bundles[] }` section; backward-compatible with v1.x; AGGREGATE auto-inference rules (co-invocation ≥80% → depends_on, data flow ≥60% → provides/consumes)
- **Progressive Disclosure Layer 0** (`refs/progressive-disclosure.md §2`) — ≤200-token bundle context injected before Layer 1 ADVERTISE stubs when task matches a known bundle and registry has `graph:` data
- **Session Artifact GoS fields** (`refs/session-artifact.md §8`) — `bundle_context` object (bundle_id, co_invoked_skills, invocation_order, data_flow, bundle_success, missing_dependencies) and `graph_signals` object (should_add_edge, should_merge_with, composability_score)
- **INSTALL dependency resolution** (`skill-framework.md §12 Step 2a`) — reads `depends_on` edges, builds dependency tree, displays dependency manifest, installs in topological order (deepest dependency first)
- **COLLECT bundle context** (`skill-framework.md §18 v3.2.0 extension`) — 4-step protocol to record `bundle_context` and `graph_signals` when invoked as part of a multi-skill task
- **`graph:` block in base template** (`templates/base.md`) — comprehensive commented-out YAML `graph:` block with all 6 edge types, documentation, and tier guidance
- **D8 section in rubrics** (`eval/rubrics.md §9`) — 3-check scoring table, tier consistency table, Phase 5 roadmap (+100 pts, v4.0+)

### 🔧 Changed

- **`builder/src/config.js`** — Added GoS constants: `GRAPH_EDGE_TYPES`, `GRAPH_SCHEMA_VERSION`, `GRAPH_SIMILARITY_MERGE_THRESHOLD = 0.95`, `GRAPH_MAX_TRAVERSAL_DEPTH = 6`, `REQUIRED_GRAPH_FIELDS`, `GRAPH_STRATEGIES`; updated `SCORING` with D8 `composability` dimension (`leanMax: 20`, `weight: 0.00`); `SCORING.lean.maxScoreWithD8 = 520`; added `refs/skill-graph.md` to `REQUIRED_FILES`
- **`builder/src/index.js`** — Exported `graph` module; added `planBundle(seedSkillId, registryObject, options)` convenience wrapper
- **`builder/src/commands/validate.js`** — Added `validateGraphEdges()` with GRAPH-001–005 checks (ID format, planning missing composes, atomic has depends_on, similarity merge advisory, self-loop)
- **`skill-framework.md`** — Version 3.1.0 → 3.2.0; added `/graph` to Mode Router; added GRAPH routing keywords (技能图, 依赖图, etc.); extended INSTALL Step 2a; extended COLLECT bundle context subsection; added §19 GRAPH Mode
- **`optimize/strategies.md`** — Version 3.2.0; added D8 dimension row; added S10/S11/S12 graph strategies; updated strategy selection matrix; added §7 Graph-Level Strategy Guidelines
- **`eval/rubrics.md`** — Added D8 note to Phase 2; added §9 D8 Composability bonus section; updated report template
- **`refs/progressive-disclosure.md`** — "Three-Layer" → "Four-Layer Architecture (v3.2.0)"; added Layer 0 GRAPH CONTEXT spec
- **`refs/session-artifact.md`** — Added `bundle_context` and `graph_signals` fields; added §8 GoS Fields

### 🧪 Tests

- **`builder/tests/unit/config.test.js`** — Updated to expect 8 SCORING dimensions (7 core + D8); added test asserting D8 leanMax=20, weight=0.00; updated core leanMax sum test to filter D8 before summing

### 📋 Background

v3.2.0 implements the Graph of Skills framework inspired by typed-dependency Graph of Skills design, which demonstrated that inference-time typed directed graphs retrieve **execution-complete bundles** rather than isolated semantically-similar skills. The GoS features build directly on the three-tier hierarchy (three-tier skill hierarchy) introduced in v3.1.0. Bundle context in COLLECT is informed by collective-evolution design collective evolution methodology.

---

## [3.1.0] - 2026-04-11

### 📝 Documentation

- **`README.md`** — full rewrite of LEAN mode section: replaced outdated 8-check rubric with accurate 17-check table organized by dimension; added `[STATIC]`/`[HEURISTIC]` reliability labels and score proxy table
- **`README.md`** — added tier-adjusted Phase 2 weights table in EVALUATE section; added confidence-zone column to certification tiers
- **`README.md`** — fixed COLLECT mode triggers (was incorrectly showing INSTALL triggers)
- **`README.md`** — updated UTE section to document L1/L2 architecture, cadence-gated checks, micro-patch rules, and platform hook integration
- **`README.md`** — updated architecture diagram to include all 6 modes (INSTALL, COLLECT) and Shared Resources
- **`README.md`** — updated Roadmap: all v3.1.0 features marked complete; separated into Completed / Planned sections
- **`README.md`** — improved Troubleshooting section with score variance guidance, skill_tier advice, and confidence zone notes

### 🔧 CI/CD

- **`.github/workflows/build-and-release.yml`** — upgraded `actions/checkout@v3→v4`, `actions/setup-node@v3→v4`, `actions/upload-artifact@v3→v4`, `actions/download-artifact@v3→v4`, `softprops/action-gh-release@v1→v2`
- **`.github/workflows/build-and-release.yml`** — removed `|| true` from `npm run lint` and `npm test`; failures now correctly fail the CI pipeline
- **`.github/workflows/build-and-release.yml`** — removed redundant `deploy-docs` job (GitHub Pages is managed by `pages.yml`)
- **`.github/workflows/security-scan.yml`** — upgraded `actions/checkout@v3→v4`, `actions/setup-node@v3→v4`
- **`.github/workflows/security-scan.yml`** — upgraded CodeQL actions `v2→v3` (init, autobuild, analyze)
- **`.github/workflows/security-scan.yml`** — pinned `trufflesecurity/trufflehog@main→v3` (eliminates unpinned-dependency supply-chain risk); removed `--debug` flag

### 🐛 Fixed

- **`dev.js` broken file watcher** — was watching nonexistent `builder/core/` directory; now watches correct `WATCH_DIRS` (refs, templates, eval, optimize) from `config.PATHS`
- **`index.js` programmatic `validate()` API** — was calling `require('./commands/validate')` as a function directly; fixed to destructure `{ validate }` from the module export (was throwing `TypeError: validate is not a function` in any programmatic consumer)
- **`cursor.js` placeholder regex** — `/\{\{(\w+)\}\}/g` missed `{{OUTER-KEY}}` and `{{outer.key}}` style markers; updated to `/\{\{([\w.-]+)\}\}/g`
- **`platforms/index.js` wrong file extension for JSON platforms** — `installSkill` was always writing `.md`; now writes `.json` for `openai` and `mcp` platforms
- **`inspect.js` JSON platform extension** — `getBuiltSkillPath` only checked `platform === 'openai'`; updated to use `JSON_PLATFORMS` set to also handle `mcp`
- **`inspect.js` duplicate placeholder reporting** — added `seen` Set to deduplicate identical placeholder matches
- **`MarkdownAdapter.js` dead compatibility versions** — `testedVersions` had hardcoded historical list `['1.0.0', '2.0.0', '2.1.0']`; now reads dynamically from `package.json`; `minVersion` updated from `'1.0.0'` to `'2.2.0'`
- **`openai.js` stale `testedVersions` and `minVersion`** — same fix as MarkdownAdapter
- **Reader test mis-placed `convergence` assertion** — `readOptimizeMode` test incorrectly expected `convergence` property; moved assertion to `readSharedResources` where it actually belongs
- **`dev.js` frozen version** — metadata blob was hardcoded `VERSION: '1.0.0'`; now reads dynamically from `builder/package.json` via shared `metadata.js`

### ✨ Added

- **`builder/src/metadata.js`** — SSoT for skill-writer's own build metadata; exports `getSkillMetadata(platform)` replacing duplicate 50-line metadata blobs in `build.js` and `dev.js`
- **`builder/.eslintrc.json`** — ESLint configuration so `npm run lint` actually enforces rules (was silently a no-op with no config)
- **`builder/src/platforms/sections/`** — externalized LoongFlow, Self-Review, and UTE section template files; separates presentation content from adapter logic in `openclaw.js`
- **`install.sh` MCP support** — added `mcp` case copying JSON manifest to `~/.mcp/servers/skill-writer/mcp-manifest.json`

### 🔧 Changed

- **`build.js` and `dev.js`** — replaced inline 50-line metadata blobs with `getSkillMetadata(platform)` from new `metadata.js` module
- **`openclaw.js`** — replaced three ~100-line inline section strings with `readSection()` calls loading from `sections/` directory
- **`opencode.js` `generateMetadata`** — now delegates entirely to `super.generateMetadata()`, only overriding `format: 'SKILL.md'`; removed dead compatibility override
- **`mcp.js` frontmatter parsing** — replaced 7-regex hand-rolled parser with single `yaml.load()` call (handles both inline and block YAML list forms); platform list now sourced from `config.PLATFORMS` instead of hardcoded array
- **`builder/templates/claude.md`** — version/description/date fields now use `{{VERSION}}`, `{{DESCRIPTION}}`, `{{generated_at}}` placeholders; added OWASP ASI security table; updated to 10-step OPTIMIZE loop; added `injected_by` and `injected_at` to `use_to_evolve` block
- **`builder/templates/openai.json`** — same placeholder and feature parity updates as claude.md

---

## [3.1.0] - 2026-04-11

### ✨ Added

- **`RESEARCH-SYNTHESIS-2026.md`** — comprehensive synthesis of 9 academic papers and industry best practices; documents Gap Matrix and improvement rationale for v3.1.0
- **Co-Evolutionary VERIFY step (§9 OPTIMIZE Step 10)** — independent re-evaluation pass after OPTIMIZE convergence, approximating co-evolutionary verifier heuristic' Surrogate Verifier; detects score inflation (delta > 50 pts → HUMAN_REVIEW)
- **Mandatory Skill Summary paragraph** — first content paragraph in every generated skill; ≤5 sentences densely encoding domain knowledge; decisive for skill routing (Skill Summary heuristic: 91.7% cross-encoder attention on body)
- **Mandatory Negative Boundaries section** — required `## Negative Boundaries` in every skill; "Do NOT use for" list with 3+ anti-cases; prevents mis-triggering (SKILL.md Pattern best practice)
- **OWASP Agentic Skills Top 10 (2026) detection** — 10 new ASI checks in `refs/security-patterns.md §5`; ASI01-ASI04 are P1 (score penalty); ASI05-ASI10 are P2 (advisory); addresses Negative Boundaries heuristic finding that 26.1% of community skills contain vulnerabilities
- **ASI01 Prompt Injection as P1 pattern** — new `refs/security-patterns.md §1.2`; detection heuristics for goal hijack and external content injection; −50 pts
- **P2 advisory patterns** — new `refs/security-patterns.md §1.3`: Missing Negative Boundaries + Executable Script Risk (2.12× higher vulnerability per Negative Boundaries heuristic)
- **reinforcement-style evolution design lesson distillation** — `refs/session-artifact.md` new fields: `lesson_type: strategic_pattern | failure_lesson | neutral` + `lesson_summary` (≤3 sentences); `skill-framework.md §18 COLLECT` new Step 4 CLASSIFY LESSON TYPE
- **`skill_tier` metadata field** — `templates/base.md` YAML: `planning | functional | atomic` (three-tier skill hierarchy three-tier hierarchy,)
- **`triggers` metadata field** — `templates/base.md` YAML: 3–8 EN + 2–5 ZH canonical trigger phrases; scored in LEAN metadata dimension
- **Inversion Q7 + Q8** — two new mandatory elicitation questions: negative scenarios (Q7) and trigger phrase examples (Q8); template-specific follow-up prompts added

### 🔧 Changed

- **`skill-framework.md §6 LEAN` — Metadata dimension**: 25 pts → 40 pts; now includes trigger phrase coverage (15 pts) and negative boundaries presence (10 pts); security dimension: 50 pts → 45 pts (recalibrated)
- **`skill-framework.md §11 Security`**: Added OWASP Agentic Skills Top 10 table; new Red Lines for ASI01 and executable scripts
- **`skill-framework.md §9 OPTIMIZE`**: `VERIFY` step renamed from old §6 "VERIFY" (re-score after single fix) to new **Step 10 Co-Evolutionary VERIFY** (post-convergence independent pass); old step renamed to `RE-SCORE`
- **`refs/security-patterns.md §2`**: Severity table updated to include P2 advisory tier
- **`refs/security-patterns.md §5`** (previously §5 Scan Report Format): Renumbered; OWASP section inserted as new §5; scan report now §6; log entry now §7
- **`refs/session-artifact.md`**: Header updated; `lesson_type` + `lesson_summary` fields added to schema
- **`templates/base.md`**: Full redesign — added Skill Summary, Negative Boundaries, skill_tier, triggers YAML, OWASP ASI checks in Security Baseline, updated checklist
- **`ARCHITECTURE-REVIEW.md`**: New Section 十一 (11) added: research synthesis and v3.1.0 improvement roadmap with P0/P1/P2/P3 prioritization

### 📋 Background

v3.1.0 is grounded in a systematic literature review of 9 recent papers (April 2026):
co-evolutionary verifier heuristic (2604.01687), three-tier skill hierarchy (2604.04804), reinforcement-style evolution design (2602.08234), Skill Summary heuristic (2603.22455),
collective-evolution design (2604.08377), Skills-in-the-Wild (2604.04323), Negative Boundaries heuristic (2603.21019),
SoK: Agentic Skills (2602.20867), and Agent Skills Survey (2602.12430).
Community sources: OWASP Agentic Top 10 (2026), SKILL.md Pattern, agentskills.io spec.

---

## [3.0.0] - 2026-04-11

### ✨ Added

- **COLLECT Mode (§18)** — structured session artifact recording; fires after every skill invocation when UTE is enabled; enables collective skill evolution via the AGGREGATE pipeline
- **AGGREGATE Mode** — multi-session distillation pipeline (Summarize → Aggregate → Execute) synthesizing N session artifacts into ranked improvement signals
- **`refs/session-artifact.md`** — canonical Session Artifact schema (skill_id, outcome, prm_signal, dimension_observations, causal-chain summary); collective-evolution design-compatible format
- **`refs/edit-audit.md`** — Edit Audit Guard: classifies OPTIMIZE changes as MICRO/MINOR/MAJOR/REWRITE; blocks destructive rewrites (>50% content change); prevents skill drift
- **`refs/skill-registry.md`** — Skill Registry spec: deterministic SHA-256[:12] IDs, 20-entry version history, push/pull/sync SHARE protocol, conflict resolution with LLM-based merge
- **UTE 2.0 two-tier architecture** — L1 (single-user, `[ENFORCED]`, current behavior) + L2 (collective, `[ASPIRATIONAL]`, requires COLLECT + AGGREGATE pipeline)
- **Edit guard integration in UTE** — UTE micro-patches are now explicitly bounded to MICRO class; structural changes escalate to full OPTIMIZE
- `skill_id` field convention — SHA-256[:12] identifier added to YAML frontmatter spec for registry-enabled skills

### 🔧 Fixed

- **`validate.js` false positive** — placeholder check now strips fenced code blocks before scanning; `{{SKILL_NAME}}`, `{{INJECTION_DATE}}`, etc. inside template snippets no longer flagged as build errors
- **`skill-framework.md §15` stale version** — `{{FRAMEWORK_VERSION}}` fill instruction updated from `"2.1.0"` to `"2.2.0"`
- **README.md scoring** — `code-reviewer` corrected to GOLD 947/1000 (was incorrectly listed as SILVER 820/1000); average updated to 920.7/1000

### 📐 Architecture

- `builder/src/config.js` — three new `refs/` files added to `REQUIRED_FILES` (session-artifact, edit-audit, skill-registry)
- `ARCHITECTURE-REVIEW.md` — new Section 十 synthesizing collective-evolution design research into product and architecture design recommendations

### 📋 Background

The v3.0 additions are informed by collective-evolution design (arxiv.org/abs/2604.08377, AMAP-ML), which
demonstrated that collective skill evolution from multi-user session data outperforms
single-user optimization — "not by using a bigger model, but by leveraging smarter experience."

---

## [2.2.0] - 2026-04-11

### 🐛 Fixed

- **Variable shadowing in `embedder.js`** — `embedCreateMode`, `embedEvaluateMode`, `embedOptimizeMode`, and `embedSharedResources` all used `const config = DEFAULT_CONFIG` which shadowed the module-level `config` import; renamed to `platformCfg` throughout
- **Input mutation bug in `opencode.js`** — `skillContent +=` mutated the function parameter; replaced with immutable local variable `formatted`
- **`validateEmbeddedContent` narrow regex** — placeholder detection used `/\{\{\w+\}\}/g` which missed `{{OUTER-KEY}}` and `{{outer.key}}` style markers; now uses `/\{\{[\w.-]+\}\}/g` with deduplication
- **`validate.js` missing JSON output checks** — only `.md` files were validated; now also validates `.json` outputs for MCP (schema_version, name, tools[]) and OpenAI (name, instructions)
- **`validate.js` placeholder regex** — upgraded from `/\{\{[A-Z_0-9]+\}\}/` to `/\{\{[\w.-]+\}\}/` to match extended placeholder patterns in generated files
- **MCP adapter empty description** — `mcp.formatSkill()` now falls back to inline body extraction when YAML frontmatter is absent (H1 title → kebab-case name; blockquote/first paragraph → description)
- **`openclaw.js` REQUIRED_SECTIONS mis-alignment** — `## §1 Identity` was listed as required but never injected by `formatSkill()`; removed from REQUIRED_SECTIONS (adapter guarantees only sections it injects: §4 LoongFlow, §9 Self-Review)
- **CLI validate exit code** — `skill-writer-builder validate` now exits with code 1 when `result.valid === false`, enabling CI pipeline integration

### ✨ Added

- **MCP platform support** — 7th platform adapter (`builder/src/platforms/mcp.js`) generating JSON manifests conforming to Model Context Protocol schema v1.0; includes `schema_version`, `tools[]`, `capabilities`, and `resources[]`
- **`MarkdownAdapter` base class** — shared base for Claude, Gemini adapters; extended to OpenCode via `OpenCodeAdapter extends MarkdownAdapter`
- **Integration test suite** (`builder/tests/unit/integration.test.js`) — 30 new end-to-end tests covering the full `reader → embedder → adapter` pipeline for all 7 platforms
- **Adapter tests for all 7 platforms** — added full test coverage for OpenCode (11 tests), OpenClaw (12), Cursor (9), OpenAI (10)

### 🔧 Changed

- **`opencode.js` refactored to `OpenCodeAdapter extends MarkdownAdapter`** — eliminates ~100 lines of duplicate code; XDG install path (`~/.config/opencode/skills`) preserved via `getInstallPath()` override
- **`MarkdownAdapter.generateMetadata()` dynamic version** — `testedVersions` array now reads current version from `package.json` dynamically instead of a hardcoded list
- **Scoring alignment** — `eval/rubrics.md` Phase 2 updated to match `config.js` canonical 7-dimension schema: Workflow Definition reduced from 20% (60 pts) to 15% (45 pts); former "Metadata Quality" (10%, 30 pts) split into "Security Baseline" (10%, 30 pts) + "Metadata Quality" (5%, 15 pts); Phase 2 total unchanged at 300 pts
- **`config.js` SCORING documentation** — added precise dimension ↔ rubric mapping table; clarified Phase 2 vs Phase 4 security gate distinction
- **`ARCHITECTURE-REVIEW.md` updated to v2.2.0** — documents all fixes, test expansion, and adds §10 (v2.2.0 architecture improvements)

### 📊 Metrics

| Metric | Before | After |
|--------|--------|-------|
| Unit tests | 0 structured | **176 (all passing)** |
| Adapter test coverage | Claude, Gemini, MCP | **All 7 platforms** |
| Integration tests | None | **30 end-to-end** |
| Platforms supported | 6 | **7 (+ MCP)** |
| `opencode.js` LOC | ~158 | **~115 (−27%)** |
| validate JSON output coverage | 0% | **100%** |

---

## [2.1.0] - 2026-04-04

### 🔧 Simplified

- Replaced Multi-LLM deliberation (3-LLM Generator/Reviewer/Arbiter) with **multi-pass self-review** protocol — realistic for single-LLM AI platforms
- Simplified UTE (Use-to-Evolve) from automated post-invocation hooks to **AI-followed protocol convention** — no longer assumes programmatic execution
- Established **Single Source of Truth** — each concept defined in exactly one Markdown file

### ✨ Added

- `refs/self-review.md` — 3-pass self-review protocol (Generate → Review → Reconcile) replacing the unrealizable 3-LLM system

### 🗑️ Removed

- Deleted entire `core/` directory (~5700 lines of duplicated YAML and README content)
- Deleted `refs/deliberation.md` (replaced by `refs/self-review.md`)
- Deleted `eval/pairwise.md` (over-engineered Bradley-Terry pairwise ranking)
- Deleted `builder/templates/claude.md` (duplicated `skill-framework.md`)

### 📈 Impact

- Project reduced from ~87 files / ~9600 lines to ~55 files / ~6000 lines
- Builder now reads directly from Markdown companion files (no YAML intermediary)
- All LLM-1/LLM-2/LLM-3 references updated to Pass 1/Pass 2/Pass 3

---

## [2.0.0] - 2026-04-01

### ✨ Added

- **LEAN Fast-Eval Mode** — 500-point heuristic evaluator (~1 s, no LLM calls); 8-check rubric with PASS/UNCERTAIN/FAIL decision gates
- **UTE (Use-to-Evolve)** — self-improvement protocol; every skill gains a `§UTE` section and `use_to_evolve:` YAML block; post-invocation hook records usage, detects feedback signals, runs cadence-gated trigger checks (lightweight/full-recompute/tier-drift)
- **LoongFlow Orchestration** — Plan-Execute-Summarize replaces rigid state machines; supports multi-LLM deliberation with consensus check
- **Variance gating** — certification tier requires both score AND variance check: PLATINUM <10, GOLD <15, SILVER <20, BRONZE <30
- **install-claude.sh** — new install script that copies `skill-framework.md` AND companion directories (`refs/`, `templates/`, `eval/`, `optimize/`) to `~/.claude/` so all `claude/` path references resolve at runtime

### 🔄 Changed

- **Canonical rubric**: Phase 1=100 / Phase 2=300 / Phase 3=400 / Phase 4=200 (total 1000)
- **Certification thresholds**: PLATINUM ≥950, GOLD ≥900, SILVER ≥800, BRONZE ≥700, FAIL <700
- **Example skill scores** re-evaluated with v2.0.0 rubric (see table below)
- **`install:claude`** now invokes `install-claude.sh` instead of a single `cp` command
- **`builder/templates/claude.md`**: version bumped to 2.0.0; added LEAN mode triggers; added ZH triggers for all four modes; scoring rubric corrected to 4-phase structure; `interface:` frontmatter field added
- **`builder/src/commands/inspect.js`**: `getBuiltSkillPath` now checks flat `skill-writer-<platform>-dev.md` pattern first, fixing inspect for all platforms
- **`builder/src/commands/build.js`**: adds `p0_count`, `p1_count`, `p2_count`, `p3_count`, `generated_at` to `skillMetadata` so security stats render correctly
- `package.json` version bumped 1.0.0 → 2.0.0; `yourusername` placeholders replaced with `theneoai`
- CONTRIBUTING.md, README.md: `yourusername` placeholders replaced with `theneoai`

### 🔧 Fixed

- All three example skills: injected complete `§UTE` body section and `use_to_evolve:` YAML with all 11 fields
- `code-reviewer/skill.md`: all section headers converted to `## §N` format; Red Lines (§3) added; `created`/`updated` dates added
- `doc-generator/skill.md`: LEAN, evaluate, optimize, 快评, 评测, 优化 triggers added to trigger line
- `api-tester/skill.md`: `{{API_BASE_URL}}` placeholder replaced; `certified_lean_score` corrected 470 → 390; UTE YAML completed with all 11 fields
- All three `eval-report.md` files: rewritten to use canonical 100/300/400/200 rubric and correct certification thresholds (GOLD ≥900, SILVER ≥800)
- `skill-framework.md`: PATH CONVENTION comment block added; `updated` date refreshed

### 📊 Updated Certification Stats

| Skill | Type | Tier | Score (v2.0.0) |
|-------|------|------|----------------|
| api-tester | api-integration | 🥇 GOLD | 920/1000 |
| code-reviewer | workflow-automation | 🥈 SILVER | 820/1000 |
| doc-generator | data-pipeline | 🥇 GOLD | 895/1000 |

**Average Score: 878.3/1000**

---

## [1.0.0] - 2026-03-31

### 🎉 Initial Release

Skill Framework MVP - Production Ready

### ✨ Added

- **Core Framework**
  - 1000-point evaluation system with 4-phase pipeline
  - Multi-LLM deliberation mechanism (Generator/Reviewer/Arbiter)
  - Self-evolution system with 3 triggers (Threshold/Time/Usage)
  - Native bilingual support (Chinese & English)

- **Example Skills** (3 certified skills, average score: 938.3/1000)
  - `api-tester` - HTTP API testing automation (GOLD 920/1000)
  - `code-reviewer` - Code review with security scanning (PLATINUM 960/1000)
  - `doc-generator` - Documentation generation pipeline (GOLD 935/1000)

- **GitHub Community**
  - Issue templates (skill submission, bug report, feature request)
  - GitHub Actions workflow for stale issue management
  - Code of Conduct based on Contributor Covenant
  - Contributing guidelines
  - Security policy with CWE scanning

- **Documentation**
  - Comprehensive README with badges and Mermaid architecture diagram
  - Project summary with certification details
  - This changelog

### 🏆 Certification Stats

| Skill | Type | Tier | Score |
|-------|------|------|-------|
| api-tester | api-integration | 🥇 GOLD | 920/1000 |
| code-reviewer | workflow-automation | 🏆 PLATINUM | 960/1000 |
| doc-generator | data-pipeline | 🥇 GOLD | 935/1000 |

**Average Score: 938.3/1000**

### 📊 Project Metrics

- Total Files: 17
- Total Lines: 3,250+
- Example Skills: 3
- GitHub Templates: 3
- CI/CD Workflows: 1

### 🔗 Links

- [Repository](https://github.com/theneoai/skill-writer)
- [Documentation](https://github.com/theneoai/skill-writer#readme)
- [Examples](https://github.com/theneoai/skill-writer/tree/main/examples)
- [Contributing](https://github.com/theneoai/skill-writer/blob/main/.github/CONTRIBUTING.md)

---

[3.2.0]: https://github.com/theneoai/skill-writer/releases/tag/v3.2.0
[3.1.0]: https://github.com/theneoai/skill-writer/releases/tag/v3.1.0
[3.0.0]: https://github.com/theneoai/skill-writer/releases/tag/v3.0.0
[2.2.0]: https://github.com/theneoai/skill-writer/releases/tag/v2.2.0
[2.1.0]: https://github.com/theneoai/skill-writer/releases/tag/v2.1.0
[2.0.0]: https://github.com/theneoai/skill-writer/releases/tag/v2.0.0
[1.0.0]: https://github.com/theneoai/skill-writer/releases/tag/v1.0.0
