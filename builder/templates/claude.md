---
name: skill-writer
version: 2.0.0
description: Meta-skill for creating, evaluating, and optimizing skills through natural language
author: skill-writer-builder
license: MIT
tags:
  - meta-skill
  - skill-creation
  - skill-evaluation
  - skill-optimization
  - automation
type: meta-framework
interface:
  input: user-natural-language
  output: structured-skill
  modes: [create, lean, evaluate, optimize]

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v2.0.0"
  injected_at: "{{generated_at}}"
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
> **Platform**: Claude  
> **Version**: 2.0.0

A meta-skill that enables Claude to create, evaluate, and optimize other skills through natural language interaction.

---

## §1 Overview

Skill Writer provides three powerful modes:

- **CREATE**: Generate new skills from scratch using structured templates
- **EVALUATE**: Assess skill quality with 1000-point scoring and certification
- **OPTIMIZE**: Continuously improve skills through iterative refinement

### Key Features

- **Zero CLI**: Natural language interface - no commands to memorize
- **Cross-Platform**: Works on OpenCode, OpenClaw, Claude, Cursor, OpenAI, and Gemini
- **Template-Based**: 4 built-in templates for common skill patterns
- **Quality Assurance**: Automated evaluation with certification tiers
- **Security Built-In**: CWE-based security pattern detection

**Red Lines (严禁)**:
- 严禁 deliver any skill without passing BRONZE gate (score ≥ 700)
- 严禁 skip LEAN or EVALUATE security scan before delivery
- 严禁 hardcoded credentials anywhere in generated skills (CWE-798)
- 严禁 skip requirement elicitation (Inversion) before entering PLAN phase
- 严禁 suppress multi-LLM consensus disagreements — log them explicitly

---

## §2 Quick Start

### Installation

```bash
# Copy to Claude skills directory
cp skill-writer-claude.md ~/.claude/skills/

# Or use Claude's skill management
```

### Usage Examples

**Create a new skill:**
```
"Create a weather API skill that fetches current conditions"
```

**Evaluate an existing skill:**
```
"Evaluate this skill and give me a quality score"
```

**Optimize a skill:**
```
"Optimize this skill to make it more concise"
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

**Examples:**
- "create a data processing skill"
- "help me write a skill for API integration"
- "I need a skill that analyzes code quality"
- "generate a skill to automate deployments"

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

**Examples:**
- "evaluate this skill and tell me what's wrong"
- "check the quality of my API skill"
- "certify my workflow automation skill"
- "score this skill out of 1000 points"

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

**Examples:**
- "optimize this skill for better performance"
- "improve my skill's error handling"
- "make this skill more user-friendly"
- "refine this skill to be more concise"

---

## §4 CREATE Mode

### 7-Step Workflow

1. **Parse Request**: Analyze intent and extract requirements
2. **Select Template**: Choose from 4 built-in templates
3. **Elicit Requirements**: Ask clarifying questions
4. **Generate Output**: Create skill using template
5. **Security Scan**: Check for CWE vulnerabilities
6. **Quality Check**: Validate structure and completeness
7. **Deliver**: Output final skill file

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

When creating a skill, Claude will ask:

1. **Purpose**: What is the primary goal?
2. **Audience**: Who are the target users?
3. **Features**: What capabilities must it have?
4. **Constraints**: Any standards or requirements?
5. **Scale**: Expected usage volume?
6. **References**: Examples to emulate or avoid?

---

## §5 EVALUATE Mode

### 4-Phase Evaluation Pipeline

1. **Structural Analysis**: Check format, sections, completeness
2. **Content Quality**: Assess clarity, examples, instructions
3. **Security Audit**: Scan for CWE patterns
4. **Scoring**: Calculate 1000-point score

### Scoring Rubric (1000 Points Total)

**Phase 1: Parse & Validate (100 points)**
- YAML syntax valid
- Required fields present (name, version, interface, description, author)
- Semantic versioning format

**Phase 2: Text Quality (300 points)**
- Clarity (50 pts): Instructions clear, no ambiguity
- Completeness (50 pts): All required sections present
- Accuracy (60 pts): Examples correct and runnable
- Safety (60 pts): Red Lines / 严禁 present
- Maintainability (40 pts): Well structured, version controlled
- Usability (40 pts): Trigger phrases clear, examples adequate

**Phase 3: Runtime Testing (400 points)**
- Each mode tested against sample inputs
- Quality gates validated
- Security scan (CWE-798/89/78/22) passed

**Phase 4: Certification (200 points)**
- LEAN re-check post-evaluation
- Variance check: |(phase2/3) − (phase3/4)| within tier limit (normalised to 100-pt scale)
- UTE injection verified

### Certification Tiers

- **PLATINUM (≥950)**: Exceptional; variance < 10
- **GOLD (≥900)**: Production-ready; variance < 15
- **SILVER (≥800)**: Good quality; variance < 20
- **BRONZE (≥700)**: Acceptable minimum for delivery; variance < 30
- **FAIL (<700)**: Route to OPTIMIZE

---

## §6 OPTIMIZE Mode

### 7-Dimension Analysis

1. **Conciseness**: Remove redundancy
2. **Clarity**: Improve understanding
3. **Completeness**: Add missing elements
4. **Security**: Fix vulnerabilities
5. **Performance**: Optimize execution
6. **Maintainability**: Improve structure
7. **Usability**: Enhance user experience

### 9-Step Optimization Loop

1. **Parse**: Understand current skill
2. **Analyze**: Identify improvement areas
3. **Generate**: Create optimized version
4. **Evaluate**: Score the new version
5. **Compare**: Check against previous
6. **Converge**: Detect improvement plateau
7. **Validate**: Ensure correctness
8. **Report**: Show changes
9. **Iterate**: Repeat if needed

### Convergence Detection

Optimization stops when:
- Score improvement < 0.5 points (delta_threshold)
- Plateau detected: no gain in last 10 iterations (window_size)
- User requests stop
- Maximum iterations reached (20)

---

## §7 Security Features

### CWE Pattern Detection

Automatically checks for:
- **CWE-78**: OS Command Injection
- **CWE-79**: Cross-Site Scripting (XSS)
- **CWE-89**: SQL Injection
- **CWE-22**: Path Traversal
- And more...

### Security Report Format

```
Security Scan Report
====================
P0: {{p0_count}} violations (Critical)
P1: {{p1_count}} violations (High)
P2: {{p2_count}} violations (Medium)
P3: {{p3_count}} violations (Low)

