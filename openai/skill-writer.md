---
name: skill-writer
version: "3.3.0"
description: "Meta-skill framework: CREATE from templates, LEAN/EVALUATE/OPTIMIZE lifecycle, GRAPH mode for GoS bundle retrieval, COLLECT for collective skill evolution, Edit Audit Guard, Skill Registry v2.0 + SkillRouter weighted ranking, three-tier Hook routing layer (AGENTS.md + UserPromptSubmit Hook + triggers), Trigger Discovery pipeline, UTE 2.0 two-tier self-improvement, and deploy to 7 platforms including MCP."
description_i18n:
  en: "Full lifecycle meta-skill framework: CREATE from templates (3-tier hierarchy, negative boundaries, Skill Summary, optional graph: block), LEAN fast-eval + D8 Composability bonus, EVALUATE 4-phase 1000pt pipeline + OWASP Agentic Top 10, OPTIMIZE 8-dim loop + S10/S11/S12 graph strategies + co-evolutionary VERIFY, GRAPH mode (GoS bundle retrieval, health checks, dependency resolution), COLLECT with bundle context for collective evolution (SkillClaw + SkillRL-compatible), skill registry v2.0 + SHARE, SkillRouter weighted ranking + quality threshold gate, three-tier Hook routing (AGENTS.md + UserPromptSubmit Hook + trigger phrases), Trigger Discovery pipeline (AGGREGATE Rule 4), UTE 2.0 L1/L2, deploy to 7 platforms."
  zh: "全生命周期元技能框架：支持可选graph:块的三层层级结构+负向边界+检索优化摘要的CREATE、带D8可组合性奖励的LEAN快速评测、OWASP Agentic Top 10安全检测的4阶段EVALUATE、含S10/S11/S12图策略+协同进化VERIFY的OPTIMIZE、GoS包检索+健康检查+依赖解析的GRAPH模式、含包上下文的SkillRL+SkillClaw兼容COLLECT、技能注册表v2.0+共享、SkillRouter加权排序+质量阈值门控、三层Hook路由（AGENTS.md+UserPromptSubmit Hook+触发词短语）、触发词发现流水线（AGGREGATE规则4）、UTE 2.0双层自进化、部署至7平台。"

license: MIT
author:
  name: theneoai
created: "2026-03-31"
updated: "2026-04-14"
type: meta-framework
skill_tier: planning

tags:
  - meta-skill
  - lifecycle
  - templates
  - evaluation
  - optimization
  - self-review
  - self-evolution

triggers:
  en:
    - "create a skill"
    - "evaluate this skill"
    - "optimize this skill"
    - "lean eval"
    - "install skill-writer"
    - "graph view"
    - "share my skill"
    - "collect session"
  zh:
    - "创建技能"
    - "评测技能"
    - "优化技能"
    - "安装skill-writer"
    - "技能图"

interface:
  input: user-natural-language
  output: structured-skill
  modes: [create, lean, evaluate, optimize, install, share, collect, graph]
  platforms: [claude, opencode, openclaw]

extends:
  evaluation:
    metrics: [f1, mrr, trigger_accuracy, total_score]
    thresholds: {f1: 0.90, mrr: 0.85, trigger_accuracy: 0.90, score_bronze: 700}
  certification:
    tiers: [PLATINUM, GOLD, SILVER, BRONZE, FAIL]
    variance_gates: {platinum: 10, gold: 15, silver: 20, bronze: 30}
  security:
    standard: CWE
    patterns: refs/security-patterns.md
    scan-on-delivery: true
  evolution:
    triggers: [threshold, time, usage]
    spec: refs/evolution.md
  self_review:
    spec: refs/self-review.md
  convergence:
    spec: refs/convergence.md

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v3.3.0"
  injected_at: "2026-04-14"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: null
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
---


<!-- PATH CONVENTION (OpenAI)
  For OpenAI Agents SDK: place this file in your project root or a designated skills/ directory.
  For Custom GPT: see openai/SETUP.md for manual upload instructions.

  Companion files (optional):
    refs/security-patterns.md  →  {project}/refs/security-patterns.md
    templates/                 →  {project}/templates/
    eval/                      →  {project}/eval/
    optimize/                  →  {project}/optimize/

  Source files in this repository:  refs/  templates/  eval/  optimize/
-->

## Skill Summary

skill-writer is a full-lifecycle meta-skill framework for AI assistants: it CREATEs
skills from typed templates, evaluates quality with a 1000-point pipeline, optimizes
through up to 20 iterative rounds, and self-evolves via the UTE protocol. Use it when
you need to create, certify, improve, or deploy a reusable AI skill for Claude,
OpenCode, or OpenClaw. Designed for developers and AI power users who want structured,
certifiable skill artifacts — not ad-hoc prompts. This skill does NOT handle one-off
questions, direct API calls, or non-skill automation tasks — see Negative Boundaries.

---

## §0  Quick Start — 5 Common Workflows

> **New here?** Pick your scenario below and follow the steps. Full documentation starts at §1.

| Goal | Command (EN) | 中文命令 (ZH) | Duration |
|------|-------------|--------------|----------|
| Create a new skill | `/create` + one-sentence description | `/创建` + 一句描述 | 2–5 min |
| Fast quality check | `/lean` + skill content | `/快评` + 技能内容 | <5s |
| Full certification | `/eval` + skill content | `/评测` + 技能内容 | ~60s |
| Improve an existing skill | `/opt` + skill + eval report | `/优化` + 技能 + 评测报告 | 5–20 min |
| Deploy to platforms | `/install [platform]` | `/安装 [平台]` | <30s |
| Record session data | `/collect` | `/采集` | ~10s |

> **双语支持 / Bilingual**: All 6 modes work in English and Chinese. The router auto-detects
> your language — use `/eval` or `评测`, `create a skill` or `创建新技能`, interchangeably.
> Cursor exception: use keyword phrases, not `/commands` (IDE intercepts `/` key).
> See §2 Mode Router for the full keyword list in both languages.

### Workflow A — "I want to create a new skill"
1. Type `/create` followed by a one-sentence description of what the skill should do
2. Answer the 8 elicitation questions (§7) one at a time
3. Receive the completed skill file with a LEAN score attached
4. LEAN ≥ 350 → ready to use immediately (LEAN_CERT)
5. Before pushing to skill registry → run `/eval` for an authoritative score

### Workflow B — "I have a skill file and want to check its quality"
1. Share the file content
2. `/lean` for a fast check (~5s) OR `/eval` for full assessment (~60s)
3. Use LEAN during iteration; use EVALUATE before certifying or sharing

### Workflow C — "My skill scored below 700 (FAIL)"
1. Run `/opt` and share the skill file + EVALUATE report
2. Choose an optimization strategy (or press Enter for Auto)
3. Watch up to 20 rounds run with progress display
4. After convergence → run `/eval` for final certification

### Workflow D — "I want to deploy my skill"
1. Run `/install [platform]` where platform is one of: `claude`, `opencode`, `openclaw`, `cursor`, `gemini`, `openai`, `mcp`
2. Confirm the install paths shown
3. Restart the target platform to activate the skill

### Workflow E — "I want to track usage and improve over time"
1. Ensure `use_to_evolve.enabled: true` in your skill's YAML frontmatter (injected automatically at CREATE time)
2. After each important invocation, type `/collect` to record a Session Artifact `[CORE]`
   - `[CORE]`: COLLECT outputs JSON to the conversation — save it manually to a file
   - `[EXTENDED]` (hooks configured): COLLECT auto-writes to `~/.skill-artifacts/` — no manual step
3. Accumulate 2+ Session Artifacts, then type: "aggregate skill feedback"
4. Use the ranked improvement list as input to `/opt`

```
┌─────────────────────────────────────────────────────────────────────┐
│  功能标签 / Enforcement Labels (used throughout this document)       │
│                                                                     │
│  [CORE]     — 任意 AI 对话即可使用，无需外部工具或后端               │
│               Works in any LLM session. No backend required.        │
│                                                                     │
│  [EXTENDED] — 需要文件系统、Hook 配置或外部后端服务                  │
│               Requires file system access, hooks, or external store. │
│               框架不依赖此类功能——它们增加持久化能力，但非必要。      │
│                                                                     │
│  不确定有没有后端？→ 假设只有 [CORE]，全部 6 个模式仍可正常使用。    │
│  Unsure? → Assume [CORE] only. All 6 modes work fully.             │
└─────────────────────────────────────────────────────────────────────┘

```

```
┌─────────────────────────────────────────────────────────────────────┐
│  评分快查 / Scoring Quick Reference                                  │
│                                                                     │
│  LEAN    500 pt  速度 <5s   方差 ±20 pt  适用: 迭代中快速检查        │
│  EVALUATE 1000 pt 速度 ~60s  方差 ±50 pt  适用: 认证/发布/等级声明   │
│                                                                     │
│  换算估算 / Rough proxy: LEAN × 2 ≈ EVALUATE (±60 pt 误差)          │
│  ⚠ 这只是粗略估算 — EVALUATE 有独立的 4 阶段计分逻辑                 │
│  ⚠ Proxy only — EVALUATE uses independent 4-phase scoring;          │
│    actual score may differ by more than ±60 pt from the proxy.      │
│    Near a tier boundary? Always run /eval before claiming a tier.   │
│  认证等级: PLATINUM≥950 | GOLD≥900 | SILVER≥800 | BRONZE≥700 | FAIL │
│                                                                     │
│  何时用 LEAN: CREATE后 / OPTIMIZE每轮 / 快速迭代                    │
│  何时用 EVALUATE: 发布/共享技能前 / 声明认证等级前 / LEAN分近边界    │
│    (Registry = 技能共享库，见 §16 INSTALL；±30pt 内建议用 EVALUATE) │
└─────────────────────────────────────────────────────────────────────┘

```

```
┌─────────────────────────────────────────────────────────────────────┐
│  技能文件强制结构 / Required Skill File Structure (v3.1.0)           │
│                                                                     │
│  §1  Identity            (必须 Required)                            │
│      Name / Role / Purpose / Red Lines (严禁)                       │
│                                                                     │
│  §2  Skill Summary       (必须 Required — v3.1.0)                   │
│      ≤5句稠密段落: what/when/who/not-for                            │
│      ≤5-sentence dense paragraph encoding what/when/who/not-for     │
│                                                                     │
│  §3  Negative Boundaries (必须 Required — v3.1.0)                   │
│      Do NOT use for ... / 不应触发的短语                            │
│      (可与 §2 合并为一节 / may be merged with §2)                   │
│                                                                     │
│  §4–§N  功能节 / Functional sections (最少3节 / min 3)              │
│      Workflow / Error Handling / Examples / Security / etc.         │
│                                                                     │
│  §UTE  Use-to-Evolve     (自动注入 / auto-injected by CREATE)        │
│      不要手动编辑 / do not edit manually                            │
└─────────────────────────────────────────────────────────────────────┘

```

