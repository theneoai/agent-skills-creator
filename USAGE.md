# Skill Writer - Usage Guide

This guide provides detailed examples and patterns for using Skill Writer effectively.

## Table of Contents

1. [Getting Started](#getting-started)
2. [INSTALL Mode Examples](#install-mode-examples)
3. [CREATE Mode Examples](#create-mode-examples)
4. [EVALUATE Mode Examples](#evaluate-mode-examples)
5. [OPTIMIZE Mode Examples](#optimize-mode-examples)
6. [Advanced Patterns](#advanced-patterns)
7. [Best Practices](#best-practices)

## Getting Started

### Installation

The fastest way to install skill-writer is to paste one of these commands into your AI agent.

**Install latest release — all platforms:**
```
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer.md and install
```

**Install latest release — single platform:**
```
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-claude.md and install to claude
```

Replace `claude` with `opencode`, `openclaw`, `cursor`, or `gemini` as needed.

Every [GitHub Release](https://github.com/theneoai/skill-writer/releases) publishes per-platform assets and includes ready-to-paste agent commands for that specific version.

See [INSTALL Mode Examples](#install-mode-examples) for more patterns, or the [README](README.md) for shell-script and manual alternatives.

### Installation Verification

After installation, verify the skill is working:

```
"Hello, are you ready to help me create skills?"
```

Expected response: The AI should acknowledge and offer to help with CREATE, LEAN, EVALUATE, OPTIMIZE, or INSTALL modes.

### First Skill Creation

Let's create a simple skill:

```
"Create a skill that greets users by name"
```

The AI will:
1. Ask 6 elicitation questions
2. Select the Base template
3. Generate the skill
4. Show you the result

## INSTALL Mode Examples

### Example 1: Install via install.md URL (Recommended)

**User Request:**
```
"read https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md and install"
```

**Agent Process:**
1. Fetch `install.md` from URL — contains self-contained install instructions
2. Fetch `skill-framework.md` and all companion files from GitHub raw URLs
3. Write to each platform's skills directory

**Sample Output:**
```
Installing Skill Writer v2.0.0...
✓ Fetched install.md (8 KB)
✓ Fetched skill-framework.md (24 KB)

Install plan:
  • ~/.claude/skills/skill-writer.md
  • ~/.config/opencode/skills/skill-writer.md
  • ~/.openclaw/skills/skill-writer.md
  • ~/.cursor/skills/skill-writer.md
  • ~/.gemini/skills/skill-writer.md

Proceed? yes

✓ [claude]   ~/.claude/skills/skill-writer.md
✓ [claude]   companion files → ~/.claude/{refs,templates,eval,optimize}/
✓ [opencode] ~/.config/opencode/skills/skill-writer.md
✓ [openclaw] ~/.openclaw/skills/skill-writer.md
✓ [cursor]   ~/.cursor/skills/skill-writer.md
✓ [gemini]   ~/.gemini/skills/skill-writer.md

Installed to 5 platforms. Restart each to activate skill-writer.
```

### Example 2: Install to a Single Platform

**User Request:**
```
"read https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md and install to claude"
```

**Sample Output:**
```
✓ Fetched install.md
✓ Fetched skill-framework.md

Install plan: ~/.claude/skills/skill-writer.md  [claude only]
Proceed? yes

✓ [claude] ~/.claude/skills/skill-writer.md
✓ [claude] companion files → ~/.claude/{refs,templates,eval,optimize}/

Installed to 1 platform. Restart Claude to activate skill-writer.
```

### Example 3: Install from Local Clone

**User Request:**
```
"install skill-writer"
"安装 skill-writer"
```

**Agent Process:**
Uses the local `install.md` already on disk (no network required).

### Example 4: URL Verification Failure

**User Request:**
```
"read https://example.com/some-other-skill.md and install"
```

**Sample Output:**
```
✗ ABORT — fetched file does not contain 'name: skill-writer'.
  This does not appear to be skill-writer.
  Check the URL and try again.
```

## CREATE Mode Examples

### Example 1: API Integration Skill

**User Request:**
```
"Create a skill for fetching weather data from OpenWeatherMap API"
```

**Elicitation Process:**
The AI will ask:
1. What's the primary goal? → "Fetch current weather and forecasts"
2. Who are the target users? → "Developers and end users"
3. What capabilities must it have? → "Current weather, 5-day forecast, location search"
4. Any constraints? → "Need API key, rate limits"
5. Expected scale? → "100 requests/day"
6. Any references? → "Similar to weather.com API"

**Generated Skill Structure:**
```yaml
name: weather-api-skill
version: 1.0.0
description: Fetch weather data from OpenWeatherMap API
template: api-integration
```

### Example 2: Data Pipeline Skill

**User Request:**
```
"Create a skill that processes CSV files and generates reports"
```

**Key Features Generated:**
- CSV parsing with validation
- Data transformation steps
- Report generation in multiple formats
- Error handling for malformed data

### Example 3: Workflow Automation Skill

**User Request:**
```
"Create a skill that automates GitHub issue management"
```

**Generated Components:**
- Issue creation from templates
- Label management
- Assignment automation
- Notification triggers

### Template Selection Guide

| Use Case | Recommended Template | Why |
|----------|---------------------|-----|
| Simple utility | Base | Minimal boilerplate |
| External API | API Integration | Built-in auth patterns |
| Data processing | Data Pipeline | Validation & transformation |
| CI/CD tasks | Workflow Automation | Step sequencing |

## EVALUATE Mode Examples

### Example 1: Basic Evaluation

**User Request:**
```
"Evaluate this skill"
```

**AI Process:**
1. Parse the skill file
2. Run 4-phase evaluation
3. Generate score report

**Sample Output:**
```
Evaluation Report
=================
Overall Score: 847/1000 (SILVER Tier)

Phase Breakdown:
- Phase 1 Parse & Validate:  88/100
- Phase 2 Text Quality:      252/300
    clarity:        42/50
    completeness:   44/50
    accuracy:       55/60
    safety:         55/60
    maintainability: 32/40
    usability:       24/40
- Phase 3 Runtime Testing:   355/400
- Phase 4 Certification:     152/200

Variance: |252/3 - 355/4| = |84 - 88.75| = 4.75 ✓ (within SILVER limit of 20)

Issues Found:
1. Missing error handling examples (-10 points, usability)
2. Unclear trigger description (-5 points, clarity)

Recommendations:
1. Add try-catch examples
2. Clarify trigger patterns with more examples
```

### Example 2: Security-Focused Evaluation

**User Request:**
```
"Evaluate this skill for security issues"
```

**Sample Output:**
```
Security Audit Report
=====================
Score: 720/1000 (SILVER Tier)

Security Issues:
⚠️ CWE-78: Potential command injection in line 45
   - Recommendation: Use parameterized commands

⚠️ CWE-89: SQL injection risk in query builder
   - Recommendation: Use prepared statements

Security Score: 140/200

Overall: Skill needs security improvements before production use.
```

### Example 3: Certification Request

**User Request:**
```
"Certify my skill for production use"
```

**Certification Criteria:**
- GOLD (≥900) or PLATINUM (≥950) required for production
- No critical security issues (P0 CWE violations → ABORT)
- All required sections present
- Clear documentation

**Sample Output:**
```
Certification Result
====================
Status: ✓ CERTIFIED - GOLD Tier
Score: 912/1000
Variance: |285/3 - 360/4| = |95 - 90| = 5.0 ✓ (within GOLD limit of 15)

This skill meets production quality standards.
Certification ID: SW-CERT-2026-001
Valid until: 2027-03-31
```

## OPTIMIZE Mode Examples

### Example 1: Conciseness Optimization

**User Request:**
```
"Optimize this skill to be more concise"
```

**Optimization Process:**
```
Iteration 1: 720 → 810 (+90 points)
- Removed redundant phrases
- Consolidated similar sections

Iteration 2: 810 → 855 (+45 points)
- Simplified complex sentences
- Removed duplicate examples

Iteration 3: 855 → 858 (+3 points)
⚠️ Convergence detected (improvement < 5 points)

Final Score: 858/1000 (GOLD Tier)
Total Improvement: +138 points
Changes: 23 optimizations applied
```

### Example 2: Security Optimization

**User Request:**
```
"Optimize this skill to fix security issues"
```

**Sample Output:**
```
Security Optimization Report
============================
Initial Score: 680/1000 (BRONZE)
Security Score: 120/200

Issues Fixed:
✓ CWE-78: Replaced exec() with spawn() with input validation
✓ CWE-89: Added parameterized queries
✓ CWE-22: Implemented path validation

Final Score: 890/1000 (GOLD)
Security Score: 195/200

All critical security issues resolved.
```

### Example 3: Comprehensive Optimization

**User Request:**
```
"Optimize this skill across all dimensions"
```

**7-Dimension Analysis:**
```
Optimization Report
===================
Initial Score: 650/1000 (BRONZE)

Improvements by Dimension:
1. Conciseness: 140 → 230 (+90)
2. Clarity: 180 → 240 (+60)
3. Completeness: 200 → 245 (+45)
4. Security: 120 → 195 (+75)
5. Performance: 80 → 95 (+15)
6. Maintainability: 70 → 98 (+28)
7. Usability: 160 → 185 (+25)

Final Score: 888/1000 (GOLD)
Total Improvement: +238 points
Iterations: 5
```

## Advanced Patterns

### Pattern 1: Iterative Refinement

**Workflow:**
```
1. CREATE: Generate initial skill
2. EVALUATE: Identify issues
3. OPTIMIZE: Fix issues
4. EVALUATE: Verify improvements
5. Repeat until satisfied
```

**Example:**
```
User: "Create a database query skill"
[Skill created with score 720]

User: "Evaluate this skill"
[Issues identified: missing error handling, unclear examples]

User: "Optimize this skill"
[Optimized to 890]

User: "Evaluate again"
[Confirmed: 890/1000, GOLD tier]
```

### Pattern 2: Template Customization

**Creating a custom template:**
```
"Create a skill using a custom template for machine learning models"
```

**Custom Template Structure:**
```yaml
name: ml-model-skill
template: custom
sections:
  - Model Architecture
  - Training Data
  - Hyperparameters
  - Evaluation Metrics
  - Deployment
```

### Pattern 3: Multi-Platform Deployment

**Agent-driven — latest release (recommended):**
```
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer.md and install
```

**Agent-driven — specific platform:**
```
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-claude.md and install to claude
```

**Shell script:**
```bash
# Install to all platforms at once
./install.sh

# Or install to specific platforms
./install.sh --platform claude
./install.sh --platform opencode

# Install directly from the latest release asset
./install.sh --url https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer.md
```

**Builder (generates platform-adapted variants):**
```bash
cd builder
node bin/skill-writer-builder.js build --platform all

# Results in:
# platforms/skill-writer-opencode-dev.md
# platforms/skill-writer-openclaw-dev.md
# platforms/skill-writer-claude-dev.md
# platforms/skill-writer-cursor-dev.md
# platforms/skill-writer-openai-dev.json
# platforms/skill-writer-gemini-dev.md
```

### Pattern 4: Batch Processing

**Creating multiple skills:**
```
"Create skills for: 1) Email validation, 2) Phone formatting, 3) Address parsing"
```

The AI will create all three skills in sequence.

## Best Practices

### For Skill Creators

1. **Be Specific**: Clear requirements lead to better skills
   - ❌ "Create a good skill"
   - ✅ "Create a skill that validates email addresses with regex"

2. **Answer Elicitation Questions**: Provide detailed answers for better results

3. **Test Triggers**: Verify trigger phrases work as expected

4. **Iterate**: Use EVALUATE and OPTIMIZE to improve

5. **Security First**: Always run security checks before deployment

### For Skill Users

1. **Use Exact Triggers**: Trigger phrases are case-sensitive

2. **Provide Context**: More context = better results
   - ❌ "Fix this"
   - ✅ "Optimize this skill for better error handling"

3. **Review Changes**: Always review optimized skills before using

4. **Version Control**: Keep backups of working skills

### For Platform Admins

1. **Regular Evaluation**: Periodically evaluate installed skills

2. **Security Audits**: Run security checks on all skills

3. **Update Templates**: Keep templates current with best practices

4. **Monitor Usage**: Track which skills are most used

## Troubleshooting Common Issues

### Issue: "Skill not found"

**Solution:**
1. Check installation path is correct
2. Verify file permissions
3. Restart AI assistant
4. Reinstall skill

### Issue: "Low evaluation score"

**Solution:**
1. Run OPTIMIZE mode
2. Review specific feedback
3. Add missing sections
4. Improve examples

### Issue: "Triggers not working"

**Solution:**
1. Check exact trigger phrase
2. Verify no extra spaces
3. Try alternative triggers
4. Check case sensitivity

### Issue: "Security warnings"

**Solution:**
1. Review CWE patterns
2. Apply recommended fixes
3. Run security-focused OPTIMIZE
4. Re-evaluate

## Tips and Tricks

### Tip 1: Use Mode Chaining

Chain modes for best results:
```
CREATE → EVALUATE → OPTIMIZE → EVALUATE
```

### Tip 2: Save Checkpoints

Before optimizing, save a copy:
```
"Save a backup of this skill before optimizing"
```

### Tip 3: Targeted Optimization

Be specific about what to optimize:
```
"Optimize only the security aspects of this skill"
```

### Tip 4: Compare Versions

Compare before and after:
```
"Show me what changed in the optimization"
```

### Tip 5: Custom Requirements

Add specific requirements:
```
"Create a skill that handles errors gracefully and logs to console"
```

## Command Reference

### Builder CLI

```bash
# Build commands
node bin/skill-writer-builder.js build --platform all
node bin/skill-writer-builder.js build --platform opencode
node bin/skill-writer-builder.js build --platform all --release

# Development
node bin/skill-writer-builder.js dev --platform opencode

# Validation
node bin/skill-writer-builder.js validate

# Inspection
node bin/skill-writer-builder.js inspect --platform opencode
```

### Natural Language Commands

**INSTALL Mode:**
- `"read <URL> and install"` — fetch from URL, install to all platforms
- `"read <URL> and install to <platform>"` — fetch from URL, install to one platform
- `"install skill-writer"` — install from local clone, all platforms
- `"install skill-writer to <platform>"` — install from local clone, one platform
- `"安装 skill-writer"` — install (Chinese)
- `"从 <URL> 安装"` — fetch from URL and install (Chinese)

Supported `<platform>` values: `claude`, `opencode`, `openclaw`, `cursor`, `gemini`, `all`

**CREATE Mode:**
- "Create a [type] skill"
- "Generate a skill for [purpose]"
- "Build a skill that [functionality]"

**EVALUATE Mode:**
- "Evaluate this skill"
- "Check quality"
- "Certify this skill"
- "Score this skill"

**OPTIMIZE Mode:**
- "Optimize this skill"
- "Improve this skill"
- "Make this better"
- "Refine this skill"

## Examples Gallery

### Example Skills Created

1. **Weather API Skill** - Fetches weather data
2. **GitHub Manager** - Automates GitHub tasks
3. **CSV Processor** - Processes data files
4. **Email Validator** - Validates email formats
5. **Code Formatter** - Formats code snippets
6. **Test Generator** - Generates unit tests
7. **Documentation Writer** - Creates documentation
8. **Security Scanner** - Scans for vulnerabilities

### Success Stories

**Story 1: From Idea to Production**
```
User created a database migration skill:
- Initial CREATE: 720 points (BRONZE)
- After OPTIMIZE: 910 points (PLATINUM)
- Time saved: 10 hours/week
```

**Story 2: Security Transformation**
```
Legacy skill with security issues:
- Initial security score: 80/200
- After security OPTIMIZE: 195/200
- Critical issues resolved: 5
```

---

**Need more help?** Check the [README](README.md) or [open an issue](https://github.com/theneoai/skill-writer/issues).
