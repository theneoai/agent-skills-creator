<!-- Extracted from claude/skill-writer.md §17 — full reference -->

## §17  INSTALL Mode

Installs skill-writer (this framework) to one or all supported platforms by fetching
from a URL or using local files.  No evaluation or generation — pure deployment.

### Platform Path Map

| Platform | Install Path | Output Format | Companion Files |
|----------|-------------|---------------|-----------------|
| claude   | `~/.claude/skills/skill-writer.md` | Markdown + YAML frontmatter | refs/, templates/, eval/, optimize/ |
| opencode | `~/.config/opencode/skills/skill-writer.md` | Markdown + YAML frontmatter | — |
| openclaw | `~/.openclaw/skills/skill-writer.md` | AgentSkills Markdown | — |
| cursor   | `~/.cursor/skills/skill-writer.md` | Markdown (no frontmatter) | — |
| gemini   | `~/.gemini/skills/skill-writer.md` | Markdown + YAML frontmatter | — |
| openai   | see platform docs | JSON | — |
| **mcp**  | `~/.mcp/servers/skill-writer/mcp-manifest.json` | MCP JSON Manifest | — |
| **all**  | all of the above | platform-specific | — |

### Install Options (from Fastest to Most Control)

**Option A — curl one-liner (no git clone required)**
Auto-detects installed platforms and installs to all of them:
```bash
curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/install.sh | bash
# Specific platform:
curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/install.sh | bash -s -- --platform claude
# All platforms:
curl -fsSL https://raw.githubusercontent.com/theneoai/skill-writer/main/install.sh | bash -s -- --all
```

**Option B — Agent install (paste into AI agent)**
```
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer.md and install
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-claude.md and install to claude
```

**Option C — Shell script (from git clone)**
```bash
git clone https://github.com/theneoai/skill-writer.git && cd skill-writer
./install.sh              # auto-detect + install
./install.sh --all        # all 8 platforms
./install.sh --platform claude
```

**`--bundle` flag** (deploy a GoS skill bundle instead of the framework itself):
```
/install --bundle          → install all skills in the active graph plan resolution
/install --bundle api-tester  → install skill + its full dependency tree
```
> Use `--bundle` after `/graph plan` resolves a task's required skill set.
> The install proceeds in topological order (deepest deps first).
> See §20 GRAPH mode for bundle planning workflow.

**Option D — Manual copy**
Pre-built files are committed in `platforms/`; copy the right one to your platform's skills directory.

### Trigger Patterns

```
"read <URL> and install"           → fetch URL, install to all platforms
"read <URL> and install to claude" → fetch URL, install to named platform only
"install skill-writer"             → install from local clone (all platforms)
"install skill-writer to cursor"   → install from local clone (single platform)
"安装 skill-writer"                → install to all platforms
"从 <URL> 安装"                    → fetch URL, install to all platforms
```

URL examples:
- `https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-claude.md`
- `https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md`
- Any raw URL returning a valid skill-writer markdown file

### Installation Workflow