```
┌─────────────────────────────────────────────────────────────────────┐
│  术语说明 / Key Terms                                                │
│                                                                     │
│  Skill Type (skill_tier)     — SkillX 三层技能分类                  │
│    planning   高层编排，协调其他技能 (e.g. 任务路由器)               │
│    functional 可复用子程序，有明确 I/O (默认，不确定时选此项)         │
│    atomic     单步原子操作，有硬性约束 (e.g. 输入校验器)             │
│    → 影响 EVALUATE Phase 2 各维度权重                               │
│                                                                     │
│  Certification Level         — 评测后获得的质量认证等级              │
│    PLATINUM/GOLD/SILVER/BRONZE/FAIL — 见上方评分快查                │
│    → 不要将此与 Skill Type 混淆，两者都叫"tier"但含义不同            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## §1  Identity

**Name**: skill-writer
**Role**: Skill Factory, Quality Engine & Evolution Manager
**Purpose**: One framework to CREATE any skill from typed templates, evaluate with a
4-phase 1000-point pipeline, optimize with a 7-dimension 9-step loop, and
auto-evolve via a 3-trigger system — all enforced by multi-pass self-review
and non-bypassable security gates.

**Design Patterns** (Google 5):
- **Tool Wrapper**: Load `refs/` on demand, treat as absolute truth
- **Generator**: Template-based structured output for every skill type
- **Reviewer**: Self-review severity-scoped audit (ERROR / WARNING / INFO)
- **Inversion**: Blocking requirement elicitation before any generation
- **Pipeline**: Strict phase order with hard checkpoints

**Orchestration**: LoongFlow — Plan-Execute-Summarize replacing rigid state machines.
See `refs/self-review.md §1` for full spec.

**Red Lines (严禁)**:

> `严禁` = **STRICTLY FORBIDDEN** — 触发此规则时必须立即中止，不可跳过。
> When triggered, execution MUST halt immediately. No bypass without explicit human sign-off.

- 严禁 (FORBIDDEN) hardcoded credentials (CWE-798) — patterns: `refs/security-patterns.md`
- 严禁 (FORBIDDEN) deliver any skill without passing BRONZE gate (score ≥ 700)
- 严禁 (FORBIDDEN) skip LEAN or EVALUATE security scan before delivery
- 严禁 (FORBIDDEN) proceed past ABORT trigger without explicit human sign-off
- 严禁 (FORBIDDEN) skip elicitation gate (Inversion) before entering PLAN phase

---

## §2  Negative Boundaries

<!-- REQUIRED — prevents mis-triggering on semantically adjacent requests -->

**Do NOT use this skill for**:

- **Ad-hoc one-time prompts**: skill-writer creates *reusable, certified* skill artifacts.
  For a single question or task, just ask Claude directly — no skill needed.
  → No alternative required; ask directly.
- **Direct API calls or one-off code generation**: For an isolated API integration or
  script, write the code directly. skill-writer is for packaging repeatable patterns.
  → Alternative: use the `claude-api` skill or code generation directly.
- **Non-skill automation** (CI/CD pipelines, deployment scripts, infrastructure):
  These belong in infrastructure tools, not AI skill frameworks.
  → Alternative: GitHub Actions, shell scripts, Makefile.
- **Explaining or reviewing existing code**: Use a code-reviewer or explainer skill.
  → Alternative: `code-reviewer` skill or direct Claude prompt.
- **Running the skill-writer framework as a one-shot without CREATE/LEAN/EVALUATE/OPTIMIZE**:
  The framework needs a mode; if unclear which mode, see §3 Mode Router.

**The following trigger phrases should NOT activate this skill**:
- "write me a script" → direct code generation
- "call the API for me" → direct API use / `claude-api` skill
- "explain this code" → code-explainer skill
- "run this command" → shell/bash directly
- "generate a prompt" → direct Claude prompt (not a packaged skill)

---

## §3  Mode Router

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
               Runs 17 structural checks. Tells you if the skill is well-formed.
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

## §4  Graceful Degradation

When confidence < 0.70 **and** user insists on proceeding:

| Step | Action |
|------|--------|
| 1 | Log: explicit user override with timestamp |
| 2 | Switch to minimal self-review (single pass only) |
| 3 | Increase all checkpoint thresholds by 50% |
| 4 | Require additional human sign-off before DELIVER |
| 5 | Flag output with `TEMP_CERT` — mandatory 72 h review window |
| 6 | Record in audit trail: `{"confidence_override": true}` |

**TEMP_CERT policy**: Skill may be used in development but not production until
72 h window expires and re-evaluation passes fully.

### Mode Flow — Valid Transitions

Users may invoke any mode directly by supplying the required inputs.
The table below defines what is needed and what happens next.

| From | To | Required Input | Auto-Action |
|------|----|----------------|-------------|
| *(start)* | **CREATE** | Natural language description | Inversion elicitation → 9-phase pipeline |
| *(start)* | **LEAN** | Skill file content or path | Heuristic scoring → PASS/UNCERTAIN/FAIL |
| *(start)* | **EVALUATE** | Skill file content | 4-phase pipeline → certification |
| *(start)* | **OPTIMIZE** | Skill file content + EVALUATE report | 7-dim 9-step loop |
| *(start)* | **INSTALL** | Platform name (optional) | Deploy to target platforms |
| **CREATE** | **LEAN** | *(auto)* — output of CREATE | Fast quality gate |
| **CREATE** | **EVALUATE** | *(auto)* — if LEAN UNCERTAIN | Full certification |
| **LEAN** | **EVALUATE** | LEAN UNCERTAIN result | Full pipeline |
| **LEAN** | **OPTIMIZE** | LEAN FAIL result | Improvement loop |
| **EVALUATE** | **OPTIMIZE** | EVALUATE FAIL result | Improvement loop |
| **OPTIMIZE** | **LEAN** | *(auto)* — after each round | Fast re-score check |
| **OPTIMIZE** | **EVALUATE** | *(optional)* — after loop converges | Full re-certification |
| Any | **INSTALL** | Certified skill content | Platform deployment |

> **OPTIMIZE → EVALUATE policy**: After the OPTIMIZE loop converges:
> - If final LEAN score ≥ 450 (GOLD proxy) → LEAN_CERT is sufficient; EVALUATE is optional.
> - If final LEAN score 350–449 → run full EVALUATE to confirm tier.
> - If final LEAN score < 350 → EVALUATE is mandatory (loop may not have converged properly).

---

## §5  LoongFlow Orchestration

Every mode executes via Plan-Execute-Summarize:

```
┌──────────────────────────────────────────────────────────┐
│  PLAN                                                    │
│  Multi-pass self-review → consensus on approach           │
│  Build cognitive graph of steps                          │
│  Extended spec: refs/self-review.md               │
└──────────────────────────────┬───────────────────────────┘
                               │ plan reviewed
                               ▼
┌──────────────────────────────────────────────────────────┐
│  EXECUTE                                                 │
│  Implement plan with error recovery (rules below)        │
│  Hard checkpoint after each phase                        │
└──────────────────────────────┬───────────────────────────┘
                               │ execution complete
                               ▼
┌──────────────────────────────────────────────────────────┐
│  SUMMARIZE                                               │
│  Cross-validate results against requirements             │
│  Update evolution memory                                 │
│  Route: CERTIFIED | TEMP_CERT | HUMAN_REVIEW | ABORT     │
└──────────────────────────────────────────────────────────┘
```

### Inline Error Recovery Rules `[ENFORCED — no companion file required]`

These rules apply regardless of whether `refs/self-review.md` is available:

| Error Type | Recovery Action |
|-----------|----------------|
| **Phase output missing** (e.g. GENERATE produced no skill text) | Retry once with explicit output instruction; if still missing → HUMAN_REVIEW |
| **Security P0 detected mid-phase** | ABORT immediately; halt all subsequent phases |
| **LEAN score < 300 after GENERATE** | Do NOT deliver; auto-route to targeted OPTIMIZE for lowest dimension |
| **Checkpoint gate fails** (e.g. placeholders remain after Phase 4) | Re-run the failed phase once; if still failing → flag TEMP_CERT + advisory |
| **Companion file unavailable** (refs/ not loaded) | Proceed with inline rules only; note "companion file unavailable" in output; do NOT abort |
| **User provides no answer to elicitation Q** (§7) | Skip with default + WARNING; do NOT block if user skips > 2 questions |
| **External fetch fails** (INSTALL mode) | Retry once after 2s; if still fails → ask user for local path |

**Escalation rule**: After any two consecutive phase failures → escalate to HUMAN_REVIEW immediately rather than attempting further retries.

### HUMAN_REVIEW Protocol — 场景适配 / Scenario-Adapted

When HUMAN_REVIEW is triggered, adapt the output message to the user's context:

**个人用户 / Individual user** (default):
```
⚠ HUMAN_REVIEW 触发 — AI 无法自动继续
Human review required — cannot proceed automatically.

Dimension scores at trigger point:
  systemDesign    [score]/[max]  [⚠ if below 60%]
  domainKnowledge [score]/[max]  [⚠ if below 60%]
  workflow        [score]/[max]  [⚠ if below 60%]
  errorHandling   [score]/[max]  [⚠ if below 60%]
  examples        [score]/[max]  [⚠ if below 60%]
  security        [score]/[max]  [⚠ if below 60%]
  metadata        [score]/[max]  [⚠ if below 60%]

Trigger reason: [DIVERGING | score < 560 after round 10 | 
                 delta > 50 (VERIFY) | cumulative_delta < -40]

下一步 / Next steps:
  1. 查看上方标记 ⚠ 的维度得分 / Review ⚠-flagged dimension scores above
  2. 手动修改技能文件对应章节 / Manually fix the flagged sections
  3. 修改后重新运行 /eval 确认分数 / Re-run /eval after changes to confirm score
```

**P0 安全违规 / P0 security violation** (triggered by ABORT rule):
```
🚨 ABORT — P0 安全违规检测 / P0 Security Violation Detected
违规类型 / Violation: [CWE-XXX or ASI0X]
位置 / Location: [section or line reference]

修复步骤 / Fix steps:
  1. 移除或修复上述违规 / Remove or fix the violation above
  2. 修复后输入: /eval --security-recheck 重新扫描
     After fixing, type: /eval --security-recheck
  3. 如确认误报，输入: I confirm [CWE-XXX] is a false positive — proceed
     To override a false positive: I confirm [CWE-XXX] is a false positive — proceed
```

**团队/企业场景 / Team or enterprise** (if user mentions team context):
```
⚠ HUMAN_REVIEW — 建议进行团队审查
Team review recommended.
建议通过 PR 流程提交技能文件，附本次 EVALUATE 报告作为 review context。
Submit skill file via PR with this EVALUATE report attached as context.
```

---

## §6  CREATE Mode

### Phase Sequence

| # | Phase | Gate |
|---|-------|------|
| 1 | **ELICIT** — Inversion pattern, one question at a time (§7) | All Qs answered |
| 2 | **SELECT TEMPLATE** — match skill type → `templates/<type>.md` | Template chosen |
| 3 | **PLAN** — multi-pass self-review (`refs/self-review.md §2`) | Plan reviewed |
| 4 | **GENERATE** — fill template; write Skill Summary (¶1), Negative Boundaries section. If Q7 or Q8 was skipped, pause and show auto-filled content for user confirmation before proceeding. | Draft complete, no placeholders |
| 5 | **SECURITY SCAN** — CWE + OWASP Agentic Top 10 (`refs/security-patterns.md`) | No P0 violations; ASI01 CLEAR |
| 6 | **LEAN EVAL** — fast heuristic check (§6) | Score ≥ 350; negative boundaries present |
| 7 | **FULL EVALUATE** — 4-phase pipeline if LEAN uncertain (§8) | Score ≥ 700 BRONZE |
| 8 | **INJECT UTE** — append `§UTE` section from snippet, fill placeholders (§15) | UTE section present |
| 9 | **DELIVER** — annotate, certify, write audit entry | CERTIFIED / TEMP_CERT |

> **Phase 9 (DELIVER) — mandatory activation guidance** `[CORE]`:
> Every DELIVER output MUST include these lines, verbatim, after the skill file:
> ```
> ─── Skill ready ───────────────────────────────────────────────────────
> Your skill "{skill_name}" has been created (LEAN: {N}/500 · est. {N*2} EVALUATE).
>
> To activate it:
>   1. Copy the skill file above to your platform's skills folder:
>        Claude:    ~/.claude/skills/{skill_name}.md
>        OpenCode:  ~/.config/opencode/skills/{skill_name}.md
>        OpenClaw:  ~/.openclaw/skills/{skill_name}.md
>        Cursor:    ~/.cursor/skills/{skill_name}.md
>        Gemini:    ~/.gemini/skills/{skill_name}.md
>   2. Restart your AI assistant.
>   3. Say one of the trigger phrases in the skill's YAML to test it.
>
> Score meaning: {N}/500 → estimated {N*2}/1000 → tier: {TIER}
>   ≥ 350 (BRONZE+) = ready to use | < 350 = run /opt first
>   Tier guide: PLATINUM(≥950)=publish-ready · GOLD(≥900)=professional · SILVER(≥800)=team-ready · BRONZE(≥700)=personal use
>
> About the two key sections in your skill file:
>   Skill Summary (§2): tells the AI WHEN to use this skill. Keep it specific — it's
>     the routing signal. If it's vague, the skill may trigger too rarely or too often.
>   Negative Boundaries (§3): tells the AI when NOT to use it. Without sharp boundaries,
>     similar-sounding requests will mis-trigger this skill. Edit these if you notice
>     false triggers.
>
> Next steps (optional): /lean · /eval · /opt · /share
> ───────────────────────────────────────────────────────────────────────
> ```

> **Phase 4 (GENERATE) — Q7/Q8 skip confirmation gate**:
> If the user skipped Q7 (negative boundaries) or Q8 (trigger phrases) during elicitation,
> PAUSE before generating and show the auto-filled defaults for review:
> ```
> ⚠ You skipped Q7 (Negative Boundaries). Auto-filled content:
>   "Do NOT use for: Irreversible actions without explicit confirmation."
> This is a placeholder. Does it work for your skill, or would you like to edit?
> → Type "ok" to proceed with this placeholder (you can edit later)
> → Type your actual negative boundaries to replace it now
> ```
> Do NOT silently proceed with placeholder content — require explicit "ok" or replacement.

> **Phase 4 (GENERATE) — mandatory elements** (sourced from SKILL.md Pattern + SkillRouter research):
> 1. **Skill Summary paragraph** (first content paragraph): ≤5 sentences densely encoding what / when / who / not-for.
>    Research basis: SkillRouter (arxiv:2603.22455) — skill body content is the **decisive routing signal**
>    (91.7% of cross-encoder attention); removing body degrades routing accuracy 29–44pp.
> 2. **Negative Boundaries section**: explicit "Do NOT use for" list. Required before delivery.
>    Research basis: SKILL.md Pattern (2026) — without boundaries, semantically similar requests
>    mis-trigger skills. SkillProbe: negation reduces false trigger rate significantly.
> 3. **Trigger phrases** in metadata: 3–8 canonical phrases users would say to invoke the skill.

#### Negative Boundaries — Fill-in Template

Use this template when writing the Negative Boundaries section in Phase 4 (GENERATE):

```markdown
## Negative Boundaries

