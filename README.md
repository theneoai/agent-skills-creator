# Skill Writer

A cross-platform meta-skill for creating, evaluating, and optimizing AI assistant skills through natural language interaction.

[![Version](https://img.shields.io/badge/version-3.4.0-blue.svg)](https://github.com/theneoai/skill-writer)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-8-orange.svg)](#supported-platforms)

## What is a skill?

A **skill** is a small instruction file (Markdown, `.md`) that you place in your AI assistant's skills folder. It tells the assistant how to handle a specific type of request — like "summarize a git diff", "write a PR description", or "validate API responses". When you say something that matches the skill's trigger phrases, the assistant follows the skill's instructions automatically.

Think of it like a custom command: you define what it does once, and then the assistant does it consistently every time you ask.

After creating a skill, it lives in `~/.claude/skills/` (or your platform's equivalent). Restart the assistant to activate it.

---

## Overview

Skill Writer is a meta-skill that enables AI assistants to create, evaluate, and optimize other skills through natural language interaction. No CLI commands required - just describe what you need.

### Key Features

- **Agent Install**: One-line install via "read [URL] and install" — works in any supported platform
- **Zero CLI Interface**: Natural language interaction - no commands to memorize
- **Cross-Platform**: Works on 8 platforms — Claude, OpenClaw, OpenCode, Cursor, Gemini, OpenAI, Kimi, Hermes
- **Eight Powerful Modes**: CREATE, LEAN, EVALUATE, OPTIMIZE, INSTALL, COLLECT, SHARE, and GRAPH
- **Template-Based**: 4 built-in templates for common skill patterns
- **Quality Assurance**: 1000-point scoring system with certification tiers
- **Tier-Aware Evaluation**: Tier-adjusted scoring weights for `planning` / `functional` / `atomic` skills (SkillX three-tier hierarchy)
- **Reliable LEAN Scoring**: 16 checks split into `[STATIC]` (deterministic, 335 pts, zero variance) and `[HEURISTIC]` (LLM-judged, 165 pts) — score variance documented per phase
- **Security Built-In**: CWE-based + OWASP Agentic Skills Top 10 (ASI01–ASI10) detection + supply-chain trust verification for pulled skills
- **Continuous Improvement**: Automated optimization with convergence detection + co-evolutionary VERIFY step + persistent score history
- **Self-Evolution**: UTE (Use-to-Evolve) L1 in-session always active; L2 collective with hooks/backend
- **Honest Skill Labeling**: `generation_method` + `validation_status` fields prevent unvalidated skills from silently reaching production
- **Behavioral Verifier**: Optional task-sample testing produces a `pragmatic_success_rate` independent of theoretical score
- **Multi-Pass Self-Review**: Generate/Review/Reconcile quality protocol
- **Graph of Skills (GoS)**: Typed dependency graph with minimum viable `depends_on` runtime; full bundle retrieval for v4.0+
- **Bilingual**: Full English + Chinese (中文) support for all modes. Framework documentation (refs/ companion files) is in English.

### Feature Availability — CORE vs. EXTENDED

Not all features require infrastructure. This table shows what works out-of-the-box vs. what needs hooks or a backend.

| Feature | Availability | Requirement |
|---------|-------------|-------------|
| CREATE / LEAN / EVALUATE | `[CORE]` | None — works in any LLM session |
| OPTIMIZE (up to 20 rounds) | `[CORE]` | None |
| INSTALL (local platform deploy) | `[CORE]` | File system write access |
| Security scan (self-authored skills) | `[CORE]` | None |
| UTE L1 — in-session feedback + micro-patches | `[CORE]` | None |
| COLLECT — output Session Artifact JSON | `[CORE]` | None (save manually) |
| Pragmatic Test Phase (task-sample validation) | `[CORE]` | User provides 3–5 task samples |
| GoS `depends_on` dependency resolution | `[CORE]` | `graph:` block in skill YAML |
| UTE L1 — cross-session invocation counts | `[EXTENDED]` | Claude Code hooks (`ute-tracker.js`) |
| UTE L2 — collective multi-user evolution | `[EXTENDED]` | AGGREGATE pipeline + shared backend |
| SHARE — push/pull to remote registry | `[EXTENDED]` | S3 / OSS / HTTP backend |
| COLLECT — auto-write artifacts to disk | `[EXTENDED]` | File system hooks |
| Trust-chain verification for pulled skills | `[EXTENDED]` | Registry with SHA-256 signing |
| GoS full bundle retrieval + health checks | `[EXTENDED]` | `builder/src/core/graph.js` (v4.0+) |

> **Unsure?** Assume `[CORE]` only. All 8 modes work fully without any backend — `[EXTENDED]` features add persistence and collective learning but are never required.

## Supported Platforms

| Platform | Installation Path | Routing File | Format |
|----------|-------------------|--------------|--------|
| [Claude](https://claude.ai) | `~/.claude/skills/` | `~/.claude/CLAUDE.md` | Markdown |
| [OpenClaw](https://openclaw.ai) | `~/.openclaw/skills/` | `~/.openclaw/AGENTS.md` | Markdown |
| [OpenCode](https://opencode.ai) | `~/.config/opencode/skills/` | `~/.config/opencode/AGENTS.md` | Markdown |
| [Cursor](https://cursor.com) | `.cursor/rules/` (project) | Built-in rules | MDC |
| [Gemini](https://gemini.google.com) | `~/.gemini/skills/` | `~/.gemini/GEMINI.md` | Markdown |
| [OpenAI](https://openai.com) | `{project}/skills/` | `{project}/AGENTS.md` | Markdown |
| [Kimi](https://kimi.moonshot.cn) | `~/.config/kimi/skills/` | `~/.config/kimi/AGENTS.md` | Markdown |
| [Hermes](https://hermes.ai) | `~/.hermes/skills/` | `~/.hermes/AGENTS.md` | Markdown |

All platforms receive the same skill file, companion files (refs/, templates/, eval/, optimize/), routing rules, and install script — full feature parity.

### Platform Feature Matrix

| Feature | Claude | OpenClaw | OpenCode | Cursor | Gemini | OpenAI | Kimi | Hermes |
|---------|--------|----------|----------|--------|--------|--------|------|--------|
| All 8 modes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Companion files | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| UTE L1 (in-session) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| UTE L1 cross-session | ✅ (hooks) | — | — | — | — | — | — | — |
| UTE L2 collective | ✅ (backend) | ✅ (backend) | ✅ (backend) | — | — | — | — | — |
| Routing file | CLAUDE.md | AGENTS.md | AGENTS.md | .mdc rules | GEMINI.md | AGENTS.md | AGENTS.md | AGENTS.md |
| Platform metadata | — | openclaw block | triggers footer | alwaysApply | — | — | bilingual | — |
| Hook injection | ✅ settings.json | — | — | — | — | — | — | — |
| Keyword-only triggers | — | — | — | ✅ (IDE intercepts /) | — | — | — | — |

> **UTE L1 in-session** works on all platforms with no configuration — the AI observes feedback and proposes micro-patches within the conversation. **UTE L1 cross-session** (persistent invocation counts and cadence gates) requires Claude Code hooks; see `refs/use-to-evolve.md §8` for setup. **UTE L2 collective** requires a shared backend (S3/OSS/HTTP) and the AGGREGATE pipeline.

## Quick Start

> **START HERE →** New to skill-writer? Follow this dependency flow:
> ```
> 1. INSTALL  → install skill-writer to your platform (one-liner below)
> 2. CREATE   → describe a skill you want and answer 8 questions
> 3. LEAN     → quick quality check (5s, 500 pts) — is the structure solid?
> 4. EVALUATE → full quality score (60s, 1000 pts) — what certification tier?
> 5. OPTIMIZE → improve to target tier (up to 20 rounds with convergence guard)
> 6. SHARE    → package and distribute to your team or registry
> ```
> Each step feeds the next. Skip ahead only if you already have a skill file.

### System Requirements

| Requirement | Version | Purpose | Install |
|-------------|---------|---------|---------|
| **Bash** | 4.0+ | Install scripts | Pre-installed on macOS/Linux |
| **Python 3** | 3.8+ | Routing-file merge (CLAUDE.md / AGENTS.md) | See below |
| **Node.js** | 16+ | Optional — UTE cross-session hooks only | See below |
| **Git** | any | Clone repository | Pre-installed or [git-scm.com](https://git-scm.com) |

**macOS (Homebrew):**
```bash
brew install python3          # required
brew install node             # optional — only if you want UTE cross-session hooks
```

**Ubuntu / Debian:**
```bash
sudo apt update && sudo apt install python3   # required
sudo apt install nodejs npm                   # optional
```

**Windows (Git Bash + WSL2 recommended):**
```bash
# Option A — Git Bash (for Cursor install only; no python3 needed):
#   Download: https://git-scm.com/download/win
#   Run cursor/install.sh inside Git Bash — no Python required for Cursor

# Option B — WSL2 (full support, all platforms):
wsl --install                 # enable WSL2
# then follow Ubuntu instructions above inside WSL2

# Option C — PowerShell (Cursor only):
#   See cursor/install.ps1 for a PowerShell-native installer
```

> **Cursor users on Windows**: Python 3 is NOT required for Cursor installation
> (the Cursor installer only copies files; no routing-file merge is needed).

### Installation

#### Option 1 — Agent Install (recommended — no git, no scripts)

Paste one line into your AI agent. The agent reads the skill file and installs itself.

| Platform | Paste into your AI agent |
|----------|--------------------------|
| **Claude** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-claude.md and install` |
| **OpenClaw** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-openclaw.md and install` |
| **OpenCode** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-opencode.md and install` |
| **Cursor** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-cursor.mdc and install` |
| **Gemini** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-gemini.md and install` |
| **OpenAI** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-openai.md and install` |
| **Kimi** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-kimi.md and install` |
| **Hermes** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-hermes.md and install` |
| **Auto-detect** | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer.md and install` |

The agent writes the skill file to the correct location, merges routing rules, and confirms activation.

#### Option 2 — Shell Script (from git clone)

```bash
git clone https://github.com/theneoai/skill-writer.git
cd skill-writer

# Auto-detect installed platforms and install
./install.sh

# Install to a specific platform
./install.sh --platform claude
./install.sh --platform openclaw
./install.sh --platform opencode

# Install to all 8 platforms
./install.sh --all

# Preview without making changes
./install.sh --dry-run
```

Each platform's install script copies:
- `{platform}/skill-writer.md` → `~/{platform-home}/skills/`
- `refs/ templates/ eval/ optimize/` → `~/{platform-home}/`
- Routing rules (CLAUDE.md / AGENTS.md) → merged idempotently

**After installation → restart your AI platform, then try:**
```
"create a skill that summarizes git diffs"
```
That's it. The AI will ask 8 questions and generate a complete skill file.

> **Cursor users**: Use keyword phrases — NOT slash commands.
> The IDE intercepts `/` for its own command palette.
> ✓ `create a skill`  ✗ `/create`
> ✓ `lean eval`       ✗ `/lean`
> ✓ `evaluate this skill`  ✗ `/eval`

#### Option 3 — Manual Copy (no script needed)

```bash
# Claude
mkdir -p ~/.claude/skills
cp claude/skill-writer.md ~/.claude/skills/skill-writer.md
# Then restart Claude

# OpenClaw
mkdir -p ~/.openclaw/skills
cp openclaw/skill-writer.md ~/.openclaw/skills/skill-writer.md
# Then restart OpenClaw

# OpenCode
mkdir -p ~/.config/opencode/skills
cp opencode/skill-writer.md ~/.config/opencode/skills/skill-writer.md
# Then restart OpenCode
```

### Usage Examples

**Create a new skill:**
```
"Create a weather API skill that fetches current conditions"
```

**Quick evaluation (LEAN mode):**
```
"Quickly evaluate this skill"
"快评这个技能"
```

**Full evaluation:**
```
"Evaluate this skill and give me a quality score"
"评测这个技能"
```

**Optimize a skill:**
```
"Optimize this skill to make it more concise"
"优化这个技能"
```

**Install skill-writer (agent-driven):**
```
"read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-claude.md and install"
"read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer.md and install"
"安装 skill-writer"
```

## Modes

### CREATE Mode

Generates new skills from scratch using structured templates and elicitation.

#### Workflow (9-Phase)
1. **ELICIT**: Ask 8 clarifying questions to understand requirements
2. **SELECT TEMPLATE**: Choose from 4 built-in templates based on your answers
3. **PLAN**: Multi-pass self-review for implementation strategy
4. **GENERATE**: Create skill using template — includes **Skill Summary** and **Negative Boundaries** (see below)
5. **SECURITY SCAN**: Check for CWE vulnerabilities + OWASP ASI01–ASI10
6. **LEAN EVAL**: Fast 500-point heuristic evaluation
7. **FULL EVALUATE**: Complete 1000-point evaluation (if LEAN uncertain or score near boundary)
8. **INJECT UTE**: Add Use-to-Evolve self-improvement hooks
9. **DELIVER**: Output final skill file with activation instructions

#### Failure-Driven CREATE (Recommended for Domain-Specific Skills)

Instead of starting from scratch, you can feed recent task failures directly to CREATE:

```
/create --from-failures
```

You'll be prompted to paste 1–3 conversation snippets where the AI produced incorrect or incomplete results. CREATE extracts the recurring failure patterns and uses them to pre-fill the Workflow, Error Handling, and Negative Boundaries sections — resulting in a domain-grounded skill rather than a generic template output.

> **Research basis**: SkillForge (arxiv:2604.08618) shows that domain-contextualized skill creation (grounded in failure trajectories) produces skills significantly better aligned with real-world task requirements than template-only generation.

#### Honest Skill Labeling

Every generated skill includes two machine-readable fields in its YAML frontmatter:

```yaml
generation_method: "auto-generated"   # auto-generated | human-authored | hybrid
validation_status: "lean-only"         # unvalidated | lean-only | full-eval | pragmatic-verified
```

These fields are checked at SHARE and INSTALL time. Skills marked `auto-generated + lean-only` trigger a deployment warning and require at minimum a full EVALUATE before being pushed to a shared registry. This prevents unvalidated skills from silently reaching production.

> **Research basis**: SkillsBench (arxiv:2602.12670) found that self-generated skills provide zero average benefit and can degrade performance. Explicit labeling ensures users know what they are deploying.

#### What's in the Generated Skill File

Every skill file includes two mandatory sections that new users often wonder about:

**Skill Summary** (§2 in the file) — 5 sentences describing what the skill does, who it's for,
what the input/output looks like, and what it's NOT for. This is how the AI knows whether to
activate the skill for a given request.

**Negative Boundaries** (§3 in the file) — A list of "Do NOT use this skill for..." examples.
This prevents the skill from firing when a user asks something similar but out of scope.
Example: A "code reviewer" skill should NOT trigger when someone asks "explain this diagram".
Without this section, skills false-trigger on semantically similar requests.

> Both sections are auto-generated from your elicitation answers (Q6 and Q7). You can edit
> them after creation to make them more specific — run `/lean` after editing to check score.

#### Available Templates

| Template | Use for | Example skill |
|----------|---------|---------------|
| **Base** | Simple skills, proof of concepts, text analysis | meeting summarizer, language translator |
| **API Integration** | REST APIs, webhooks, integrations | weather fetcher, GitHub PR creator |
| **Data Pipeline** | ETL, data transformation, analysis | CSV validator, log parser |
| **Workflow Automation** | Multi-step tasks, CI/CD, orchestration | deploy checker, PR review workflow |

> Not sure which to pick? If your skill makes HTTP calls → API Integration. If it transforms
> data step-by-step → Data Pipeline. If it coordinates multiple sub-tasks → Workflow Automation.
> Otherwise → Base.

#### Triggers (EN/ZH)
- "create a [type] skill" / "创建一个[类型]技能"
- "help me write a skill for [purpose]" / "帮我写一个技能"
- "I need a skill that [description]" / "我需要一个技能"
- "generate a skill to [action]" / "生成一个技能"
- "build a skill for [task]" / "构建一个技能"

### LEAN Mode

Fast evaluator for rapid quality assessment. Core rubric is **500 points** (7 dimensions, D1–D7). Skills with a `graph:` block earn an optional **D8 Composability bonus** of up to 20 pts (max total: 520). Checks are labeled by execution method:
- **`[STATIC]`** — deterministic regex/structural match; same skill → same result every run (335 pts max, zero variance)
- **`[HEURISTIC]`** — requires LLM judgment to assess adequacy (165 pts max, ±5–15 pts variance)
- **`[BONUS]`** — D8 Composability; only scored when `graph:` block is present; 0 pts if absent (no penalty)

#### 16-Check Rubric (organized by dimension)

| Dimension | Check | Points | Type |
|-----------|-------|--------|------|
| **System Design** (max 95) | Identity section present (`## §1` or `## Identity`) | 55 | `[STATIC]` |
| | Red Lines / 严禁 text present | 40 | `[STATIC]` |
| **Domain Knowledge** (max 95) | Template type correctly matched (API/pipeline/workflow keywords) | 55 | `[HEURISTIC]` |
| | Field specificity visible (concrete values, not generic placeholders) | 40 | `[HEURISTIC]` |
| **Workflow** (max 75) | ≥ 3 `## §N` pattern sections | 45 | `[STATIC]` |
| | Quality Gates table with numeric thresholds | 30 | `[STATIC]` |
| **Error Handling** (max 75) | Error/recovery section present | 45 | `[STATIC]` |
| | Escalation paths documented (HUMAN_REVIEW path present) | 30 | `[HEURISTIC]` |
| **Examples** (max 75) | ≥ 2 fenced code blocks | 45 | `[STATIC]` |
| | Trigger keywords present in both EN + ZH | 30 | `[STATIC]` |
| **Security** (max 45) | Security Baseline section present | 25 | `[STATIC]` |
| | No hardcoded secrets pattern | 10 | `[STATIC]` |
| | ASI01: no unguarded `{user_input}` interpolation in commands | 10 | `[HEURISTIC]` |
| **Metadata** (max 40) | YAML frontmatter with `name`, `version`, `interface` | 15 | `[STATIC]` |
| | `triggers` field with ≥ 3 EN + ≥ 2 ZH phrases | 15 | `[STATIC]` |
| | Negative Boundaries section present | 10 | `[STATIC]` |
| **Composability D8** *(bonus, max +20)* | `graph:` block present with at least one typed edge | 10 | `[BONUS]` |
| | `skill_tier` matches graph role (planning→composes, atomic→no depends_on) | 5 | `[BONUS]` |
| | All edge `skill_id` values use valid `[a-f0-9]{12}` format | 5 | `[BONUS]` |

#### Score Proxies and Decision Gates

| LEAN Score | Proxy | Decision |
|------------|-------|----------|
| ≥ 475 (core) | PLATINUM proxy (est. ≥ 950) | LEAN PASS — deliver with `LEAN_CERT` |
| ≥ 450 (core) | GOLD proxy (est. ≥ 900) | LEAN PASS |
| ≥ 400 (core) | SILVER proxy (est. ≥ 800) | LEAN PASS |
| ≥ 350 (core) | BRONZE proxy (est. ≥ 700) | LEAN PASS |
| 300–349 (core) | UNCERTAIN | Escalate to full EVALUATE |
| < 300 (core) | FAIL | Route to OPTIMIZE |

> **D8 bonus**: Added on top of the core score. A skill at 460 core + 20 D8 = 480 total. D8 does not affect pass/fail thresholds — thresholds are evaluated against core score only.
>
> **Score reliability**: If two LEAN runs differ by ≤ 20 pts, treat them as equivalent.
> Static-only floor (335 pts) means any well-structured skill will clear the PASS threshold on `[STATIC]` checks alone.

#### Triggers
- "lean evaluate" / "快评"
- "quick check" / "快速检查"
- "rapid eval" / "快速评估"

### EVALUATE Mode

Assesses skill quality with rigorous 1000-point scoring and certification.

#### 4-Phase Pipeline

| Phase | Points | Focus | Variance |
|-------|--------|-------|---------|
| Phase 1: Structural | 100 | YAML syntax, format, metadata, `generation_method`/`validation_status` fields | ±0–5 pts |
| Phase 2: Content Quality | 300 | Clarity, completeness, accuracy, safety, maintainability, usability | ±15–30 pts |
| Phase 3: Runtime Tests | 400 | Unit, integration, sandbox, error handling, performance, security tests | ±20–40 pts |
| Phase 4: Certification | 200 | Variance gate, security scan, F1/MRR gates, behavioral verifier, consensus | ±5–10 pts |

> **Total score variance**: ±30–60 pts across runs. Re-run if the score falls in a confidence zone (see below).

#### Pragmatic Test Phase (Optional — recommended before production deploy)

After the 4-phase pipeline, you can trigger an additional Pragmatic Test by providing real task samples:

```
/eval --pragmatic  (then provide 3–5 actual task examples)
```

The Pragmatic Test executes the skill against your samples and reports a **pragmatic_success_rate** independently of the theoretical score:

```
THEORETICAL SCORE:  920/1000  →  GOLD
PRAGMATIC RESULTS:  4/5 tasks passed  (80%)  →  PRAGMATIC_GOOD
```

This closes the gap between "looks good on paper" and "works in my actual workflow". If `pragmatic_success_rate < 60%`, deployment is blocked until the skill is optimized against the failing samples.

> **Research basis**: "Skills in the Wild" (arxiv:2604.04323) found that 39 of 49 evaluated skills yielded zero pass-rate improvement in realistic settings — high theoretical scores do not guarantee real-world utility.

#### Tier-Adjusted Phase 2 Weights

Phase 2 weights shift based on `skill_tier` in YAML frontmatter:

| Dimension | `planning` | `functional` (default) | `atomic` |
|-----------|-----------|----------------------|---------|
| System Design | **30%** | 20% | 15% |
| Workflow | **25%** | 20% | 15% |
| Error Handling | 15% | 15% | **25%** |
| Examples | 10% | 15% | **20%** |
| Security | 10% | 15% | **15%** |

#### Certification Tiers

| Tier | Score | Confidence Zone (re-run) | Phase 2 Min | Phase 3 Min |
|------|-------|--------------------------|-------------|-------------|
| **PLATINUM** | ≥950 | 940–959 | ≥270 | ≥360 |
| **GOLD** | ≥900 | 890–919 | ≥255 | ≥340 |
| **SILVER** | ≥800 | 790–819 | ≥225 | ≥300 |
| **BRONZE** | ≥700 | 690–719 | ≥195 | ≥265 |
| **FAIL** | <700 | — | — | — |

> **Confidence zone**: Scores within ±10 pts of a tier boundary may flip on re-run. Run twice and take the lower score.

#### Triggers (EN/ZH)
- "evaluate this skill" / "评测这个技能"
- "check the quality" / "检查质量"
- "certify my skill" / "认证我的技能"
- "score this skill" / "评分"
- "assess this skill" / "评估这个技能"

### OPTIMIZE Mode

Continuously improves skills through iterative refinement with 8-dimension analysis (7 core + D8 Composability bonus).

#### 8-Dimension Analysis

| Dimension | Weight | Focus |
|-----------|--------|-------|
| System Design | 20% | Architecture, workflow structure |
| Domain Knowledge | 20% | Accuracy, terminology, context |
| Workflow Definition | 20% | Step clarity, transitions |
| Error Handling | 15% | Edge cases, recovery |
| Examples | 15% | Coverage, relevance |
| Security | 10% | CWE + OWASP ASI baseline |
| Metadata | 10% | Documentation, tags, tier |
| **Composability (D8)** | *bonus* | Graph block, typed edges, tier consistency (S10/S11/S12) |

> **D8 strategies**: S10 Graph Extraction (decompose monolithic skills into composable sub-skills), S11 Coupling Reduction (break circular dependencies via intermediate skill), S12 Similarity Consolidation (merge near-duplicate skills with similarity ≥ 0.95). These activate when LEAN D8 score < 15 or when `/graph check` reports GRAPH-004/005.

#### 10-Step Optimization Loop
1. **Parse**: Understand current skill and read `skill_tier` for weight selection
2. **Analyze**: Identify improvement areas across 7 dimensions (tier-adjusted weights)
3. **Generate**: Create optimized version
4. **Evaluate**: Score the new version (LEAN 500-pt scale)
5. **Compare**: Check against previous
6. **RE-SCORE**: Re-score after each single fix
7. **Converge**: Detect improvement plateau
8. **Report**: Show changes and dimension breakdown
9. **Iterate**: Repeat if needed (max 20 rounds)
10. **VERIFY**: Co-evolutionary independent re-evaluation after convergence — score inflation delta > 50 pts → HUMAN_REVIEW

> **Tier-aware strategy** (from `optimize/strategies.md §6`):
> - `planning` skills: prioritize Workflow (25%) → System Design (30%) first
> - `atomic` skills: prioritize Error Handling (25%) → Examples (20%) first
> - `functional` skills: target lowest-scoring dimension first (default)

#### Convergence Detection
Optimization stops when:
- Score improvement < 0.5 points
- 10 iterations without significant gain (plateau window)
- User requests stop
- Maximum iterations reached (20)
- DIVERGING detected → HALT → HUMAN_REVIEW

#### When to Stop Optimizing

| Current Tier | Recommendation |
|-------------|----------------|
| FAIL (<700) | Keep optimizing — skill is not ready to use |
| BRONZE (700–799) | Optimize if planning to share; OK to use personally |
| SILVER (800–899) | Ready for team use with `beta` tag; PLATINUM push optional |
| GOLD (900–949) | Excellent quality; further PLATINUM optimization is nice-to-have only |
| PLATINUM (≥950) | Done — publish with `stable` tag |

> GOLD (≥900) is the target for most team skills. PLATINUM (≥950) is for widely-shared or
> production-critical skills. Don't optimize past GOLD unless you have a specific quality goal.

#### Triggers (EN/ZH)
- "optimize this skill" / "优化这个技能"
- "improve my skill" / "改进我的技能"
- "make this skill better" / "让这个技能更好"
- "refine this skill" / "精炼这个技能"
- "enhance this skill" / "增强这个技能"

### INSTALL Mode

> **INSTALL vs. SHARE — which do you want?**
> - **INSTALL** = deploys the *skill-writer framework* to your AI platform. Use this once, when setting up.
>   Trigger: `"install skill-writer"` / `"install skill-writer to claude"`
> - **SHARE** = packages a skill *you created* and distributes it to your team.
>   Trigger: `"share this skill"` / `"export my skill"` / `"install my skill to claude"`
>
> Rule of thumb: if the object is **skill-writer** → INSTALL. If the object is **your skill** → SHARE.

Installs skill-writer itself to one or all supported platforms from a URL or local clone.

#### Workflow
1. **PARSE_INPUT**: Extract URL and target platform(s) from user message
2. **FETCH**: If URL provided, download and verify the file
2a. **RESOLVE DEPENDENCIES** *(v3.2.0)*: If the skill has a `graph:` block, read `depends_on` edges, build the dependency tree, and display the full manifest before proceeding. Install order follows topological sort (deepest dependency first).
3. **CONFIRM**: Show install plan (including dependency list if any), ask user to confirm
4. **INSTALL**: Write skill file(s) to each platform's skills directory in dependency order
4e. **AGENTS.md GENERATION** *(v3.3.0)*: After writing skill files, generate or update the platform's agent context file with skill registry routing rules. Target files: `~/.claude/CLAUDE.md` (Claude), `~/.config/opencode/AGENTS.md` (OpenCode), `~/.openclaw/AGENTS.md` (OpenClaw). Uses idempotent `<!-- skill-writer:start/end -->` markers — safe to re-run.
4f. **HOOK INJECTION** *(v3.3.0)*: Merge a `UserPromptSubmit` hook entry into `~/.claude/settings.json` (Claude only). The hook fires before the LLM sees each user message and injects a ≤50-token skill-awareness reminder. Appends to existing hook arrays; never overwrites.
5. **REPORT**: List installed paths, AGENTS.md path (created/updated), dependency results, and next steps

> **Three-Tier Routing Model** (v3.3.0): INSTALL now establishes all three routing layers in one pass:
> 1. **AGENTS.md** (step 4e) — session-constant skill inventory; always present in system prompt
> 2. **UserPromptSubmit Hook** (step 4f) — per-message nudge; fires before LLM reasoning starts
> 3. **Trigger phrases** — in-skill keyword routing from YAML `triggers.en/zh`

#### Platform Paths

| Platform | Skills Directory | Routing File |
|----------|-----------------|--------------|
| Claude | `~/.claude/skills/` | `~/.claude/CLAUDE.md` |
| OpenCode | `~/.config/opencode/skills/` | `~/.config/opencode/AGENTS.md` |
| OpenClaw | `~/.openclaw/skills/` | `~/.openclaw/AGENTS.md` |

### COLLECT Mode

COLLECT records a structured **Session Artifact** after each skill invocation — a snapshot of what happened, how well it worked, and what to improve. Accumulate 2+ artifacts, then run AGGREGATE to get a ranked improvement list for `/opt`.

**[CORE]** — COLLECT outputs JSON to the conversation. Copy it to a file manually.  
**[EXTENDED]** — With UTE hooks configured, COLLECT auto-writes to `~/.skill-artifacts/` after each invocation. No manual step needed.

#### When to run COLLECT
- After an important or representative skill invocation
- When a trigger phrase didn't match (helps identify missing keywords)
- Before running OPTIMIZE (feed artifacts as input for evidence-based improvement)

#### Workflow
1. **CAPTURE**: Record invocation context, outcome, and PRM signal
2. **CLASSIFY**: Assign lesson type (`strategic_pattern` / `failure_lesson` / `neutral`)
3. **BUNDLE CONTEXT** *(v3.2.0)*: If invoked as part of a multi-skill task, record `bundle_context` (co-invoked skills, invocation order, data flow, missing dependencies) and `graph_signals` (edge suggestions, merge candidates, composability score) — feeds the AGGREGATE graph auto-inference pipeline
4. **STORE**: Output JSON artifact `[CORE]` or auto-write to `~/.skill-artifacts/` `[EXTENDED]`
5. **AGGREGATE** (after 2+ artifacts): Distill artifacts into ranked improvement signals → OPTIMIZE candidates; automatically infers `depends_on` / `provides` / `consumes` edges from co-invocation patterns

#### Triggers (EN/ZH)
- `/collect` or `collect session data` / `收集本次会话` — manual trigger
- `record session artifact` / `记录会话数据`
- `export invocation log` / `导出调用日志`
- Auto-triggered by UTE after each invocation `[EXTENDED]`

#### AGGREGATE (multi-session synthesis)
After collecting 2+ Session Artifacts, type:
- `"aggregate skill feedback"` / `"聚合技能反馈"`

AGGREGATE groups findings by skill dimension, identifies the "no-skill bucket" (sessions where no skill triggered), and ranks improvement opportunities by evidence count. Output feeds directly into `/opt`.

### GRAPH Mode *(v3.2.0 — Graph of Skills)*

GRAPH manages the typed dependency graph between skills — visualize relationships, resolve bundles, detect health issues, and plan skill decomposition.

#### Sub-commands

| Command | Action |
|---------|--------|
| `/graph view` | ASCII art dependency graph for the current skill registry |
| `/graph check` | Run health checks GRAPH-001–008 (dangling edges, cycles, isolated nodes, etc.) |
| `/graph plan [skill-id]` | Plan decomposition of a monolithic skill into composable sub-skills |
| `/graph bundle [skill-id]` | Resolve the full execution bundle for a seed skill (BFS + PageRank) |
| `/graph diff` | Show edges added/removed since last registry snapshot |

#### Graph Data Model

Skills declare relationships in YAML frontmatter via an optional `graph:` block:

```yaml
graph:
  skill_id: "a1b2c3d4e5f6"        # SHA-256[:12] identifier
  tier: functional                  # planning | functional | atomic
  edges:
    - type: depends_on              # 6 types: depends_on, composes, similar_to,
      target_skill_id: "..."        #   uses_resource, provides, consumes
      label: "requires schema validation"
```

Six typed edge types are supported:

| Type | Meaning | Example |
|------|---------|---------|
| `depends_on` | Cannot run without target | api-tester → schema-validator |
| `composes` | Orchestrates target as a step | pipeline-runner → data-transformer |
| `similar_to` | Overlapping capability (merge candidate ≥ 0.95) | summarizer-v1 → summarizer-v2 |
| `uses_resource` | Reads a ref/template | any skill → refs/security-patterns.md |
| `provides` | Outputs an artifact consumed downstream | api-tester → "test-results-json" |
| `consumes` | Receives artifact from upstream | report-generator → "test-results-json" |

#### Graph Health Checks (GRAPH-001–008)

| Code | Severity | What it checks |
|------|----------|---------------|
| GRAPH-001 | WARNING | Edge `skill_id` not in `[a-f0-9]{12}` format |
| GRAPH-002 | WARNING | `planning` tier skill has no `composes` edges |
| GRAPH-003 | WARNING | `atomic` tier skill has `depends_on` edges (should be self-contained) |
| GRAPH-004 | WARNING | `similar_to` similarity ≥ 0.95 — merge advisory |
| GRAPH-005 | ERROR | Self-loop (skill depends on itself) |
| GRAPH-006 | WARNING | Circular dependency detected (A→B→C→A) |
| GRAPH-007 | INFO | Isolated node (no edges in or out) |
| GRAPH-008 | WARNING | `provides`/`consumes` artifact name mismatch |

#### Progressive Disclosure — Five-Layer Architecture *(v3.3.0)*

Skills are loaded only as far as needed for the task, keeping token use proportional to what the agent actually requires. Layer -1 is new in v3.3.0:

| Layer | Name | Token Budget | When Loaded |
|-------|------|-------------|-------------|
| **-1** | **Hook Injection** *(v3.3.0)* | ≤ 50 | Every message — `UserPromptSubmit` hook; fires before LLM sees input |
| 0 | Graph Context *(v3.2.0)* | ≤ 200 | Task matches a known bundle AND registry has `graph:` data |
| 1 | Advertise | ≤ 100 per skill | Every session — injected from YAML `name` + `description` |
| 2 | Load | < 5,000 | Task matches skill domain via trigger phrases |
| 3 | Read Resources | as needed | On-demand — skill body references a companion file |

**Layer -1 (v3.3.0)** fires at `UserPromptSubmit` — before the LLM decides what to do. This solves the "LLM forgets skills exist" failure mode that trigger-phrase matching alone cannot fix. INSTALL step 4f generates the hook config automatically.

**Layer 0 (v3.2.0)** — bundle context example:

```
Bundle: API Testing Suite
Skills (execute in order):
  1. schema-validator  → validates input schema     [atomic]
  2. api-tester        → executes test suite         [functional, entry point]
  3. report-generator  → produces coverage report    [functional]
Data flow: api-tester → report-generator via "test-results-json"
```

#### Triggers (EN/ZH)
- `/graph` or `skill graph` / `技能图`
- `show skill dependencies` / `显示技能依赖`
- `check graph health` / `检查技能图健康`
- `resolve bundle for [skill]` / `解析技能包`
- `plan skill decomposition` / `规划技能分解`

## Sharing Your Created Skills

Once you have created and evaluated a skill, you can share it with your team or publish it.

### SHARE Mode — Package and Distribute a Skill

Say any of the following to enter SHARE mode:
- `"share this skill"` / `"分享这个技能"`
- `"package my skill for distribution"` / `"打包我的技能"`
- `"install my skill to Claude"` / `"install this skill"`
- `"deploy my skill"` / `"部署我的技能"`

**SHARE is different from INSTALL**: INSTALL deploys skill-writer itself. SHARE packages a skill *you created* for use by others.

### 5-Step SHARE Workflow

1. **VALIDATE** — Checks that the skill has at minimum a BRONZE LEAN score (≥350/500). Skills below BRONZE are blocked from sharing.
2. **PACKAGE** — Wraps the skill in standard Markdown format for all 8 supported platforms.
3. **STAMP** — Adds certification metadata: tier badge, version, author, publish date.
4. **DELIVER** — Outputs the packaged skill as:
   - A copyable code block (all platforms `[CORE]`)
   - A downloadable file (if file system hooks are configured `[EXTENDED]`)
5. **GUIDE** — Explains where to place the file on each platform.

### Registry Publishing Thresholds

| Tier | Score | Registry Tag | Can Publish? |
|------|-------|-------------|--------------|
| PLATINUM/GOLD | ≥900 | `stable` | ✅ Recommended |
| SILVER | ≥800 | `beta` | ✅ Allowed |
| BRONZE | ≥700 | `experimental` | ✅ Allowed |
| FAIL | <700 | — | ❌ Fix first |

> Skills tagged `experimental` include a notice: "Community use — review before production deployment."
>
> Share via GitHub Gist:
> 1. Run `/share` → copy the packaged skill file output
> 2. Create a private GitHub Gist, paste the skill content
> 3. Share the raw Gist URL with your team: `"read [gist-url] and install to claude"`
> Team members paste that line into their AI assistant and the skill installs automatically.
>
> **v3.2.0**: The Skill Registry now supports schema v2.0 with `graph:` section for storing typed edges and bundles (`registry.json`). Skills with graph data include dependency manifests displayed during INSTALL.

### Team Deployment Workflow (step-by-step)

For team leads distributing a skill to team members:

```
1. Create & evaluate:
   /create → answer 8 questions → receive skill file
   /eval   → confirm tier (SILVER+ recommended for team use)

2. Get team lead approval (recommended for BRONZE; required for FAIL):
   → Share the EVALUATE report with team lead
   → Team lead reviews: Negative Boundaries + Security section
   → Team lead gives "approved" signal

3. Package and share:
   /share  → outputs packaged skill file + installation command

4. Team installs (each team member runs):
   "read [gist-url] and install to [platform]"

5. Iterate based on team feedback:
   Team members run /collect after using the skill
   Share artifacts with skill owner → /aggregate → /opt
```

---

## How Skills Work After Creation

When skill-writer finishes generating your skill, you have a **Markdown file** (`.md`) with a YAML frontmatter block. Here is what happens next:

### Skill Anatomy

```
---
name: my-skill
version: "1.0.0"
triggers:
  en: ["do X", "run X for me"]
  zh: ["执行X"]
---

## §1  Identity
...
```

The **YAML frontmatter** tells the AI assistant when to activate the skill (via the `triggers` list). The **Markdown body** is the skill's instructions — the AI reads this as its operating procedure.

### Where Your Skill File Goes

Place the `.md` file in the skills directory for your platform:

| Platform | Directory |
|----------|-----------|
| Claude | `~/.claude/skills/your-skill.md` |
| OpenCode | `~/.config/opencode/skills/your-skill.md` |
| OpenClaw | `~/.openclaw/skills/your-skill.md` |
After placing the file, restart the AI assistant. It will load the skill automatically on startup.

### How Trigger Routing Works

When you type a message, the AI compares it against each loaded skill's `triggers` list:
- Exact or near-match → skill activates
- No match → general assistant mode (no skill)

You can also activate skills with `/skill-name` on platforms that support slash commands (Claude, OpenCode, OpenClaw).

### Diagnosing False Triggers

A **false trigger** is when your skill activates for the wrong request (e.g., a "code reviewer" skill fires when someone says "review my architecture diagram").

**How to diagnose**:
1. Open your skill file and read the `triggers` section in the YAML frontmatter
2. Check the **Skill Summary** (§2) — if it's too broad, nearby skills will also match
3. Check the **Negative Boundaries** (§3) — add the false-triggering phrase there

**How to fix false triggers**:
```yaml
# In your skill's YAML frontmatter — add exclusions:
triggers:
  en:
    - "review my code"         # ← KEEP: your skill's purpose
    - "check this PR"          # ← KEEP
  # NOT listed → will not activate on these phrases
```

```markdown
## Negative Boundaries
**Do NOT use this skill for:**
- "review my architecture diagram" → use a diagram-explainer skill instead
- "explain this design doc" → use a doc-summarizer skill instead
```

**Debug by asking the AI**:
> "Does my skill `pr-reviewer` match the phrase 'review my architecture'? Show me why or why not."

The AI will explain which trigger phrases matched and which Negative Boundaries should have blocked it.

**If a skill isn't triggering when it should**:
1. Add the missing phrase to `triggers.en` in the YAML frontmatter
2. Run `/lean` to confirm triggers section has ≥3 EN + ≥2 ZH phrases (required for LEAN PASS)

### Improving Your Skill Over Time

| Situation | Action |
|-----------|--------|
| Skill triggered when it shouldn't | Add specific phrase to `Negative Boundaries` section |
| Skill missed a valid trigger phrase | Add phrase to `triggers.en` / `triggers.zh` in YAML |
| Output quality degraded | Run `/eval` → `/opt` |
| Many users gave similar feedback | Run `/collect` → `/aggregate` → `/opt` |
| Skill version bumped, team not notified | Update `version:` in YAML, reshare via `/share` |

---

## Security Features

### CWE Pattern Detection

Automatically checks for:
- **CWE-78**: OS Command Injection
- **CWE-79**: Cross-Site Scripting (XSS)
- **CWE-89**: SQL Injection
- **CWE-22**: Path Traversal
- And more...

### OWASP Agentic Skills Top 10 (2026)

| ID | Risk | Severity | What triggers it |
|----|------|----------|-----------------|
| ASI01 | Prompt Injection / Goal Hijack | P1 (−50 pts) | Skill instructions say "if user asks X, do Y" where Y ignores the skill's scope |
| ASI02 | Insecure Tool Use | P1 (−50 pts) | Skill calls external tools (shell, APIs) without validating input first; e.g., `run_command({user_input})` |
| ASI03 | Excessive Agency | P1 (−50 pts) | Skill takes irreversible actions (delete, send, publish) without explicit user confirmation step |
| ASI04 | Uncontrolled Resource Consumption | P1 (−50 pts) | No size/rate limits on loops or external calls; skill can run indefinitely |
| ASI05 | Missing Negative Boundaries | P2 (advisory) | No "Do NOT use for" section, or section uses only generic placeholders |
| ASI06 | Sensitive Data Exposure | P2 (advisory) | Skill outputs API keys, passwords, or PII in logs/responses |
| ASI07 | Insufficient Logging | P2 (advisory) | No audit trail or error logging defined |
| ASI08 | Insecure Deserialization | P2 (advisory) | Skill parses untrusted JSON/YAML without schema validation |
| ASI09 | Executable Script Risk | P2 (advisory) | Skill generates runnable code from user input without sandboxing note |
| ASI10 | Broken Access Control | P2 (advisory) | Skill doesn't check caller permissions before taking actions |

**To fix an ASI warning**: Read the "What triggers it" column. Common fixes:
- ASI02: Add an input validation step before any tool call
- ASI03: Add "ask user to confirm before proceeding" to any destructive action
- ASI05: Add a specific "Do NOT use for..." section with 2–3 concrete examples

### Security Severity Levels

| Level | Examples | Action |
|-------|----------|--------|
| P0 (Critical) | CWE-798, CWE-89, CWE-78 | ABORT immediately |
| P1 (High) | CWE-22, CWE-306, ASI01–ASI04 | −50 points |
| P2 (Medium) | ASI05–ASI10, various CWE | −30 points (advisory) |
| P3 (Low) | Minor issues | −10 points |

### Security Report Format

```
Security Scan Report
====================
P0: X violations (Critical)
P1: X violations (High)
P2: X violations (Medium)
P3: X violations (Low)

Recommendations:
- [Specific fixes]
```

## UTE (Use-to-Evolve)

Self-improvement protocol that enables skills to evolve through usage. Two-tier architecture:
- **L1 (Single-user)** `[CORE]`: Post-invocation hook runs per session; persists state to `~/.claude/skills/.ute-state/`
- **L2 (Collective)** `[EXTENDED]`: Requires external aggregation infrastructure (SkillClaw-compatible). See `refs/use-to-evolve.md §10`.

### UTE YAML Block

```yaml
use_to_evolve:
  enabled: true
  injected_by: "skill-writer v3.4.0"
  injected_at: "2026-04-11"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: 390
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
  generation_method: "auto-generated"   # auto-generated | human-authored | hybrid
  validation_status: "lean-only"        # unvalidated | lean-only | full-eval | pragmatic-verified
```

### Cadence-Gated Health Checks

| Cadence | Trigger | Action |
|---------|---------|--------|
| Every 10 invocations | Lightweight check | rolling_success_rate < 0.80 → warn |
| Every 50 invocations | Full metric recompute | F1 < 0.90 → queue OPTIMIZE |
| Every 100 invocations | Tier drift check | estimated_lean < (certified − 50) → full EVALUATE |

### Micro-Patch Rules

**Eligible** (apply autonomously after LEAN validation):
- Add trigger keyword (YAML + mode section)
- Add ZH trigger equivalent
- Bump patch version + update `updated` date

**Ineligible** (must queue for OPTIMIZE):
- Structural section changes, output contract changes, security baseline changes

### Platform Hook Integration (Claude Code / OpenCode)

UTE state tracking upgrades from `[EXTENDED]` to `[CORE]` when platform hooks are configured:

```json
// ~/.claude/settings.json
{
  "hooks": {
    "PostToolUse": [{"command": "bash ~/.claude/skills/ute-hook.sh post-tool"}],
    "Stop": [{"command": "bash ~/.claude/skills/ute-hook.sh stop"}]
  }
}
```

See `refs/use-to-evolve.md §8` for full hook setup instructions. The hook script is a plain bash file — no Node.js required.

## Project Structure

```
skill-writer/
├── claude/                        # Claude platform (direct-use files)
│   ├── skill-writer.md            # SKILL.md v3.4.0 compliant skill file
│   ├── CLAUDE.md                  # Routing rules (merged into ~/.claude/CLAUDE.md)
│   └── install.sh                 # Installs to ~/.claude/
├── openclaw/                      # OpenClaw platform
│   ├── skill-writer.md            # Same skill + metadata.openclaw YAML block
│   ├── AGENTS.md                  # Routing rules
│   └── install.sh                 # Installs to ~/.openclaw/
├── opencode/                      # OpenCode platform
│   ├── skill-writer.md            # Same skill + Triggers footer
│   ├── AGENTS.md                  # Routing rules
│   └── install.sh                 # Installs to ~/.config/opencode/
├── cursor/                        # Cursor platform (MDC format)
│   ├── skill-writer.mdc           # MDC rule (alwaysApply, keyword-only triggers)
│   └── install.sh                 # Installs to .cursor/rules/ (no Python required)
├── gemini/                        # Gemini platform
│   ├── skill-writer.md
│   ├── GEMINI.md                  # Routing rules
│   └── install.sh                 # Installs to ~/.gemini/skills/
├── openai/                        # OpenAI platform
│   ├── skill-writer.md
│   ├── AGENTS.md                  # Routing rules
│   └── install.sh                 # Installs to {project}/skills/
├── kimi/                          # Kimi platform (bilingual metadata)
│   ├── skill-writer.md
│   ├── AGENTS.md                  # Routing rules
│   └── install.sh                 # Installs to ~/.config/kimi/skills/
├── hermes/                        # Hermes platform (local LLM)
│   ├── skill-writer.md
│   ├── AGENTS.md                  # Routing rules
│   └── install.sh                 # Installs to ~/.hermes/skills/
├── refs/                          # Companion reference files (all platforms)
│   ├── self-review.md             # Multi-pass self-review protocol
│   ├── use-to-evolve.md           # UTE 2.0 self-improvement spec (L1/L2 architecture)
│   ├── evolution.md               # 6-trigger evolution system (v3.4.0)
│   ├── convergence.md             # Convergence detection rules
│   ├── security-patterns.md       # CWE + OWASP ASI security patterns
│   ├── session-artifact.md        # Session artifact schema (COLLECT mode)
│   ├── edit-audit.md              # Edit Audit Guard (MICRO/MINOR/MAJOR/REWRITE)
│   ├── skill-registry.md          # Skill Registry spec (SHA-256 IDs, push/pull/sync)
│   ├── skill-graph.md             # Graph of Skills spec (v3.2.0)
│   └── progressive-disclosure.md  # Five-layer loading pattern (Layer -1 ~ Layer 3)
├── templates/                     # Skill templates (4 types + UTE snippet)
│   ├── base.md
│   ├── api-integration.md
│   ├── data-pipeline.md
│   ├── workflow-automation.md
│   └── use-to-evolve-snippet.md
├── eval/                          # Evaluation resources
│   ├── rubrics.md                 # 1000-point scoring rubric (585 lines)
│   └── benchmarks.md              # Benchmark test cases
├── optimize/                      # Optimization resources
│   ├── strategies.md              # 8-dimension strategy catalog (S1–S12, 765 lines)
│   └── anti-patterns.md           # Common pitfalls
├── examples/                      # Certified example skills
│   ├── 00-starter/                # BRONZE ~730/1000 — learning reference
│   ├── api-tester/                # GOLD 920/1000
│   ├── code-reviewer/             # GOLD 947/1000
│   └── doc-generator/             # GOLD 895/1000
├── scripts/                       # CI/dev automation scripts
│   ├── lint.sh                    # Shellcheck wrapper for all install scripts
│   ├── validate.sh                # Dry-run all platform installers
│   └── check-version.py           # Version consistency check across platform files
├── docs/                          # Documentation and GitHub Pages site
│   ├── index.html                 # GitHub Pages landing page
│   ├── skill-creator-analysis.md  # Architecture analysis and design decisions
│   └── mcp-integration.md         # MCP server integration guide
├── Makefile                       # Dev targets: lint, validate, check-version, install, ci
├── skill-framework.md             # Complete specification (source of truth, 2772 lines)
└── install.sh                     # Top-level dispatcher → delegates to platform scripts
```

## Architecture

### Core + Adapter Pattern

```
┌──────────────────────────────────────────────────────────────────┐
│                     Skill Writer Meta-Skill                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌─────────────┐  ┌──────────────────┐  ┌─────────────────────┐  │
│  │ CREATE Mode │  │    LEAN Mode     │  │   EVALUATE Mode     │  │
│  │             │  │                  │  │                     │  │
│  │ • Templates │  │ • 500-pt scoring │  │ • 4-Phase pipeline  │  │
│  │ • Elicit 8Q │  │ • 16 checks      │  │ • 1000-pt scoring   │  │
│  │ • 9-Phase   │  │ • [STATIC] +     │  │ • Tier-adjusted     │  │
│  │   Workflow  │  │   [HEURISTIC]    │  │   Phase 2 weights   │  │
│  └─────────────┘  └──────────────────┘  └─────────────────────┘  │
│                                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────────┐  │
│  │OPTIMIZE Mode│  │INSTALL Mode │  │      COLLECT Mode        │  │
│  │             │  │             │  │                          │  │
│  │ • 8-dim     │  │ • 8-platform│  │ • Session artifact log   │  │
│  │   analysis  │  │   support   │  │ • Lesson classification  │  │
│  │ • 10-step   │  │ • Dep tree  │  │ • Bundle context (GoS)   │  │
│  │   loop      │  │   resolution│  │ • trigger_signals (v3.3) │  │
│  │ • VERIFY    │  │ • AGENTS.md │  │ • AGGREGATE pipeline     │  │
│  │             │  │   + Hook    │  │   Rule 4 trigger         │  │
│  │             │  │   (v3.3.0)  │  │   discovery (v3.3.0)     │  │
│  └─────────────┘  └─────────────┘  └──────────────────────────┘  │
│                                                                    │
│  ┌─────────────────────────────┐  ┌──────────────────────────┐   │
│  │        SHARE Mode           │  │      GRAPH Mode          │   │
│  │                             │  │      (v3.2.0)            │   │
│  │ • BRONZE+ gate (≥350/500)   │  │  • 6 typed edge types    │   │
│  │ • Package for 8 platforms   │  │  • Health checks 001–008 │   │
│  │ • Registry push/pull        │  │  • Bundle BFS+PageRank   │   │
│  │ • Honest label stamp        │  │  • D8 Composability      │   │
│  │ • stable/beta/experimental  │  │  • Layer 0 bundle ctx    │   │
│  └─────────────────────────────┘  └──────────────────────────┘   │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                     Shared Resources                       │   │
│  │  • CWE + OWASP ASI01–ASI10 Security Patterns              │   │
│  │  • UTE 2.0 Self-Evolution — 6 triggers (L1 + L2)          │   │
│  │  • Multi-Pass Self-Review (Generate/Review/Reconcile)      │   │
│  │  • Skill Registry v2.0 + SkillRouter weighted ranking      │   │
│  │    (quality threshold gate + usage_stats) — v3.3.0         │   │
│  │  • Edit Audit Guard (MICRO/MINOR/MAJOR/REWRITE classes)    │   │
│  │  • Five-Layer Progressive Disclosure (Layer -1 Hook,       │   │
│  │    Layer 0 GoS, Layer 1 Advertise, Layer 2–3) — v3.3.0     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Platform-Specific Builder (8 platforms)        │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐   │
│  │ Claude │ │OpenClaw │ │ OpenCode │ │ Cursor │ │  Gemini  │   │
│  │  .sh   │ │  .sh    │ │   .sh    │ │  .sh   │ │   .sh    │   │
│  └────────┘ └─────────┘ └──────────┘ └────────┘ └──────────┘   │
│                                                                    │
│  ┌────────┐ ┌──────┐                                             │
│  │ OpenAI │ │ Kimi │  Hermes install.sh                          │
│  │  .sh   │ │ .sh  │                                             │
│  └────────┘ └──────┘                                             │
└──────────────────────────────────────────────────────────────────┘
```

## Example Skills

All example skills are certified with detailed evaluation reports.

| Skill | Type | Tier | Score | Description |
|-------|------|------|-------|-------------|
| [git-commit-writer](examples/git-commit-writer/) | Base | 🏆 PLATINUM | 1007/1020 | Conventional Commits message generator — **full lifecycle walkthrough** |
| [api-tester](examples/api-tester/) | API Integration | 🥇 GOLD | 920/1000 | HTTP API testing automation |
| [code-reviewer](examples/code-reviewer/) | Workflow Automation | 🥇 GOLD | 947/1000 | Code review with security scanning |
| [doc-generator](examples/doc-generator/) | Data Pipeline | 🥇 GOLD | 895/1000 | Documentation generation |

### Walkthrough: Full Lifecycle Example (git-commit-writer)

The `git-commit-writer` example shows **every step** of the skill-writer process with real
inputs, scores, and diffs. Read it to understand what creating a skill actually looks like.

#### The 8-Question Elicitation Session

You type: `"create a skill that writes conventional commit messages"`

The AI asks 8 guided questions:

```
Q1  Skill name?                → git-commit-writer
Q2  Core functionality?        → Generate Conventional Commits 1.0.0 messages
                                  from git diff or description
Q3  Target user?               → Developers on teams that enforce conventional
                                  commits in CI
Q4  ≥3 English trigger phrases → "write commit message", "generate commit for
                                  this diff", "help me commit", ...
Q5  ≥2 Chinese trigger phrases → "写提交信息", "生成提交消息", "帮我写提交"
Q6  3+ things NOT to do        → no squash/rebase, no PR descriptions,
                                  no changelog, no explaining past commits
Q7  Modes needed?              → GENERATE (diff→message), VALIDATE (check message)
Q8  Security boundaries?       → read-only, no shell, no network
```

The AI selects `base.md` template (text generation, no API/pipeline/workflow), fills all
placeholders from your answers, and produces a complete 9-section skill file.

#### What the LEAN Output Looks Like

```
LEAN Evaluation — git-commit-writer v1.0.0
──────────────────────────────────────────────────────────
  ✓ [STATIC]    Identity + Red Lines           95/95
  ✓ [HEURISTIC] Template type matched          45/55   ← partial
  ✗ [HEURISTIC] Field specificity              28/40   ← gap: no type table
  ✓ [STATIC]    Workflow (9 §N sections)       75/75
  ✓ [STATIC]    Error/recovery present         45/45
  ✗ [HEURISTIC] Escalation HUMAN_REVIEW         0/30   ← MISSING
  ✓ [STATIC]    Examples (2 code blocks)       75/75
  ✓ [STATIC]    Security Baseline              45/45
  ✓ [STATIC]    Metadata + triggers            40/40
──────────────────────────────────────────────────────────
  LEAN: 448/500  →  SILVER proxy (est. 896)  ✓ PASS

  Weaknesses to fix:
    1. Add HUMAN_REVIEW decision matrix  (-30 pts)
    2. Add Conventional Commits type table  (-12 pts)
```

LEAN runs in ~5 seconds and tells you **exactly** what to fix — no guessing.

#### What the OPTIMIZE Changes Look Like

OPTIMIZE makes two targeted additions (no structural rewrites):

**Fix 1 — HUMAN_REVIEW escalation matrix**:
```markdown
Escalation Decision Matrix:
  Confidence ≥ 0.80   → Deliver message directly
  Confidence 0.70–0.79 → Deliver with 2nd-best type alternative
  Confidence < 0.70   → HUMAN_REVIEW: ask user to choose type manually
    └── After 2 failed retries → output raw analysis, prompt user
```

**Fix 2 — Type classification table (10 types, not a plain list)**:
```markdown
| Type     | When to use                          | Trigger words in diff           |
|----------|--------------------------------------|---------------------------------|
| feat     | New user-visible feature             | add, new, introduce, implement  |
| fix      | Bug fix                              | fix, resolve, correct, patch    |
| refactor | Restructure, no behavior change      | rename, move, extract, inline   |
| docs     | Documentation only                   | .md, docs/, # in diff           |
| ...      | (10 types total)                     | ...                             |
```

#### Before and After

```
v1.0.0  448/500 LEAN  →  SILVER proxy  (est. 896/1000)
v1.1.0  493/500 LEAN  →  PLATINUM proxy  (est. 986/1000)   +45 pts

Full EVALUATE:  1007/1020  🏆 PLATINUM
Behavioral Verifier:  5/5 test cases passed
```

**One round of targeted fixes. SILVER → PLATINUM.**

> See the [full walkthrough](examples/git-commit-writer/README.md) for complete
> LEAN outputs, all OPTIMIZE diffs, and the full EVALUATE report.

## Contributing

### Adding New Templates

1. Create template in `templates/`
2. Add metadata header with placeholders
3. Include placeholder documentation
4. Test with CREATE mode
5. Update documentation

### Adding Platform Support

1. Create `{platform}/` directory with three files: `skill-writer.md`, `AGENTS.md` (or `CLAUDE.md`), `install.sh`
2. Copy `claude/skill-writer.md` as base; update PATH CONVENTION comment and add platform-specific metadata
3. Copy `claude/install.sh` as base; update `PLATFORM_HOME` and routing file handling
4. Add platform to `detect_platforms()` and `--all` list in top-level `install.sh`
5. Update README.md platform table
6. See CONTRIBUTING.md for full platform guide

## Troubleshooting

### Common Issues

**Issue**: Skill not triggering
- **Solution**: Verify `triggers` field in YAML frontmatter has ≥ 3 EN + ≥ 2 ZH phrases. Add synonyms for common user phrasings (see anti-pattern A1).

**Issue**: Low LEAN score despite good content
- **Solution**: Check if `skill_tier` is declared — missing `skill_tier` silently defaults to `functional` and may apply wrong weights. Also verify Negative Boundaries section is present (10 pts in metadata dimension).

**Issue**: Score jumps between evaluation runs
- **Solution**: Phase 2 and 3 variance is ±15–40 pts per run. Scores within ±20 pts of each other are equivalent. Use LEAN as the primary iteration signal; run full EVALUATE only for certification.

**Issue**: EVALUATE score near a tier boundary
- **Solution**: Re-run once. If scores differ by < 20 pts, take the lower value. See the "Confidence Zone" column in the Certification Tiers table.

**Issue**: Security warnings
- **Solution**: P0 violations (CWE-798, CWE-89) trigger ABORT — fix before continuing. P1 (ASI01–ASI04) deduct 50 pts. See Security Features section.

**Issue**: Skill not loading after install
- **Solution**: Verify the skill file was copied to the correct path (`~/.claude/skills/`, `~/.openclaw/skills/`, or `~/.config/opencode/skills/`). Restart the AI assistant after installing.

### Debug Mode

Enable debug output:
```
"Enable debug mode for skill writer"
```

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/theneoai/skill-writer/issues)
- **Documentation**: [Full Documentation](https://theneoai.github.io/skill-writer)
- **Examples**: [Example Skills](https://github.com/theneoai/skill-writer/tree/main/examples)

## Roadmap

### Completed

- [x] Core engine with CREATE, LEAN, EVALUATE, OPTIMIZE, INSTALL, COLLECT, SHARE, GRAPH modes
- [x] 3-platform direct-file architecture (Claude, OpenClaw, OpenCode) — no build pipeline
- [x] SKILL.md v3.3.0 compliance: skill_tier, triggers, 11-field use_to_evolve, Skill Summary, Negative Boundaries
- [x] LEAN fast-evaluation mode with [STATIC]/[HEURISTIC] reliability labels
- [x] UTE 2.0 self-improvement protocol (L1 enforced + L2 collective)
- [x] Multi-pass self-review protocol (Generate/Review/Reconcile)
- [x] OWASP Agentic Skills Top 10 (ASI01–ASI10) security detection
- [x] Co-evolutionary VERIFY step (Step 10 in OPTIMIZE loop)
- [x] Edit Audit Guard and Skill Registry (SHA-256 IDs, push/pull/sync)
- [x] `skill_tier` (planning/functional/atomic) — tier-aware evaluation weights
- [x] `triggers` metadata field — EN + ZH phrase coverage in LEAN scoring
- [x] Mandatory Skill Summary and Negative Boundaries in all generated skills
- [x] Score variance documentation and confidence-zone tier boundaries
- [x] Semantic versioning breaking-change matrix for skill consumers
- [x] Tier anti-patterns catalog (F1–F4) and tier-aware OPTIMIZE strategy
- [x] UTE platform hook integration for Claude Code and OpenCode
- [x] **v3.2.0** — Graph of Skills (GoS): typed edge schema, bundle retrieval (BFS + PageRank), GRAPH-001–008 health checks
- [x] **v3.2.0** — D8 Composability: optional LEAN bonus dimension (0–20 pts); S10/S11/S12 optimization strategies
- [x] **v3.2.0** — GRAPH Mode (§19): `/graph view`, `/graph check`, `/graph plan`, `/graph bundle`, `/graph diff`
- [x] **v3.2.0** — INSTALL dependency resolution: topological sort + dependency manifest before install
- [x] **v3.2.0** — COLLECT bundle context: `bundle_context` + `graph_signals` fields; AGGREGATE auto-infers edges
- [x] **v3.2.0** — Registry schema v2.0: top-level `graph:` section with `edges[]` + `bundles[]`
- [x] **v3.2.0** — Progressive Disclosure Layer 0: ≤200-token bundle context prefix (pre-ADVERTISE)
- [x] **v3.2.0** — Graph of Skills (GoS) algorithm: buildGraph, detectCycles, topologicalSort, resolveBundle, checkGraphHealth, scoreD8Composability
- [x] **v3.3.0** — Three-Tier Hook Routing: AGENTS.md (session-constant) + UserPromptSubmit Hook (per-message) + trigger phrases
- [x] **v3.3.0** — Progressive Disclosure Layer -1 (Hook Injection): ≤50-token per-message skill-awareness nudge; five-layer architecture
- [x] **v3.3.0** — SkillRouter Weighted Ranking: multi-factor rank formula (trigger×0.4 + lean×0.3 + usage×0.2 + quality×0.1); quality threshold gate (0.35)
- [x] **v3.3.0** — Trigger Discovery Pipeline: `trigger_signals` in session artifact; AGGREGATE Rule 4 promotes observed user language to canonical triggers
- [x] **v3.3.0** — Simplified 3-platform direct-file architecture; removed Node.js build pipeline

### Planned

- [ ] Web UI for skill management
- [ ] Skill marketplace / registry cloud backend
- [ ] CI/CD pipeline templates for skill projects
- [ ] Automated regression testing framework for skill outputs
- [ ] Phase 5 EVALUATE (D8 full scoring: +100 pts) — v4.0+

## Acknowledgments

- Inspired by [Skilo](https://github.com/yazcaleb/skilo) cross-platform skill sharing
- Built on [AgentSkills](https://github.com/opencode/agentskills) format
- Security patterns from [CWE](https://cwe.mitre.org/)

---

**Made with ❤️ by the Skill Writer Team**

*Last updated: 2026-04-14*
