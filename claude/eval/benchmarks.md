# Evaluation Benchmarks

> **Purpose**: Test cases for computing F1, MRR, and Trigger Accuracy across skill types.
> **Load**: During EVALUATE mode, §4 of `claude/skill-framework.md`
> **Format**: Each case has an `input`, expected `mode`, and expected `confidence` band.

---

## How to Use

1. Run each test case through the skill's mode router.
2. Record predicted mode and confidence score.
3. Compute F1 and MRR using the formulas in `claude/eval/rubrics.md`.
4. A skill PASSES if F1 ≥ 0.90, MRR ≥ 0.85, trigger_accuracy ≥ 0.90.

---

## §1  Skill-Framework Benchmarks

These test the `skill-framework.md` meta-skill's mode router (CREATE / EVALUATE / OPTIMIZE).

### CREATE Mode — Positive Cases

| ID | Input | Expected Mode | Min Confidence |
|----|-------|--------------|----------------|
| CF-C-01 | "create a new skill for querying databases" | CREATE | 0.90 |
| CF-C-02 | "build a skill that integrates Slack API" | CREATE | 0.90 |
| CF-C-03 | "新建一个处理CSV文件的skill" | CREATE | 0.90 |
| CF-C-04 | "scaffold a workflow automation skill" | CREATE | 0.85 |
| CF-C-05 | "I need a skill that summarizes long documents" | CREATE | 0.85 |
| CF-C-06 | "开发一个调用天气API的技能" | CREATE | 0.90 |
| CF-C-07 | "generate a skill for data transformation" | CREATE | 0.85 |
| CF-C-08 | "make me a skill that can send emails" | CREATE | 0.85 |

### EVALUATE Mode — Positive Cases

| ID | Input | Expected Mode | Min Confidence |
|----|-------|--------------|----------------|
| CF-E-01 | "evaluate this skill: weather-query" | EVALUATE | 0.90 |
| CF-E-02 | "test the skill and give me F1 score" | EVALUATE | 0.90 |
| CF-E-03 | "评测这个skill的性能" | EVALUATE | 0.90 |
| CF-E-04 | "score my skill against the benchmarks" | EVALUATE | 0.85 |
| CF-E-05 | "assess skill quality for sql-query-skill" | EVALUATE | 0.85 |
| CF-E-06 | "run quality check on skill file" | EVALUATE | 0.85 |
| CF-E-07 | "验证skill是否符合质量标准" | EVALUATE | 0.90 |
| CF-E-08 | "benchmark the trigger accuracy" | EVALUATE | 0.85 |

### OPTIMIZE Mode — Positive Cases

| ID | Input | Expected Mode | Min Confidence |
|----|-------|--------------|----------------|
| CF-O-01 | "optimize the skill, F1 is 0.82" | OPTIMIZE | 0.90 |
| CF-O-02 | "improve skill trigger accuracy" | OPTIMIZE | 0.90 |
| CF-O-03 | "优化这个skill的性能" | OPTIMIZE | 0.90 |
| CF-O-04 | "enhance skill to meet quality thresholds" | OPTIMIZE | 0.85 |
| CF-O-05 | "the skill's MRR dropped, please fix it" | OPTIMIZE | 0.85 |
| CF-O-06 | "提升skill的触发准确率" | OPTIMIZE | 0.85 |
| CF-O-07 | "refine skill structure to pass rubrics" | OPTIMIZE | 0.85 |
| CF-O-08 | "tune the skill, it's failing evaluations" | OPTIMIZE | 0.85 |

### Ambiguous / Edge Cases

| ID | Input | Expected Mode | Behavior |
|----|-------|--------------|----------|
| CF-A-01 | "skill help" | EVALUATE | Default; confidence < 0.70 → ask user |
| CF-A-02 | "don't create, evaluate my skill" | EVALUATE | Negative filter → EVALUATE |
| CF-A-03 | "create and then evaluate skill" | CREATE | CREATE first; chain EVALUATE after |
| CF-A-04 | "fix my skill quality issues" | OPTIMIZE | "fix quality" → OPTIMIZE |
| CF-A-05 | "what can this framework do?" | — | Meta-query → describe modes |

---

## §2  API Integration Skill Benchmarks

Template: `claude/templates/api-integration.md`

### QUERY Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| AI-Q-01 | "get current temperature in Tokyo" | QUERY | Location extraction |
| AI-Q-02 | "fetch user profile for ID 12345" | QUERY | ID extraction |
| AI-Q-03 | "retrieve latest exchange rates" | QUERY | No parameters |
| AI-Q-04 | "查询北京今天的天气" | QUERY | ZH input |
| AI-Q-05 | "look up order status for ORD-9876" | QUERY | Order ID extraction |

