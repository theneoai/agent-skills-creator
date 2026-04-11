# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-04-11

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
- **Co-Evolutionary VERIFY step (§9 OPTIMIZE Step 10)** — independent re-evaluation pass after OPTIMIZE convergence, approximating EvoSkills' Surrogate Verifier (arxiv:2604.01687); detects score inflation (delta > 50 pts → HUMAN_REVIEW)
- **Mandatory Skill Summary paragraph** — first content paragraph in every generated skill; ≤5 sentences densely encoding domain knowledge; decisive for skill routing (SkillRouter arxiv:2603.22455: 91.7% cross-encoder attention on body)
- **Mandatory Negative Boundaries section** — required `## Negative Boundaries` in every skill; "Do NOT use for" list with 3+ anti-cases; prevents mis-triggering (SKILL.md Pattern best practice)
- **OWASP Agentic Skills Top 10 (2026) detection** — 10 new ASI checks in `refs/security-patterns.md §5`; ASI01-ASI04 are P1 (score penalty); ASI05-ASI10 are P2 (advisory); addresses SkillProbe finding that 26.1% of community skills contain vulnerabilities
- **ASI01 Prompt Injection as P1 pattern** — new `refs/security-patterns.md §1.2`; detection heuristics for goal hijack and external content injection; −50 pts
- **P2 advisory patterns** — new `refs/security-patterns.md §1.3`: Missing Negative Boundaries + Executable Script Risk (2.12× higher vulnerability per SkillProbe)
- **SkillRL lesson distillation** — `refs/session-artifact.md` new fields: `lesson_type: strategic_pattern | failure_lesson | neutral` + `lesson_summary` (≤3 sentences); `skill-framework.md §18 COLLECT` new Step 4 CLASSIFY LESSON TYPE
- **`skill_tier` metadata field** — `templates/base.md` YAML: `planning | functional | atomic` (SkillX three-tier hierarchy, arxiv:2604.04804)
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
EvoSkills (2604.01687), SkillX (2604.04804), SkillRL (2602.08234), SkillRouter (2603.22455),
SkillClaw (2604.08377), Skills-in-the-Wild (2604.04323), SkillProbe (2603.21019),
SoK: Agentic Skills (2602.20867), and Agent Skills Survey (2602.12430).
Community sources: OWASP Agentic Top 10 (2026), SKILL.md Pattern, agentskills.io spec.

---

## [3.0.0] - 2026-04-11

### ✨ Added

- **COLLECT Mode (§18)** — structured session artifact recording; fires after every skill invocation when UTE is enabled; enables collective skill evolution via the AGGREGATE pipeline
- **AGGREGATE Mode** — multi-session distillation pipeline (Summarize → Aggregate → Execute) synthesizing N session artifacts into ranked improvement signals
- **`refs/session-artifact.md`** — canonical Session Artifact schema (skill_id, outcome, prm_signal, dimension_observations, causal-chain summary); SkillClaw-compatible format
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
- `ARCHITECTURE-REVIEW.md` — new Section 十 synthesizing SkillClaw research into product and architecture design recommendations

### 📋 Background

The v3.0 additions are informed by SkillClaw (arxiv.org/abs/2604.08377, AMAP-ML), which
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

[3.1.0]: https://github.com/theneoai/skill-writer/releases/tag/v3.1.0
[3.0.0]: https://github.com/theneoai/skill-writer/releases/tag/v3.0.0
[2.2.0]: https://github.com/theneoai/skill-writer/releases/tag/v2.2.0
[2.1.0]: https://github.com/theneoai/skill-writer/releases/tag/v2.1.0
[2.0.0]: https://github.com/theneoai/skill-writer/releases/tag/v2.0.0
[1.0.0]: https://github.com/theneoai/skill-writer/releases/tag/v1.0.0
