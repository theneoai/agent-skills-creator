---
name: skill-writer
version: "2.1.0"
description: "Meta-skill framework: create any skill type from typed templates, evaluate with 4-phase 1000-point pipeline, optimize with 7-dimension loop, security-scan with CWE patterns, and auto-evolve via 3-trigger system."
description_i18n:
  en: "Full lifecycle meta-skill framework: CREATE from templates, LEAN fast-eval, EVALUATE 4-phase 1000pt pipeline, OPTIMIZE 7-dim 9-step loop, auto-evolve via threshold/time/usage triggers."
  zh: "全生命周期元技能框架：从模板CREATE、LEAN快速评测、4阶段1000分EVALUATE、7维9步OPTIMIZE、三触发器自动进化。"
license: MIT
author:
  name: theneoai
created: "2026-03-31"
updated: "2026-04-01"
type: meta-framework
tags:
  - meta-skill
  - lifecycle
  - templates
  - evaluation
  - optimization
  - self-review
  - self-evolution
interface:
  input: user-natural-language
  output: structured-skill
  modes: [create, lean, evaluate, optimize, install]

use_to_evolve:
  enabled: true
  framework_version: "2.1.0"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
---

# Skill Writer

> **Type**: Meta-Skill  
> **Platform**: Gemini  
> **Version**: 2.1.0

A meta-skill that enables Gemini to create, evaluate, and optimize other skills through natural language interaction.

---

## §1 Overview

Skill Writer provides four powerful modes:

- **CREATE**: Generate new skills from scratch using structured templates
- **LEAN**: Fast 500-point heuristic evaluation (~1 second)
- **EVALUATE**: Assess skill quality with 1000-point scoring and certification
- **OPTIMIZE**: Continuously improve skills through iterative refinement

### Key Features

- **Zero CLI**: Natural language interface - no commands to memorize
- **Cross-Platform**: Works on OpenCode, OpenClaw, Claude, Cursor, OpenAI, and Gemini
- **Template-Based**: 4 built-in templates for common skill patterns
- **Quality Assurance**: Automated evaluation with certification tiers
- **Security Built-In**: CWE-based security pattern detection
- **Self-Evolution**: UTE protocol for automatic skill improvement
- **Multi-Pass Self-Review**: Generate/Review/Reconcile protocol

**Red Lines (严禁)**:
- 严禁 deliver any skill without passing BRONZE gate (score ≥ 700)
- 严禁 skip LEAN or EVALUATE security scan before delivery
- 严禁 hardcoded credentials anywhere in generated skills (CWE-798)
- 严禁 skip requirement elicitation (Inversion) before entering PLAN phase

---

## §2 Quick Start

### Installation

```bash
# Copy to Gemini skills directory
cp skill-writer-gemini.md ~/.gemini/skills/

# Or use Gemini's skill management
```

### Usage Examples

