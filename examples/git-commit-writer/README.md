# Example: git-commit-writer

**Tier**: 🏆 PLATINUM · **Score**: 1007/1020 · **Type**: Base (text assistant)  
**Skill version**: 1.1.0 · **Created with**: skill-writer v3.4.0

> This example is a **complete walkthrough** of the skill-writer lifecycle:
> CREATE → Security Scan → LEAN Eval → OPTIMIZE → full EVALUATE.
> Every command, every score, every change is shown so you can replicate the process
> for your own skills.

---

## What This Skill Does

`git-commit-writer` generates [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)-compliant
commit messages from a git diff or a plain-text description of changes.

**Two modes**:
- **GENERATE** — diff or description in → `<type>(<scope>): <description>` out
- **VALIDATE** — check an existing message for spec violations

---

## Quick Install

After installing skill-writer, paste this into your AI assistant:

```
"read https://github.com/theneoai/skill-writer/raw/main/examples/git-commit-writer/skill.md and install to claude"
```

Then try:
```
"write commit message for this diff: + export function validateEmail(s) { ... }"
```

---

## Full Lifecycle Walkthrough

### Step 1 — CREATE Mode: 8-Question Elicitation

Type: `"create a skill that writes conventional commit messages"`

The AI asks 8 guided questions and waits for your answers:

```
skill-writer CREATE mode — 8-question elicitation
══════════════════════════════════════════════════

Q1 Skill name?
   → git-commit-writer

Q2 Core functionality in one sentence?
   → Generate Conventional Commits 1.0.0 compliant messages
     from a git diff or plain-text description of changes.

Q3 Who is the target user?
   → Developers on teams that enforce conventional commits in CI.

Q4 Give ≥ 3 English trigger phrases (what will users type):
   → "write commit message"
   → "generate commit for this diff"
   → "help me commit"
   → "commit message for"
   → "what should my commit say"

Q5 Give ≥ 2 Chinese trigger phrases:
   → "写提交信息"
   → "生成提交消息"
   → "帮我写提交"

Q6 What are 3+ things this skill should NOT do?
   → 不重写 git 历史（squash/rebase）
   → 不生成 PR 描述
   → 不解释已有提交的含义
   → 不生成 changelog

Q7 What modes does it need?
   → GENERATE: produce message from diff/description
   → VALIDATE: check an existing message for compliance

Q8 Security boundaries?
   → Read-only; no shell execution; no network calls; text output only.
```

**Template selected**: `base.md` — text analysis and generation, no API calls, no data pipeline.

---

### Step 2 — Generated Skill Structure (v1.0.0)

After answering the 8 questions, the AI produces a complete skill file.
The key sections automatically filled from your answers:

```markdown
---
name: git-commit-writer
version: "1.0.0"
skill_tier: functional
triggers:
  en:
    - "write commit message"
    - "generate commit for this diff"
    - "help me commit"
    - "commit message for"
    - "what should my commit say"
  zh:
    - "写提交信息"
    - "生成提交消息"
    - "帮我写提交"
use_to_evolve:
  generation_method: "auto-generated"
  validation_status: "lean-only"
  ...
---

## Skill Summary        ← 5-sentence overview (auto-generated from Q2/Q3/Q6)
## §1  Identity         ← Name, role, purpose, red lines (from Q2/Q8)
## §2  Negative Boundaries  ← 4 anti-cases with alternatives (from Q6)
## §3  Loop             ← 5-phase PARSE→CLASSIFY→GENERATE→VALIDATE→DELIVER
## §4  GENERATE Mode    ← Steps, type list, output contract (from Q7)
## §5  VALIDATE Mode    ← Steps, checks, output contract (from Q7)
## §6  Error Handling   ← 5 error conditions with recovery actions
## §7  Quality Gates    ← F1 ≥ 0.90, MRR ≥ 0.85, subject ≤ 72 chars
## §8  Security Baseline← CWE-78/89/798, ASI01/02/05 declarations
## §9  Usage Examples   ← 2 concrete examples (EN + ZH)
## §UTE Use-to-Evolve   ← Self-evolution hooks (auto-injected)
```

