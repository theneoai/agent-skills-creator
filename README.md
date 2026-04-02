# Skill Writer

A cross-platform meta-skill for creating, evaluating, and optimizing AI assistant skills through natural language interaction.

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/theneoai/skill-writer)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-6-orange.svg)](#supported-platforms)
[![GitHub Actions](https://github.com/theneoai/skill-writer/workflows/Skill%20Writer%20-%20Build%20and%20Release/badge.svg)](https://github.com/theneoai/skill-writer/actions)
[![Security Scan](https://github.com/theneoai/skill-writer/workflows/Skill%20Writer%20-%20Security%20Scan/badge.svg)](https://github.com/theneoai/skill-writer/actions)

## Overview

Skill Writer is a meta-skill that enables AI assistants to create, evaluate, and optimize other skills through natural language interaction. No CLI commands required - just describe what you need.

### Key Features

- **Agent Install**: One-line install via "read [URL] and install" — works in any supported platform
- **Zero CLI Interface**: Natural language interaction - no commands to memorize
- **Cross-Platform**: Works on 6 major AI platforms
- **Five Powerful Modes**: CREATE, LEAN, EVALUATE, OPTIMIZE, and INSTALL
- **Template-Based**: 4 built-in templates for common skill patterns
- **Quality Assurance**: 1000-point scoring system with certification tiers
- **Security Built-In**: CWE-based security pattern detection
- **Continuous Improvement**: Automated optimization with convergence detection
- **Self-Evolution**: UTE (Use-to-Evolve) protocol for automatic skill improvement
- **Multi-LLM Deliberation**: Generator/Reviewer/Arbiter consensus mechanism

## Supported Platforms

| Platform | Status | Installation Path |
|----------|--------|-------------------|
| [OpenCode](https://opencode.ai) | ✅ P0 | `~/.config/opencode/skills/` |
| [OpenClaw](https://openclaw.ai) | ✅ P0 | `~/.openclaw/skills/` |
| [Claude](https://claude.ai) | ✅ P0 | `~/.claude/skills/` |
| [Cursor](https://cursor.sh) | ✅ P1 | `~/.cursor/skills/` |
| [OpenAI](https://openai.com) | ✅ P1 | Platform-specific |
| [Gemini](https://gemini.google.com) | ✅ P2 | `~/.gemini/skills/` |

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
3. **PLAN**: Multi-LLM deliberation for implementation strategy
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

Fast 500-point heuristic evaluator (~1 second, no LLM calls) for rapid quality assessment.

#### 8-Check Rubric

| Check | Points | Criteria |
|-------|--------|----------|
| YAML frontmatter | 60 | name, version, interface fields present |
| §N Pattern Sections | 60 | ≥3 sections with `## §N` format |
| Red Lines | 50 | "Red Lines" or "严禁" text present |
| Quality Gates Table | 60 | Table with numeric thresholds |
| Code Block Examples | 50 | ≥2 code block examples |
| Trigger Keywords | 120 | EN+ZH keywords for all 4 modes |
| Security Baseline | 50 | Security section present |
| No Placeholders | 50 | No `{{PLACEHOLDER}}`残留 |

#### Decision Gates
- **PASS (≥350)**: Skill passes LEAN certification
- **UNCERTAIN (300-349)**: Upgrade to full EVALUATE mode
- **FAIL (<300)**: Route to OPTIMIZE mode

#### Triggers
- "lean evaluate" / "快评"
- "quick check" / "快速检查"
- "rapid eval" / "快速评估"

### EVALUATE Mode

Assesses skill quality with rigorous 1000-point scoring and certification.

#### 4-Phase Pipeline

| Phase | Points | Focus |
|-------|--------|-------|
| Phase 1: Structural | 100 | YAML syntax, format, metadata |
| Phase 2: Content Quality | 300 | Clarity, completeness, accuracy, safety, maintainability, usability |
| Phase 3: Runtime Tests | 400 | Unit, integration, sandbox, error handling, performance, security tests |
| Phase 4: Certification | 200 | Documentation, coverage, quality, compatibility, review |

#### Certification Tiers

| Tier | Score | Variance | Phase 2 Min | Phase 3 Min |
|------|-------|----------|-------------|-------------|
| **PLATINUM** | ≥950 | <10 | ≥270 | ≥360 |
| **GOLD** | ≥900 | <15 | ≥255 | ≥340 |
| **SILVER** | ≥800 | <20 | ≥225 | ≥300 |
| **BRONZE** | ≥700 | <30 | ≥195 | ≥265 |
| **FAIL** | <700 | — | — | — |

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

#### 9-Step Optimization Loop
1. **Parse**: Understand current skill
2. **Analyze**: Identify improvement areas across 7 dimensions
3. **Generate**: Create optimized version
4. **Evaluate**: Score the new version
5. **Compare**: Check against previous
6. **Converge**: Detect improvement plateau
7. **Validate**: Ensure correctness
8. **Report**: Show changes
9. **Iterate**: Repeat if needed

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

| Platform | Skills Directory |
|----------|-----------------|
| Claude | `~/.claude/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| OpenClaw | `~/.openclaw/skills/` |
| Cursor | `~/.cursor/skills/` |
| Gemini | `~/.gemini/skills/` |

#### Triggers (EN/ZH)
- `"read <URL> and install"` / `"从 <URL> 安装"`
- `"read <URL> and install to <platform>"`
- `"install skill-writer"` / `"安装 skill-writer"`
- `"install skill-writer to <platform>"`

## Security Features

### CWE Pattern Detection

Automatically checks for:
- **CWE-78**: OS Command Injection
- **CWE-79**: Cross-Site Scripting (XSS)
- **CWE-89**: SQL Injection
- **CWE-22**: Path Traversal
- And more...

### Security Severity Levels

| Level | CWE Examples | Action |
|-------|--------------|--------|
| P0 (Critical) | CWE-798, CWE-89, CWE-78 | ABORT immediately |
| P1 (High) | CWE-22, CWE-306, CWE-862 | -50 points |
| P2 (Medium) | Various | -30 points |
| P3 (Low) | Minor issues | -10 points |

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

Self-improvement protocol that enables skills to evolve through usage.

### UTE YAML Block

```yaml
use_to_evolve:
  framework_version: "2.0.0"
  injection_date: "2026-04-01"
  certified_lean_score: 390
  last_ute_check: "2026-04-01"
```

### 3-Trigger System

1. **Threshold Trigger**: Quality drops below certified baseline
2. **Time Trigger**: Freshness check (cadence-gated)
3. **Usage Trigger**: Usage pattern analysis

### Post-Invocation Hook
- Records usage context
- Detects implicit feedback signals
- Runs trigger checks
- Applies micro-patches if needed

## Builder Tool

The `skill-writer-builder` CLI tool generates platform-specific skills from the core engine.

### Installation

```bash
cd builder
npm install
```

### Commands

> **Note**: Run `npm run build` from the project root before using `npm run install:*` scripts — they copy files from the `platforms/` directory created by the build step.

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
├── core/                          # Core engine (platform-agnostic)
│   ├── create/                    # CREATE mode
│   │   ├── workflow.yaml          # 9-phase workflow
│   │   ├── elicitation.yaml       # 6 elicitation questions
│   │   └── templates/             # 4 templates
│   │       ├── base.md
│   │       ├── api-integration.md
│   │       ├── data-pipeline.md
│   │       └── workflow-automation.md
│   ├── evaluate/                  # EVALUATE mode
│   │   ├── phases.yaml            # 4-phase pipeline
│   │   ├── rubrics.yaml           # Scoring rubrics
│   │   └── certification.yaml     # Certification tiers
│   ├── optimize/                  # OPTIMIZE mode
│   │   ├── dimensions.yaml        # 7-dimension analysis
│   │   ├── strategies.yaml        # Optimization strategies
│   │   └── convergence.yaml       # Convergence rules
│   └── shared/                    # Shared resources
│       ├── security/
│       │   └── cwe-patterns.yaml  # CWE security patterns
│       └── utils/
│           └── helpers.yaml       # Utility functions
├── builder/                       # Builder tool
│   ├── bin/
│   │   └── skill-writer-builder.js
│   ├── src/
│   │   ├── commands/              # CLI commands
│   │   │   ├── build.js
│   │   │   ├── dev.js
│   │   │   ├── validate.js
│   │   │   └── inspect.js
│   │   ├── core/                  # Core modules
│   │   │   ├── reader.js
│   │   │   └── embedder.js
│   │   └── platforms/             # Platform adapters
│   │       ├── index.js
│   │       ├── opencode.js
│   │       ├── openclaw.js
│   │       ├── claude.js
│   │       ├── cursor.js
│   │       ├── openai.js
│   │       └── gemini.js
│   └── templates/                 # Platform-specific templates
│       ├── opencode.md
│       ├── openclaw.md
│       ├── claude.md
│       ├── cursor.md
│       ├── openai.json
│       └── gemini.md
├── platforms/                     # Generated platform files
│   ├── skill-writer-opencode-dev.md
│   ├── skill-writer-openclaw-dev.md
│   ├── skill-writer-claude-dev.md
│   ├── skill-writer-cursor-dev.md
│   ├── skill-writer-openai-dev.json
│   └── skill-writer-gemini-dev.md
├── examples/                      # Example skills
│   ├── api-tester/                # GOLD 920/1000
│   ├── code-reviewer/             # SILVER 820/1000
│   └── doc-generator/             # GOLD 895/1000
└── docs/                          # GitHub Pages documentation
    └── index.html
```

## Architecture

### Core + Adapter Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    Skill Writer Meta-Skill                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ CREATE Mode  │  │  LEAN Mode   │  │EVALUATE Mode │      │
│  │              │  │              │  │              │      │
│  │ • Templates  │  │ • 500-Point  │  │ • 4-Phase    │      │
│  │ • Elicitation│  │   Heuristic  │  │   Pipeline   │      │
│  │ • 9-Phase    │  │ • 8-Check    │  │ • 1000-Point │      │
│  │   Workflow   │  │   Rubric     │  │   Scoring    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────┐  ┌─────────────────────────────────────┐ │
│  │OPTIMIZE Mode │  │              Shared Resources        │ │
│  │              │  │  • CWE Security Patterns            │ │
│  │ • 7-Dimension│  │  • UTE Self-Evolution               │ │
│  │   Analysis   │  │  • Multi-LLM Deliberation           │ │
│  │ • 9-Step     │  │  • Utility Functions                │ │
│  │   Loop       │  │                                     │ │
│  └──────────────┘  └─────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                 Platform-Specific Builder                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │OpenCode │ │OpenClaw │ │ Claude  │ │ Cursor  │ ...       │
│  │ Adapter │ │ Adapter │ │ Adapter │ │ Adapter │           │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Example Skills

All example skills are certified with detailed evaluation reports.

| Skill | Type | Tier | Score | Description |
|-------|------|------|-------|-------------|
| [api-tester](examples/api-tester/) | API Integration | 🥇 GOLD | 920/1000 | HTTP API testing automation |
| [code-reviewer](examples/code-reviewer/) | Workflow Automation | 🥈 SILVER | 820/1000 | Code review with security scanning |
| [doc-generator](examples/doc-generator/) | Data Pipeline | 🥇 GOLD | 895/1000 | Documentation generation |

**Average Score: 878.3/1000**

## Contributing

### Adding New Templates

1. Create template in `core/create/templates/`
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
- **Solution**: Check trigger phrases match exactly. Triggers are case-sensitive.

**Issue**: Low evaluation score
- **Solution**: Run OPTIMIZE mode for specific improvements. Check the detailed feedback.

**Issue**: Security warnings
- **Solution**: Review CWE patterns and fix violations. See Security Features section.

**Issue**: Build fails
- **Solution**: Run `validate` command to check core engine structure.

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

- [x] Core engine with CREATE, LEAN, EVALUATE, OPTIMIZE, INSTALL modes
- [x] Builder tool with CLI
- [x] Support for 6 platforms (OpenCode, OpenClaw, Claude, Cursor, OpenAI, Gemini)
- [x] LEAN fast-evaluation mode
- [x] UTE (Use-to-Evolve) self-improvement protocol
- [x] Multi-LLM deliberation mechanism
- [ ] Web UI for skill management
- [ ] Skill marketplace integration
- [ ] Automated testing framework
- [ ] CI/CD pipeline templates

## Acknowledgments

- Inspired by [Skilo](https://github.com/yazcaleb/skilo) cross-platform skill sharing
- Built on [AgentSkills](https://github.com/opencode/agentskills) format
- Security patterns from [CWE](https://cwe.mitre.org/)

---

**Made with ❤️ by the Skill Writer Team**

*Last updated: 2026-04-01*