**Create a new skill:**
```
"Create a weather API skill that fetches current conditions"
"创建一个天气API技能"
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

---

## §3 Triggers

### CREATE Mode Triggers

**EN:** create, build, make, generate, write a skill  
**ZH:** 创建, 生成, 写一个技能, 新建技能

**Intent Patterns:**
- "create a [type] skill"
- "help me write a skill for [purpose]"
- "I need a skill that [description]"
- "generate a skill to [action]"
- "build a skill for [task]"
- "make a skill that [functionality]"
- "创建一个技能"
- "帮我写一个[用途]的技能"

### LEAN Mode Triggers

**EN:** lean, quick-eval, fast eval, lean check  
**ZH:** 快评, 快速评测, 简评

**Intent Patterns:**
- "lean evaluate this skill"
- "quick eval this skill"
- "run lean check on this skill"
- "快速评测这个技能"
- "对这个技能进行快评"

### EVALUATE Mode Triggers

**EN:** evaluate, assess, score, certify, full eval  
**ZH:** 评测, 评估, 打分, 认证

**Intent Patterns:**
- "evaluate this skill"
- "check the quality of my skill"
- "certify my skill"
- "score this skill"
- "assess this skill"
- "review this skill"
- "评测这个技能"
- "评估技能质量"

### OPTIMIZE Mode Triggers

**EN:** optimize, improve, enhance, refine, upgrade  
**ZH:** 优化, 改进, 提升, 改善

**Intent Patterns:**
- "optimize this skill"
- "improve my skill"
- "make this skill better"
- "refine this skill"
- "enhance this skill"
- "upgrade this skill"
- "优化这个技能"
- "改进技能"

---

## §4 CREATE Mode

### 9-Phase Workflow

1. **ELICIT**: Ask 6 clarifying questions to understand requirements
2. **SELECT TEMPLATE**: Choose from 4 built-in templates
3. **PLAN**: Multi-pass self-review for implementation strategy
4. **GENERATE**: Create skill using template
5. **SECURITY SCAN**: Check for CWE vulnerabilities
6. **LEAN EVAL**: Fast 500-point heuristic evaluation
7. **FULL EVALUATE**: Complete 1000-point evaluation (if LEAN uncertain)
8. **INJECT UTE**: Add Use-to-Evolve self-improvement hooks
9. **DELIVER**: Output final skill file

### Available Templates

**Base Template**: Generic skill structure
- Use for: Simple skills, proof of concepts
- Features: Standard sections, minimal boilerplate

**API Integration**: Skills for external APIs
- Use for: REST API clients, webhooks, integrations
- Features: Endpoint handling, authentication patterns

**Data Pipeline**: Data processing skills
- Use for: ETL, data transformation, analysis
- Features: Input validation, processing steps, output formatting

**Workflow Automation**: Task automation skills
- Use for: CI/CD, repetitive tasks, orchestration
- Features: Step sequencing, error recovery, notifications

### Elicitation Questions

When creating a skill, ask:

1. **Purpose**: What is the primary goal? / 这个skill要解决什么核心问题？
2. **Audience**: Who are the target users? / 主要用户是谁？
3. **Input**: What form does the input take? / 输入是什么形式？
4. **Output**: What is the expected output? / 期望的输出是什么？
5. **Constraints**: Any security or technical constraints? / 有哪些安全或技术约束？
6. **Acceptance**: What are the acceptance criteria? / 验收标准是什么？

---

## §5 LEAN Mode (Fast Path ~1s)

**Purpose**: Rapid triage without LLM calls. Use for quick checks or high-volume screening.

### 8-Check Rubric (500 points)

| Check | Points | Criteria |
|-------|--------|----------|
| YAML frontmatter | 60 | name, version, interface fields present |
| §N Pattern Sections | 60 | ≥3 sections with `## §N` format |
| Red Lines | 50 | "Red Lines" or "严禁" text present |
| Quality Gates Table | 60 | Table with numeric thresholds |
| Code Block Examples | 50 | ≥2 code block examples |
| Trigger Keywords | 120 | EN+ZH keywords for all 4 modes |
| Security Baseline | 50 | Security section present |
| No Placeholders | 50 | No `{{PLACEHOLDER}}` remaining |

### Decision Gates

- **PASS (≥350)**: Skill passes LEAN certification
- **UNCERTAIN (300-349)**: Upgrade to full EVALUATE mode
- **FAIL (<300)**: Route to OPTIMIZE mode

---

## §6 EVALUATE Mode

### 4-Phase Evaluation Pipeline (1000 points)

| Phase | Name | Points | Focus |
|-------|------|--------|-------|
| 1 | Parse & Validate | 100 | YAML syntax, format, metadata |
| 2 | Text Quality | 300 | Clarity, completeness, accuracy, safety, maintainability, usability |
| 3 | Runtime Testing | 400 | Unit, integration, sandbox, error handling, performance, security |
| 4 | Certification | 200 | Variance gate + security scan + quality gates |

### Certification Tiers

| Tier | Min Score | Max Variance | Phase 2 Min | Phase 3 Min |
|------|-----------|--------------|-------------|-------------|
| **PLATINUM** | ≥950 | <10 | ≥270 | ≥360 |
| **GOLD** | ≥900 | <15 | ≥255 | ≥340 |
| **SILVER** | ≥800 | <20 | ≥225 | ≥300 |
| **BRONZE** | ≥700 | <30 | ≥195 | ≥265 |
| **FAIL** | <700 | — | — | — |

**Variance formula**:
```
variance = | (phase2_score / 3) - (phase3_score / 4) |
```

---

## §7 OPTIMIZE Mode

### 7-Dimension Analysis