```
1. PARSE_INPUT
   - Extract URL (if present) and target platform(s)
   - target = explicit platform OR "all"

2. FETCH (if URL provided)
   - Fetch content from URL
   - Verify it contains YAML frontmatter with name: skill-writer
   - If verification fails → ABORT with message

2b. SHA-256 VERIFY (external skills) `[CORE]`
    IF skill came from an external URL (not local clone):
      - Compute SHA-256 of fetched content
      - IF skill YAML frontmatter contains use_to_evolve.content_hash:
          Compare computed SHA-256 with content_hash
          IF mismatch → ABORT: "Content hash mismatch — skill may have been tampered in transit"
          Ask user: "Trust and install anyway? (yes/no)"
          On "no" → ABORT
      - ELSE:
          Embed computed SHA-256 into use_to_evolve.content_hash before install
          Log: ✓ SHA-256 computed and embedded

2a. RESOLVE DEPENDENCIES (v3.2.0 — GoS dependency resolution) `[CORE]`
    IF skill has graph.depends_on entries in its YAML frontmatter:
      - Parse graph.depends_on list
      - For each dependency: check if skill_id is in registry
      - Recursively resolve transitive deps (DFS, max depth 6, cycle-safe)
      - Show dependency manifest:
        Installing: <skill-name> v<version>
        Dependencies:
          ✓ <dep-name> v<ver>  (already installed)
          ⚠ <dep-name> v<ver>  (will install — in registry)
          ✗ <dep-name> v<ver>  (not in registry — manual install required)
      - If any required dep is ✗ → WARN but do not ABORT (soft dependency resolution)
    ELSE:
      → Skip dependency resolution (no graph block or no depends_on)

3. CONFIRM
   - Show: source (URL or local), target platforms, install paths, dependency manifest
   - Ask: "Proceed with installation? (yes/no)"
   - On "no" → ABORT gracefully

4. INSTALL (in topological order — deps first, then target skill)
   FOR EACH skill in dependency tree (topological sort):
     a. mkdir -p <install_path_dir>
     b. Write skill content to <install_path>
     c. IF platform == claude AND local clone available:
          Copy companion files (refs/, templates/, eval/, optimize/)
          to ~/.claude/{refs,templates,eval,optimize}/
     d. Log: ✓ <install_path>

4e. GENERATE AGENTS.md ROUTING RULES `[CORE]`
    After writing all skill files, generate or update the platform's agent
    context file with skill-routing rules. This implements the "always-present
    context" layer that makes skills reliably triggerable without relying on
    trigger-phrase matching alone.

    Target files by platform:
      claude   → ~/.claude/CLAUDE.md          (append/update skill-writer block)
      opencode → ~/.config/opencode/AGENTS.md (append/update skill-writer block)
      cursor   → ~/.cursor/rules/skill-writer.mdc (create/overwrite)
      gemini   → ~/.gemini/GEMINI.md          (append/update skill-writer block)
      openclaw → ~/.openclaw/AGENTS.md        (append/update skill-writer block)

    Content template (insert between <!-- skill-writer:start --> markers):
    ```
    <!-- skill-writer:start -->
    ## Skill Registry — Active Skills

    Installed skills are indexed at: <install_path_dir>/registry.json
    Before creating any reusable component, function, or workflow, check:
      → Run: /share (or type "find skill <query>") to search installed skills
      → Prefer existing GOLD/SILVER skills over writing from scratch

    ## Skill-Writer Framework Rules

    When the user asks to create, evaluate, optimize, or install a skill:
      → Load: <install_path> (skill-writer framework)
      → Do NOT generate ad-hoc skill definitions — always use the framework

    Skill trigger routing (checked before responding to user):
      create/build/make a skill  → skill-writer CREATE mode
      evaluate/score/assess      → skill-writer EVALUATE or LEAN mode
      optimize/improve a skill   → skill-writer OPTIMIZE mode
      install skill-writer       → skill-writer INSTALL mode
    <!-- skill-writer:end -->
    ```

    Merge strategy:
      IF <!-- skill-writer:start --> already exists in target file:
        → Replace the block between the markers (idempotent update)
      ELSE:
        → Append block to end of file (or create file if absent)

    Platform-specific notes:
      Cursor: write as `.mdc` (Markdown with YAML frontmatter):
        ---
        description: Skill-Writer routing rules
        alwaysApply: true
        ---
        <block content without markers>

4f. GENERATE HOOK INJECTION CONFIG `[CORE for Claude/OpenCode; EXTENDED for others]`
    Hooks fire at the UserPromptSubmit event — before the LLM processes the user
    message. This is the most reliable routing layer: it injects skill-awareness
    context even when the user's phrasing doesn't match any trigger keyword.

    Target: ~/.claude/settings.json  (Claude platform only in v3.2.0)

    Hook block to merge into settings.json:
    ```json
    {
      "hooks": {
        "UserPromptSubmit": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "echo '[skill-writer] Check registry before creating new components: run /share to search installed skills.'"
              }
            ]
          }
        ]
      }
    }
    ```

    Merge strategy for settings.json:
      IF hooks.UserPromptSubmit already exists:
        → Check if skill-writer hook is present (match on command string)
        → IF absent: append to hooks.UserPromptSubmit array
        → IF present: skip (idempotent)
      ELSE:
        → Add hooks.UserPromptSubmit array with the block above

    Safety note: only append to existing hooks — NEVER overwrite or delete
    existing hook entries. If settings.json does not exist, create it with
    only the hooks key.

    Skip this step and report "Hook injection: skipped" if:
      - Platform is not Claude or OpenCode (other platforms lack hook support)
      - User explicitly passed --no-hook flag
      - File system write permission is denied

5. REPORT
   ✓ Installed to N platform(s):
     • <platform>: <install_path>
   ✓ AGENTS.md routing rules: <agents_path> (created / updated)
   ✓ Dependencies installed: <dep1>, <dep2> (if any)
   ⚠ Manual action required: <dep3> not in registry — install separately
   ℹ Restart <platform> to activate skill-writer.
   ℹ Companion files (refs/, eval/, templates/, optimize/) copied for Claude.
   ℹ AGENTS.md ensures skills are triggered reliably without relying on
     trigger-phrase matching alone (AGENTS.md > Hook > Skill three-layer model).
```

