<!-- Extracted from claude/skill-writer.md §6 — full reference -->

# CREATE Mode

> **Default: test-first.** Before GENERATE, the mode asks the user to provide
> or confirm a trigger-eval set. After GENERATE, the mode runs
> `scripts/run_trigger_eval.py` and reports precision / recall / f1. Delivery
> without a real trigger-eval sets `validation_status: lean-only` and blocks
> SHARE until `/eval` runs.
>
> **Why test-first**: LLM-authored skills pass rubrics by design — they are
> written with the rubric in mind. Real API-call evaluation against a
> held-out query set is the only signal that breaks generator bias. This
> mirrors Anthropic skill-creator's eval workflow.

## Test-First Sub-phase (runs between Phase 5 and Phase 6)

1. Ask the user: "Do you have a trigger-eval JSON file (list of `{query,
   should_trigger}` pairs)? Minimum 10 should-trigger + 10 should-not-trigger."
2. If **yes** — accept path; run `python3 scripts/run_trigger_eval.py
   --skill <out> --eval-set <path> --runs 3`; attach the resulting f1 to
   the DELIVER block; set `validation_status: full-eval`.
3. If **no** — offer three options:
    - a) Use `eval/trigger-eval.example.json` as a placeholder (weak signal
      but better than nothing; keeps `validation_status: lean-only`).
    - b) Auto-generate 20 queries from the skill's description + negative
      boundaries (Behavioral Verifier). Run trigger eval on those.
      `validation_status: full-eval`.
    - c) Skip real eval entirely. `validation_status: unvalidated`. SHARE
      mode will hard-block this skill.
4. Print the three options and their trade-offs. Never silently choose.

## §6  CREATE Mode (legacy rubric pipeline — retained for reference)

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


### Phase Sequence

| # | Phase | Gate |
|---|-------|------|
| 1 | **ELICIT** — Inversion pattern, one question at a time (§8) | All Qs answered |
| 2 | **SELECT TEMPLATE** — match skill type → `templates/<type>.md` | Template chosen |
| 3 | **PLAN** — multi-pass self-review (`refs/self-review.md §2`) | Plan reviewed |
| 4 | **GENERATE** — fill template; write Skill Summary (¶1), Negative Boundaries section. If Q7 or Q8 was skipped, pause and show auto-filled content for user confirmation before proceeding. | Draft complete, no placeholders |
| 5 | **SECURITY SCAN** — CWE + OWASP Agentic Top 10 (`refs/security-patterns.md`) | No P0 violations; ASI01 CLEAR |
| 6 | **LEAN EVAL** — fast heuristic check (§7) | Score ≥ 350; negative boundaries present |
| 7 | **FULL EVALUATE** — 4-phase pipeline if LEAN uncertain (§9) | Score ≥ 700 BRONZE |
| 8 | **INJECT UTE** — append `§UTE` section from snippet, fill placeholders (§15) | UTE section present |
| 9 | **DELIVER** — annotate, certify, inject honest labels, write audit entry | CERTIFIED / TEMP_CERT |

### Honest Skill Labeling (Phase 9 — mandatory, v3.4.0)

Every generated skill MUST include these two fields in its YAML frontmatter at DELIVER time:

```yaml
generation_method: "auto-generated"   # set at CREATE; user updates to "human-authored" or "hybrid" after manual edit
validation_status: "lean-only"         # updated by EVALUATE ("full-eval") and Pragmatic Test ("pragmatic-verified")
```

**Routing impact**: `auto-generated + lean-only` → `source_quality_score = 0.2`; `lean-passed (≥350)` → 0.5.
**SHARE gate** (three-level check):

| Condition | Gate | Action |
|-----------|------|--------|
| `validation_status: unvalidated` | HARD BLOCK | Must run `/eval` before SHARE allowed |
| `auto-generated + lean-only` | BLOCK with override | Blocks until user confirms OR runs `/eval` |
| `validation_status: lean-only` AND intent to share publicly | WARNING + pragmatic requirement | Prompt: "Run `/eval --pragmatic` to confirm real-world utility before sharing" |
| `pragmatic_success_rate < 0.60` (PRAGMATIC_WEAK) | BLOCK | Must optimize against failing samples first |
| `pragmatic_success_rate < 0.40` (PRAGMATIC_FAIL) | HARD BLOCK | Deploy blocked — skill not fit for stated purpose |
| `lifecycle_status: deprecated` | HARD BLOCK | Cannot share deprecated skills |

> **Design rationale**: industry observations on unvalidated skills — high theoretical scores do
> not predict real-world utility. Requiring pragmatic test before public SHARE prevents
> GOLD-certified skills with `PRAGMATIC_WEAK` from polluting the shared registry.

Full spec: `refs/skill-registry.md §12`.

### Failure-Driven CREATE (`--from-failures` flag)

When user types `/create --from-failures`, replace the standard ELICIT phase with:

```
FAILURE ELICITATION (replaces Q1–Q8):
  1. Ask: "Paste 1–3 recent conversation snippets where the AI produced wrong or incomplete
           results for the task you want to automate. Press ENTER twice when done."
  2. EXTRACT from each snippet:
       - What was the user's intent?
       - What step failed (routing? execution? output format? error handling?)
       - What recovery action was needed?
  3. SYNTHESIZE failure patterns:
       - Recurring failure modes → pre-fill Workflow Error Handling section
       - Missed intents → pre-fill Negative Boundaries "Do NOT miss these cases"
       - Recurring task steps → pre-fill Workflow phases
  4. CONFIRM: Show the synthesized failure map and ask user to confirm or edit
  5. Resume standard Phase 2 (SELECT TEMPLATE) with the enriched context