### BATCH Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| AI-B-01 | "get weather for London, Paris, Berlin" | BATCH | 3-item list |
| AI-B-02 | "批量查询以下用户：user1, user2, user3" | BATCH | ZH batch input |
| AI-B-03 | "fetch data for all items in this list: [...]" | BATCH | Array input |

### Error / Security Cases

| ID | Input | Expected Behavior |
|----|-------|------------------|
| AI-S-01 | Input containing `'; DROP TABLE --` | Sanitize; do not inject into URL |
| AI-S-02 | API key passed in user message | Reject + warn: "Do not pass credentials in messages" |
| AI-S-03 | Request 10,000 batch items | Reject if > BATCH_LIMIT; ask confirmation |

---

## §3  Data Pipeline Skill Benchmarks

Template: `claude/templates/data-pipeline.md`

### TRANSFORM Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| DP-T-01 | "convert sales.csv to JSON format" | TRANSFORM | Format conversion |
| DP-T-02 | "normalize all date fields to ISO-8601" | TRANSFORM | Field normalization |
| DP-T-03 | "转换数据并去除重复记录" | TRANSFORM | ZH; dedup operation |
| DP-T-04 | "parse the log file and extract error lines" | TRANSFORM | Filter transform |

### VALIDATE Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| DP-V-01 | "validate data against schema" | VALIDATE | Schema check |
| DP-V-02 | "check for null values in required fields" | VALIDATE | Null check |
| DP-V-03 | "验证数据完整性" | VALIDATE | ZH input |
| DP-V-04 | "run data quality checks on the file" | VALIDATE | Quality check |

### INGEST / EXPORT

| ID | Input | Expected Mode |
|----|-------|--------------|
| DP-I-01 | "load the data from orders.csv" | INGEST |
| DP-I-02 | "import dataset into the pipeline" | INGEST |
| DP-E-01 | "export results to output.json" | EXPORT |
| DP-E-02 | "导出处理后的数据" | EXPORT |

---

## §4  Workflow Automation Skill Benchmarks

Template: `claude/templates/workflow-automation.md`

### RUN Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| WA-R-01 | "run the deployment workflow" | RUN | Direct command |
| WA-R-02 | "execute the data sync workflow on staging" | RUN | With target env |
| WA-R-03 | "开始执行备份流程" | RUN | ZH input |
| WA-R-04 | "start the onboarding workflow for user@example.com" | RUN | With parameter |

### DRY-RUN Mode

| ID | Input | Expected Mode |
|----|-------|--------------|
| WA-D-01 | "dry-run the deployment workflow" | DRY-RUN |
| WA-D-02 | "show me what would happen if I run this" | DRY-RUN |
| WA-D-03 | "simulate the workflow without executing" | DRY-RUN |
| WA-D-04 | "预演部署流程" | DRY-RUN |

### STATUS / ROLLBACK

| ID | Input | Expected Mode |
|----|-------|--------------|
| WA-S-01 | "what's the status of the workflow?" | STATUS |
| WA-S-02 | "rollback the last workflow run" | ROLLBACK |
| WA-S-03 | "undo the changes from the workflow" | ROLLBACK |
| WA-S-04 | "查看工作流执行状态" | STATUS |

---

## §5  Minimum Pass Criteria (Summary)

| Skill Type | Min F1 | Min MRR | Min Trigger Accuracy | Min Test Cases |
|------------|--------|---------|---------------------|----------------|
| skill-framework | 0.90 | 0.85 | 0.90 | 29 (§1 above) |
| api-integration | 0.90 | 0.85 | 0.90 | 13 (§2 above) |
| data-pipeline | 0.90 | 0.85 | 0.90 | 12 (§3 above) |
| workflow-automation | 0.90 | 0.85 | 0.90 | 12 (§4 above) |

A skill may add domain-specific test cases beyond these minimums.

---

## §6  Adding Custom Benchmark Cases

When creating a new skill with `skill-framework.md CREATE mode`, add at least:
- 5 positive cases per mode
- 2 ambiguous / edge cases per mode
- 2 negative / anti-trigger cases
- 2 security-boundary cases (if the skill handles user input)

Format:
```markdown
| ID | Input | Expected Mode | Min Confidence | Notes |
|----|-------|--------------|----------------|-------|
| <SKILL_PREFIX>-<MODE_PREFIX>-01 | "<test input>" | <MODE> | 0.90 | <context> |
```