### How to Share / Export Your Skill

> **Note**: INSTALL mode deploys the *skill-writer framework* to platforms. To share a skill
> **you created**, use one of the export methods below.

**Trigger phrases** (route to skill export workflow, not framework install):
```
"share this skill"          → package + export + show registry instructions
"push this skill"           → same as "share"
"export this skill"         → output packaged skill file only (no instructions)
"分享这个技能"               → same as "share this skill" in Chinese
"发布技能"                   → publish skill
```

**Export workflow** (triggered by above phrases):
```
1. VALIDATE  — confirm skill has passed LEAN ≥ 350 (LEAN_CERT minimum)
2. PACKAGE   — output: YAML frontmatter + full skill body as single .md file
               Name: {skill_name}-v{version}.md
3. STAMP     — compute SHA-256 of skill content; embed as use_to_evolve.content_hash
4. DELIVER   — output the packaged file to conversation
5. GUIDE     — show tier status + sharing options:

       ─── Registry Push Eligibility ────────────────────────────
       Skill tier: {TIER}  |  Score: {EVALUATE_SCORE}/1000
       (If only LEAN score available: LEAN {N} × 2 ≈ {N*2} estimated)
       Push status: {RECOMMENDED | ALLOWED as beta | ALLOWED as experimental | BLOCKED}
       To confirm tier before pushing: run /eval
       ──────────────────────────────────────────────────────────

       Sharing options:
       (a) Direct install: copy {skill_name}-v{version}.md to
           ~/.claude/skills/  (or platform skills dir) → restart platform
       (b) Team share via Agent Install: paste to GitHub Gist, then share:
           "read [your-gist-url] and install to claude"
           → Team members paste that one line and the skill installs automatically
       (c) Future registry: [registry URL TBD — v3.2.0 milestone]
           Registry push tag: {stable | beta | experimental} (based on tier)

       ─── Team Deployment Checklist ──────────────────────────────
       □ LEAN score ≥ 350 (BRONZE minimum) — confirmed above
       □ Negative Boundaries section has ≥ 3 specific anti-cases
         (not just "avoid irreversible actions" generic placeholder)
       □ Security scan: no P0/P1 violations
       □ Trigger phrases tested with at least one team member
       □ Platform paths confirmed:
           Claude:    ~/.claude/skills/{skill_name}.md
           OpenCode:  ~/.config/opencode/skills/{skill_name}.md
           Cursor:    ~/.cursor/skills/{skill_name}.md
       □ Team members know to restart assistant after install
       □ Gist URL or skill file link shared in team channel/wiki
       □ Version number in YAML frontmatter reflects current state
         (bump version: "1.1.0" when making significant updates)
       ────────────────────────────────────────────────────────────
```

### Registry Push Policy

Before pushing a skill to the shared registry, use the following tier thresholds to
determine the appropriate tag and whether to proceed:

| Tier | Score | Push | Tag |
|------|-------|------|-----|
| **PLATINUM** | ≥ 950 | Recommended | `stable` |
| **GOLD** | ≥ 900 | Recommended | `stable` |
| **SILVER** | ≥ 800 | Allowed | `beta` |
| **BRONZE** | ≥ 700 | Allowed | `experimental` |
| **FAIL** | < 700 | **Blocked** — fix first | — |

> **These thresholds are for EVALUATE (1000-pt) scores.** If you only have a LEAN score
> from OPTIMIZE, multiply by 2 to estimate: LEAN 375 → estimated ~750 → SILVER tier.
> This is an estimate (±60 pt variance). Use `/eval` for an authoritative score before
> pushing, especially if your estimated tier is within ±30 pts of a tier boundary.

### Enterprise / Team Access Control

For teams deploying skills to shared infrastructure (CI/CD, MCP servers, internal registries):

**Approval gates** — add these checks before any registry push or team-wide deploy:

```
IF skill.tier == FAIL (<700):
  → BLOCK push; output: "Skill blocked from team registry — score {N}/1000 < 700 minimum.
     Run /eval to diagnose, then /opt to improve before re-attempting."

IF skill.tier == BRONZE (700–799):
  → WARN: "Experimental tier — team lead approval recommended before deploy."
  → Output skill with tag: experimental
  → Proceed only on explicit confirmation: "I confirm experimental deploy"

IF skill.tier >= SILVER (≥800):
  → Allow push with tag: beta (SILVER) or stable (GOLD/PLATINUM)
```

**Team governance checklist** (append to DELIVER output when team context detected):
```
Team Deploy Checklist:
  □ EVALUATE score ≥ 700 (required) — current: {N}/1000
  □ Negative Boundaries reviewed by a second team member
  □ Security scan shows no P0/P1 violations
  □ Skill committed to version control (not only local files)
  □ Install path documented in team runbook
  □ Rollback plan: previous version skill file retained as skill-v{prev}.md
```

**Security note for shared MCP deployments**: The MCP manifest (`mcp-manifest.json`) runs
server-side. Review `ASI02` (insecure tool use) and `ASI03` (excessive agency) flags before
adding to a shared server. Minimum required: SILVER certification + P1-clean security scan.

### Error Handling

| Error | Action |
|-------|--------|
| URL unreachable | Report network error, offer local-clone fallback |
| YAML name mismatch | ABORT — file is not skill-writer |
| Directory write failure | Report path + permission error |
| Platform not detected | Install anyway; warn path may not be active |

### Example Interactions

```
User: "read https://raw.githubusercontent.com/theneoai/skill-writer/main/skill-framework.md and install"
→ Fetch from URL ✓
→ Confirm: install to all 5 local platforms? yes
→ ✓ ~/.claude/skills/skill-writer.md
→ ✓ ~/.config/opencode/skills/skill-writer.md
→ ✓ ~/.openclaw/skills/skill-writer.md
→ ✓ ~/.cursor/skills/skill-writer.md
→ ✓ ~/.gemini/skills/skill-writer.md
→ Installed to 5 platforms. Restart each to activate.
```

```
User: "read https://raw.githubusercontent.com/.../skill-framework.md and install to claude"
→ Fetch from URL ✓
→ Confirm: install to claude only? yes
→ ✓ ~/.claude/skills/skill-writer.md  + companion files
→ Installed to 1 platform. Restart Claude to activate.
```

---

## §17b  MCP Integration Guide

> MCP (Model Context Protocol) requires structured JSON calls instead of chat keywords.
> **Full spec**: `experimental/mcp-integration.md`

**Quick install**:
```bash
./install.sh --platform mcp
```

**Quick test** (confirms MCP is working):
```json
{"tool": "skill-writer", "mode": "lean", "input": "a skill that returns json"}
```

**Key difference from chat platforms**: MCP is stateless — all 8 elicitation answers must be
provided in a single call (`elicitation_answers` field). UTE auto-trigger does not fire;
call explicitly from your application. Full protocol: `experimental/mcp-integration.md §3`.

---

