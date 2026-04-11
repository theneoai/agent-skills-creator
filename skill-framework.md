---
name: skill-writer
version: "3.1.0"
description: "Meta-skill framework: CREATE from templates, LEAN/EVALUATE/OPTIMIZE lifecycle, COLLECT mode for collective skill evolution, Edit Audit Guard, Skill Registry for push/pull sharing, UTE 2.0 two-tier self-improvement, and deploy to 7 platforms including MCP."
description_i18n:
  en: "Full lifecycle meta-skill framework: CREATE from templates (3-tier hierarchy, negative boundaries, Skill Summary), LEAN fast-eval, EVALUATE 4-phase 1000pt pipeline + OWASP Agentic Top 10, OPTIMIZE 7-dim 9-step loop + co-evolutionary VERIFY, COLLECT for collective evolution (SkillClaw + SkillRL-compatible), skill registry + SHARE, UTE 2.0 L1/L2, deploy to 7 platforms."
  zh: "全生命周期元技能框架：三层层级结构+负向边界+检索优化摘要的CREATE、LEAN快速评测、OWASP Agentic Top 10安全检测的4阶段EVALUATE、加入协同进化VERIFY的OPTIMIZE、SkillRL+SkillClaw兼容COLLECT、技能注册表+共享、UTE 2.0双层自进化、部署至7平台。"

license: MIT
author:
  name: theneoai
created: "2026-03-31"
updated: "2026-04-11"
type: meta-framework

tags:
  - meta-skill
  - lifecycle
  - templates
  - evaluation
  - optimization
  - self-review
  - self-evolution

interface:
  input: user-natural-language
  output: structured-skill
  modes: [create, lean, evaluate, optimize, install, collect]
  platforms: [claude, opencode, openclaw, cursor, openai, gemini, mcp]

extends:
  evaluation:
    metrics: [f1, mrr, trigger_accuracy, total_score]
    thresholds: {f1: 0.90, mrr: 0.85, trigger_accuracy: 0.90, score_bronze: 700}
  certification:
    tiers: [PLATINUM, GOLD, SILVER, BRONZE, FAIL]
    variance_gates: {platinum: 10, gold: 15, silver: 20, bronze: 30}
  security:
    standard: CWE
    patterns: claude/refs/security-patterns.md
    scan-on-delivery: true
  evolution:
    triggers: [threshold, time, usage]
    spec: claude/refs/evolution.md
  self_review:
    spec: claude/refs/self-review.md
  convergence:
    spec: claude/refs/convergence.md
  use_to_evolve:
    enabled: true
    spec: claude/refs/use-to-evolve.md
    snippet: claude/templates/use-to-evolve-snippet.md
    inject_on: [create, optimize]
---

<!-- PATH CONVENTION
  Throughout this document, `claude/` is a path prefix relative to the Claude
  configuration root (~/.claude/). Companion files are installed there by
  `npm run install:claude` (which runs install-claude.sh):

    claude/refs/security-patterns.md  →  ~/.claude/refs/security-patterns.md
    claude/refs/use-to-evolve.md      →  ~/.claude/refs/use-to-evolve.md
    claude/refs/convergence.md        →  ~/.claude/refs/convergence.md
    claude/refs/self-review.md        →  ~/.claude/refs/self-review.md
    claude/refs/evolution.md          →  ~/.claude/refs/evolution.md
    claude/templates/                 →  ~/.claude/templates/
    claude/eval/                      →  ~/.claude/eval/
    claude/optimize/                  →  ~/.claude/optimize/

  Source files in this repository:  refs/  templates/  eval/  optimize/
-->

## §0  Quick Start — 5 Common Workflows

> **New here?** Pick your scenario below and follow the steps. Full documentation starts at §1.

| Goal | Command | Duration |
|------|---------|----------|
| Create a new skill | `/create` + one-sentence description | 2–5 min |
| Fast quality check | `/lean` + skill content | <5s |
| Full certification | `/eval` + skill content | ~60s |
| Improve an existing skill | `/opt` + skill + eval report | 5–20 min |
| Deploy to platforms | `/install [platform]` | <30s |
| Record session data | `/collect` | ~10s |

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
│  换算: LEAN分 × 2 ≈ EVALUATE分 (估算值, 误差 ±60 pt)               │
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
- **Tool Wrapper**: Load `claude/refs/` on demand, treat as absolute truth
- **Generator**: Template-based structured output for every skill type
- **Reviewer**: Self-review severity-scoped audit (ERROR / WARNING / INFO)
- **Inversion**: Blocking requirement elicitation before any generation
- **Pipeline**: Strict phase order with hard checkpoints

