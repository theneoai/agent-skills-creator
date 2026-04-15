# Contributing to Skill Writer

Thank you for your interest in contributing to Skill Writer! This document provides guidelines and instructions for contributing.

## Ways to Contribute

### 1. Submit a New Skill

Help expand our skill library by submitting new skills.

**Requirements:**
- Follow the skill template format (one of: `templates/base.md`, `templates/api-integration.md`, `templates/data-pipeline.md`, `templates/workflow-automation.md`)
- Include at least 2 usage examples (EN + ZH triggers shown)
- Provide bilingual documentation (Chinese/English) — Skill Summary + Negative Boundaries
- Pass all quality checks:
  - LEAN score ≥ 350/500 (run `/lean eval` inside Claude with skill-writer installed)
  - Full EVALUATE score ≥ 700/1000 (BRONZE tier minimum)
  - No P0 CWE issues (CWE-798, CWE-89, CWE-78) — see `refs/security-patterns.md`

**Process:**
1. Create a new issue using the [Skill Submission template](ISSUE_TEMPLATE/skill_submission.md)
2. Fill in all required information
3. Attach your skill file
4. Wait for review and feedback

### 2. Report Bugs

Help us improve by reporting bugs you encounter.

**Process:**
1. Check if the bug has already been reported
2. Create a new issue using the [Bug Report template](ISSUE_TEMPLATE/bug_report.md)
3. Provide detailed reproduction steps
4. Include environment information (platform: Claude/OpenClaw/etc., skill-writer version)

### 3. Suggest Features

Have an idea for improvement? We'd love to hear it!

**Process:**
1. Create a new issue using the [Feature Request template](ISSUE_TEMPLATE/feature_request.md)
2. Describe the problem and proposed solution
3. Discuss with maintainers and community

### 4. Improve Documentation

Help us improve our documentation.

**Areas to contribute:**
- Fix typos and grammar
- Add examples and tutorials
- Translate documentation (EN ↔ ZH)
- Improve clarity and completeness in `skill-framework.md`, `refs/`, or platform files

## Development Setup

### Prerequisites

- Git
- Any AI platform with skill-writer installed (Claude Code recommended)
- No Node.js or build tools required — skill-writer is a zero-dependency Markdown framework

### Setup Steps

```bash
# Clone the repository
git clone https://github.com/theneoai/skill-writer.git
cd skill-writer

# Install to your AI platform (no build step required)
./install.sh                          # auto-detect installed platforms
./install.sh --platform claude        # Claude only
./install.sh --platform cursor        # Cursor only
```

### Project Structure

```
skill-writer/
├── claude/                # Claude platform files
│   ├── skill-writer.md    # Main skill file (SKILL.md v3.4.0 compliant)
│   ├── CLAUDE.md          # Routing rules for Claude Code
│   └── install.sh
├── openclaw/              # OpenClaw platform files
├── opencode/              # OpenCode platform files
├── cursor/                # Cursor platform files
├── gemini/                # Gemini platform files
├── openai/                # OpenAI Agents SDK files
├── kimi/                  # Kimi / Moonshot AI files
├── hermes/                # Hermes platform files
├── refs/                  # Shared companion reference files
│   ├── security-patterns.md
│   ├── convergence.md
│   ├── skill-graph.md
│   └── ...
├── templates/             # Skill creation templates (4 types)
├── eval/                  # Evaluation rubrics + benchmarks
├── optimize/              # Optimization strategies + anti-patterns
├── examples/              # Example skills (00-starter, api-tester, code-reviewer, doc-generator)
├── skill-framework.md     # Complete specification document
├── install.sh             # Top-level dispatcher
└── CHANGELOG.md
```

## Skill Development Guide

### Skill Structure (v3.4.0)

All skills follow this YAML frontmatter + body structure:

