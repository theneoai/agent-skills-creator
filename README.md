# Skill Writer

A cross-platform meta-skill for creating, evaluating, and optimizing AI assistant skills through natural language interaction.

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/theneoai/skill-writer)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-6-orange.svg)](#supported-platforms)
[![GitHub Actions](https://github.com/theneoai/skill-writer/workflows/Build%20and%20Release/badge.svg)](https://github.com/theneoai/skill-writer/actions)
[![Security Scan](https://github.com/theneoai/skill-writer/workflows/Security%20Scan/badge.svg)](https://github.com/theneoai/skill-writer/actions)

## Overview

Skill Writer is a meta-skill that enables AI assistants to create, evaluate, and optimize other skills through natural language interaction. No CLI commands required - just describe what you need.

### Key Features

- **Zero CLI Interface**: Natural language interaction - no commands to memorize
- **Cross-Platform**: Works on 6 major AI platforms
- **Three Powerful Modes**: CREATE, EVALUATE, and OPTIMIZE
- **Template-Based**: 4 built-in templates for common skill patterns
- **Quality Assurance**: 1000-point scoring system with certification tiers
- **Security Built-In**: CWE-based security pattern detection
- **Continuous Improvement**: Automated optimization with convergence detection

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

#### OpenCode
```bash
# Clone the repository
git clone https://github.com/theneoai/skill-writer.git
cd skill-writer

# Copy the skill file
cp platforms/skill-writer-opencode-dev.md ~/.config/opencode/skills/skill-writer.md

# Or use the builder
cd builder
npm install
npm run dev -- --platform opencode
```

#### OpenClaw
```bash
cp platforms/skill-writer-openclaw-dev.md ~/.openclaw/skills/skill-writer.md
```

#### Claude
```bash
cp platforms/skill-writer-claude-dev.md ~/.claude/skills/skill-writer.md
```

#### Cursor
```bash
cp platforms/skill-writer-cursor-dev.md ~/.cursor/skills/skill-writer.md
```

#### Gemini
```bash
cp platforms/skill-writer-gemini-dev.md ~/.gemini/skills/skill-writer.md
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

## Modes

### CREATE Mode

Generates new skills from scratch using structured templates and elicitation.

#### Workflow
1. **Parse Request**: Analyze intent and extract requirements
2. **Select Template**: Choose from 4 built-in templates
3. **Elicit Requirements**: Ask 6 clarifying questions
4. **Generate Output**: Create skill using template
5. **Security Scan**: Check for CWE vulnerabilities
6. **Quality Check**: Validate structure and completeness
7. **Deliver**: Output final skill file

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

#### Triggers
- "create a [type] skill"
- "help me write a skill for [purpose]"
- "I need a skill that [description]"
- "generate a skill to [action]"
- "build a skill for [task]"

### EVALUATE Mode

Assesses skill quality with rigorous 1000-point scoring and certification.

#### 4-Phase Pipeline
1. **Structural Analysis**: Check format, sections, completeness
2. **Content Quality**: Assess clarity, examples, instructions
3. **Security Audit**: Scan for CWE patterns
4. **Scoring**: Calculate 1000-point score

#### Scoring Rubric

| Category | Points | Criteria |
|----------|--------|----------|
| Completeness | 250 | Required sections, placeholders, examples |
| Clarity | 250 | Clear instructions, precise language |
| Security | 200 | No CWE violations, safe patterns |
| Usability | 200 | Easy to understand, good examples |
| Maintainability | 100 | Well structured, documented |

#### Certification Tiers

- **PLATINUM (950-1000)**: Exceptional quality
- **GOLD (850-949)**: Production-ready
- **SILVER (750-849)**: Good quality
- **BRONZE (650-749)**: Acceptable
- **FAIL (<650)**: Needs improvement

#### Triggers
- "evaluate this skill"
- "check the quality of my skill"
- "certify my skill"
- "score this skill"
- "assess this skill"

### OPTIMIZE Mode

Continuously improves skills through iterative refinement.

#### 7-Dimension Analysis
1. **Conciseness**: Remove redundancy
2. **Clarity**: Improve understanding
3. **Completeness**: Add missing elements
4. **Security**: Fix vulnerabilities
5. **Performance**: Optimize execution
6. **Maintainability**: Improve structure
7. **Usability**: Enhance user experience

#### 9-Step Optimization Loop
1. **Parse**: Understand current skill
2. **Analyze**: Identify improvement areas
3. **Generate**: Create optimized version
4. **Evaluate**: Score the new version
5. **Compare**: Check against previous
6. **Converge**: Detect improvement plateau
7. **Validate**: Ensure correctness
8. **Report**: Show changes
9. **Iterate**: Repeat if needed

#### Convergence Detection
Optimization stops when:
- Score improvement < 5 points
- 3 iterations without significant gain
- User requests stop
- Maximum iterations reached (10)

#### Triggers
- "optimize this skill"
- "improve my skill"
- "make this skill better"
- "refine this skill"
- "enhance this skill"

## Security Features

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
P0: X violations (Critical)
P1: X violations (High)
P2: X violations (Medium)
P3: X violations (Low)

Recommendations:
- [Specific fixes]
```

## Builder Tool

The `skill-writer-builder` CLI tool generates platform-specific skills from the core engine.

### Installation

```bash
cd builder
npm install
```

### Commands

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
│   │   ├── workflow.yaml          # 7-step workflow
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
└── platforms/                     # Generated platform files
    ├── skill-writer-opencode-dev.md
    ├── skill-writer-openclaw-dev.md
    ├── skill-writer-claude-dev.md
    ├── skill-writer-cursor-dev.md
    ├── skill-writer-openai-dev.json
    └── skill-writer-gemini-dev.md
```

## Architecture

### Core + Adapter Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    Skill Writer Meta-Skill                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ CREATE Mode  │  │EVALUATE Mode │  │ OPTIMIZE Mode│      │
│  │              │  │              │  │              │      │
│  │ • Templates  │  │ • 4-Phase    │  │ • 7-Dimension│      │
│  │ • Elicitation│  │   Pipeline   │  │   Analysis   │      │
│  │ • 7-Step     │  │ • 1000-Point │  │ • 9-Step     │      │
│  │   Workflow   │  │   Scoring    │  │   Loop       │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Shared Resources                        │   │
│  │  • CWE Security Patterns • Utility Functions        │   │
│  └─────────────────────────────────────────────────────┘   │
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

- [x] Core engine with CREATE, EVALUATE, OPTIMIZE modes
- [x] Builder tool with CLI
- [x] Support for 6 platforms (OpenCode, OpenClaw, Claude, Cursor, OpenAI, Gemini)
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

*Last updated: 2026-03-31*