Total: **9 sections**, ~180 lines, ready to evaluate.

---

### Step 3 — Security Scan

The skill is automatically scanned before scoring:

```
Security Scan Report — git-commit-writer v1.0.0
═══════════════════════════════════════════════
✓ CWE-798: No hardcoded credentials
✓ CWE-89:  No SQL injection templates
✓ CWE-78:  No shell=True with user input
✓ ASI01:   No unguarded {user_input} interpolation in commands

P0: 0 violations  (Critical — would ABORT delivery)
P1: 0 violations  (High)
P2: 0 violations  (Medium)

Result: PASS — safe to proceed to LEAN evaluation
```

---

### Step 4 — LEAN Evaluation: v1.0.0 (448/500)

LEAN runs 16 structural checks in ~5 seconds.
Checks marked `[STATIC]` are deterministic (zero variance);
`[HEURISTIC]` require LLM judgment (±5–15 pt variance).

```
LEAN Evaluation Report — git-commit-writer v1.0.0
══════════════════════════════════════════════════════════════
                                              Score  Max  Type
──────────────────────────────────────────────────────────────
SYSTEM DESIGN
  ✓ Identity section present (## §1)          55/55  [STATIC]
  ✓ Red Lines / 严禁 present                  40/40  [STATIC]

DOMAIN KNOWLEDGE
  ✓ Template type correctly matched (base)    45/55  [HEURISTIC]
    ↳ commit type keywords present but no structured type table
  ✓ Field specificity (concrete values)       28/40  [HEURISTIC]
    ↳ mentions feat/fix/refactor but no lookup table or scope rules

WORKFLOW
  ✓ ≥ 3 §N sections (found 9)               45/45  [STATIC]
  ✓ Quality Gates with numeric thresholds    30/30  [STATIC]

ERROR HANDLING
  ✓ Error/recovery section present           45/45  [STATIC]
  ✗ Escalation paths (HUMAN_REVIEW)           0/30  [HEURISTIC]
    ↳ MISSING: no HUMAN_REVIEW keyword or decision path found

EXAMPLES
  ✓ ≥ 2 fenced code blocks (found 2)        45/45  [STATIC]
  ✓ Trigger keywords in EN + ZH             30/30  [STATIC]

SECURITY
  ✓ Security Baseline section present       25/25  [STATIC]
  ✓ No hardcoded secrets                    10/10  [STATIC]
  ✓ ASI01: no unguarded {user_input}        10/10  [HEURISTIC]

METADATA
  ✓ YAML: name, version, interface          15/15  [STATIC]
  ✓ triggers ≥3 EN + ≥2 ZH (5 EN, 3 ZH)   15/15  [STATIC]
  ✓ Negative Boundaries present             10/10  [STATIC]
──────────────────────────────────────────────────────────────
[STATIC]    335+/365 pts  (zero variance — structural floor met)
[HEURISTIC]  83/135 pts  (estimate ±20 pts)
──────────────────────────────────────────────────────────────
TOTAL LEAN: 448/500

Proxy tier:   SILVER (est. 896/1000)  → LEAN PASS ✓

Weaknesses to fix before full certification:
  1. [HEURISTIC -30] Escalation HUMAN_REVIEW: add decision matrix
                     with explicit confidence thresholds
  2. [HEURISTIC -12] Field specificity: add Conventional Commits
                     type table + scope inference rules
```

**448/500 = LEAN PASS at SILVER proxy.** The skill works but we know
exactly where the 52 missing points are. Route to OPTIMIZE.

---

### Step 5 — OPTIMIZE Round 1

OPTIMIZE identifies the two weak dimensions and applies targeted fixes.
No structural changes — only precision additions.

#### Fix 1: Add HUMAN_REVIEW Escalation Decision Matrix (+28 pts)

**Before** (v1.0.0 §6 Error Handling):
```markdown
| Ambiguous scope | List top 3 candidate scopes; ask user to pick | Accept user-selected scope |
| Input is not a diff | Return guidance: "Please paste a git diff..." | Prompt for valid input |
```