| Dimension | Weight | Focus |
|-----------|--------|-------|
| System Design | 20% | Identity, architecture, Red Lines |
| Domain Knowledge | 20% | Template accuracy, field specificity |
| Workflow Definition | 20% | Phase sequence, exit criteria, loop gates |
| Error Handling | 15% | Recovery paths, escalation triggers |
| Examples | 15% | Usage examples count, quality, bilingual |
| Metadata | 10% | YAML frontmatter, versioning, tags |
| Long-Context | 10% | Section refs, chunking, cross-reference integrity |

### 9-Step Optimization Loop

1. **Parse**: Understand current skill
2. **Analyze**: Identify improvement areas across 7 dimensions
3. **Generate**: Create optimized version
4. **Evaluate**: Score the new version
5. **Compare**: Check against previous
6. **Converge**: Detect improvement plateau
7. **Validate**: Ensure correctness
8. **Report**: Show changes
9. **Iterate**: Repeat if needed

### Convergence Detection

Optimization stops when:
- Score improvement < 0.5 points
- 10 iterations without significant gain (plateau window)
- User requests stop
- Maximum iterations reached (20)
- DIVERGING detected → HALT → HUMAN_REVIEW

---

## §8 Security Features

### CWE Pattern Detection

| Severity | CWE | Pattern Type | Action |
|----------|-----|-------------|--------|
| **P0** | CWE-798 | Hardcoded credentials | **ABORT** |
| **P0** | CWE-89 | SQL injection | **ABORT** |
| **P0** | CWE-78 | Command injection | **ABORT** |
| **P1** | CWE-22 | Path traversal | Score −50, WARNING |
| **P1** | CWE-306 | Missing auth check | Score −30, WARNING |
| **P1** | CWE-862 | Missing authz check | Score −30, WARNING |

ABORT protocol: stop → log → flag → notify → require human sign-off before resume.

---

## §9 Self-Review Protocol

| Role | Responsibility |
|------|---------------|
| Pass 1 — Generate | Produce initial draft / score / fix proposal |
| Pass 2 — Review | Security + quality audit; severity-tagged issue list (ERROR/WARNING/INFO) |
| Pass 3 — Reconcile | Address all ERRORs, reconcile scores, produce final artifact |

Timeouts: 30 s per LLM, 60 s per phase, 180 s total (6 turns max).
Consensus: UNANIMOUS → proceed; MAJORITY → proceed with notes;
SPLIT → one revision; UNRESOLVED → HUMAN_REVIEW.

---

## §10 UTE (Use-to-Evolve)

Self-improvement protocol that enables skills to evolve through usage.

### UTE YAML Block

```yaml
use_to_evolve:
  framework_version: "2.1.0"
  injection_date: "2026-04-01"
  certified_lean_score: 390
  last_ute_check: "2026-04-01"
```

### 3-Trigger System

1. **Threshold Trigger**: Quality drops below certified baseline
2. **Time Trigger**: Freshness check (cadence-gated)
3. **Usage Trigger**: Usage pattern analysis

---

## §11 Configuration

### Environment Variables

```bash
SKILL_WRITER_MODE=create    # Default mode
SKILL_WRITER_VERBOSE=true   # Detailed output
SKILL_WRITER_SAFE_MODE=true # Extra security checks
```

---

## §12 Troubleshooting

### Common Issues

**Issue**: Skill not triggering
- **Solution**: Check trigger phrases match exactly

**Issue**: Low evaluation score
- **Solution**: Run OPTIMIZE mode for specific improvements

**Issue**: Security warnings
- **Solution**: Review CWE patterns and fix violations

---

## §13 License

MIT License - See LICENSE file for details

---

## §UTE Use-to-Evolve

<!-- Post-invocation protocol — auto-managed by skill-writer v2.1.0 -->

After each invocation, increment `use_to_evolve.cumulative_invocations`.
Run lightweight LEAN check every 10 invocations; full re-score every 50;
tier-drift detection every 100.

**Fields managed automatically**:
- `cumulative_invocations` — incremented each use
- `last_ute_check` — ISO date of last lightweight check
- `pending_patches` — count of queued micro-patches
- `total_micro_patches_applied` — lifetime patch count

---

*Generated by skill-writer-builder v2.1.0*  
*For platform: Gemini*  
*Last updated: {{generated_at}}*