**Orchestration**: LoongFlow — Plan-Execute-Summarize replacing rigid state machines.
See `claude/refs/self-review.md §1` for full spec.

**Red Lines (严禁)**:

> `严禁` = **STRICTLY FORBIDDEN** — 触发此规则时必须立即中止，不可跳过。
> When triggered, execution MUST halt immediately. No bypass without explicit human sign-off.

- 严禁 (FORBIDDEN) hardcoded credentials (CWE-798) — patterns: `claude/refs/security-patterns.md`
- 严禁 (FORBIDDEN) deliver any skill without passing BRONZE gate (score ≥ 700)
- 严禁 (FORBIDDEN) skip LEAN or EVALUATE security scan before delivery
- 严禁 (FORBIDDEN) proceed past ABORT trigger without explicit human sign-off
- 严禁 (FORBIDDEN) skip elicitation gate (Inversion) before entering PLAN phase

---

## §2  Mode Router

### Priority 0 — Explicit Slash Commands `[CORE — evaluated first, skip keyword scoring]`

When a message begins with a slash command, route immediately without keyword scoring.
No confirmation needed. These commands are LLM-evaluated (not platform CLI commands).

| Slash Command | Routes to | Chinese Equivalent |
|--------------|-----------|-------------------|
| `/create` | CREATE mode | `/创建` |
| `/lean` | LEAN mode | `/快评` |
| `/eval` or `/evaluate` | EVALUATE mode | `/评测` |
| `/opt` or `/optimize` | OPTIMIZE mode | `/优化` |
| `/install` | INSTALL mode | `/安装` |
| `/collect` | COLLECT mode | `/采集` |
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
│ INSTALL  [安装,部署,读取安装 | install,read.*install,            │
│           fetch.*install,setup,deploy]                          │
│ COLLECT  [采集,记录,收集,会话数据 | collect,record,artifact,    │
│           session-data,session-artifact,export.*log]            │
│                                                                 │
│ confidence HIGH   → AUTO-ROUTE (no confirmation)                │
│ confidence MEDIUM → show "I'll run [MODE] — confirm? (yes/no)"  │
│ confidence LOW    → show mode menu (see below)                  │
└─────────────────────────────────────────────────────────────────┘
```

**Low confidence mode menu** (show when no clear keyword and no context clue):
```
Not sure which mode to use. Please choose:
  1. /create  — 创建新技能 / Build a new skill from a description
  2. /lean    — 快速检查 (~5s) / Quick quality check (~5s, heuristic scoring)
  3. /eval    — 完整评测 (~60s) / Full 4-phase quality evaluation (~60s)
  4. /opt     — 迭代优化 (最多20轮) / Iterative improvement loop (up to 20 rounds)
  5. /install — 部署到平台 / Deploy skill to platforms
  6. /collect — 记录会话数据 / Record this session as a skill artifact

Or describe what you want to do and I'll route automatically.
(Cursor/IDE users: type the number or keyword — not the /command)
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

## §3  Graceful Degradation

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

## §4  LoongFlow Orchestration

Every mode executes via Plan-Execute-Summarize:

```
┌──────────────────────────────────────────────────────────┐
│  PLAN                                                    │
│  Multi-pass self-review → consensus on approach           │
│  Build cognitive graph of steps                          │
│  Extended spec: claude/refs/self-review.md               │
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

These rules apply regardless of whether `claude/refs/self-review.md` is available:

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

下一步 / Next steps:
  1. 查看下方标记 ⚠ 的维度得分 / Review ⚠-flagged dimension scores below
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

## §5  CREATE Mode

### Phase Sequence

| # | Phase | Gate |
|---|-------|------|
| 1 | **ELICIT** — Inversion pattern, one question at a time (§7) | All Qs answered |
| 2 | **SELECT TEMPLATE** — match skill type → `claude/templates/<type>.md` | Template chosen |
| 3 | **PLAN** — multi-pass self-review (`claude/refs/self-review.md §2`) | Plan reviewed |
| 4 | **GENERATE** — fill template; write Skill Summary (¶1), Negative Boundaries section | Draft complete, no placeholders |
| 5 | **SECURITY SCAN** — CWE + OWASP Agentic Top 10 (`claude/refs/security-patterns.md`) | No P0 violations; ASI01 CLEAR |
| 6 | **LEAN EVAL** — fast heuristic check (§6) | Score ≥ 350; negative boundaries present |
| 7 | **FULL EVALUATE** — 4-phase pipeline if LEAN uncertain (§8) | Score ≥ 700 BRONZE |
| 8 | **INJECT UTE** — append `§UTE` section from snippet, fill placeholders (§15) | UTE section present |
| 9 | **DELIVER** — annotate, certify, write audit entry | CERTIFIED / TEMP_CERT |

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

Template files: `claude/templates/<type>.md`

---

## §6  LEAN Mode (Fast Path ~1s)

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
    → Schedule full EVALUATE within 24 h (recommended, not blocking)

lean_score 300–349 (UNCERTAIN)
    → Show escalation notice BEFORE starting EVALUATE (never silent):

      Output exactly this block:
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
    → Route to OPTIMIZE (§9) with full dimension report
```

> **Escalation transparency principle** `[CORE]`: When LEAN auto-escalates to EVALUATE,
> always show the escalation notice before proceeding. Never silently run a 60-second pipeline
> when the user requested a 5-second check. The /skip escape hatch respects user intent.

---

## §7  Inversion — Requirement Elicitation

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
   > 💡 **示例 / Examples**: "不用于生产数据库操作" / "不适用于超过1000条记录的批量处理" / "不用于需要实时数据的场景"
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

## §8  EVALUATE Mode — 4-Phase Pipeline

**Total: 1000 points** | Full rubrics: `claude/eval/rubrics.md`

### Phase Overview

| Phase | Name | Max Points | Method |
|-------|------|-----------|--------|
| 1 | Parse & Validate | 100 | Heuristic (schema, sections, no placeholders) |
| 2 | Text Quality | 300 | Static analysis across 6 sub-dimensions |
| 3 | Runtime Testing | 400 | Trigger pattern tests, mode definitions, error handling |
| 4 | Certification | 200 | Variance gate + security scan + quality gates |

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
   → If present: apply tier-adjusted Phase 2 weights (claude/eval/rubrics.md §8)
   → If absent or 'functional': use default Phase 2 weights (rubrics.md §4)
3. Phase 1: Parse — YAML, required sections, trigger presence, no placeholders
4. Phase 2: Text — 7 sub-dimensions with tier-adjusted weights
5. Phase 3: Runtime — benchmark test cases (claude/eval/benchmarks.md)
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

Full protocol: `claude/refs/self-review.md §2`

---

## §9  OPTIMIZE Mode — 7-Dimension 9-Step Loop

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

Convergence check (every round):
  IF volatility OR plateau OR trend=STABLE → STOP early
  See: claude/refs/convergence.md

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
  └──────────────────────────────────────────────────────────────────┘

Post-loop — UTE update:
  Update use_to_evolve.certified_lean_score with VERIFY score (more conservative)
  Reset use_to_evolve.last_ute_check to today