**After** (v1.1.0 §6 Error Handling):
```markdown
| Confidence < 0.70 after 2 attempts | HUMAN_REVIEW: output raw analysis + ask user | Present top-3 candidates |
| Breaking change w/ prod impact      | HUMAN_REVIEW: require explicit confirmation  | Abort footer if declined |

Escalation Decision Matrix:
  Confidence ≥ 0.80   → Deliver message directly
  Confidence 0.70–0.79 → Deliver with alternatives (show 2nd best type)
  Confidence < 0.70   → HUMAN_REVIEW: present analysis, ask user to decide
    ├── After 1 clarification → retry classify
    └── After 2 failed retries → output raw diff summary + "please classify manually"

  Breaking change detected + user_confirmed = false → ABORT footer, warn user
  Breaking change detected + user_confirmed = true  → add BREAKING CHANGE: footer
```

#### Fix 2: Add Conventional Commits Type Table + Scope Rules (+17 pts)

**Before** (v1.0.0 §4 GENERATE steps):
```markdown
2. Determine type from nature of change:
   - New feature → feat
   - Bug fix → fix
   - Refactor without behavior change → refactor
   [... plain list ...]
```

**After** (v1.1.0 §4 GENERATE — structured tables):
```markdown
Type Classification Table (Conventional Commits 1.0.0):

| Type     | When to use                            | Example trigger words in diff       |
|----------|----------------------------------------|-------------------------------------|
| feat     | New user-visible feature               | add, new, introduce, implement      |
| fix      | Bug fix, corrects incorrect behavior   | fix, resolve, correct, patch        |
| refactor | Restructure, no behavior change        | rename, move, extract, inline       |
| docs     | Documentation only                     | .md, docs/, # in diff               |
| test     | Test additions or fixes                | test/, spec/, __tests__/, .test.    |
| ci       | CI/CD pipeline config                  | .yml in .github/, Jenkinsfile       |
| build    | Build system or dependency changes     | Makefile, package.json, Cargo.toml  |
| style    | Formatting, whitespace, no logic change| prettier, eslint --fix, indent-only |
| perf     | Performance improvements               | O(n)→O(1), cache, memoize, lazy     |
| chore    | Routine maintenance                    | version bumps in lock files         |

Scope Inference Rules (from changed file paths):

| Path pattern         | Inferred scope |
|----------------------|----------------|
| src/auth/, lib/auth  | auth           |
| src/api/, routes/    | api            |
| src/ui/, components/ | ui             |
| docs/, *.md          | docs           |
| Makefile, scripts/   | build          |
| .github/workflows/   | ci             |
| Multiple top dirs    | (omit scope)   |
```

---

### Step 6 — LEAN Re-Evaluation: v1.1.0 (493/500)

```
LEAN Report — git-commit-writer v1.1.0 (post-OPTIMIZE)
══════════════════════════════════════════════════════════════
  ✓ [STATIC]    Identity section present          55/55
  ✓ [STATIC]    Red Lines / 严禁                   40/40
  △ [HEURISTIC] Template type correctly matched   52/55  (+7 vs v1.0.0)
  △ [HEURISTIC] Field specificity                 38/40  (+10 vs v1.0.0)
  ✓ [STATIC]    ≥ 3 §N sections (9)               45/45
  ✓ [STATIC]    Quality Gates                     30/30
  ✓ [STATIC]    Error/recovery section            45/45
  △ [HEURISTIC] Escalation / HUMAN_REVIEW         28/30  (+28 vs v1.0.0)
  ✓ [STATIC]    ≥ 2 code blocks (3)               45/45
  ✓ [STATIC]    EN + ZH triggers in body          30/30
  ✓ [STATIC]    Security Baseline present         25/25
  ✓ [STATIC]    No hardcoded secrets              10/10
  ✓ [HEURISTIC] ASI01 clean                       10/10
  ✓ [STATIC]    YAML: name/version/interface      15/15
  ✓ [STATIC]    triggers ≥3 EN + ≥2 ZH           15/15
  ✓ [STATIC]    Negative Boundaries               10/10
──────────────────────────────────────────────────────────────
TOTAL LEAN: 493/500  (+45 pts from v1.0.0)

Proxy tier:  🏆 PLATINUM (est. ≥950)  → LEAN PASS ✓

Convergence: +45 pts > 5 pt threshold → OPTIMIZE successful
```

