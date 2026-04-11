# Skill Writer

A cross-platform meta-skill for creating, evaluating, and optimizing AI assistant skills through natural language interaction.

[![Version](https://img.shields.io/badge/version-3.1.0-blue.svg)](https://github.com/theneoai/skill-writer)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-7-orange.svg)](#supported-platforms)
[![GitHub Actions](https://github.com/theneoai/skill-writer/workflows/Skill%20Writer%20-%20Build%20and%20Release/badge.svg)](https://github.com/theneoai/skill-writer/actions)
[![Security Scan](https://github.com/theneoai/skill-writer/workflows/Skill%20Writer%20-%20Security%20Scan/badge.svg)](https://github.com/theneoai/skill-writer/actions)

## Overview

Skill Writer is a meta-skill that enables AI assistants to create, evaluate, and optimize other skills through natural language interaction. No CLI commands required - just describe what you need.

### Key Features

- **Agent Install**: One-line install via "read [URL] and install" — works in any supported platform
- **Zero CLI Interface**: Natural language interaction - no commands to memorize
- **Cross-Platform**: Works on 7 major AI platforms (including MCP)
- **Six Powerful Modes**: CREATE, LEAN, EVALUATE, OPTIMIZE, INSTALL, and COLLECT
- **Template-Based**: 4 built-in templates for common skill patterns
- **Quality Assurance**: 1000-point scoring system with certification tiers
- **Tier-Aware Evaluation**: Tier-adjusted scoring weights for `planning` / `functional` / `atomic` skills (SkillX three-tier hierarchy)
- **Reliable LEAN Scoring**: 17 checks split into `[STATIC]` (deterministic, 335 pts, zero variance) and `[HEURISTIC]` (LLM-judged, 165 pts) — score variance documented per phase
- **Security Built-In**: CWE-based + OWASP Agentic Skills Top 10 (ASI01–ASI10) detection
- **Continuous Improvement**: Automated optimization with convergence detection + co-evolutionary VERIFY step
- **Self-Evolution**: UTE (Use-to-Evolve) protocol for automatic skill improvement (L1 enforced + L2 collective)
- **Multi-Pass Self-Review**: Generate/Review/Reconcile quality protocol

## Supported Platforms

| Platform | Status | Installation Path |
|----------|--------|-------------------|
| [OpenCode](https://opencode.ai) | ✅ P0 | `~/.config/opencode/skills/` |
| [OpenClaw](https://openclaw.ai) | ✅ P0 | `~/.openclaw/skills/` |
| [Claude](https://claude.ai) | ✅ P0 | `~/.claude/skills/` |
| [Cursor](https://cursor.sh) | ✅ P1 | `~/.cursor/skills/` |
| [OpenAI](https://openai.com) | ✅ P1 | `~/.openai/skills/` (JSON) |
| [Gemini](https://gemini.google.com) | ✅ P2 | `~/.gemini/skills/` |
| [MCP](https://modelcontextprotocol.io) | ✅ P2 | `~/.mcp/servers/skill-writer/` (JSON manifest) |

## Quick Start

### Installation

#### Option 1 — Agent Install from Latest Release (Recommended)

Paste one command into your AI agent to install the latest stable release:

| Platform | Agent command |
|----------|--------------|
| All platforms | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer.md and install` |
| Claude only | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-claude.md and install to claude` |
| OpenCode only | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-opencode.md and install to opencode` |
| OpenClaw only | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-openclaw.md and install to openclaw` |
| Cursor only | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-cursor.md and install to cursor` |
| Gemini only | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-gemini.md and install to gemini` |
| OpenAI only | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-openai.json and install to openai` |
| MCP only | `read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-mcp.json and install to mcp` |

Each [GitHub Release](https://github.com/theneoai/skill-writer/releases) includes per-platform assets and ready-to-paste agent commands for that version.

To install from the development branch (always latest, includes companion files for Claude):

```
read https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md and install
read https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md and install to claude
```

#### Option 2 — Shell Script

```bash
git clone https://github.com/theneoai/skill-writer.git
cd skill-writer

# Install to all supported platforms
./install.sh

# Install to a single platform
./install.sh --platform claude
./install.sh --platform opencode
./install.sh --platform cursor
./install.sh --platform gemini
./install.sh --platform openai
./install.sh --platform mcp

# Install directly from a release asset
./install.sh --url https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer.md
```

#### Option 3 — Manual Copy

```bash
# Claude
cp skill-framework.md ~/.claude/skills/skill-writer.md

# OpenCode
mkdir -p ~/.config/opencode/skills
cp skill-framework.md ~/.config/opencode/skills/skill-writer.md

# OpenClaw
mkdir -p ~/.openclaw/skills
cp skill-framework.md ~/.openclaw/skills/skill-writer.md

# Cursor
mkdir -p ~/.cursor/skills
cp skill-framework.md ~/.cursor/skills/skill-writer.md

# Gemini
mkdir -p ~/.gemini/skills
cp skill-framework.md ~/.gemini/skills/skill-writer.md

# OpenAI (JSON format)
mkdir -p ~/.openai/skills
cp platforms/skill-writer-openai-dev.json ~/.openai/skills/skill-writer.json

# MCP (JSON manifest)
mkdir -p ~/.mcp/servers/skill-writer
cp platforms/skill-writer-mcp-dev.json ~/.mcp/servers/skill-writer/mcp-manifest.json
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
"read https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md and install"
"read https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md and install to claude"
"安装 skill-writer"
```

## Modes

### CREATE Mode

Generates new skills from scratch using structured templates and elicitation.

#### Workflow (9-Phase)
1. **ELICIT**: Ask 6 clarifying questions to understand requirements
2. **SELECT TEMPLATE**: Choose from 4 built-in templates
3. **PLAN**: Multi-pass self-review for implementation strategy
4. **GENERATE**: Create skill using template
5. **SECURITY SCAN**: Check for CWE vulnerabilities
6. **LEAN EVAL**: Fast 500-point heuristic evaluation
7. **FULL EVALUATE**: Complete 1000-point evaluation (if LEAN uncertain)
8. **INJECT UTE**: Add Use-to-Evolve self-improvement hooks
9. **DELIVER**: Output final skill file

#### Available Templates

**Base Template**
- Use for: Simple skills, proof of concepts
- Features: Standard sections, minimal boilerplate

**API Integration**
- Use for: REST API clients, webhooks, integrations
- Features: Endpoint handling, authentication patterns

**Data Pipeline**
- Use for: ETL, data transformation, analysis
- Features: Input validation, processing steps, output formatting

**Workflow Automation**
- Use for: CI/CD, repetitive tasks, orchestration
- Features: Step sequencing, error recovery, notifications

#### Triggers (EN/ZH)
- "create a [type] skill" / "创建一个[类型]技能"
- "help me write a skill for [purpose]" / "帮我写一个技能"
- "I need a skill that [description]" / "我需要一个技能"
- "generate a skill to [action]" / "生成一个技能"
- "build a skill for [task]" / "构建一个技能"

### LEAN Mode

Fast 500-point evaluator for rapid quality assessment. Checks are labeled by execution method:
- **`[STATIC]`** — deterministic regex/structural match; same skill → same result every run (335 pts max, zero variance)
- **`[HEURISTIC]`** — requires LLM judgment to assess adequacy (165 pts max, ±5–15 pts variance)

#### 17-Check Rubric (organized by dimension)

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

#### Score Proxies and Decision Gates

| LEAN Score | Proxy | Decision |
|------------|-------|----------|
| ≥ 475 | PLATINUM proxy (est. ≥ 950) | LEAN PASS — deliver with `LEAN_CERT` |
| ≥ 450 | GOLD proxy (est. ≥ 900) | LEAN PASS |
| ≥ 400 | SILVER proxy (est. ≥ 800) | LEAN PASS |
| ≥ 350 | BRONZE proxy (est. ≥ 700) | LEAN PASS |
| 300–349 | UNCERTAIN | Escalate to full EVALUATE |
| < 300 | FAIL | Route to OPTIMIZE |

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
| Phase 1: Structural | 100 | YAML syntax, format, metadata | ±0–5 pts |
| Phase 2: Content Quality | 300 | Clarity, completeness, accuracy, safety, maintainability, usability | ±15–30 pts |
| Phase 3: Runtime Tests | 400 | Unit, integration, sandbox, error handling, performance, security tests | ±20–40 pts |
| Phase 4: Certification | 200 | Documentation, coverage, quality, compatibility, review | ±5–10 pts |

> **Total score variance**: ±30–60 pts across runs. Re-run if the score falls in a confidence zone (see below).

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

Continuously improves skills through iterative refinement with 7-dimension analysis.

#### 7-Dimension Analysis

| Dimension | Weight | Focus |
|-----------|--------|-------|
| System Design | 20% | Architecture, workflow structure |
| Domain Knowledge | 20% | Accuracy, terminology, context |
| Workflow Definition | 20% | Step clarity, transitions |
| Error Handling | 15% | Edge cases, recovery |
| Examples | 15% | Coverage, relevance |
| Metadata | 10% | Documentation, tags |
| Long-Context | 10% | Token efficiency, structure |

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

#### Triggers (EN/ZH)
- "optimize this skill" / "优化这个技能"
- "improve my skill" / "改进我的技能"
- "make this skill better" / "让这个技能更好"
- "refine this skill" / "精炼这个技能"
- "enhance this skill" / "增强这个技能"

### INSTALL Mode

Installs skill-writer itself to one or all supported platforms from a URL or local clone.

#### Workflow
1. **PARSE_INPUT**: Extract URL and target platform(s) from user message
2. **FETCH**: If URL provided, download and verify the file
3. **CONFIRM**: Show install plan, ask user to confirm
4. **INSTALL**: Write skill file to each platform's skills directory
5. **REPORT**: List installed paths and next steps

#### Platform Paths

| Platform | Skills Directory | Format |
|----------|-----------------|--------|
| Claude | `~/.claude/skills/` | Markdown |
| OpenCode | `~/.config/opencode/skills/` | Markdown |
| OpenClaw | `~/.openclaw/skills/` | Markdown |
| Cursor | `~/.cursor/skills/` | Markdown |
| Gemini | `~/.gemini/skills/` | Markdown |
| OpenAI | `~/.openai/skills/` | JSON |
| MCP | `~/.mcp/servers/skill-writer/` | JSON manifest |

### COLLECT Mode

Records structured session artifacts after each skill invocation (when UTE is enabled). Enables collective skill evolution via the AGGREGATE pipeline.

#### Workflow
1. **CAPTURE**: Record invocation context, outcome, and PRM signal
2. **CLASSIFY**: Assign lesson type (`strategic_pattern` / `failure_lesson` / `neutral`)
3. **STORE**: Append to session artifact log (refs/session-artifact.md schema)
4. **AGGREGATE** (periodic): Distill N artifacts into ranked improvement signals → OPTIMIZE candidates

#### Triggers (EN/ZH)
- Auto-triggered by UTE after each invocation (no user input required)
- `"collect this session"` / `"收集本次会话"`
- `"record session artifact"` / `"记录会话数据"`
- `"export invocation log"` / `"导出调用日志"`

## Security Features

### CWE Pattern Detection

Automatically checks for:
- **CWE-78**: OS Command Injection
- **CWE-79**: Cross-Site Scripting (XSS)
- **CWE-89**: SQL Injection
- **CWE-22**: Path Traversal
- And more...

### OWASP Agentic Skills Top 10 (2026)

| ID | Risk | Severity |
|----|------|----------|
| ASI01 | Prompt Injection / Goal Hijack | P1 (−50 pts) |
| ASI02 | Insecure Tool Use | P1 (−50 pts) |
| ASI03 | Excessive Agency | P1 (−50 pts) |
| ASI04 | Uncontrolled Resource Consumption | P1 (−50 pts) |
| ASI05 | Missing Negative Boundaries | P2 (advisory) |
| ASI06 | Sensitive Data Exposure | P2 (advisory) |
| ASI07 | Insufficient Logging | P2 (advisory) |
| ASI08 | Insecure Deserialization | P2 (advisory) |
| ASI09 | Executable Script Risk | P2 (advisory) |
| ASI10 | Broken Access Control | P2 (advisory) |

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
- **L1 (Single-user)** `[ENFORCED]`: Post-invocation hook runs per session; persists state to `~/.claude/skills/.ute-state/`
- **L2 (Collective)** `[ASPIRATIONAL]`: Requires external aggregation infrastructure (SkillClaw-compatible)

### UTE YAML Block

```yaml
use_to_evolve:
  enabled: true
  injected_by: "skill-writer v3.1.0"
  injected_at: "2026-04-11"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: 390
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
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

UTE state tracking upgrades from `[ASPIRATIONAL]` to `[ENFORCED]` when platform hooks are configured:

```json
// ~/.claude/settings.json
{
  "hooks": {
    "PostToolUse": [{"command": "node ~/.claude/skills/ute-tracker.js post-tool"}],
    "Stop": [{"command": "node ~/.claude/skills/ute-tracker.js stop"}]
  }
}
```

See `refs/use-to-evolve.md §8` for full hook setup and `ute-tracker.js` implementation.

## Builder Tool

The `skill-writer-builder` CLI tool generates platform-specific skills from the core engine.

### Installation

```bash
cd builder
npm install
```

### Commands

> **Note**: Run `npm run build` from the project root before using `npm run install:*` scripts — they copy files from the `platforms/` directory created by the build step. In CI, lint and test run without `|| true` and will fail the pipeline on errors.

#### Build
```bash
# Build for all platforms
node bin/skill-writer-builder.js build --platform all --output ./platforms

# Build for specific platform
node bin/skill-writer-builder.js build --platform opencode --output ./platforms

# Release build
node bin/skill-writer-builder.js build --platform all --release
```

#### Development Mode
```bash
# Watch for changes and auto-rebuild
node bin/skill-writer-builder.js dev --platform opencode
```

#### Validate
```bash
# Validate core engine structure
node bin/skill-writer-builder.js validate
```

#### Inspect
```bash
# Inspect built skill
node bin/skill-writer-builder.js inspect --platform opencode
```

## Project Structure

```
skill-writer/
├── skill-framework.md             # Main skill definition (entry point)
├── refs/                          # Reference documentation
│   ├── self-review.md             # Multi-pass self-review protocol
│   ├── use-to-evolve.md           # UTE 2.0 self-improvement spec (L1/L2 architecture)
│   ├── evolution.md               # 3-trigger evolution system
│   ├── convergence.md             # Convergence detection rules
│   ├── security-patterns.md       # CWE + OWASP ASI security patterns
│   ├── session-artifact.md        # Session artifact schema (COLLECT mode)
│   ├── edit-audit.md              # Edit Audit Guard (MICRO/MINOR/MAJOR/REWRITE)
│   └── skill-registry.md          # Skill Registry spec (SHA-256 IDs, push/pull/sync)
├── templates/                     # Skill templates (4 types + UTE snippet)
│   ├── base.md
│   ├── api-integration.md
│   ├── data-pipeline.md
│   ├── workflow-automation.md
│   └── use-to-evolve-snippet.md
├── eval/                          # Evaluation resources
│   ├── rubrics.md                 # 1000-point scoring rubric
│   └── benchmarks.md              # Benchmark test cases
├── optimize/                      # Optimization resources
│   ├── strategies.md              # 7-dimension strategy catalog
│   └── anti-patterns.md           # Common pitfalls
├── builder/                       # Multi-platform builder tool
│   ├── bin/
│   │   └── skill-writer-builder.js
│   ├── src/
│   │   ├── commands/              # CLI commands (build, dev, validate, inspect)
│   │   ├── core/                  # Reader and embedder modules
│   │   ├── metadata.js            # SSoT for builder metadata (version, platforms)
│   │   └── platforms/             # 7 platform adapters
│   │       ├── MarkdownAdapter.js # Shared base class for markdown platforms
│   │       ├── sections/          # Externalized section templates (openclaw)
│   │       └── index.js           # Platform registry
│   ├── templates/                 # Platform-specific output templates
│   ├── .eslintrc.json             # ESLint configuration
│   └── tests/                     # Jest test suite (179 tests)
├── platforms/                     # Generated platform files (7 platforms, gitignored)
├── examples/                      # Certified example skills
│   ├── api-tester/                # GOLD 920/1000
│   ├── code-reviewer/             # GOLD 947/1000
│   └── doc-generator/             # GOLD 895/1000
└── docs/                          # GitHub Pages documentation
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
│  │ • Elicit 8Q │  │ • 17 checks      │  │ • 1000-pt scoring   │  │
│  │ • 9-Phase   │  │ • [STATIC] +     │  │ • Tier-adjusted     │  │
│  │   Workflow  │  │   [HEURISTIC]    │  │   Phase 2 weights   │  │
│  └─────────────┘  └──────────────────┘  └─────────────────────┘  │
│                                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────────┐  │
│  │OPTIMIZE Mode│  │INSTALL Mode │  │      COLLECT Mode        │  │
│  │             │  │             │  │                          │  │
│  │ • 7-dim     │  │ • 7-platform│  │ • Session artifact log   │  │
│  │   analysis  │  │   support   │  │ • Lesson classification  │  │
│  │ • 10-step   │  │ • Agent     │  │ • AGGREGATE pipeline     │  │
│  │   loop      │  │   install   │  │ • Collective evolution   │  │
│  │ • VERIFY    │  │   protocol  │  │   (SkillRL-compatible)   │  │
│  └─────────────┘  └─────────────┘  └──────────────────────────┘  │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                     Shared Resources                       │   │
│  │  • CWE + OWASP ASI01–ASI10 Security Patterns              │   │
│  │  • UTE 2.0 Self-Evolution (L1 enforced + L2 collective)    │   │
│  │  • Multi-Pass Self-Review (Generate/Review/Reconcile)      │   │
│  │  • Skill Registry (SHA-256 IDs, push/pull/sync, semver)    │   │
│  │  • Edit Audit Guard (MICRO/MINOR/MAJOR/REWRITE classes)    │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Platform-Specific Builder                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────────┐  │
│  │OpenCode │ │OpenClaw │ │ Claude  │ │ Cursor  │ │ OpenAI /  │  │
│  │ Adapter │ │ Adapter │ │ Adapter │ │ Adapter │ │ Gemini /  │  │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ │   MCP     │  │
│                                                    └───────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Example Skills

All example skills are certified with detailed evaluation reports.

| Skill | Type | Tier | Score | Description |
|-------|------|------|-------|-------------|
| [api-tester](examples/api-tester/) | API Integration | 🥇 GOLD | 920/1000 | HTTP API testing automation |
| [code-reviewer](examples/code-reviewer/) | Workflow Automation | 🥇 GOLD | 947/1000 | Code review with security scanning |
| [doc-generator](examples/doc-generator/) | Data Pipeline | 🥇 GOLD | 895/1000 | Documentation generation |

**Average Score: 920.7/1000**

## Contributing

### Adding New Templates

1. Create template in `templates/`
2. Add metadata header with placeholders
3. Include placeholder documentation
4. Test with CREATE mode
5. Update documentation

### Adding Platform Support

1. Create adapter in `builder/src/platforms/`
2. Implement required functions:
   - `formatSkill()`
   - `getInstallPath()`
   - `generateMetadata()`
   - `validateSkill()`
3. Add to platform registry in `index.js`
4. Create platform template in `builder/templates/`
5. Test build command
6. Update documentation

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

**Issue**: Build fails
- **Solution**: Run `validate` command to check core engine structure. Ensure `npm ci` completes without errors before building.

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

- [x] Core engine with CREATE, LEAN, EVALUATE, OPTIMIZE, INSTALL, COLLECT modes
- [x] Builder tool with CLI and Jest test suite (179 tests)
- [x] Support for 7 platforms (OpenCode, OpenClaw, Claude, Cursor, OpenAI, Gemini, MCP)
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

### Planned

- [ ] Web UI for skill management
- [ ] Skill marketplace / registry cloud backend
- [ ] CI/CD pipeline templates for skill projects
- [ ] Automated regression testing framework for skill outputs

## Acknowledgments

- Inspired by [Skilo](https://github.com/yazcaleb/skilo) cross-platform skill sharing
- Built on [AgentSkills](https://github.com/opencode/agentskills) format
- Security patterns from [CWE](https://cwe.mitre.org/)

---

**Made with ❤️ by the Skill Writer Team**

*Last updated: 2026-04-11*
