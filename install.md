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

### Step 1 — Get the main skill file

**If you read this file from a URL:**
```
Fetch: https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md
Store content as: SKILL_CONTENT
```

**If you read this file from a local path:**
```
Read: skill-framework.md  (same directory as this file)
Store content as: SKILL_CONTENT
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
| deliberation.md | `…/refs/deliberation.md` | `refs/deliberation.md` | `~/.claude/refs/deliberation.md` |
| convergence.md | `…/refs/convergence.md` | `refs/convergence.md` | `~/.claude/refs/convergence.md` |
| security-patterns.md | `…/refs/security-patterns.md` | `refs/security-patterns.md` | `~/.claude/refs/security-patterns.md` |
| base.md | `…/templates/base.md` | `templates/base.md` | `~/.claude/templates/base.md` |
| api-integration.md | `…/templates/api-integration.md` | `templates/api-integration.md` | `~/.claude/templates/api-integration.md` |
| data-pipeline.md | `…/templates/data-pipeline.md` | `templates/data-pipeline.md` | `~/.claude/templates/data-pipeline.md` |
| workflow-automation.md | `…/templates/workflow-automation.md` | `templates/workflow-automation.md` | `~/.claude/templates/workflow-automation.md` |
| use-to-evolve-snippet.md | `…/templates/use-to-evolve-snippet.md` | `templates/use-to-evolve-snippet.md` | `~/.claude/templates/use-to-evolve-snippet.md` |
| rubrics.md | `…/eval/rubrics.md` | `eval/rubrics.md` | `~/.claude/eval/rubrics.md` |
| benchmarks.md | `…/eval/benchmarks.md` | `eval/benchmarks.md` | `~/.claude/eval/benchmarks.md` |
| pairwise.md | `…/eval/pairwise.md` | `eval/pairwise.md` | `~/.claude/eval/pairwise.md` |
| strategies.md | `…/optimize/strategies.md` | `optimize/strategies.md` | `~/.claude/optimize/strategies.md` |
| anti-patterns.md | `…/optimize/anti-patterns.md` | `optimize/anti-patterns.md` | `~/.claude/optimize/anti-patterns.md` |

`…` expands to `https://raw.githubusercontent.com/theneoai/skill-writer/main`

Create each destination directory as needed. Skip any file that cannot be fetched/read.

### Step 5 — Print summary

```
Installing Skill Writer v2.0.0...

✓ [claude]   ~/.claude/skills/skill-writer.md
✓ [claude]   companion files → ~/.claude/{refs,templates,eval,optimize}/
✓ [opencode] ~/.config/opencode/skills/skill-writer.md
...

Installed to N platform(s). Restart each platform to activate Skill Writer.
```

---

## §4  All Remote URLs (reference)

```
# Main skill
https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md

# refs/
https://raw.githubusercontent.com/theneoai/skill-writer/main/refs/use-to-evolve.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/refs/evolution.md
https://raw.githubusercontent.com/theneoai/skill-writer/main/refs/deliberation.md
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
https://raw.githubusercontent.com/theneoai/skill-writer/main/eval/pairwise.md

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

---

## §7  Verification

After installation, ask your agent:

```
"Are you skill-writer? What version?"
```

Expected: agent confirms skill-writer v2.0.0 and lists available modes (CREATE / LEAN / EVALUATE / OPTIMIZE / INSTALL).