**Improvement summary**:

| What changed | Points gained |
|-------------|--------------|
| HUMAN_REVIEW decision matrix added | +28 pts |
| Complete type table (10 types) added | +7 pts |
| Scope inference rules table added | +10 pts |
| **Total** | **+45 pts** |

One round of targeted fixes moved the skill from **SILVER proxy → PLATINUM proxy**.

---

### Step 7 — Full EVALUATE (1007/1020)

After LEAN hits PLATINUM proxy (≥ 475), run the full 4-phase pipeline:

```
Full EVALUATE — git-commit-writer v1.1.0
══════════════════════════════════════════════════════════
Phase 1 — Parse & Validate    100/100  ✓  All 14 checks pass
Phase 2 — Text Quality        300/300  ✓  Phase2 min PLATINUM ≥270 met
Phase 3 — Runtime Testing     387/400  ✓  Phase3 min PLATINUM ≥360 met
Phase 4 — Certification       200/200  ✓  Variance < 10 (PLATINUM gate)
Bonus   — Behavioral Verifier  +20     ✓  5/5 test cases passed
──────────────────────────────────────────────────────────
TOTAL:   1007/1020

Certification:  🏆 PLATINUM
Variance:       |300 − 387| / 10 = 8.7 < 10  ✓
Security gate:  P0: 0, P1: 0, P2: 0  ✓
```

**Behavioral Verifier — 5 auto-generated test cases**:

| # | Input | Expected | Pass? |
|---|-------|----------|-------|
| T1 | `+ export function validateEmail(s)` | `feat: add validateEmail utility` | ✓ |
| T2 | "fixed login redirect bug in auth module" | `fix(auth): resolve login redirect loop` | ✓ |
| T3 | diff removes exported `UserV1`, adds `UserV2` | `feat(api)!: replace UserV1 with UserV2` + `BREAKING CHANGE:` footer | ✓ |
| T4 | "写提交信息：更新了 README 的安装说明" | `docs: update README installation instructions` | ✓ |
| T5 | "pls make commit good" (no context) | HUMAN_REVIEW: ask user to pick type | ✓ |

---

## Score Timeline

```
v1.0.0  CREATE output      448/500 LEAN  ──► SILVER proxy  (est. 896/1000)
  │
  │  OPTIMIZE Round 1 (2 targeted fixes, ~5 min)
  │  + HUMAN_REVIEW decision matrix
  │  + Conventional Commits type table + scope rules
  │
v1.1.0  post-OPTIMIZE      493/500 LEAN  ──► PLATINUM proxy (est. 986/1000)
                          1007/1020 EVAL ──► 🏆 PLATINUM CERTIFIED
```

---

## What This Demonstrates

1. **LEAN is a fast, reliable triage signal.** 16 checks in ~5 seconds pinpointed
   the exact missing pieces (HUMAN_REVIEW escalation, field specificity) without
   requiring a slow full evaluation.

2. **OPTIMIZE is targeted, not a rewrite.** Both fixes were additive — two new tables
   and one decision matrix. The skill's core structure was not touched.

3. **One round was enough.** +45 pts in a single round moved the skill from
   SILVER to PLATINUM proxy, clearing the GOLD threshold by a large margin.

4. **Honest labeling tracks reality.** `generation_method: "auto-generated"` and
   `validation_status: "full-eval"` are machine-readable fields that tell downstream
   tools (SHARE gate, registry) exactly how this skill was made and verified.

---

## Files

| File | Description |
|------|-------------|
| [`skill.md`](skill.md) | Certified skill v1.1.0 (PLATINUM 1007/1020) |
| [`eval-report.md`](eval-report.md) | Full 4-phase EVALUATE report + Behavioral Verifier results |
| [`README.md`](README.md) | This walkthrough |