Recommendations:
- [Specific fixes]
```

---

## §8 Usage Patterns

### Pattern 1: Rapid Skill Creation

```
User: "Create a skill for GitHub issue management"
Claude: [Asks 6 elicitation questions]
User: [Answers questions]
Claude: [Generates skill using API Integration template]
```

### Pattern 2: Quality Assurance

```
User: "Evaluate this skill"
Claude: [Runs 4-phase evaluation]
Claude: "Score: 847/1000 (GOLD tier). Issues found:..."
```

### Pattern 3: Continuous Improvement

```
User: "Optimize this skill"
Claude: [Runs optimization loop]
Claude: "Improved from 720 to 890 points. Changes:..."
```

---

## §9 Configuration

### Environment Variables

```bash
SKILL_WRITER_MODE=create    # Default mode
SKILL_WRITER_VERBOSE=true   # Detailed output
SKILL_WRITER_SAFE_MODE=true # Extra security checks
```

### Custom Templates

Place custom templates in:
```
~/.claude/skills/skill-writer/templates/
```

---

## §10 Troubleshooting

### Common Issues

**Issue**: Skill not triggering
- **Solution**: Check trigger phrases match exactly

**Issue**: Low evaluation score
- **Solution**: Run OPTIMIZE mode for specific improvements

**Issue**: Security warnings
- **Solution**: Review CWE patterns and fix violations

### Debug Mode

Enable debug output:
```
"Enable debug mode for skill writer"
```

---

## §11 Claude-Specific Notes

### Format Preferences

- Single H1 header preferred
- Clear section hierarchy
- YAML frontmatter for metadata
- Markdown for content

### Installation Path

```
~/.claude/skills/skill-writer.md
```

### Best Practices

- Use clear, conversational language
- Provide specific examples
- Include error handling guidance
- Test triggers before deployment

---

## §12 Contributing

### Adding New Templates

1. Create template in `core/create/templates/`
2. Add metadata header
3. Include placeholder documentation
4. Test with CREATE mode

### Adding Platform Support

1. Create adapter in `builder/src/platforms/`
2. Implement required functions
3. Add to platform registry
4. Test build command

---

## License

MIT License - See LICENSE file for details

---

## Support

- **Issues**: https://github.com/theneoai/skill-writer/issues
- **Documentation**: https://github.com/theneoai/skill-writer/docs
- **Examples**: https://github.com/theneoai/skill-writer/examples

---

---

## §UTE Use-to-Evolve

<!-- Post-invocation hook — auto-managed by skill-writer v2.0.0 -->
<!-- skill: skill-writer | version: 2.0.0 | injected: {{generated_at}} -->

After each invocation, increment `use_to_evolve.cumulative_invocations`.
Run lightweight LEAN check every 10 invocations; full re-score every 50;
tier-drift detection every 100.

**Fields managed automatically** (do not edit manually):
- `cumulative_invocations` — incremented each use
- `last_ute_check` — ISO date of last lightweight check
- `pending_patches` — count of queued micro-patches
- `total_micro_patches_applied` — lifetime patch count

---

*Generated by skill-writer-builder v2.0.0*  
*For platform: Claude*  
*Last updated: {{generated_at}}*