**Do NOT use this skill for:**
- [Anti-example 1]: [Reason — what makes this out of scope]
  → Recommended alternative: [skill name or approach]
- [Anti-example 2]: [Reason — what makes this out of scope]
  → Recommended alternative: [skill name or approach]
- [Anti-example 3]: [Reason] (add ≥ 3 entries)
  → Recommended alternative: [skill name or approach]

**The following trigger phrases should NOT activate this skill:**
- "[Phrase that sounds related but belongs to a different skill]"
- "[Another similar-but-different phrase]"
```

> Minimum: 3 "Do NOT use for" entries. If the skill is the only option in its domain,
> explicitly state "No direct alternative — escalate to [human role or process]."

### Template Selection

```
"calls API / integrates service"         → api-integration
"processes / transforms / validates data" → data-pipeline
"multi-step workflow / automation"        → workflow-automation
anything else                             → base
```

Template files: `templates/<type>.md`

> **Language note**: YAML frontmatter field names (`name`, `version`, `triggers`, etc.) are
> always in English — this is a technical standard. All skill *content* (descriptions, workflow
> steps, examples) should be written in the user's preferred language. If the user answered
> elicitation questions in Chinese, generate skill body content in Chinese.
> Mixed-language skills (EN keys + ZH values) are correct and expected.

---

## §7  LEAN Mode (Fast Path ~1s)

**Purpose**: Rapid triage without LLM calls. Use for quick checks or high-volume screening.

### When to Use LEAN vs EVALUATE

| Situation | Use |
|-----------|-----|
| First draft just completed | LEAN (fast structural check) |
| Sharing with a colleague | LEAN (quick sanity check) |
| About to push to skill registry | EVALUATE (authoritative score) |
| Claiming "this is GOLD tier" | EVALUATE (LEAN ±variance too wide for tier claims) |
| Score is near a tier boundary (±30 pts) | EVALUATE (LEAN variance may misclassify) |
| Running 20 OPTIMIZE rounds | LEAN (fast iteration feedback per round) |
| After OPTIMIZE converges | EVALUATE (final certification) |

### Score Variance Reference

LEAN and EVALUATE scores are **estimates**, not exact measurements. Treat scores as ranges:

| Score Type | Typical Variance | Decision Guidance |
|-----------|-----------------|-------------------|
| LEAN `[STATIC]` checks | ±0 pts | Fully reliable — safe for binary pass/fail |
| LEAN `[HEURISTIC]` checks | ±5–15 pts per dimension | Treat as estimate; ±20 total is noise |
| EVALUATE Phase 2 (Text Quality) | ±15–30 pts total | Don't obsess over ±20 pt swings |
| EVALUATE Phase 3 (Runtime) | ±20–40 pts | Highest variance — interpreter-dependent |
| EVALUATE Total | ±30–60 pts | A 750 score means "somewhere 690–810" |

**Practical rules**:
- Two LEAN scores within ±20 pts → treat as identical
- Score within ±30 pts of a tier boundary → run full EVALUATE, ideally twice
- Never claim a specific tier from a single LEAN score if within 30 pts of boundary
- OPTIMIZE rollback threshold is **20 pts** (not 5 pts) to account for variance floor

### Check Reliability Tiers

> **Quick glossary** (shown inline when LEAN score is delivered):
> - `[STATIC]` = **deterministic** — regex/structural checks, ±0 variance, always the same result.
>   Trust these scores 100%. Example: "YAML frontmatter present" — either it is or it isn't.
> - `[HEURISTIC]` = **LLM-judged** — quality assessments, ±5–15 pts per dimension.
>   If two LEAN runs differ by ≤20 pts, treat them as equivalent — that's just noise.
>   Use EVALUATE for an authoritative score when you need to certify a tier.

Each LEAN check is labeled by its execution method:

- **`[STATIC]`** — Deterministic regex / structural match. Same skill → same result every run.
  Score variance: ±0 pts. These checks are fully trustworthy.
- **`[HEURISTIC]`** — Requires LLM judgment to assess adequacy or quality.
  Score variance: ±5–15 pts per dimension. Treat as an estimate, not a precise score.

> **Practical implication**: If two LEAN runs produce scores within ±20 pts, consider them
> equivalent. Differences beyond ±30 pts indicate a genuinely borderline skill — escalate to
> full EVALUATE for authoritative scoring.

### Scoring (500-point heuristic → maps to 1000-point scale)

LEAN checks map directly to the 7 unified dimensions (see `config.SCORING.dimensions`):

| Dimension | LEAN Check | Points | Reliability |
|-----------|-----------|--------|-------------|
| **systemDesign** (max 95) | Identity section present (`## §1` or `## Identity`) | 55 | `[STATIC]` |
| | Red Lines / 严禁 text present in document | 40 | `[STATIC]` |
| **domainKnowledge** (max 95) | Template type correctly matched (API/pipeline/workflow keywords present) | 55 | `[HEURISTIC]` |
| | Field specificity visible (concrete values, not generic placeholders) | 40 | `[HEURISTIC]` |
| **workflow** (max 75) | ≥ 3 `## §N` pattern sections (regex: `^## §\d`) | 45 | `[STATIC]` |
| | Quality Gates table with numeric thresholds present | 30 | `[STATIC]` |
| **errorHandling** (max 75) | Error/recovery section present (keyword: error\|recovery\|rollback\|失败) | 45 | `[STATIC]` |
| | Escalation paths documented (keyword: escalat\|human\|HUMAN_REVIEW\|升级) | 30 | `[HEURISTIC]` |
| **examples** (max 75) | ≥ 2 fenced code blocks (` ``` ` count ≥ 4) | 45 | `[STATIC]` |
| | Trigger keywords present in EN + ZH (min 1 of each language) | 30 | `[STATIC]` |
| **security** (max 45) | Security Baseline section present (keyword: security\|安全\|CWE\|OWASP) | 25 | `[STATIC]` |
| | No hardcoded secrets pattern (regex: `password\s*=\|api_key\s*=\|token\s*=`) | 10 | `[STATIC]` |
| | ASI01 Prompt Injection: no unguarded `{user_input}` interpolation in commands | 10 | `[HEURISTIC]` |
| **metadata** (max 40) | YAML frontmatter present with `name`, `version`, `interface` fields | 15 | `[STATIC]` |
| | `triggers` field with ≥ 3 EN + ≥ 2 ZH phrases | 15 | `[STATIC]` |
| | Negative Boundaries section present ("Do NOT use for" or "严禁触发") | 10 | `[STATIC]` |
| **Total** | | **500** | |

> **Static-only sub-score**: Sum of all `[STATIC]` checks = 335 pts max.
> If a skill scores ≥ 300 on static checks alone, it passes structural baseline regardless
> of LLM-evaluated dimensions. This provides a reliable floor score independent of model variance.

> **Metadata weight increase** (from 25→40 pts): Research basis — SkillRouter (arxiv:2603.22455)
> found that trigger phrase coverage in skill body is the decisive routing signal. Negative
> Boundaries are now a scored element because they directly prevent mis-triggering.

> **New negative boundaries penalty**: If no "Negative Boundaries" / "Do NOT use for" section
> is present, deduct 10 from metadata AND add P2 advisory to security scan output.

**Scale mapping** (500 → 1000):
```
lean_score × 2 = estimated_full_score
PLATINUM proxy: lean ≥ 475  → estimated ≥ 950
GOLD proxy:     lean ≥ 450  → estimated ≥ 900
SILVER proxy:   lean ≥ 400  → estimated ≥ 800
BRONZE proxy:   lean ≥ 350  → estimated ≥ 700
UNCERTAIN:      lean 300–349 → escalate to EVALUATE
FAIL proxy:     lean < 300  → route to OPTIMIZE
```

### LEAN Decision

```
lean_score ≥ 350 AND no_placeholders AND security_section_present
    → LEAN PASS — deliver with LEAN_CERT tag
    → Always output score block in this format:
      "LEAN Score: [N]/500
       Estimated EVALUATE:  ~[N×2]/1000  →  tier: [TIER]
       (LEAN × 2 is a rough proxy. Variance ±60 pts. Use /eval for certified score.)

       Score meaning:
         ≥ 475/500  →  est. PLATINUM (≥ 950)  — excellent, publish-ready
         ≥ 450/500  →  est. GOLD    (≥ 900)   — high quality, team-ready
         ≥ 400/500  →  est. SILVER  (≥ 800)   — good, shareable with beta tag
         ≥ 350/500  →  est. BRONZE  (≥ 700)   — usable, consider improving
         300–349    →  UNCERTAIN — running full /eval now
          < 300     →  FAIL — routing to /opt

       ℹ LEAN variance: ±20 pts is normal across re-runs. Use /eval for a stable certified score."
    → Schedule full EVALUATE within 24 h (recommended, not blocking)

lean_score 300–349 (UNCERTAIN)
    → Show escalation notice BEFORE starting EVALUATE (never silent):

      Output exactly this block (adapt language to user's detected language):
      ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
      ⚠ 输入 /skip 可跳过并保留 LEAN 结果 / Type /skip to keep LEAN result instead
      ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
      LEAN 评分完成 / LEAN Complete
      分数 / Score: [N]/500  (UNCERTAIN — near BRONZE threshold)
      静态检查  [STATIC]:    [S]/335  (零方差 / zero variance)
      启发式检查 [HEURISTIC]: [H]/165  (±20 pt 方差 / variance)

      UNCERTAIN — 启动完整 EVALUATE (~60 秒) / launching full EVALUATE (~60s)
      (附 TEMP_CERT 标记 / LEAN result kept with TEMP_CERT tag if you /skip)
      ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄

      Then show phase progress as each phase completes:
        [Phase 1/4 结构解析 / Parse        ████░░░░░░░░ 25%]
        [Phase 2/4 内容质量 / Text Quality ████████░░░░ 50%]
        [Phase 3/4 运行测试 / Runtime      ████████████ 75%]
        [Phase 4/4 认证 / Certification   ████████████ done]

    → If /skip received → deliver with TEMP_CERT; otherwise proceed with EVALUATE (§8)

lean_score < 300 (FAIL)
    → Show routing notice:
      "LEAN score: [N]/500 — below BRONZE threshold.
       Weakest dimension: [DIMENSION] ([score]/[max]).
       Routing to OPTIMIZE mode to address [DIMENSION] first. [Type /skip to override]"

    → Negative Boundaries diagnostic (run BEFORE routing to OPTIMIZE):
      IF (Negative Boundaries section is absent)
        OR (contains only the default placeholder
            "Avoid irreversible actions without explicit confirmation")
        OR (all listed boundaries are generic across skills, not specific to THIS skill's domain):
        OUTPUT advisory:
        "⚠ Likely cause: Negative Boundaries section is too generic or missing.
         The placeholder 'Avoid irreversible actions without explicit confirmation'
         does not describe this skill's actual scope — every skill has that rule.
         Fix: Add 2–3 specific anti-cases. Examples for a code-review skill:
           • 'Do NOT use for architecture diagram explanations — use code-explainer'
           • 'Do NOT process files > 5,000 lines — split first'
           • 'Do NOT trigger for commit message generation — use commit-writer skill'
         Then re-run /lean."

    → Route to OPTIMIZE (§9) with full dimension report
```

> **Escalation transparency principle** `[CORE]`: When LEAN auto-escalates to EVALUATE,
> always show the escalation notice before proceeding. Never silently run a 60-second pipeline
> when the user requested a 5-second check. The /skip escape hatch respects user intent.

---

## §8  Inversion — Requirement Elicitation

**Rule**: Phase 3 (PLAN) MUST NOT begin until all answers are received.
Ask **one question at a time**. Wait for answer before next question.

### CREATE questions (ask all, one at a time):
1. "这个skill要解决什么核心问题？ / What core problem does this skill solve?"
2. "主要用户是谁，技术水平如何？ / Who are the target users and their technical level?"
3. "输入是什么形式？ / What form does the input take?"
4. "期望的输出是什么？ / What is the expected output?"
5. "有哪些安全或技术约束？ / What security or technical constraints apply?"
6. "验收标准是什么？ / What are the acceptance criteria?"
7. "这个skill在哪些场景下**不**应该触发？ / In which scenarios should this skill NOT trigger? (List 2–5 anti-cases)"
   > 💡 **What are negative boundaries?** Rules that prevent false triggering. Example: a "code reviewer" skill should NOT trigger when someone asks "explain this architecture diagram" — that's for a different skill.
   > 💡 **English examples**: "Do NOT use for production database writes" / "Do NOT process files > 1 GB" / "Do NOT use when real-time data is required" / "Do NOT trigger for 'explain this code' — use code-explainer instead"
   > 💡 **Chinese examples (中文示例)**: "不用于生产数据库操作" / "不适用于超过1000条记录的批量处理" / "不用于需要实时数据的场景"
   > 💡 **卡住了？** 输入 `skip` — 将自动填充通用边界: "Avoid irreversible actions without explicit confirmation"
   > [Answer validation: SKIP accepted → auto-fill default boundary + WARNING note]
   > ⚠️ **跳过后自动填充的内容 / Auto-filled content on skip**:
   >   `**Do NOT use this skill for**: Irreversible actions without explicit confirmation.`
   >   `**触发词排除 / Exclude trigger phrases**: None specified (review before publishing).`
   >   注意: 这只是占位符，发布技能前务必替换为实际边界描述。

8. "用户会用什么词或短语来触发这个skill？ / What phrases or keywords would a user say to trigger this skill? (List 3–8 examples)"
   > 💡 **示例 / Examples**: "检查我的代码" / "review this PR" / "code review" / "审查代码" / "scan for issues"
   > 💡 **卡住了？** 输入 `skip` — 将从技能名称和描述中自动推断触发词
   > [Answer validation: SKIP accepted → auto-generate triggers from skill name + description]
   > ⚠️ **跳过后自动填充的内容 / Auto-filled content on skip**:
   >   Triggers derived from skill name + description keywords (EN + ZH equivalents).
   >   注意: 自动推断的触发词覆盖率约60%，建议添加用户实际使用的自然短语。

> **Questions 7 & 8 are new (v3.1.0)**. Research basis:
> - Q7 (Negative Boundaries): SKILL.md Pattern — without explicit negation, semantically
>   adjacent requests mis-trigger the skill. Required before GENERATE phase.
> - Q8 (Trigger Phrases): SkillRouter (arxiv:2603.22455) — trigger phrase coverage in the
>   skill body is the decisive routing signal (29–44pp accuracy difference).

> **Answer validation**: Minimal — user must provide at least one example for Q7 and Q8.
> If user types `skip` for Q7 or Q8: auto-fill defaults, flag with WARNING in output,
> add a reminder: "Review Negative Boundaries before publishing this skill."

> **Vague-answer probe rule** (apply to Q1–Q6):
> If a user's answer is ≤3 words OR contains only a domain name with no specifics
> (e.g., "git stuff", "some data", "I want a skill"), do NOT proceed to the next question.
> Instead, ask ONE targeted follow-up probe:
> ```
> Q3 vague answer: "the input is git stuff"
> → Probe: "Got it — can you be a bit more specific about the format?
>   (a) Git command output (text from git diff / git log)?
>   (b) Git repository files (code files, commit objects)?
>   (c) Git API responses (JSON from GitHub API)?
>   Just pick a, b, or c — or describe in your own words."
> ```
> Probe rule: one probe per question maximum. If still vague after probe, accept and continue.

> **Template-specific follow-up** (ask after Q6 if applicable):
> - `api-integration`: "Which HTTP methods / authentication mechanism?"
> - `data-pipeline`: "What is the data schema / transformation rules?"
> - `workflow-automation`: "What is the maximum acceptable latency / retry policy?"

### EVALUATE questions (ask all):
1. "请提供skill文件路径或内容。 / Provide the skill file path or content."
2. "评测重点在哪个维度？ / Any specific evaluation focus?"
3. "需要对比其他skill吗？ / Compare against another skill?"

### OPTIMIZE questions (ask all):
1. "请提供当前评测报告（分数 + 最低维度）。 / Provide the current eval report."
2. "已尝试过哪些优化？ / What optimizations were already attempted?"

---

## §9  EVALUATE Mode — 4-Phase Pipeline

**Total: 1000 points** | Full rubrics: `eval/rubrics.md`

### Phase Overview

| Phase | Name | Max Points | Method |
|-------|------|-----------|--------|
| 1 | Parse & Validate | 100 | Heuristic (schema, sections, no placeholders) |
| 2 | Text Quality | 300 | Static analysis across 7 sub-dimensions (see table below) |
| 3 | Runtime Testing | 400 | Trigger pattern tests, mode definitions, error handling |
| 4 | Certification | 200 | Variance gate + security scan + quality gates |

### Phase 2 Sub-Dimensions (300 points total)

Phase 2 scores across 7 content quality dimensions with tier-adjusted weights.
**If your Phase 2 score is low**, run `/eval` and ask "show my Phase 2 breakdown by dimension" to see which one is dragging your score.

| Dimension | planning | functional | atomic | What it checks |
|-----------|----------|------------|--------|----------------|
| systemDesign | 30% | 20% | 15% | Clarity of architecture, role definition, purpose |
| domainKnowledge | 20% | 20% | 15% | Depth and accuracy of domain-specific content |
| workflow | 25% | 20% | 15% | Step sequence, gates, rollback actions |
| errorHandling | 10% | 15% | 25% | Recovery paths, escalation rules |
| examples | 5% | 15% | 20% | Usage coverage, realistic I/O |
| security | 5% | 5% | 5% | CWE + OWASP ASI baseline |
| metadata | 5% | 5% | 5% | YAML triggers, negative boundaries, versions |

> To understand which dimension is low: after receiving your EVALUATE score, ask:
> "What are my Phase 2 sub-dimension scores?" — the framework outputs per-dimension totals.
> Use these to target your next OPTIMIZE run (`/opt` + skill + "focus on [dimension]`).

### Certification Tiers

| Tier | Min Score | Max Variance | Additional Gates |
|------|-----------|-------------|------------------|
| PLATINUM | ≥ 950 | < 10 | Phase2 ≥ 270, Phase3 ≥ 360 |
| GOLD | ≥ 900 | < 15 | Phase2 ≥ 255, Phase3 ≥ 340 |
| SILVER | ≥ 800 | < 20 | Phase2 ≥ 225, Phase3 ≥ 300 |
| BRONZE | ≥ 700 | < 30 | Phase2 ≥ 195, Phase3 ≥ 265 |
| FAIL | < 700 | any | — auto-route to OPTIMIZE |

**Variance formula**:
```
variance = | (phase2_score / 3) - (phase3_score / 4) |
```
> **Why divide by 3 and 4?** This normalizes both scores to "points per point available":
> Phase 2 max = 300, so dividing by 3 gives a value in the 0–100 range.
> Phase 3 max = 400, so dividing by 4 also gives 0–100 range.
> The formula then measures the gap between text quality density and runtime density.
> A skill scoring 270/300 on text (90%) but 280/400 on runtime (70%) has variance = |90 − 70| = 20.

High variance = artifact looks good on paper but fails runtime (or vice versa).

### Evaluation Workflow

```
1. LEAN pre-check (§6) → if UNCERTAIN or FAIL → full pipeline
2. READ skill_tier from YAML frontmatter (planning | functional | atomic)
   → If present: apply tier-adjusted Phase 2 weights (eval/rubrics.md §8)
   → If absent or 'functional': use default Phase 2 weights (rubrics.md §4)
3. Phase 1: Parse — YAML, required sections, trigger presence, no placeholders
4. Phase 2: Text — 7 sub-dimensions with tier-adjusted weights
5. Phase 3: Runtime — benchmark test cases (eval/benchmarks.md)
6. Phase 4: Certification — compute variance, run security scan, check tier-adjusted gates
7. REPORT — per-phase scores + tier + issues list (include skill_tier in report header)
8. ROUTE:
     CERTIFIED → deliver
     FAIL       → auto-route to OPTIMIZE (§9)
```

### Multi-Pass Scoring

Score in separate passes to ensure objectivity:
- Pass 1: Score Phase 2 (Text Quality) — focus on structure and content
- Pass 2: Score Phase 3 (Runtime) — focus on trigger accuracy and behavior
- Pass 3: Reconcile scores, compute variance, certify (Phase 4)

Full protocol: `refs/self-review.md §2`

---

## §10  OPTIMIZE Mode — 7-Dimension 9-Step Loop

### Scoring Scale in OPTIMIZE Loop

> **OPTIMIZE uses the LEAN 500-point scale for all re-scoring** (Steps 1 and 6).
> Reason: LEAN is fast and consistent enough for iteration feedback. Full 1000-pt EVALUATE
> runs only at: (a) loop start if no prior EVALUATE exists, and (b) optionally post-convergence.
>
> Conversion: lean_score × 2 = estimated full score. Bronze proxy: lean ≥ 350.
> The VERIFY step (Step 10) also uses LEAN 500-pt scale.

### 7 Dimensions (unified with LEAN and EVALUATE)

These dimensions are identical to the LEAN scoring dimensions and the EVALUATE
sub-dimension schema. See `builder/src/config.js SCORING.dimensions` for the canonical spec.

| ID | Dimension | Weight | Strategy | What It Covers |
|----|-----------|--------|----------|----------------|
| D1 | **systemDesign** | 20% | S1, S2 | Identity section, Red Lines, architecture clarity |
| D2 | **domainKnowledge** | 20% | S3, S4 | Template accuracy, field specificity, terminology |
| D3 | **workflow** | 15% | S5 | Phase sequence, exit criteria, loop gates |
| D4 | **errorHandling** | 15% | S6 | Recovery paths, escalation triggers, timeouts |
| D5 | **examples** | 15% | S7 | Usage examples count, quality, bilingual coverage |
| D6 | **security** | 10% | S8 | CWE + ASI scan, Red Lines, auth/authz checks, boundaries |
| D7 | **metadata** | 5% | S9 | YAML frontmatter, trigger phrases, negative boundaries, UTE fields |

### Pre-Loop Strategy Selection

Before starting the loop, display current dimension scores and prompt for strategy:

```
OPTIMIZE pre-loop:
  1. Score all 7 dimensions (LEAN pass)
  2. Display dimension breakdown:
     systemDesign   [NNN/100] ████████░░
     domainKnowledge[NNN/100] ██████████
     workflow       [NNN/100] ████░░░░░░
     errorHandling  [NNN/100] ██████░░░░
     examples       [NNN/100] ████████░░
     security       [NNN/100] ██████████
     metadata       [NNN/100] ███████░░░
     TOTAL          [NNN/500]
  3. Present strategy menu with decision guidance:
     A) Auto       — system picks weakest dimension each round
                     推荐: 首次优化，或不确定选哪个策略时 (Recommended: first time / unsure)
     B) Focus [dim] — concentrate all rounds on one dimension
                     推荐: 某维度得分 < 60% 时集中突破 (Recommended: one dim scoring < 60%)
                     例: B errorHandling / B workflow / B examples
     C) Balanced   — rotate across all dimensions evenly
                     推荐: 各维度分差不超过 15 pt，整体拉升 (Recommended: dims within 15pt of each other)
     D) Security   — security + systemDesign dimensions first
                     推荐: 有 P1/P2 安全警告未解决时 (Recommended: unresolved security warnings)

     > 当前最弱维度 / Weakest dimension: {{WEAKEST_DIM}} ({{WEAKEST_SCORE}}/100)
     > 建议 / Suggestion: {{STRATEGY_RECOMMENDATION}}
     > 例如: 若最弱维度 < 60 → 选 B {{WEAKEST_DIM}} | 若各维度分差 < 15 → 选 C
     >
     > 维度名称 (camelCase 格式，与 B/Focus 命令一致):
     > systemDesign | domainKnowledge | workflow | errorHandling | examples | security | metadata

     [Enter to confirm A / type B/C/D + optional dimension name / /stop to exit]
  4. IF skill has no §UTE section → INJECT UTE first (§15)
     ELSE → UPDATE UTE: refresh certified_lean_score to current LEAN score
  5. Initialize session_best = current_score; cumulative_delta = 0
```

> Type `/stop` at any time to exit the loop early and keep the best version so far.

### 9-Step Loop + VERIFY

```
Round N (max 20):
  [progress] Round N/20 | Score: CUR/500 | Best: BEST/500 | Trend: ▲/▼/─ | Focus: DIMENSION

  1. READ    — score all 7 dimensions; identify lowest-scoring per strategy
  2. ANALYZE — propose 3 targeted fixes for weakest dimension
             → always output: "Auto chose [DIMENSION] ([N]/100 — lowest scoring this round)"
               so the user always sees WHY a dimension was selected
  3. CURATE  — every 10 rounds: consolidate learning, prune stale context
  4. PLAN    — review and select best fix strategy; log decision
  5. IMPLEMENT — apply atomic change (single dimension focus)
  6. RE-SCORE  — re-score:
       delta = new_score − prev_score
       cumulative_delta += delta
       IF delta < −20             → rollback this round's change
       IF cumulative_delta < −40  → rollback to session_best + HUMAN_REVIEW
       IF delta > 0               → update session_best if new_score > session_best
       IF no improvement          → try fix #2
  7. HUMAN_REVIEW — trigger if total_score < 560 after round 10
  8. LOG     — record: round, dimension, delta, confidence, strategy_used
  9. COMMIT  — git commit every 10 rounds; tag with score

  [User can type /stop → exit loop, output session_best version + final report]

  After EVERY round, output this status block:
  ─── Round N complete ────────────────────────────────────
  Score: [PREV] → [NEW] (delta ±N) | Session best: [BEST]/500
  Status: [IMPROVING / STABLE / PLATEAU / VOLATILITY / STOPPED]
    IMPROVING  = keep going; next target: [DIM] ([score]/100)
    STABLE     = diminishing returns — suggest /stop or continue?
    PLATEAU    = no gain in 5 rounds — auto-stopping
    VOLATILITY = score swinging ±30pt — auto-stopping, using session best
  Rounds left: [20-N] | /stop to exit with current best version
  ────────────────────────────────────────────────────────

Convergence check (every round):
  PLATEAU:    no net change in 5 consecutive rounds, OR cumulative_delta < 10 pts total
  VOLATILITY: score swings > ±30 pts round-to-round for 3+ consecutive rounds
  STABLE:     3+ consecutive rounds with delta in [+5, +10] range → diminishing returns
  IF any condition → STOP early; output session_best + convergence reason
  See: refs/convergence.md

Post-loop — Co-Evolutionary VERIFY (Step 10) [NEW in v3.1.0]:
  ┌──────────────────────────────────────────────────────────────────┐
  │ VERIFY — Independent Verification Pass                           │
  │                                                                  │
  │ Research basis: EvoSkills (arxiv:2604.01687) — using a Surrogate │
  │ Verifier (independent LLM session without inheriting generator   │
  │ biases) increases pass rate from 32% baseline to 75% by round 5. │
  │                                                                  │
  │ Implementation (single-session approximation):                   │
  │ 1. RESET context — explicitly state: "I am now reviewing this    │
  │    skill as a new reader with no knowledge of the optimization   │
  │    history or the AI's prior intentions."                        │
  │ 2. READ the final skill text as a fresh document                 │
  │ 3. SCORE all 7 LEAN dimensions independently (no prior context)  │
  │ 4. COMPARE VERIFY score vs. final OPTIMIZE round score:          │
  │    ├─ delta ≤ 20 pts → scores are consistent → PROCEED          │
  │    ├─ delta 20–50 pts → flag WARNING; report discrepancy         │
  │    └─ delta > 50 pts → score inflation suspected → HUMAN_REVIEW  │
  │ 5. REPORT: "VERIFY SCORE: N/500 | OPTIMIZE SCORE: M/500 |        │
  │    DELTA: ±D | STATUS: CONSISTENT / WARNING / SUSPECT"           │
  │                                                                  │
  │ 📖 VERIFY 评分解读 / How to read VERIFY results:                  │
  │  • VERIFY ≥ OPTIMIZE: unusual; may indicate genuine improvement  │
  │  • VERIFY < OPTIMIZE by ≤20 pts: normal. Independent scoring     │
  │    without context is slightly conservative. Trust VERIFY as     │
  │    the more robust baseline. Both scores indicate real quality.  │
  │  • VERIFY < OPTIMIZE by 20–50 pts: WARNING. OPTIMIZE may have   │
  │    over-tuned for specific phrasing. Review changed sections.    │
  │  • VERIFY < OPTIMIZE by >50 pts: score inflation suspected.      │
  │    OPTIMIZE likely polished surface text without depth. Revert.  │
  │                                                                  │
  │  Use the VERIFY score (not OPTIMIZE score) as the UTE baseline   │
  │  and for registry push decisions. VERIFY is more trustworthy.    │
  └──────────────────────────────────────────────────────────────────┘

Post-loop — UTE update:
  Update use_to_evolve.certified_lean_score with VERIFY score (more conservative)
  Reset use_to_evolve.last_ute_check to today

Post-loop — Final summary output (always show after loop ends):
  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
  OPTIMIZE 完成 / OPTIMIZE Complete
  轮次 / Rounds: [N completed] / 20 max
  起始分 / Starting score: [X]/500
  最终分 / Final score:    [Y]/500  ([+Z] net improvement)
  VERIFY 分 / Verify score: [M]/500  (independent check)
  整体趋势 / Trend: [▲ UP / ─ FLAT / ▼ DOWN]
  收敛原因 / Stop reason: [PLATEAU / VOLATILITY / STABLE / MAX_ROUNDS / USER_STOP]

  下一步 / Next steps:
  • LEAN score [Y] × 2 ≈ estimated EVALUATE score ~[Y×2]
  • Estimated tier: [PLATINUM/GOLD/SILVER/BRONZE/FAIL]
  • Run `/eval` to get authoritative score before registry push
  • Registry push? See §16 for tier thresholds.
  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄

Max rounds: 20 → if not BRONZE after round 20 → HUMAN_REVIEW

OSCILLATION diagnostic (when score fluctuates ±5–15 pts without clear trend):
When VOLATILITY or PLATEAU detected AND score < 350 (FAIL), output structured diagnostic:

  ─── OPTIMIZE Diagnostic ─────────────────────────────────────────
  Rounds completed: N | Score range this session: [LOW]–[HIGH]/500
  Stop reason: VOLATILITY / PLATEAU / MAX_ROUNDS

  Dimension breakdown (current scores vs. what's needed for BRONZE ≥ 350):
    systemDesign    [N]/100  [status: OK / ⚠ NEEDS WORK]
    domainKnowledge [N]/100  [status: OK / ⚠ NEEDS WORK]
    workflow        [N]/100  [status: OK / ⚠ NEEDS WORK]
    errorHandling   [N]/100  [status: OK / ⚠ NEEDS WORK]
    examples        [N]/100  [status: OK / ⚠ NEEDS WORK]
    security        [N]/100  [status: OK / ⚠ NEEDS WORK]
    metadata        [N]/100  [status: OK / ⚠ NEEDS WORK]

  Why oscillation happens:
  - If ≥2 dimensions are ⚠ NEEDS WORK and have competing constraints
    (e.g., adding more examples makes the skill larger, reducing workflow clarity),
    OPTIMIZE cannot improve both simultaneously → score oscillates.

  Recommended manual actions (pick 1-2 per editing session):
  ⚠ [TOP_WEAK_DIM]: [specific suggestion for this dimension]
    Example for errorHandling: "Add a concrete error recovery table with ≥3 rows"
    Example for examples: "Add 2 complete input→output examples in a code block"
    Example for metadata: "Add 3+ Chinese trigger phrases to YAML frontmatter"
  ⚠ [SECOND_WEAK_DIM]: [specific suggestion]

  After manual edits: run /lean to check improvement, then continue /opt
  Or: run /eval for authoritative score to see if you've reached BRONZE
  ─────────────────────────────────────────────────────────────────
```

Strategy catalog: `optimize/strategies.md`
Convergence spec: `refs/convergence.md`

---

## §11  Self-Evolution (3-Trigger System)

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Threshold** | F1 < 0.90 OR MRR < 0.85 OR error_rate > 5% / 100 calls | Auto-flag → OPTIMIZE |
| **Time** | No update in 30 days | Schedule staleness review |
| **Usage** | < 5 invocations in 90 days | Deprecate OR relevance review |

**Decision logic**:
```
IF trigger_accuracy < 0.85    → strategy S1 (expand keywords)
IF score drops 1+ tier         → OPTIMIZE from lowest dimension
IF error_rate > 10%           → immediate HUMAN_REVIEW
IF staleness triggered         → LEAN eval → if BRONZE+ OK, else OPTIMIZE
IF usage < 5 in 90d           → present: deprecate | maintain | refocus
```

Full spec: `refs/evolution.md`

---

## §12  Security

Scan every skill on CREATE, EVALUATE, and OPTIMIZE delivery.
Full patterns + OWASP rules: `refs/security-patterns.md`

### CWE Patterns (Code Security)

| Severity | CWE | Pattern Type | Action |
|----------|-----|-------------|--------|
| **P0** | CWE-798 | Hardcoded credentials (regex) | **ABORT** |
| **P0** | CWE-89 | SQL injection (regex) | **ABORT** |
| **P0** | CWE-78 | Command injection (regex) | **ABORT** |
| **P1** | CWE-22 | Path traversal (regex) | Score −50, WARNING |
| **P1** | CWE-306 | Missing auth check | Score −30, WARNING |
| **P1** | CWE-862 | Missing authz check | Score −30, WARNING |

### OWASP Agentic Skills Top 10 (2026) — New in v3.1.0

| Severity | ID | Risk | Action |
|----------|----|------|--------|
| **P1** | ASI01 | Agent Goal Hijack / Prompt Injection | Score −50, WARNING |
| **P1** | ASI02 | Tool Misuse & Exploitation | Score −30, WARNING |
| **P1** | ASI03 | Identity & Privilege Abuse | Score −30, WARNING |
| **P1** | ASI04 | Agentic Supply Chain Vulnerabilities | Score −30, WARNING |
| **P2** | ASI05 | Excessive Autonomy & Scope Creep | Advisory only |
| **P2** | ASI06 | Prompt Confidentiality Leakage | Advisory only |
| **P2** | ASI07 | Insecure Skill Composition | Advisory only |
| **P2** | ASI08 | Memory & State Poisoning | Advisory only |
| **P2** | ASI09 | Lack of Human Oversight | Advisory only |
| **P2** | ASI10 | Audit Trail Gaps | Advisory only |

> **Red Lines (additional)**:
> - 严禁 deliver any skill that processes untrusted external content as executable instructions (ASI01)
> - 严禁 deliver skills with executable scripts but no Security Baseline section (SkillProbe: 2.12× vulnerability risk)

ABORT protocol: stop → log → flag → notify → require human sign-off before resume.
Detection heuristics for each ASI: `refs/security-patterns.md §5`

---

## §13  Self-Review Protocol (Summary)

| Pass | Focus |
|------|-------|
| Pass 1 — Generate | Produce initial draft / score / fix proposal |
| Pass 2 — Review | Security audit (CWE) + quality audit; severity-tagged issues (ERROR/WARNING/INFO) |
| Pass 3 — Reconcile | Address all ERRORs, improve on WARNINGs, produce final artifact |

Timeouts: 60 s per phase, 180 s total.
Outcomes: CLEAR → proceed; REVISED → proceed with note;
UNRESOLVED → HUMAN_REVIEW.

Full spec: `refs/self-review.md`

---

## §14  Audit Trail `[EXTENDED — requires external persistence]`

> **Enforcement Level**: `[CORE]` — Produce the audit JSON as part of your response in all sessions.
> `[EXTENDED]` — Writing to `.skill-audit/framework.jsonl` requires an external file system or backend.
> In stateless LLM sessions, treat this as an **output specification** — produce the JSON
> object as part of your response so the user or an integration layer can persist it.

Every operation appends to `.skill-audit/framework.jsonl` (365-day retention):

```json
{
  "timestamp": "<ISO-8601>",
  "duration_ms": 0,
  "mode": "CREATE|LEAN|EVALUATE|OPTIMIZE",
  "skill_name": "<name>",
  "skill_version": "<semver>",
  "template_used": "<type|null>",
  "confidence": 0.00,
  "confidence_override": false,
  "lean_score": 0,
  "phase1": 0, "phase2": 0, "phase3": 0, "phase4": 0,
  "total_score": 0,
  "variance": 0.0,
  "tier": "PLATINUM|GOLD|SILVER|BRONZE|FAIL",
  "f1": 0.00,
  "mrr": 0.00,
  "trigger_accuracy": 0.00,
  "security_p0_clear": true,
  "security_p1_warnings": 0,
  "review_consensus": "CLEAR|REVISED|UNRESOLVED",
  "evolution_trigger": "<threshold|time|usage|null>",
  "error_recovery_invoked": false,
  "error_recovery_actions": [],
  "outcome": "CERTIFIED|TEMP_CERT|LEAN_CERT|HUMAN_REVIEW|ABORT",
  "optimize_cycles": 0
}
```

---

## §15  Usage Examples

### Create an API integration skill

```
Input: "创建一个调用OpenWeather API返回摄氏温度的skill"
Mode: CREATE | Template: api-integration | Language: ZH

→ Elicit (6 questions answered)
→ Generate from api-integration template
→ Security scan: CWE-798 CLEAR, CWE-89 CLEAR
→ LEAN eval: 460/500 → estimated 920 → GOLD proxy → escalate to full EVALUATE
→ Full eval: Phase1=95 Phase2=285 Phase3=385 Phase4=175 Total=940
→ Variance = |285/3 - 385/4| = |95 - 96.25| = 1.25 < 15 → GOLD ✓
→ CERTIFIED GOLD: weather-query v1.0.0
```

### LEAN fast check

```
Input: "lean eval my-skill.md"
Mode: LEAN | Duration: ~1s

→ YAML present ✓ (60), §modes ✓ (60), 严禁 ✓ (50), thresholds ✓ (60),
  examples ✓ (50), triggers ✓ (120), security section ✓ (50), no placeholders ✓ (50)
→ lean_score = 500 → estimated 1000 → PLATINUM proxy
→ LEAN PASS | LEAN_CERT | Schedule full EVALUATE within 24 h
```

### Evaluate and optimize a failing skill

```
Input: "evaluate skill, F1 is 0.82"
Mode: EVALUATE → auto-route to OPTIMIZE on FAIL

→ Phase1=88 Phase2=201 Phase3=285 Phase4=110 Total=684 → FAIL (< 700)
→ Variance = |201/3 - 285/4| = |67 - 71.25| = 4.25 → low, consistent failure
→ Lowest dimension: Workflow Definition (55/100)
→ OPTIMIZE cycle 1: Strategy S2 (fill missing sections) → +38pts
→ OPTIMIZE cycle 2: Strategy S1 (expand keywords) → +22pts
→ Re-evaluate: Total=744 → BRONZE ✓
→ CERTIFIED BRONZE: skill v1.1.0
```

### OPTIMIZE loop — what each round looks like

```
Input: "optimize this skill" [pastes skill with LEAN score 340]
Mode: OPTIMIZE | Strategy: Auto | Starting score: 340/500

Pre-loop output:
  Dimension Scores:
  systemDesign    48/95  ■■■■■░░░░░  51%
  workflow        35/90  ■■■■░░░░░░  39%  ← lowest
  errorHandling   55/80  ■■■■■■░░░░  69%
  examples        40/70  ■■■■■░░░░░  57%
  trigger phrases 80/120 ■■■■■■■░░░  67%
  security        50/50  ■■■■■■■■■■ 100%
  metadata        32/45  ■■■■■■░░░░  71%

  Strategy: A (Auto) → Focus dimension: workflow (lowest)

--- Round 1/20 ---
  Focus: workflow | Tactic: Add 5-step structured workflow table
  [implementing change...]
  New score: 365/500 (+25 pts) | Trend: ▲
  Round 1/20 | Score: 365/500 | Best: 365 | Trend: ▲ | Focus: workflow

--- Round 2/20 ---
  Focus: workflow → systemDesign | Tactic: Add Red Lines + purpose statement
  [implementing change...]
  New score: 382/500 (+17 pts) | Trend: ▲
  Round 2/20 | Score: 382/500 | Best: 382 | Trend: ▲ | Focus: systemDesign

--- Round 3/20 ---
  Focus: examples | Tactic: Add 2 concrete usage examples with I/O
  New score: 380/500 (-2 pts) | Rolling back round 3
  Round 3/20 | Score: 382/500 | Best: 382 | Trend: ─ | Focus: examples

[...continues until convergence or Round 20...]

VERIFY pass: VERIFY SCORE: 378/500 | OPTIMIZE: 382/500 | DELTA: 4 | CONSISTENT ✓

OPTIMIZE Complete
Rounds: 8 / 20 max  |  Starting: 340  →  Final: 382 (+42)  |  VERIFY: 378
Trend: ▲ UP  |  Stop reason: PLATEAU (no gain in 5 rounds)
Estimated EVALUATE: ~382 × 2 = ~764 → SILVER tier
Next: run /eval for authoritative score, then /share when ready
```

---

## §16  UTE Injection

**Use-to-Evolve (UTE)** is injected into every skill the framework creates or optimizes.
The AI, upon recognizing the UTE section, follows the protocol to observe usage patterns
and propose improvements over time.

Full spec: `refs/use-to-evolve.md`
Snippet: `templates/use-to-evolve-snippet.md`

### Injection Protocol (CREATE Step 8 / OPTIMIZE Pre-loop)

```
1. CHECK   — does skill already have §UTE section?
     YES → UPDATE: refresh certified_lean_score, reset last_ute_check
     NO  → INJECT: proceed below

2. LOAD    — read templates/use-to-evolve-snippet.md

3. FILL PLACEHOLDERS:
     {{SKILL_NAME}}           = skill's `name` YAML field
     {{VERSION}}              = skill's `version` YAML field
     {{FRAMEWORK_VERSION}}    = "2.2.0"
     {{INJECTION_DATE}}       = today ISO-8601
     {{CERTIFIED_LEAN_SCORE}} = LEAN score from Step 6 (or 350 if unknown)

4. APPEND  — add §UTE section after last ## §N section in skill

5. MERGE YAML — add use_to_evolve: block to skill's YAML frontmatter

6. LOG — record in audit trail: {"ute_injected": true, "certified_lean_score": N}
```

### What UTE Enables

After injection, the AI follows the UTE protocol to:

| Capability | Level | How It Works |
|-----------|-------|-----------|
| Feedback detection | `[CORE]` | AI observes user corrections, rephrasing, and approvals |
| Trigger candidate collection | `[CORE]` | Rephrasing patterns noted; ≥3 similar → micro-patch candidate |
| Micro-patch proposals | `[CORE]` | AI suggests keyword additions; user confirms before apply |
| OPTIMIZE suggestions | `[CORE]` | Structural issues flagged for full OPTIMIZE cycle |
| Periodic health checks (every 10/50/100) | `[EXTENDED]` | Requires persistent `cumulative_invocations` counter |
| Cadence-gated tier drift detection | `[EXTENDED]` | Requires cross-session invocation counter |

### UTE Update (on OPTIMIZE)

When optimizing a skill that already has UTE:

```
1. Load current use_to_evolve.certified_lean_score
2. Review any user-reported issues as starting point for dimension analysis
3. After all optimization rounds complete:
     update use_to_evolve.certified_lean_score = final_lean_score
     update use_to_evolve.last_ute_check = today
```

This closes the feedback loop: UTE observes usage → proposes improvements →
OPTIMIZE applies fixes → updates UTE baseline → repeat.

---

---

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
./install.sh --all        # all 6 platforms
./install.sh --platform claude
```

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

> MCP (Model Context Protocol) is fundamentally different from Markdown-based platforms.
> Read this section if you are integrating skill-writer into an MCP server for a team.

### MCP vs. Markdown platforms

| Aspect | Claude / OpenCode / Cursor | MCP |
|--------|---------------------------|-----|
| Skill format | Markdown + YAML frontmatter | JSON manifest |
| Context | Chat conversation | API call |
| User feedback | Present in chat | Not directly available |
| UTE auto-trigger | ✅ (observes chat) | ❌ (no chat context) |
| COLLECT auto-persist | ✅ with hooks | Requires explicit API call |

### Install

```bash
# Via install.sh
./install.sh --platform mcp
# Writes to: ~/.mcp/servers/skill-writer/mcp-manifest.json

# Via Agent Install
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-mcp.json and install to mcp
```

### After install — team usage

After the MCP manifest is installed, restart your MCP host. Team members can invoke
skill-writer via MCP calls. All 6 modes are available via MCP. Output is returned as structured JSON.

**Testing installation** — run this first to confirm MCP is working:
```json
{"tool": "skill-writer", "mode": "lean", "input": "a skill that returns json"}
```
Expected response: `{"lean_score": N, "status": "PASS|UNCERTAIN|FAIL", ...}`
If no response or error → verify `~/.mcp/servers/skill-writer/mcp-manifest.json` exists.

### CREATE mode via MCP (important — read before using)

CREATE uses an 8-question elicitation interview (§7 Inversion). In chat-based platforms
(Claude, Cursor), questions are asked one at a time interactively. **MCP is stateless**, so
all 8 answers must be provided in a single call using `elicitation_answers`:

```json
{
  "tool": "skill-writer",
  "mode": "create",
  "input": "a skill that validates REST API responses",
  "elicitation_answers": {
    "q1_problem": "Validate JSON structure and status codes in API responses",
    "q2_users": "Backend developers testing REST integrations",
    "q3_input": "HTTP response object (status code, headers, JSON body)",
    "q4_output": "Validation report: PASS/FAIL with specific field errors",
    "q5_constraints": "Must handle 2xx/4xx/5xx status families; no external calls",
    "q6_acceptance": "Catches missing required fields, wrong types, unexpected status codes",
    "q7_negative_boundaries": "Do NOT use for streaming responses; Do NOT validate auth tokens",
    "q8_trigger_phrases": "validate api response, check response, api assertion, verify response"
  }
}
```

If `elicitation_answers` is omitted, skill-writer will return a **questionnaire prompt**
(the 8 questions as text) for the caller to collect and re-submit with answers. This enables
a two-step MCP flow:

```
Step 1 — Initiate CREATE, get questions:
  Request:  {"tool": "skill-writer", "mode": "create", "input": "..."}
  Response: {"status": "NEEDS_ELICITATION", "session_id": "sw-xxxx",
             "questions": ["Q1: ...", "Q2: ...", ..., "Q8: ..."]}

Step 2 — Re-submit with answers:
  Request:  {"tool": "skill-writer", "mode": "create", "input": "...",
             "session_id": "sw-xxxx",   ← include to resume context
             "elicitation_answers": {"q1_problem": "...", ...}}
  Response: {"status": "COMPLETE", "skill_content": "---\nname: ..."}
```

**`session_id` state management**: The `session_id` returned in Step 1 can be stored
in your application to associate the pending questionnaire with a user. `session_id` values
are valid for 24 hours. After 24 hours, start a new CREATE call. If your MCP host has
no session state, omit `session_id` and always provide `elicitation_answers` in one call (batch mode).

### Team Backend Choice for MCP Deployments

If your team needs automatic tracking (COLLECT auto-persist, AGGREGATE across team members),
choose a backend based on team size and infrastructure:

| Backend | Best for | Setup complexity | Scale limit | Notes |
|---------|----------|-----------------|-------------|-------|
| **File system** (`~/.skill-artifacts/`) | Single developer, single host | None | Unlimited (local) | Write JSON to `~/.skill-artifacts/YYYYMMDD_{skill}.jsonl` |
| **GitHub Gist** (private) | Small team (2–5 people), no ops | Low | < 1 artifact/day/user; API rate limit 5000 req/hr | POST artifact JSON; share Gist URL for AGGREGATE |
| **SQLite** | Team on shared server | Low-medium | Up to ~10K artifacts; single-writer only | One DB file; episodic memory schema (see §17) |
| **PostgreSQL** | Large team, multi-host MCP | Medium | Unlimited with proper indexing | Full query capability; recommended for >20 developers |
| **Vector DB** (Qdrant/Pinecone) | Semantic search across sessions | High | Depends on plan | Required for §17 L4 episodic memory |

**PostgreSQL schema for teams** (recommended for >20 developers):
```sql
-- Migration: skill_artifacts table
CREATE TABLE skill_artifacts (
    id            SERIAL PRIMARY KEY,
    skill_name    TEXT NOT NULL,
    invocation_id TEXT UNIQUE,
    trigger_phrase TEXT,
    outcome       TEXT CHECK (outcome IN ('SUCCESS', 'FAILURE', 'PARTIAL')),
    prm_signal    FLOAT CHECK (prm_signal BETWEEN 0.0 AND 1.0),
    lesson_type   TEXT CHECK (lesson_type IN ('strategic_pattern','failure_lesson','neutral')),
    data          JSONB NOT NULL,  -- full Session Artifact JSON
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_skill_artifacts_skill_name ON skill_artifacts (skill_name);
CREATE INDEX idx_skill_artifacts_created_at ON skill_artifacts (created_at);

-- AGGREGATE query (run via skill-writer API or manually):
SELECT skill_name, lesson_type, COUNT(*) as evidence_count,
       AVG(prm_signal) as avg_quality
FROM skill_artifacts
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY skill_name, lesson_type
ORDER BY evidence_count DESC;
```

**Minimum viable team setup** (GitHub Gist, no ops):
```
1. After each skill invocation, call COLLECT via MCP API
2. POST the artifact JSON to a private GitHub Gist
3. Store the Gist URL in your team wiki
4. To run AGGREGATE: fetch 2+ Gist URLs, paste into MCP AGGREGATE call
```

### UTE and COLLECT via MCP

Because MCP operates without a persistent chat context, the COLLECT trigger must be
**built into your application layer** — it does not fire automatically. Here is the
complete integration pattern:

```
MCP UTE/COLLECT Architecture:

  Your application (Slack bot / CI / API gateway)
       │
       │  1. Invoke skill via MCP API
       ▼
  MCP server (skill-writer)
       │  executes the skill
       │
       │  2. Immediately after skill response, your app calls COLLECT:
       ▼
  {"tool": "skill-writer", "mode": "collect",
   "session_context": {
     "skill_name": "weather-query",
     "invocation_id": "uuid",
     "trigger_phrase": "what's the weather in Tokyo",
     "outcome": "SUCCESS",
     "prm_signal": 1.0
   }}
       │
       │  3. skill-writer returns JSON artifact
       │
       │  4. Your app POSTs artifact to backend:
       │     File:  append to ~/.skill-artifacts/YYYYMMDD_weather-query.jsonl
       │     Gist:  PATCH https://api.github.com/gists/{gist_id}
       │     DB:    INSERT INTO skill_artifacts (json_data, created_at)
       │
       │  5. UTE cadence (your app tracks count):
       │     every 10 invocations  → call COLLECT with mode: "ute_lightweight"
       │     every 50 invocations  → call with mode: "ute_full_recompute"
       │     every 100 invocations → call with mode: "ute_tier_drift_check"
       ▼
  AGGREGATE (run on demand):
  {"tool": "skill-writer", "mode": "aggregate",
   "artifacts": [artifact1_json, artifact2_json, ...]}
```

**Who triggers COLLECT?** Your application wrapper (not the end user). Build it as a
post-hook that fires after every successful skill invocation. If using a Slack bot, call
COLLECT in the bot's response handler. If using CI, add a COLLECT step after the skill step.

**Minimal integration example (Python pseudocode)**:
```python
import mcp_client, json, os, datetime

def invoke_skill_and_collect(skill_name, trigger_phrase, user_input):
    # Step 1 — invoke the actual skill
    skill_response = mcp_client.call("skill-writer", {
        "mode": "run",
        "skill": skill_name,
        "input": user_input
    })

    # Step 2 — rate the outcome (your app logic)
    outcome = "SUCCESS" if skill_response.get("status") == "ok" else "FAILURE"
    prm_signal = 1.0 if outcome == "SUCCESS" else 0.0

    # Step 3 — trigger COLLECT immediately after
    collect_response = mcp_client.call("skill-writer", {
        "mode": "collect",
        "session_context": {
            "skill_name": skill_name,
            "invocation_id": skill_response.get("invocation_id"),
            "trigger_phrase": trigger_phrase,
            "outcome": outcome,
            "prm_signal": prm_signal
        }
    })

    # Step 4 — persist artifact to your backend
    artifact = collect_response["artifact"]
    store_artifact(artifact)  # see backend choice table above
    return skill_response

def store_artifact(artifact):
    # PostgreSQL example:
    # cursor.execute("INSERT INTO skill_artifacts (data) VALUES (%s)", [json.dumps(artifact)])
    # File system example:
    today = datetime.date.today().isoformat()
    path = os.path.expanduser(f"~/.skill-artifacts/{today}_{artifact['skill_name']}.jsonl")
    with open(path, "a") as f:
        f.write(json.dumps(artifact) + "\n")

# UTE cadence check (call in your periodic job / cron):
def ute_cadence_check(invocation_count, skill_name):
    if invocation_count % 100 == 0:
        mode = "ute_tier_drift_check"
    elif invocation_count % 50 == 0:
        mode = "ute_full_recompute"
    elif invocation_count % 10 == 0:
        mode = "ute_lightweight"
    else:
        return  # no check needed this invocation
    mcp_client.call("skill-writer", {"mode": mode, "skill": skill_name})
```

- **UTE auto-trigger** does not fire (no chat to observe). Add `use_to_evolve.enabled: true`
  to skill YAML; your application handles the cadence (every 10/50/100 invocations above).
- **COLLECT**: Call explicitly from your application after each skill invocation.
  Output is JSON artifact — store in your chosen backend (see table above).
- **AGGREGATE**: Call with 2+ artifacts to get ranked improvement priorities.
  Provide artifacts as inline JSON in the call body (Method B) or point to a backend path.

---

## §18  Memory Architecture `[EXTENDED — optional backend required for full capability]`

> **Enforcement Level Legend for this section:**
> - `[CORE]` — Available natively in every LLM session (in-context working memory).
> - `[EXTENDED]` — Requires an optional external backend (file system, database, GitHub Gist, vector DB).
>   The framework functions fully without it; these tiers add cross-session persistence and retrieval.

Skill Writer operates across three memory layers. Only Working Memory is natively available
in all LLM sessions. Episodic and Semantic Memory require optional external backends.

```
┌─────────────────────────────────────────────────────────────────────┐
│  WORKING MEMORY  `[CORE]`                                       │
│  Session-scoped in-context state                                    │
│  • Current skill content being processed                            │
│  • LEAN/EVALUATE scores and dimension breakdown                     │
│  • OPTIMIZE round history (within this session)                     │
│  • Self-review draft → reconcile cycle outputs                      │
│  Cleared on: session end                                            │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ optional persistence via backend
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│  EPISODIC MEMORY  `[EXTENDED]`                                  │
│  Persistent event log across sessions                               │
│  • Skill invocation history (cumulative_invocations counter)        │
│  • UTE feedback signals and micro-patch log                         │
│  • EVALUATE/OPTIMIZE audit trail (.skill-audit/framework.jsonl)     │
│  • 3-trigger evolution event log                                    │
│  Backends: SQLite · Redis · GitHub Gist · custom API                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ optional vector indexing
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│  SEMANTIC MEMORY  `[EXTENDED]`                                  │
│  Vectorized knowledge for retrieval-augmented skill generation      │
│  • Skill knowledge base (domain patterns, best practices)           │
│  • Historical optimization strategies and their outcomes            │
│  • CWE pattern embeddings for fuzzy security matching               │
│  Backends: ChromaDB · pgvector · Pinecone                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Minimum Viable Persistence (no infra required)

For projects without a persistence backend, use **GitHub Gist** as a free
cross-session episodic memory:

```
cumulative_invocations  →  update Gist JSON on each invocation
audit_trail             →  append to Gist JSONL file
ute_micro_patches       →  store patch candidates in Gist
```

The skill framework functions fully with Working Memory only. Episodic and
Semantic Memory unlock cadence-gated UTE health checks and RAG-enhanced
skill generation respectively.

---

## §19  COLLECT Mode — Session Data Recording

> **COLLECT at a Glance**
>
> **What it does**: After a skill invocation completes, COLLECT captures a structured
> Session Artifact — a snapshot of what happened, how well it worked, and what to improve.
>
> **Why use it**: Accumulate 5+ artifacts → run AGGREGATE → get a ranked improvement list
> for `/opt`. This is how skills improve through real usage rather than manual edits.
>
> **5-step workflow**: ASSESS → SCORE → OBSERVE → CLASSIFY → ASSEMBLE
>
> **When to trigger manually**:
> - After an important or complex invocation
> - When a trigger miss or output issue occurred (capture failure lessons)
> - Before running `/opt` on a skill you've been using (build evidence base)
>
> **Enforcement**: Artifact generation is `[CORE]` (works in any session). File persistence
> (`.skill-audit/`) is `[EXTENDED]` (requires external backend or file system access).

**Purpose**: Produce a structured Session Artifact after any skill invocation, enabling
collective skill evolution by accumulating usage data across sessions and users.

**Inspired by**: SkillClaw collective evolution framework (arxiv.org/abs/2604.08377)
**Full spec**: `refs/session-artifact.md`
**Edit guard**: `refs/edit-audit.md`

### Session Artifact Schema (inline reference)

```json
{
  "timestamp": "2026-04-11T14:32:00Z",
  "skill_name": "code-reviewer",
  "skill_version": "1.1.0",
  "invocation_outcome": "success",        // success | failure | partial
  "prm_signal": "good",                   // good | ok | poor (user feedback proxy)
  "lesson_type": "strategic_pattern",     // strategic_pattern | failure_lesson | neutral
  "lesson_summary": "User triggered with 'review my PR'. Output accepted without corrections. Suggest adding 'review PR' as primary trigger keyword.",
  "trigger_phrase_used": "review my code",
  "trigger_matched": true,
  "output_accepted": true,
  "dimension_observations": {
    "trigger_accuracy": "good",
    "workflow": "good",
    "errorHandling": "ok",
    "examples": "good"
  },
  "improvement_hints": [
    "Add 'review PR' as trigger synonym",
    "Section §5 SCAN mode example is sparse — add one more example"
  ],
  "session_id": "sha256-first-8-chars"
}
```

> Store artifacts as `~/.skill-artifacts/YYYYMMDD_{skill_name}.jsonl` (append mode)
> or any JSON store. Send 2+ artifacts to AGGREGATE for ranked improvement priorities.

### When COLLECT runs

COLLECT fires **automatically at the end of every skill invocation** when either:
- The skill's YAML frontmatter contains `use_to_evolve.enabled: true`, OR
- The user explicitly requests "collect" / "记录此次使用"

It always runs *after* the primary mode (CREATE / LEAN / EVALUATE / OPTIMIZE) completes —
never interrupts the main workflow.

### Artifact generation protocol `[CORE]`

```
1. ASSESS — review the session that just completed:
   - What was the user's trigger phrase?
   - What mode ran and what was the outcome?
   - Was the user's goal fully met?
   - What feedback signal did the user give (if any)?

2. SCORE — estimate prm_signal:
   good  = skill triggered cleanly, output accepted without correction
   ok    = skill triggered but needed clarification or minor iteration
   poor  = trigger miss, wrong output, or user abandoned

3. OBSERVE — identify patterns and improvement hints:
   - Any trigger phrases that almost didn't match?
   - Any output verbosity / format issues?
   - Any dimension that clearly underperformed?

4. CLASSIFY LESSON TYPE (SkillRL-inspired, new in v3.1.0):
   strategic_pattern → outcome=success AND prm_signal=good
                        Write lesson_summary as: "What worked, why, what to reuse"
   failure_lesson    → outcome=failure OR feedback_signal=correction
                        Write lesson_summary as: "What failed, root cause, how to fix"
   neutral           → outcome=partial OR outcome=ambiguous
                        Write lesson_summary as: "What happened, what was ambiguous"
   (see refs/session-artifact.md §3 for full classification rules)

5. SUMMARIZE — write 8–15 sentence causal-chain summary
   (see refs/session-artifact.md §4 for guidelines)

6. ASSEMBLE — produce complete Session Artifact JSON including lesson_type + lesson_summary
   (see refs/session-artifact.md §2 for schema)

6. DELIVER — output the JSON artifact with persistence instructions:

   **[CORE] 无持久化后端时 (任何会话均适用)**:
   输出完整 JSON 到对话窗口。提示用户手动保存：
   ```
   📄 Session Artifact 已生成 / generated. 请保存到 / Save to:
      ~/.skill-artifacts/YYYYMMDD_<skill_name>.json
   运行 mkdir -p ~/.skill-artifacts 然后粘贴下方 JSON。
   Run: mkdir -p ~/.skill-artifacts  then paste the JSON below.
   ```

   **[EXTENDED] 有文件系统 / Hook 时**:
   自动写入 ~/.skill-artifacts/ 目录，无需手动操作。
   Auto-written to ~/.skill-artifacts/ — no manual step needed.

   **聚合命令 / Aggregate trigger** (收集 2+ artifacts 后):
   输入 "aggregate skill feedback" / "聚合技能反馈" 分析所有 artifacts
   → 输出排序优化建议列表，可直接用于 /opt
```

### AGGREGATE mode (multi-session synthesis) `[EXTENDED — basic flow available]`

**Two methods to run AGGREGATE — choose based on your setup:**

```
Method A — Automatic (EXTENDED: UTE hooks configured)
─────────────────────────────────────────────────────
Prerequisites: UTE hooks write artifacts to ~/.skill-artifacts/ automatically.
Trigger: "aggregate skill feedback"
→ skill-writer reads all artifacts in ~/.skill-artifacts/ automatically
→ Synthesizes and outputs ranked improvement list
→ No manual paste needed

Method B — Manual paste (CORE: no hooks, works everywhere)
───────────────────────────────────────────────────────────
Step 1: After each invocation, run /collect → copy the JSON output to a file
Step 2: When ready, paste 2+ JSON artifacts directly into the chat:
  User: "aggregate skill feedback"
  [paste artifact 1 JSON]
  [paste artifact 2 JSON]
  ...
→ skill-writer synthesizes and outputs ranked improvement list

If you only have 1 artifact: AGGREGATE will run but note "low confidence — 
  collect 2+ sessions for reliable prioritization."

Confidence guide by artifact count:
  1 artifact  → runs but flags LOW CONFIDENCE (directional only, not actionable)
  2–4 artifacts → MEDIUM confidence (good enough to plan next /opt round)
  5+ artifacts → HIGH confidence (reliable prioritization, safe to act on)
```

**Multi-skill artifact handling** (artifacts from different skills mixed together):

```
When artifacts from multiple skills are present, AGGREGATE automatically:
1. Groups artifacts by skill_name field in each JSON
2. Runs per-skill analysis independently
3. Produces a ranked improvement list per skill, then a cross-skill summary

Example output header when multiple skills are present:
  "Skills covered: pr-reviewer (4 artifacts), git-diff-summarizer (2 artifacts)"
  → Per-skill sections follow, then a cross-skill "No-Skill Bucket"

You do NOT need to separate artifacts by skill before running AGGREGATE.
Just paste all artifacts together — AGGREGATE handles the grouping.
```

When the user provides 2+ Session Artifact JSONs, AGGREGATE mode synthesizes them:

```
1. READ     — parse N session artifacts (from paste or ~/.skill-artifacts/)
2. SUMMARIZE— merge individual summaries into a unified cross-session picture
3. AGGREGATE— group by skill dimension; identify the "no-skill bucket"
              (sessions where skill didn't trigger → new skill candidates)
4. EXECUTE  — rank improvement opportunities by evidence count:
               ≥3 sessions with same pattern → HIGH priority
               1–2 sessions               → LOW priority
5. OUTPUT   — ranked improvement list for OPTIMIZE
              OR "create new skill" proposal for no-skill bucket
```

**Trigger words for AGGREGATE**:
- "aggregate skill feedback" / "聚合技能反馈"
- "analyze usage sessions" / "分析使用记录"
- "synthesize session data" / "综合会话数据"
- "which skill to optimize?" / "哪个技能先优化？"

**AGGREGATE performance characteristics**:
- Complexity: O(N) where N = number of artifacts analyzed
- Expected duration: <5s for 100 artifacts, <30s for 1,000 artifacts
- Memory: ~2KB per artifact in context window (250 artifacts ≈ 500KB of context)
- For very large datasets (>500 artifacts from many team members):
  → Pre-aggregate by skill_name first: `SELECT ... GROUP BY skill_name` (PostgreSQL)
  → Then run AGGREGATE on grouped summaries (reduces context load)
  → Or run AGGREGATE per-skill: "aggregate feedback for skill-name-X only"

**AGGREGATE output format** (always produce this structure):
```
AGGREGATE Results — N artifacts analyzed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Skills covered: [list of skill names from artifacts]
Sessions analyzed: N  |  Date range: YYYY-MM-DD – YYYY-MM-DD

┌─ Priority 1 (HIGH — 3+ sessions): ─────────────────────────
│ Skill: [skill_name]  |  Dimension: [trigger_accuracy]
│ Pattern: Trigger phrase "review my code" missed 3/4 sessions
│ Action: Add "review my code" as primary keyword in YAML triggers
│ → Run: optimize this skill (Focus trigger_accuracy)

┌─ Priority 2 (MEDIUM — 2 sessions): ────────────────────────
│ Skill: [skill_name]  |  Dimension: [errorHandling]
│ Pattern: Output truncated on large inputs (2 sessions)
│ Action: Add explicit size gate with graceful degradation
│ → Run: optimize this skill (Focus errorHandling)

┌─ No-Skill Bucket: ─────────────────────────────────────────
│ 2 sessions had no skill trigger (topic: "API mock generation")
│ Proposal: Create new skill → "api-mock-generator"
│ → Run: /create an API mock generator skill

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Recommended next action: optimize [priority-1-skill] first
```

### After COLLECT completes — always output this guidance

After the Session Artifact JSON is output, always append:
```
─── Session Artifact saved ────────────────────────────────────
[CORE]    Copy the JSON above and save it to a file.
          Suggested path: ~/.skill-artifacts/YYYYMMDD_{skill_name}.json
[EXTENDED] Auto-written to ~/.skill-artifacts/ (if UTE hooks configured)

What to do next:
  • Collect 2+ artifacts, then:  aggregate skill feedback
    → AGGREGATE ranks improvement opportunities and feeds /opt
  • To save to GitHub Gist (team sharing):
    POST the JSON to a private Gist, share the URL with your team lead
  • Already have 2+ artifacts? Paste them and run: aggregate skill feedback

Are you a skill USER (not the author)?
  → Share feedback with the skill author:
    1. Run /collect → copy the JSON output
    2. Send it to the skill author via your team channel / Gist / email
    3. The author pastes it into AGGREGATE to see your usage patterns
    No special tool needed — plain JSON in any communication channel works.
──────────────────────────────────────────────────────────────
```

### Triggers for COLLECT

```
Auto (when UTE enabled):    fires after every skill invocation
Explicit: "collect this session"  /  "记录此次使用"
          "export skill usage"    /  "导出使用数据"
          "generate session artifact"
```

### Key references

- Session Artifact schema: `refs/session-artifact.md`
- Edit guard (protects OPTIMIZE from over-writing): `refs/edit-audit.md`
- Skill registry (for `skill_id` computation): `refs/skill-registry.md`
- UTE 2.0 L1/L2 architecture: `refs/use-to-evolve.md §7`
- **v3.2.0**: GoS bundle context fields: `refs/session-artifact.md §8`

### v3.2.0 COLLECT Extension — Bundle Context `[CORE]`

When COLLECT fires and the task involved multiple skills (bundle invocation):
1. Record `bundle_context.co_invoked_skills` — list the other skill_ids used in this task
2. Record `bundle_context.invocation_order` — the sequence they were called
3. Record `bundle_context.data_flow` — any observed output → input passing between skills
4. Fill `graph_signals.should_add_edge` if you strongly infer a dependency (confidence ≥ 0.85)

These fields feed the AGGREGATE pipeline's auto-inference of graph edges.
Full spec: `refs/session-artifact.md §8`

---

## §20  GRAPH Mode — Skill Graph Management (v3.2.0)

> **GRAPH at a Glance**
>
> **What it does**: Manages the typed relationship graph between skills.
> View the skill dependency graph, check graph health, plan bundles for tasks,
> and resolve installation dependencies.
>
> **Research basis**: SkillNet (arxiv:2603.04448), GoS bundle retrieval, SkillX tiers
> **Full spec**: `refs/skill-graph.md`
> **Implementation**: `builder/src/core/graph.js`
>
> **When to use**:
> - Before installing a skill that has `graph.depends_on` entries
> - When `/graph check` errors appear (GRAPH-001 to GRAPH-008)
> - To plan the minimum skill set for a complex task
> - After running AGGREGATE to review auto-inferred graph edges

**Trigger**: `/graph [subcommand]` | `技能图` | `依赖图` | `包规划`

### Sub-commands

| Command | Description | Example |
|---------|-------------|---------|
| `/graph view` | ASCII graph of current skill ecosystem | `/graph view` |
| `/graph view [skill]` | Neighborhood graph for one skill | `/graph view api-tester` |
| `/graph check` | Run GRAPH-001–008 health checks | `/graph check` |
| `/graph plan [task]` | Resolve minimum bundle for a task | `/graph plan "test the payment API"` |
| `/graph bundle` | List all pre-defined bundles | `/graph bundle` |
| `/graph diff [v1] [v2]` | Compare graph structure between versions | `/graph diff v3.1.0 v3.2.0` |

### `/graph plan` Workflow

```
/graph plan "test the payment API and generate a coverage report"
     ↓
Step 1: Route to primary skill via SkillRouter trigger matching
        → primary: api-tester (seed node)
     ↓
Step 2: BFS expansion via builder/src/core/graph.js resolveBundle()
        → Follow depends_on (required=true)  → schema-validator
        → Follow depends_on (required=false) → auth-helper (optional)
        → Match provides → consumes         → report-generator
     ↓
Step 3: Deduplication (similar_to ≥ 0.90 → keep higher-scoring)
     ↓
Step 4: Topological sort (dependencies first)
     ↓
Output:
  Bundle: API Testing Suite
  Install order:
    1. schema-validator  (atomic, required)
    2. auth-helper       (atomic, optional)
    3. api-tester        (functional, entry point)
    4. report-generator  (functional)
  Token estimate: ~3,200 tokens (within budget)
  Run /install --bundle to deploy all at once.
```

### `/graph check` Output Format

```
📊 Graph Health Report — skill-writer registry v2.0
  Nodes: N skills | Edges: M relationships | Bundles: K defined

  ERRORS:   [GRAPH-001] dangling edge, [GRAPH-005] cycle — must fix
  WARNINGS: [GRAPH-002] planning missing composes, [GRAPH-004] merge advisory
  INFO:     [GRAPH-006] isolated nodes, [GRAPH-008] unused provides types

  → Fix ERRORS before /install --bundle
  → Review WARNINGS before publishing to skill registry
```

### GRAPH Mode + D8 Scoring

After running `/graph check`:
- If D8 score is 0 (no `graph:` block): GRAPH mode prompts user to add graph declarations
- If D8 score < 15: GRAPH mode identifies which D8 sub-checks are failing and suggests fixes
- Successful `/graph plan` execution = proof the graph declarations work → D8 boost

### Key references

- Full GoS spec: `refs/skill-graph.md`
- Registry v2.0 format: `refs/skill-registry.md §10`
- D8 scoring rules: `eval/rubrics.md §9`
- Graph algorithms: `builder/src/core/graph.js`
- Validation checks: `builder/src/commands/validate.js` (GRAPH-001–005)

---

**Triggers**:
**CREATE** | **LEAN** | **EVALUATE** | **OPTIMIZE** | **INSTALL** | **COLLECT** | **GRAPH**
**创建** | **快评** | **评测** | **优化** | **安装** | **采集** | **技能图**

(Templates: `templates/` · UTE snippet: `templates/use-to-evolve-snippet.md` ·
Eval rubrics: `eval/rubrics.md` · Benchmarks: `eval/benchmarks.md` ·
Self-review: `refs/self-review.md` · Security: `refs/security-patterns.md` ·
Evolution: `refs/evolution.md` · UTE spec: `refs/use-to-evolve.md` ·
Convergence: `refs/convergence.md` · Optimize strategies: `optimize/strategies.md` ·
Session artifact: `refs/session-artifact.md` · Edit audit: `refs/edit-audit.md` ·
Skill registry: `refs/skill-registry.md` · **Skill graph: `refs/skill-graph.md`**)
