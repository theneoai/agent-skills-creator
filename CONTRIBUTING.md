# Contributing to Skill Writer

Thank you for your interest in contributing to Skill Writer!

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Project Structure](#project-structure)
4. [Adding New Features](#adding-new-features)
5. [Adding Platform Support](#adding-platform-support)
6. [Testing](#testing)
7. [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to:

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Respect different viewpoints and experiences

## Getting Started

### Prerequisites

- Git
- bash (macOS/Linux/WSL)
- A supported AI platform (Claude, OpenClaw, or OpenCode)

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/theneoai/skill-writer.git
   cd skill-writer
   ```

3. Install to your platform (no build step required):
   ```bash
   ./install.sh                   # auto-detect
   ./install.sh --platform claude # specific platform
   ./install.sh --dry-run         # preview only
   ```

## Project Structure

```
skill-writer/
├── claude/            # Claude platform
│   ├── skill-writer.md    ← v3.4.0 skill file
│   ├── CLAUDE.md          ← Routing rules (merged into ~/.claude/CLAUDE.md)
│   └── install.sh         ← Installs to ~/.claude/
├── openclaw/          # OpenClaw platform
│   ├── skill-writer.md    ← Same skill + metadata.openclaw YAML block
│   ├── AGENTS.md          ← Routing rules
│   └── install.sh         ← Installs to ~/.openclaw/
├── opencode/          # OpenCode platform
│   ├── skill-writer.md    ← Same skill + Triggers footer
│   ├── AGENTS.md          ← Routing rules
│   └── install.sh         ← Installs to ~/.config/opencode/
├── cursor/            # Cursor IDE platform
│   ├── skill-writer.mdc   ← MDC rule file (alwaysApply: true)
│   ├── install.sh         ← Installs to .cursor/rules/ or ~/.cursor/rules/
│   └── install.ps1        ← Windows PowerShell installer
├── gemini/            # Gemini platform
│   ├── skill-writer.md
│   └── install.sh         ← Installs to ~/.gemini/
├── openai/            # OpenAI Agents SDK
│   ├── skill-writer.md
│   └── install.sh         ← Installs to project dir
├── kimi/              # Kimi / Moonshot AI
│   ├── skill-writer.md
│   └── install.sh         ← Installs to ~/.config/kimi/
├── hermes/            # Hermes platform
│   ├── skill-writer.md
│   └── install.sh         ← Installs to ~/.hermes/
│
├── scripts/           # Dev helper scripts (called by Makefile and CI)
│   ├── lint.sh            ← shellcheck all install scripts
│   ├── validate.sh        ← dry-run all installers
│   └── check-version.py   ← verify version consistency across all platform files
├── refs/              # Companion reference files (all platforms)
├── templates/         # 4 skill creation templates
├── eval/              # Evaluation rubrics and benchmarks
├── optimize/          # Optimization strategies and anti-patterns
├── examples/          # Certified example skills
├── VERSION            # Single source of truth for the current version
├── Makefile           # Common dev targets: lint, validate, check-version, ci
├── skill-framework.md # Complete specification (source of truth)
└── install.sh         # Top-level dispatcher → delegates to platform scripts
```

**No build pipeline** — all platform files are direct Markdown, hand-maintained.
Changes to a platform's skill file are made by editing `{platform}/skill-writer.md` directly.

To keep the 8 platform files in sync when making cross-platform changes:
1. Edit `skill-framework.md` first (master spec)
2. Mirror the changes to each platform's `skill-writer.md`
3. Run `make check-version` to confirm all files report the same version number
4. Run `make ci` to validate everything before pushing

## Adding New Features

### Updating the Skill Framework

Most features live in `skill-framework.md` (the master specification) and are mirrored to each platform skill file.

Workflow:
1. Edit `skill-framework.md` first (source of truth)
2. Mirror changes to all affected platform `skill-writer.md` files
3. For platform-specific content (e.g., `metadata.openclaw`), edit only that platform's file
4. Update companion files in `refs/`, `eval/`, or `optimize/` as needed
5. Run `make ci` to validate everything locally before pushing

### Adding a New Template

1. Create file in `templates/`:
   ```bash
   touch templates/my-template.md
   ```

2. Follow the pattern from `templates/base.md` — fill required placeholders:
   `{{SKILL_NAME}}`, `{{ONE_LINE_DESCRIPTION}}`, `{{TARGET_USER}}`, etc.

3. Test with CREATE mode in your AI assistant

4. Update the template selection table in `skill-framework.md §6 CREATE Mode`

### Adding a New Mode

1. Add a new `## §N Mode-Name Mode` section to `skill-framework.md`
2. Add the mode trigger to the YAML frontmatter `modes:` list and `triggers.en/zh` arrays
3. Add the mode to the routing table in `claude/CLAUDE.md`, `openclaw/AGENTS.md`, `opencode/AGENTS.md`
4. Mirror the section to all three platform skill files
5. Update README.md mode documentation

## Adding Platform Support

### Creating a New Platform Directory

Each platform is a self-contained directory with three files:

```bash
mkdir newplatform/
```

1. **`newplatform/skill-writer.md`** — copy from `claude/skill-writer.md` as base, then:
   - Update PATH CONVENTION comment to reference `~/.newplatform/` paths
   - Add any platform-specific YAML metadata block
   - Add any platform-specific sections (if the platform has unique capabilities)

2. **`newplatform/AGENTS.md`** — routing rules file:
   ```markdown
   <!-- skill-writer:start -->
   ## Skill Registry — Active Skills
   **skill-writer** is installed and active.
   ...routing table for all 8 modes...
   <!-- skill-writer:end -->
   ```

3. **`newplatform/install.sh`** — install script (copy from `claude/install.sh` as base):
   - Set `PLATFORM_HOME="${HOME}/.newplatform"` (or platform-specific path)
   - Install skill, companion files, routing file
   - Handle idempotent routing file merge with `<!-- skill-writer:start/end -->` markers
   - Support `--dry-run` flag

4. Update top-level `install.sh`:
   - Add platform to `detect_platforms()` function
   - Add platform to `--all` target list

5. Update README.md platform table

## Testing

### Manual Testing

```bash
# Run full local CI (lint + dry-run all platforms + version check)
make ci

# Preview install for a specific platform (no changes made)
./install.sh --platform claude --dry-run

# Install and verify
./install.sh --platform claude
ls ~/.claude/skills/
ls ~/.claude/refs/

# Verify routing rules merged
grep -n "skill-writer:start" ~/.claude/CLAUDE.md

# Test idempotency (run twice, should produce same result)
./install.sh --platform claude
./install.sh --platform claude
```

### Skill Quality Check

After editing any skill file, verify quality:

1. Install to Claude: `./install.sh --platform claude`
2. In Claude: type `lean eval` and paste the skill content
3. Score should be ≥ 350/500 (LEAN threshold)
4. For certification: type `evaluate this skill` — score ≥ 700/1000 (BRONZE)

### Platform-Specific Testing

```bash
# OpenClaw
./install.sh --platform openclaw --dry-run
# Then: restart OpenClaw → type "create a skill" to verify routing

# OpenCode
./install.sh --platform opencode --dry-run
# Then: restart OpenCode → type "create a skill" to verify routing
```

## Submitting Changes

### Pull Request Process

1. **Before Submitting:**
   - Run `make ci` (lint + dry-run validation + version consistency)
   - Test routing with your AI assistant
   - Update documentation in the platform files you changed
   - Bump `VERSION` and add a `CHANGELOG.md` entry if the change is user-visible

2. **PR Description Should Include:**
   - What changed and why
   - Which platforms are affected
   - How to verify the change
   - LEAN/EVALUATE score if you modified a skill file

3. **Review Process:**
   - Maintainers will review within 48 hours
   - Address feedback promptly
   - Keep discussion constructive

### Commit Message Format

```
type(scope): subject

body (optional)
```

Types: `feat` | `fix` | `docs` | `refactor` | `chore`

Scope examples: `claude`, `openclaw`, `opencode`, `refs`, `templates`, `eval`, `optimize`

Examples:
```
feat(templates): add ML model template

fix(openclaw): correct path references in install.sh

docs(refs): update security-patterns.md with ASI09/ASI10

refactor(install): simplify idempotent AGENTS.md merge
```

## Style Guide

### Markdown Skill Files

- YAML frontmatter: 2-space indentation
- Sections: `## §N Section-Name` pattern
- Required sections: Skill Summary, §2 Negative Boundaries, §3 Mode Router
- Line wrap: 80–120 chars for prose, no wrap for tables/code
- Placeholders: `{{UPPER_SNAKE_CASE}}`

### Install Scripts

- Use `set -euo pipefail`
- Support `--dry-run` flag on all write operations
- Idempotent: safe to run multiple times
- Backup existing files before overwriting (`.bak.YYYYMMDD_HHMMSS`)

## Questions?

- **General**: Open a [Discussion](https://github.com/theneoai/skill-writer/discussions)
- **Bugs**: Open an [Issue](https://github.com/theneoai/skill-writer/issues)
- **Security**: Open a [GitHub Security Advisory](https://github.com/theneoai/skill-writer/security/advisories/new)

## Recognition

Contributors will be listed in release notes and credited in documentation.
