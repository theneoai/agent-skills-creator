# Skill Writer — Agent Install Guide

> **For AI agents**: This file contains self-contained installation instructions.
> Execute the steps in §3 exactly as written. No extra user input is needed unless
> the target platform is ambiguous.

---

## §1  File Sources

All files can be fetched from GitHub. Use whichever source applies:

| Scenario | How to get files |
|----------|-----------------|
| Read this file from a **URL** | Fetch each file from the GitHub raw URLs listed in §4 |
| Read this file from a **local clone** | Read files from the same directory as this file |

**Base URL (for remote fetch):**
```
https://raw.githubusercontent.com/theneoai/skill-writer/main/
```

**Main skill file:**
```
https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md
```

**Platform-specific built files (recommended for most platforms):**
```
https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-<platform>-dev.md
```

> **Note**: The `platforms/` directory contains pre-built, self-contained skill files for each platform. These are recommended over `skill-framework.md` because they don't have external file dependencies (like `claude/refs/` paths).

---

## §2  Platform → Destination Map

| Platform | Skills directory | Companion files |
|----------|----------------|-----------------|
| **claude** | `~/.claude/skills/` | Yes — see §4 |
| **opencode** | `~/.config/opencode/skills/` | No |
| **openclaw** | `~/.openclaw/skills/` | No |
| **cursor** | `~/.cursor/skills/` | No |
| **gemini** | `~/.gemini/skills/` | No |
| **openai** | N/A — manual only | See §5 |

Installed filename on all platforms: **`skill-writer.md`**

---

## §3  Installation Steps (Agent: execute these)

### Step 1 — Get the skill file

**IMPORTANT**: For most platforms (opencode, openclaw, cursor, gemini), use the **pre-built platform files** from the `platforms/` directory. These are self-contained and don't require external companion files.

**For OpenCode, OpenClaw, Cursor, Gemini:**
```
Fetch: https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-<platform>-dev.md
Store content as: SKILL_CONTENT
```

**For Claude:**
```
Fetch: https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md
Store content as: SKILL_CONTENT
```

**If you read this file from a local path:**
```
# For most platforms (recommended):
Read: platforms/skill-writer-<platform>-dev.md

# For Claude (requires companion files):
Read: skill-framework.md
```

Verify: `SKILL_CONTENT` must contain the text `name: skill-writer`. If not, abort and tell the user.

### Step 2 — Determine target platform(s)

Detect from the user's message:

| User says | Target |
|-----------|--------|
| "install" / "install to all" / "安装" | all (claude, opencode, openclaw, cursor, gemini) |
| "install to claude" / "安装到 claude" | claude |
| "install to opencode" / "安装到 opencode" | opencode |
| "install to openclaw" / "安装到 openclaw" | openclaw |
| "install to cursor" / "安装到 cursor" | cursor |
| "install to gemini" / "安装到 gemini" | gemini |

If unclear, ask: "Which platform? (claude / opencode / openclaw / cursor / gemini / all)"

### Step 3 — Write skill file for each target platform

For each target platform:
1. Create the skills directory if it does not exist
2. Write `SKILL_CONTENT` to `<skills_dir>/skill-writer.md`
3. If platform is **claude**, also execute Step 4
4. Report: `✓ [<platform>] <full destination path>`

### Step 4 — Claude companion files (claude only)

Fetch each file below and write to the corresponding destination.

**If remote:** fetch from the URL shown.
**If local:** read from the repo path shown.