```yaml
---
name: skill-name
version: "1.0.0"
description: "One-line description."
description_i18n:
  en: "English description"
  zh: "中文描述"

license: MIT
author:
  name: Your Name
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
type: assistant          # assistant | tool-wrapper | analyzer | api-integration | etc.
skill_tier: functional   # planning | functional | atomic

tags:
  - tag1
  - tag2

triggers:
  en:
    - "trigger phrase 1"
    - "trigger phrase 2"
    - "trigger phrase 3"
  zh:
    - "触发词 1"
    - "触发词 2"

interface:
  input: user-natural-language
  output: text

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v3.4.0"
  injected_at: "YYYY-MM-DD"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
  generation_method: "human-authored"  # auto-generated | human-authored | hybrid
  validation_status: "lean-only"       # unvalidated | lean-only | full-eval | pragmatic-verified
---

## Skill Summary
[≤5 dense sentences: WHAT / WHEN / WHO / NOT-FOR]

## §1  Identity
...

## §2  Negative Boundaries
...

## §UTE Use-to-Evolve
...
```

### Best Practices

1. **Naming**: Use descriptive, lowercase names with hyphens (e.g. `git-diff-summarizer`)
2. **Skill Summary**: Write last, after you know the full skill — it's the decisive routing signal
3. **Negative Boundaries**: ≥3 specific anti-cases with example phrasings and alternative skills
4. **Examples**: Provide at least 2 practical examples (EN + ZH triggers both shown)
5. **Security**: Pass P0 security scan (CWE-798, CWE-89, CWE-78) before submitting
6. **Triggers**: 3–8 EN phrases + 2–5 ZH phrases; cover the most natural user phrasings
7. **Evaluation**: Run `/lean eval` (≥350) and `/eval` (≥700) before submitting

### Quality Standards

| Metric | Minimum | Target |
|--------|---------|--------|
| LEAN Score | 350/500 | 450+ |
| Full Evaluate Score | 700/1000 (BRONZE) | 850+ (SILVER/GOLD) |
| P0 Security Issues | 0 | 0 |
| Trigger Accuracy (F1) | ≥ 0.90 | ≥ 0.95 |
| Examples | 2 | 3+ |
| Behavioral Verifier pass_rate | ≥ 0.60 | ≥ 0.80 |

## Pull Request Process

1. **Fork the Repository**

   Fork at: https://github.com/theneoai/skill-writer/fork

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/<your-username>/skill-writer.git
   cd skill-writer
   ```

3. **Create a Branch**
   ```bash
   git checkout -b feat/your-skill-name
   # or for doc fixes:
   git checkout -b fix/describe-the-fix
   ```

4. **Make Changes**
   - For new skills: add to `examples/<skill-name>/skill.md` + optional `eval-report.md`
   - For framework changes: edit `skill-framework.md` or relevant `refs/*.md`
   - For template changes: edit the relevant `templates/*.md`
   - Update CHANGELOG.md if appropriate

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add <skill-name> skill (BRONZE, lean=XXX)"
   # or:
   git commit -m "fix: update security patterns for ASI07 coverage"
   ```

6. **Push to Your Fork**
   ```bash
   git push origin feat/your-skill-name
   ```

7. **Create Pull Request**
   - Use a clear title referencing the skill name or fix description
   - Reference related issues with `Closes #<issue>`
   - Describe your changes and include LEAN/EVALUATE scores for new skills
   - Request review from maintainers

### PR Checklist

- [ ] Skill follows v3.4.0 template structure (skill_tier, triggers, Skill Summary, Negative Boundaries, use_to_evolve with 13 fields)
- [ ] LEAN score ≥ 350/500 (include score in PR description)
- [ ] Full EVALUATE score ≥ 700/1000 or TEMP_CERT: true with 72h re-eval window
- [ ] P0 security scan clear (CWE-798, CWE-89, CWE-78)
- [ ] No `{{PLACEHOLDER}}` tokens remaining
- [ ] At least 2 usage examples with EN and ZH triggers shown
- [ ] generation_method and validation_status YAML fields present
- [ ] Commit messages are clear and descriptive

## Code Review Process

All submissions require review before being merged:

1. Automated CI checks must pass (YAML validation, install script checks — see `.github/workflows/`)
2. At least one maintainer approval required
3. Address all review comments
4. Squash commits if requested

## Getting Help

- Open a [Discussion](https://github.com/theneoai/skill-writer/discussions)
- Open an issue with the [Feature Request template](ISSUE_TEMPLATE/feature_request.md)
- Read `skill-framework.md` — the complete specification is in that one file

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](../LICENSE).

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes (CHANGELOG.md)
- SKILL.md author field (your name in the skill's YAML frontmatter)

Thank you for contributing to Skill Writer!