Max rounds: 20 → if not BRONZE after round 20 → HUMAN_REVIEW
```

Strategy catalog: `claude/optimize/strategies.md`
Convergence spec: `claude/refs/convergence.md`

---

## §10  Self-Evolution (3-Trigger System)

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

Full spec: `claude/refs/evolution.md`

---

## §11  Security

Scan every skill on CREATE, EVALUATE, and OPTIMIZE delivery.
Full patterns + OWASP rules: `claude/refs/security-patterns.md`

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
Detection heuristics for each ASI: `claude/refs/security-patterns.md §5`

---

## §12  Self-Review Protocol (Summary)

| Pass | Focus |
|------|-------|
| Pass 1 — Generate | Produce initial draft / score / fix proposal |
| Pass 2 — Review | Security audit (CWE) + quality audit; severity-tagged issues (ERROR/WARNING/INFO) |
| Pass 3 — Reconcile | Address all ERRORs, improve on WARNINGs, produce final artifact |

Timeouts: 60 s per phase, 180 s total.
Outcomes: CLEAR → proceed; REVISED → proceed with note;
UNRESOLVED → HUMAN_REVIEW.

Full spec: `claude/refs/self-review.md`

---

## §13  Audit Trail `[EXTENDED — requires external persistence]`

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

## §14  Usage Examples

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

---

## §15  UTE Injection

**Use-to-Evolve (UTE)** is injected into every skill the framework creates or optimizes.
The AI, upon recognizing the UTE section, follows the protocol to observe usage patterns
and propose improvements over time.

Full spec: `claude/refs/use-to-evolve.md`
Snippet: `claude/templates/use-to-evolve-snippet.md`

### Injection Protocol (CREATE Step 8 / OPTIMIZE Pre-loop)

```
1. CHECK   — does skill already have §UTE section?
     YES → UPDATE: refresh certified_lean_score, reset last_ute_check
     NO  → INJECT: proceed below

2. LOAD    — read claude/templates/use-to-evolve-snippet.md

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

## §16  INSTALL Mode

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

3. CONFIRM
   - Show: source (URL or local), target platforms, install paths
   - Ask: "Proceed with installation? (yes/no)"
   - On "no" → ABORT gracefully

4. INSTALL (per platform)
   FOR EACH platform in target:
     a. mkdir -p <install_path_dir>
     b. Write skill content to <install_path>
     c. IF platform == claude AND local clone available:
          Copy companion files (refs/, templates/, eval/, optimize/)
          to ~/.claude/{refs,templates,eval,optimize}/
     d. Log: ✓ <install_path>

5. REPORT
   ✓ Installed to N platform(s):
     • <platform>: <install_path>
   ℹ Restart <platform> to activate skill-writer.
   ℹ Companion files (refs/, eval/, templates/, optimize/) copied for Claude.
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

> Use `/eval` for an authoritative score before pushing. A single LEAN score near a tier
> boundary (±30 pts) is not sufficient — run EVALUATE to confirm.

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

## §17  Memory Architecture `[EXTENDED — optional backend required for full capability]`

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

## §18  COLLECT Mode — Session Data Recording

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
**Full spec**: `claude/refs/session-artifact.md`
**Edit guard**: `claude/refs/edit-audit.md`

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

When the user provides 2+ Session Artifact JSONs, AGGREGATE mode synthesizes them:

```
1. READ     — parse N session artifacts
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

### Triggers for COLLECT

```
Auto (when UTE enabled):    fires after every skill invocation
Explicit: "collect this session"  /  "记录此次使用"
          "export skill usage"    /  "导出使用数据"
          "generate session artifact"
```

### Key references

- Session Artifact schema: `claude/refs/session-artifact.md`
- Edit guard (protects OPTIMIZE from over-writing): `claude/refs/edit-audit.md`
- Skill registry (for `skill_id` computation): `claude/refs/skill-registry.md`
- UTE 2.0 L1/L2 architecture: `claude/refs/use-to-evolve.md §7`

---

**Triggers**:
**CREATE** | **LEAN** | **EVALUATE** | **OPTIMIZE** | **INSTALL** | **COLLECT**
**创建** | **快评** | **评测** | **优化** | **安装** | **采集**

(Templates: `claude/templates/` · UTE snippet: `claude/templates/use-to-evolve-snippet.md` ·
Eval rubrics: `claude/eval/rubrics.md` · Benchmarks: `claude/eval/benchmarks.md` ·
Self-review: `claude/refs/self-review.md` · Security: `claude/refs/security-patterns.md` ·
Evolution: `claude/refs/evolution.md` · UTE spec: `claude/refs/use-to-evolve.md` ·
Convergence: `claude/refs/convergence.md` · Optimize strategies: `claude/optimize/strategies.md` ·
Session artifact: `claude/refs/session-artifact.md` · Edit audit: `claude/refs/edit-audit.md` ·
Skill registry: `claude/refs/skill-registry.md`)
