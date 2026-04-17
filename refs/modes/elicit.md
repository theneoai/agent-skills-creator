<!-- Extracted from claude/skill-writer.md §8 — full reference -->

## §8  Inversion — Requirement Elicitation

**Rule**: Phase 3 (PLAN) MUST NOT begin until all answers are received.
Ask **one question at a time**. Wait for answer before next question.

### CREATE questions — ask one at a time, wait for answer before next

| Q | Question | → Shapes |
|---|----------|---------|
| 1 | What's the one-sentence purpose? | Skill Summary + triggers |
| 2 | Who uses it? (persona) | Examples + language choice |
| 3 | What skill tier? (planning/functional/atomic) | EVALUATE Phase 2 weights |
| 4 | What are the 3–5 main workflow steps? | Workflow section |
| 5 | What should it NEVER do? (negative boundaries) | §N Negative Boundaries |
| 6 | Trigger phrases the user would say? | YAML triggers block |
| 7 | Any reference files / tools it needs? | Dependencies section |
| 8 | Example input → expected output? | §Usage Examples |

**Skip handling** (Q5 and Q6 are mandatory; others have defaults):
- Q5 vague/skip → auto-fill: "Avoid irreversible actions without explicit confirmation." + WARNING
- Q6 vague/skip → auto-generate triggers from skill name + description keywords (EN + ZH). Note: ~60% coverage — add natural phrases before publishing.
- Vague-answer probe (Q1–Q4, Q7–Q8): if answer ≤3 words or domain-only (e.g. "git stuff"), ask ONE follow-up probe (a/b/c options). Accept after one probe regardless.

**Template-specific follow-up** (ask after Q4 if applicable):
- `api-integration`: "Which HTTP methods / authentication mechanism?"
- `data-pipeline`: "What is the data schema / transformation rules?"
- `workflow-automation`: "What is the maximum acceptable latency / retry policy?"

### EVALUATE questions (ask all):
1. "请提供skill文件路径或内容。 / Provide the skill file path or content."
2. "评测重点在哪个维度？ / Any specific evaluation focus?"
3. "需要对比其他skill吗？ / Compare against another skill?"

### OPTIMIZE questions (ask all):
1. "请提供当前评测报告（分数 + 最低维度）。 / Provide the current eval report."
2. "已尝试过哪些优化？ / What optimizations were already attempted?"

---