```

> **Research basis**: Failure-Driven CREATE heuristic — domain-contextualized skill creation
> grounded in failure trajectories (Workflow Mining from historical interactions) produces
> skills significantly better aligned with real-world requirements than template-only generation.

> **Phase 9 (DELIVER) — mandatory activation guidance** `[CORE]`:
> Every DELIVER output MUST include these lines, verbatim, after the skill file:
> ```
> ─── Skill ready ───────────────────────────────────────────────────────
> Your skill "{skill_name}" has been created (LEAN: {N}/500 · est. {N*2} EVALUATE).
> Labels: generation_method=auto-generated · validation_status=lean-only
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
> ⚠ This skill is auto-generated (validation_status: lean-only).
>   Research shows self-generated skills have variable real-world utility.
>   Before sharing or deploying to production:
>     /eval           → run full 1000-pt evaluation (updates validation_status to "full-eval")
>     /eval --pragmatic → test against 3–5 real tasks (adds pragmatic_success_rate)
>
> About the two key sections in your skill file:
>   Skill Summary (§2): tells the AI WHEN to use this skill. Keep it specific — it's
>     the routing signal. If it's vague, the skill may trigger too rarely or too often.
>   Negative Boundaries (§3): tells the AI when NOT to use it. Without sharp boundaries,
>     similar-sounding requests will mis-trigger this skill. Edit these if you notice
>     false triggers.
>
> Next steps (optional): /lean · /eval · /eval --pragmatic · /opt · /share
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

> **Phase 4 (GENERATE) — mandatory elements** (sourced from SKILL.md Pattern + Skill Summary heuristic research):
> 1. **Skill Summary paragraph** (first content paragraph): ≤5 sentences densely encoding what / when / who / not-for.
>    Design heuristic: Skill Summary heuristic — skill body content is the **decisive routing signal**
>    (a large share of router attention (empirical, unpublished)); removing body materially degrades routing accuracy (observed internally).
> 2. **Negative Boundaries section**: explicit "Do NOT use for" list. Required before delivery.
>    Design heuristic: SKILL.md Pattern (2026) — without boundaries, semantically similar requests
>    mis-trigger skills. Negative Boundaries heuristic: negation reduces false trigger rate significantly.
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

