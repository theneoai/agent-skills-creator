<!-- Extracted from claude/skill-writer.md §3 — full reference -->

## §3  Mode Router

**How it works**: Paste any natural-language request — the AI auto-detects the mode from keywords.
You never need to type slash commands.

| If your request mentions... | Mode triggered | Time |
|-----------------------------|---------------|------|
| create / build / new / 新建 + skill | CREATE | ~5 min (9 phases) |
| lean / quick check / 快评 | LEAN | <5 s |
| evaluate / score / 评测 | EVALUATE | ~60 s |
| optimize / improve / 优化 | OPTIMIZE | ~2 min/round |
| install skill-writer / 安装 | INSTALL | ~30 s |
| share / publish / 发布 | SHARE | ~30 s |
| collect session / 采集 | COLLECT | ~2 min |
| graph view / dependencies / 技能图 | GRAPH | ~30 s |

> **Ambiguous input?** The router shows a 3-option menu. You pick.
> **ZH input?** All modes work in Chinese — keywords above accept Chinese equivalents.


> **Cursor users — read this first**: Cursor's IDE command palette intercepts `/` key presses.
> Do NOT type `/create`, `/lean`, `/eval`, etc. — they will open the IDE command palette,
> not the skill framework. Instead, use **keyword phrases only**:
> `create a skill that …` | `lean eval` | `evaluate this skill` | `optimize this skill`
> See the Platform Feature Matrix in README.md for the full keyword mapping table.

### Priority 0 — Explicit Slash Commands `[CORE — evaluated first, skip keyword scoring]`

When a message begins with a slash command, route immediately without keyword scoring.
No confirmation needed. These commands are LLM-evaluated (not platform CLI commands).

| Slash Command | Routes to | Chinese Equivalent |
|--------------|-----------|-------------------|
| `/create` | CREATE mode | `/创建` |
| `/lean` | LEAN mode | `/快评` |
| `/eval` or `/evaluate` | EVALUATE mode | `/评测` |
| `/opt` or `/optimize` | OPTIMIZE mode | `/优化` |
| `/install` | INSTALL mode (deploy framework to platforms) | `/安装` |
| `/share` | SHARE mode (export + package your created skill) | `/分享` |
| `/collect` | COLLECT mode | `/采集` |
| `/aggregate` | AGGREGATE mode (multi-session synthesis) | `/聚合` |
| `/graph` | GRAPH mode (skill graph view, health, bundle planning) | `/技能图` |
| `/skip` | Accept current result as-is (TEMP_CERT if below BRONZE) | `/跳过` |
| `/deprecate` | Mark skill as deprecated; check dependents; update lifecycle_status | `/废弃` |

> `/skip` is only meaningful when the framework has displayed a "type /skip" prompt
> (e.g., LEAN UNCERTAIN escalation, OPTIMIZE early exit). It does not trigger a mode
> route — it signals "accept and stop" for the currently running operation.

> **Note**: These slash commands are evaluated by the LLM processing this skill prompt,
> not by the platform's native command system.
>
> **Platform-specific command support**:
> | Platform | `/command` syntax | Keyword fallback |
> |----------|-------------------|-----------------|
> | Claude, OpenCode, OpenClaw, Gemini | ✅ Supported | ✅ Also works |
> | **Cursor** | ⚠️ May be intercepted by IDE command palette | ✅ Use keywords only |
> | OpenAI, MCP | — Not applicable | ✅ Use keywords only |
>
> **Cursor users**: If `/create` opens a command palette instead of triggering the skill,
> always use the keyword form: `create a skill`, `lean eval`, `evaluate`, `optimize`.

### Priority 1 — Keyword Routing

```
User Input
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ PARSE: extract keywords, detect language (ZH / EN / mixed)      │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ ROUTE                                                           │
│                                                                 │
│ CREATE   [创建,新建,开发,生成,构建,制作 | create,build,make,     │
│           generate,scaffold,develop,add,new]                    │
│ LEAN     [快评,速测,粗评 | lean,quick-eval,fast-check,triage]   │
│ EVALUATE [评测,评估,评分,验证,测试,审查 | evaluate,test,score,   │
│           assess,validate,benchmark,check,review]               │
│ OPTIMIZE [优化,改进,提升,调优,完善,增强 | optimize,improve,      │
│           enhance,tune,refine,upgrade,evolve]                   │
│ INSTALL  [安装,部署,读取安装 | install.*skill-writer,            │
│           read.*install,fetch.*install,setup,deploy,           │
│           install skill-writer]                                 │
│           ⚠ "install MY skill" or "install THIS skill"         │
│             → SHARE (not INSTALL) — see routing note below     │
│ SHARE    [分享,发布,推送,导出技能,安装我的技能 |                  │
│           share,push.*skill,export.*skill,publish.*skill,      │
│           distribute,install.*my.*skill,install.*this.*skill,  │
│           deploy.*my.*skill]                                    │
│ COLLECT  [采集,记录,收集,会话数据 | collect,record,artifact,    │
│           session-data,session-artifact,export.*log]            │
│ AGGREGATE[聚合,分析,综合,汇总,聚合反馈 |                        │
│           aggregate,analyze.*sessions,synthesize.*session,      │
│           aggregate.*feedback,which.*skill.*optimize]           │
│ GRAPH    [技能图,依赖图,包规划,技能关系 |                         │
│           skill.*graph,graph.*view,graph.*check,graph.*plan,    │
│           graph.*bundle,bundle.*plan,skill.*depend.*,           │
│           /graph view,/graph check,/graph plan,/graph bundle]   │
│                                                                 │
│ confidence HIGH   → AUTO-ROUTE (no confirmation)                │
│ confidence MEDIUM → show "I'll run [MODE] — confirm? (yes/no)"  │
│ confidence LOW    → show mode menu (see below)                  │
└─────────────────────────────────────────────────────────────────┘
```

