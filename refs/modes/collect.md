<!-- Extracted from claude/skill-writer.md §19 — full reference -->

## §19  COLLECT + AGGREGATE Mode

> **COLLECT** `[CORE]` — Record one session's skill performance as a structured artifact.
> **AGGREGATE** `[EXTENDED — basic flow available]` — Synthesize 2+ COLLECT artifacts into ranked improvement priorities.
> Both are invoked via COLLECT mode; AGGREGATE runs after you have multiple artifacts.

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

**Inspired by**: collective-evolution design collective evolution framework (arxiv.org/abs/2604.08377)
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

4. CLASSIFY LESSON TYPE (reinforcement-style evolution design-inspired, new in v3.1.0):
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