| File | Remote URL | Local path | Destination |
|------|-----------|------------|-------------|
| use-to-evolve.md | `…/refs/use-to-evolve.md` | `refs/use-to-evolve.md` | `~/.claude/refs/use-to-evolve.md` |
| evolution.md | `…/refs/evolution.md` | `refs/evolution.md` | `~/.claude/refs/evolution.md` |
| self-review.md | `…/refs/self-review.md` | `refs/self-review.md` | `~/.claude/refs/self-review.md` |
| convergence.md | `…/refs/convergence.md` | `refs/convergence.md` | `~/.claude/refs/convergence.md` |
| security-patterns.md | `…/refs/security-patterns.md` | `refs/security-patterns.md` | `~/.claude/refs/security-patterns.md` |
| base.md | `…/templates/base.md` | `templates/base.md` | `~/.claude/templates/base.md` |
| api-integration.md | `…/templates/api-integration.md` | `templates/api-integration.md` | `~/.claude/templates/api-integration.md` |
| data-pipeline.md | `…/templates/data-pipeline.md` | `templates/data-pipeline.md` | `~/.claude/templates/data-pipeline.md` |
| workflow-automation.md | `…/templates/workflow-automation.md` | `templates/workflow-automation.md` | `~/.claude/templates/workflow-automation.md` |
| use-to-evolve-snippet.md | `…/templates/use-to-evolve-snippet.md` | `templates/use-to-evolve-snippet.md` | `~/.claude/templates/use-to-evolve-snippet.md` |
| rubrics.md | `…/eval/rubrics.md` | `eval/rubrics.md` | `~/.claude/eval/rubrics.md` |
| benchmarks.md | `…/eval/benchmarks.md` | `eval/benchmarks.md` | `~/.claude/eval/benchmarks.md` |
| strategies.md | `…/optimize/strategies.md` | `optimize/strategies.md` | `~/.claude/optimize/strategies.md` |
| anti-patterns.md | `…/optimize/anti-patterns.md` | `optimize/anti-patterns.md` | `~/.claude/optimize/anti-patterns.md` |

`…` expands to `https://raw.githubusercontent.com/theneoai/skill-writer/main`

Create each destination directory as needed. Skip any file that cannot be fetched/read.

### Step 5 — Print summary

```
Installing Skill Writer v2.1.0...

✓ [claude]   ~/.claude/skills/skill-writer.md
✓ [claude]   companion files → ~/.claude/{refs,templates,eval,optimize}/
✓ [opencode] ~/.config/opencode/skills/skill-writer.md
...

Installed to N platform(s). Restart each platform to activate Skill Writer.
```

---

## §4  All Remote URLs (reference)

### Pre-built Platform Files (Recommended)

These files are self-contained and ready to use:

```
# OpenCode
https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-opencode-dev.md

# OpenClaw
https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-openclaw-dev.md

# Cursor
https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-cursor-dev.md

# Gemini
https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-gemini-dev.md

# OpenAI (JSON format)
https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-openai-dev.json
```

### Source Files (Claude only - requires companion files)

```
# Main skill (for Claude)
https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md

# refs/
https://raw.githubusercontent.com/theneoai/skill-writer/main/refs/use-to-evolve.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/refs/evolution.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/refs/self-review.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/refs/convergence.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/refs/security-patterns.md

# templates/
https://raw.githubusercontent.com/theneoai/skill-writer/main/templates/base.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/templates/api-integration.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/templates/data-pipeline.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/templates/workflow-automation.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/templates/use-to-evolve-snippet.md

# eval/
https://raw.githubusercontent.com/theneoai/skill-writer/main/eval/rubrics.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/eval/benchmarks.md


# optimize/
https://raw.githubusercontent.com/theneoai/skill-writer/main/optimize/strategies.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/optimize/anti-patterns.md
```

---

## §5  OpenAI — Manual Installation

OpenAI does not support a local skills directory. Tell the user:

> Upload `skill-framework.md` as a custom instruction or system prompt
> in your OpenAI project or assistant settings.

---

## §6  User Commands

```
# Via URL (works from any machine)
read https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md and install
read https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md and install to claude

# From local clone
read install.md and install
read install.md and install to opencode

# Chinese
读取 https://raw.githubusercontent.com/theneoai/skill-writer/main/install.md 并安装
读取 install.md 并安装到 cursor
```

### Quick Install (One-liners)

**OpenCode:**
```bash
curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-opencode-dev.md -o ~/.config/opencode/skills/skill-writer.md
```

**OpenClaw:**
```bash
curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-openclaw-dev.md -o ~/.openclaw/skills/skill-writer.md
```

**Cursor:**
```bash
curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-cursor-dev.md -o ~/.cursor/skills/skill-writer.md
```

**Gemini:**
```bash
curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/platforms/skill-writer-gemini-dev.md -o ~/.gemini/skills/skill-writer.md
```

**Claude** (requires companion files, see §4):
```bash
curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md -o ~/.claude/skills/skill-writer.md
# Then copy companion files from refs/, templates/, eval/, optimize/
```

---

## §7  Verification

After installation, ask your agent:

```
"Are you skill-writer? What version?"
```

Expected: agent confirms skill-writer v2.1.0 and lists available modes (CREATE / LEAN / EVALUATE / OPTIMIZE / INSTALL).