**INSTALL vs. SHARE disambiguation** (apply before keyword routing):
```
IF input matches: "install my skill" | "install this skill" | "deploy my skill"
                  "install [specific-skill-name].md" (not "skill-writer")
    → Route to SHARE mode (user wants to package/deploy their own skill)
IF input matches: "install skill-writer" | "install to claude" | "read [URL] and install"
    → Route to INSTALL mode (user wants to deploy the framework to a platform)
```

**Supported languages for keyword routing**:
```
EN (English):  full support — all keyword sets
ZH (Chinese):  full support — all keyword sets
Other languages: type English or Chinese keywords, or use /slash commands
  (Korean, Japanese, etc.: type "create a skill" or "/create")
```

**Low confidence mode menu** (show when no clear keyword and no context clue):
```
Not sure which mode to use. Please choose:

  1. /create  — Build a new skill from scratch
               I'll ask you 8 questions about what the skill should do, then generate it.
               Best for: "I want a skill that does X"
               Time: 2–5 min

  2. /lean    — Quick quality check on an existing skill (5 seconds)
               Runs 16 structural checks. Tells you if the skill is well-formed.
               Best for: After writing a draft, before running full eval
               Time: ~5s

  3. /eval    — Full quality evaluation with certification score (60 seconds)
               4-phase pipeline, 1000 pts. Gives you PLATINUM/GOLD/SILVER/BRONZE/FAIL.
               Best for: Before sharing or publishing a skill
               Time: ~60s

  4. /opt     — Improve a skill through up to 20 rounds of targeted iteration
               Focuses on your weakest dimension first, with rollback protection.
               Best for: Skill stuck at BRONZE; want to reach SILVER or higher
               Time: 5–20 min

  5. /install — Install skill-writer itself to one or more AI platforms
               Not for your skills — this installs the skill-writer framework.
               Best for: First-time setup or adding a new platform
               Time: <30s

  6. /share   — Package your created skill to share with your team or publish
               Validates quality threshold, stamps metadata, outputs a ready-to-share file.
               Best for: After creating and evaluating a skill
               Time: ~30s

  7. /collect — Record this session as a structured improvement artifact
               Outputs JSON you can save and later feed to /aggregate for evidence-based /opt.
               Best for: After an important skill invocation or when a trigger missed
               Time: ~10s

Type a number, the /command, or describe what you want to do in plain language.
(Cursor/IDE users: type the number or keyword phrase — IDE intercepts /commands)
```

**Routing Decision Tree** `[CORE — apply in order, stop at first match]`:

```
Step 1 — Primary keyword match (most important signal):
  Does the input contain a clear mode keyword from the ROUTE table above?
  YES → confidence = HIGH
  NO  → continue to Step 2

Step 2 — Context clues:
  Does the surrounding context (prior conversation, file shared) imply a mode?
  e.g. user shares a skill.md file + asks to "check it" → EVALUATE implied
  YES → confidence = MEDIUM
  NO  → continue to Step 3

Step 3 — Negative signals:
  Does the input explicitly exclude a mode?
  e.g. "don't evaluate, just create" → EVALUATE blocked
  YES (exclusion found) → remove that mode from candidates; re-evaluate
  NO  → continue to Step 4

Step 4 — Language weight:
  EN input: EN keywords count 1.0×, ZH keywords count 0.3×
  ZH input: ZH keywords count 1.0×, EN keywords count 0.3×
  Mixed:    both count 1.0×

Decision:
  HIGH   (clear keyword match, no ambiguity)      → AUTO-ROUTE (no confirmation)
  MEDIUM (context clue but no direct keyword)     → "I'll run [MODE] — confirm? (yes/no)"
  LOW    (no keyword, weak context, or conflict)  → Show mode menu (Priority 1 above)

Tie-break rule: If two modes score equally, ask the user one clarifying question.
```

---

