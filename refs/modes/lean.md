<!-- Extracted from claude/skill-writer.md §7 — full reference -->

## §7  LEAN Mode (Fast Path ~1s)

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

**Score Reliability**: LEAN produces ±20 pt variance across runs (LLM heuristic scoring).
- Scores within ±20 pts = equivalent; don't over-optimize for small deltas
- Score ≥350 confirmed across 2 runs = confident BRONZE+ signal
- Single run within 20 pts of a tier boundary → run full EVALUATE to confirm

### Check Reliability Tiers

Each LEAN check is labeled by its execution method:

- **`[STATIC]`** — Deterministic regex / structural match. Same skill → same result every run.
  Score variance: ±0 pts. These checks are fully trustworthy.
- **`[HEURISTIC]`** — Requires LLM judgment to assess adequacy or quality.
  Score variance: ±5–15 pts per dimension. Treat as an estimate, not a precise score.

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

> **Metadata weight increase** (from 25→40 pts): Research basis — Skill Summary heuristic
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

       ℹ LEAN variance: ±20 pts is normal across re-runs — see Score Reliability above."
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

