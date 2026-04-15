# Evaluation Benchmarks

> **Purpose**: Test cases for computing F1, MRR, and Trigger Accuracy across skill types.
> **Load**: During EVALUATE mode, §4 of `claude/skill-writer.md`
> **Format**: Each case has an `input`, expected `mode`, and expected `confidence` band.

---

## How to Use

1. Run each test case through the skill's mode router.
2. Record predicted mode and confidence score.
3. Compute F1 and MRR using the formulas in `claude/eval/rubrics.md`.
4. A skill PASSES if F1 ≥ 0.90, MRR ≥ 0.85, trigger_accuracy ≥ 0.90.

---

## §1  Skill-Framework Benchmarks

These test the `skill-writer.md` meta-skill's mode router (CREATE / EVALUATE / OPTIMIZE).

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

## §5  LEAN Mode Benchmarks

> LEAN is a fast 500-pt pre-screen used before full EVALUATE. These cases verify that
> LEAN correctly identifies passing (≥350) and failing (<350) skills based on static
> + heuristic checks without triggering the full 1000-pt pipeline.

### LEAN Pass Cases (expected score ≥ 350)

| ID | Skill Condition | Expected LEAN Result | Key Signals |
|----|-----------------|---------------------|-------------|
| LN-P-01 | Skill with all required fields, 5+ triggers, Skill Summary, Negative Boundaries | LEAN_PASS (≥350) | D1–D4 all pass |
| LN-P-02 | Skill with graph: block + all required sections | LEAN_PASS (≥370, +20 D8 bonus) | D8 composability bonus |
| LN-P-03 | Skill with 8 triggers (EN+ZH), dense Skill Summary | LEAN_PASS (≥350) | High D2 trigger score |

### LEAN Fail Cases (expected score <350)

| ID | Skill Condition | Expected LEAN Result | Failing Dimension |
|----|-----------------|---------------------|-------------------|
| LN-F-01 | Skill missing `triggers:` block | LEAN_FAIL (<350) | D2 (Trigger Coverage) |
| LN-F-02 | Skill missing Skill Summary and Negative Boundaries | LEAN_FAIL (<350) | D3 (Body Quality) |
| LN-F-03 | Skill missing `skill_tier:` and `use_to_evolve:` YAML fields | LEAN_FAIL (<350) | D1 (YAML Completeness) |
| LN-F-04 | Skill with `{{PLACEHOLDER}}` tokens remaining | LEAN_FAIL (<350) | D1 (YAML Completeness) |
| LN-F-05 | Skill with CWE-798 violation (hardcoded credential) | LEAN_FAIL (P0 abort) | D6 (Security) |

### LEAN Mode Trigger Cases

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| LN-T-01 | "lean eval" | LEAN | Canonical trigger |
| LN-T-02 | "快评" | LEAN | ZH canonical trigger |
| LN-T-03 | "quick score this skill" | LEAN | Confidence ≥ 0.80 |
| LN-T-04 | "pre-screen skill before evaluate" | LEAN | Confidence ≥ 0.75 |

---

## §6  Pragmatic Test Benchmarks

> Pragmatic Test (`/eval --pragmatic`) checks real-world utility beyond theoretical scores.
> These cases verify the pragmatic_success_rate computation and tier assignment.

### Pragmatic Test Execution Cases

| ID | Skill | Sample Task | Expected Outcome | Notes |
|----|-------|------------|-----------------|-------|
| PT-E-01 | git-diff-summarizer | User pastes a 50-line diff: "summarize this diff" | PASS | Core use case |
| PT-E-02 | git-diff-summarizer | User pastes empty string: "summarize this" | FAIL | Edge case: empty input |
| PT-E-03 | git-diff-summarizer | Binary diff output pasted | PARTIAL | Binary file skipped (documented) |
| PT-E-04 | api-tester | "test GET /users endpoint returns 200" | PASS | Happy path |
| PT-E-05 | api-tester | "test endpoint with malformed URL" | FAIL | Error handling |

### Pragmatic Test Tier Classification

| ID | pragmatic_success_rate | Expected Tier | Expected PRAGMATIC_LABEL | SHARE gate |
|----|----------------------|---------------|--------------------------|------------|
| PT-T-01 | ≥ 80% (4/5 PASS) | PRAGMATIC_GOOD | PRAGMATIC_VERIFIED | Allowed |
| PT-T-02 | 60–79% (3/5 PASS) | ADEQUATE | PRAGMATIC_ADEQUATE | Allowed with warning |
| PT-T-03 | 40–59% (2/5 PASS) | WEAK | PRAGMATIC_WEAK | Blocked: must re-eval |
| PT-T-04 | <40% (0–1/5 PASS) | FAIL | PRAGMATIC_FAIL | HARD BLOCK |

### Pragmatic Test Trigger Cases

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| PT-T-01 | "eval --pragmatic" | EVALUATE (pragmatic=true) | Canonical trigger |
| PT-T-02 | "pragmatic test my skill" | EVALUATE (pragmatic=true) | Alternate phrasing |
| PT-T-03 | "test against real tasks" | EVALUATE (pragmatic=true) | Confidence ≥ 0.80 |
| PT-T-04 | "实用性测试" | EVALUATE (pragmatic=true) | ZH trigger |

---

## §7  Behavioral Verifier Benchmarks

> Behavioral Verifier auto-generates 5 test cases (3 positive + 2 negative) from the
> Skill Summary and scores pass_rate. These cases verify the generation + scoring logic.

### Verifier Test Case Generation

| ID | Skill Summary Content | Expected Positive Cases | Expected Negative Cases |
|----|----------------------|------------------------|------------------------|
| BV-G-01 | Summary mentions "reads git diff" and "outputs changelog" | "summarize [diff]" → PASS | "execute git commands" → REJECT |
| BV-G-02 | Summary mentions "calls weather API" and "returns temperature" | "get temperature in [city]" → PASS | "modify weather data" → REJECT |
| BV-G-03 | Summary mentions "validates CSV schema" | "check schema compliance" → PASS | "delete records" → REJECT |

### Verifier Score Classification

| ID | pass_rate | Expected Verifier Score | Warning Issued |
|----|-----------|------------------------|----------------|
| BV-S-01 | 5/5 (1.00) | +20 pts (BEHAVIORAL_VERIFIED) | No |
| BV-S-02 | 4/5 (0.80) | +20 pts (BEHAVIORAL_VERIFIED) | No |
| BV-S-03 | 3/5 (0.60) | +10 pts (BEHAVIORAL_PARTIAL) | Warning: "3/5 verifier tests passed" |
| BV-S-04 | 2/5 (0.40) | +0 pts (BEHAVIORAL_WEAK) | WARNING: "Possible generator bias" |
| BV-S-05 | 0/5 (0.00) | +0 pts + FLAG | ESCALATE to HUMAN_REVIEW |

### Verifier Anti-Gaming Cases

| ID | Scenario | Expected Behavior |
|----|----------|------------------|
| BV-A-01 | Developer writes Skill Summary that mirrors test inputs verbatim | Verifier detects low semantic diversity; WARNING issued |
| BV-A-02 | Skill Summary omits scope (no NOT-FOR statements) | Negative cases cannot be generated; partial score only |
| BV-A-03 | Skill Summary is < 2 sentences | Insufficient context; verifier generates only 2 cases |

---

## §8  Failure-Driven CREATE Benchmarks

> `create --from-failures` uses failure trajectory inputs to generate skills targeting
> observed failure patterns (SkillForge research: arxiv:2604.08618).

### Failure Input Cases

| ID | Failure Description | Expected Skill Output | Key Sections |
|----|--------------------|-----------------------|--------------|
| FD-C-01 | "AI repeatedly fails to format SQL queries correctly" | SQL query formatter skill | Negative Boundaries: non-SQL queries; triggers: 'format SQL', 'fix SQL query' |
| FD-C-02 | "Agent misinterprets date format in API responses" | Date normalization skill | Canonical use case: ISO-8601 conversion |
| FD-C-03 | "Agent executes commands without user confirmation" | Confirmation gate skill | Red Lines: no unconfirmed execution; ASI05 checkpoint |

### Failure-Driven Mode Trigger Cases

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| FD-T-01 | "create skill from these failures: [...]" | CREATE (from-failures=true) | Canonical trigger |
| FD-T-02 | "build skill to fix this recurring error" | CREATE (from-failures=true) | Confidence ≥ 0.80 |
| FD-T-03 | "从失败案例创建技能" | CREATE (from-failures=true) | ZH trigger |
| FD-T-04 | "I keep getting errors with X, make a skill for it" | CREATE (from-failures=true) | Natural language failure description |

---

## §9  INSTALL / SHARE / COLLECT / GRAPH Mode Benchmarks

### INSTALL Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| IS-I-01 | "install skill-writer" | INSTALL | Canonical trigger |
| IS-I-02 | "安装skill-writer到Claude" | INSTALL | ZH trigger |
| IS-I-03 | "install to cursor" | INSTALL (platform=cursor) | Platform-specific |
| IS-I-04 | "install all platforms" | INSTALL (all=true) | Multi-platform |

### SHARE Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| SH-S-01 | "share my skill to the registry" | SHARE | Canonical trigger |
| SH-S-02 | "publish skill to OpenClaw" | SHARE | Platform-specific |
| SH-S-03 | "分享技能到注册表" | SHARE | ZH trigger |
| SH-S-04 | "push skill with BRONZE cert" | SHARE (requires cert check) | Certification gate |

### SHARE Security Gate Cases

| ID | Scenario | Expected Behavior |
|----|----------|------------------|
| SH-G-01 | Skill with `validation_status: "unvalidated"` | SHARE BLOCKED: must run /eval first |
| SH-G-02 | Skill with `validation_status: "lean-only"` | WARNING: prompt for full eval before sharing |
| SH-G-03 | Skill with CWE-798 (hardcoded credential) in body | SHARE HARD BLOCK: P0 security violation |
| SH-G-04 | Skill from UNTRUSTED source without signature | SHARE BLOCKED: run supply chain check first |

### COLLECT Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| CO-C-01 | "collect session" | COLLECT | Canonical trigger |
| CO-C-02 | "record this session for skill evolution" | COLLECT | Alternate phrasing |
| CO-C-03 | "采集当前会话" | COLLECT | ZH trigger |

### GRAPH Mode

| ID | Input | Expected Mode | Notes |
|----|-------|--------------|-------|
| GR-G-01 | "graph view" | GRAPH | Canonical trigger |
| GR-G-02 | "技能图" | GRAPH | ZH canonical |
| GR-G-03 | "show skill dependencies" | GRAPH | Alternate phrasing |
| GR-G-04 | "plan skill bundle for my project" | GRAPH (plan=true) | Bundle planning |
| GR-G-05 | "resolve all skill dependencies for deploy" | GRAPH (resolve=true) | Dependency resolution |

---

## §10  Minimum Pass Criteria (Summary)

| Skill Type | Min F1 | Min MRR | Min Trigger Accuracy | Min Test Cases |
|------------|--------|---------|---------------------|----------------|
| skill-writer (§1) | 0.90 | 0.85 | 0.90 | 29 |
| api-integration (§2) | 0.90 | 0.85 | 0.90 | 13 |
| data-pipeline (§3) | 0.90 | 0.85 | 0.90 | 12 |
| workflow-automation (§4) | 0.90 | 0.85 | 0.90 | 12 |
| LEAN mode (§5) | n/a | n/a | 0.80 | 4 trigger cases |
| Pragmatic Test (§6) | n/a | n/a | 0.80 | 4 trigger cases |
| Behavioral Verifier (§7) | n/a | n/a | n/a | 5 per skill |
| Failure-Driven CREATE (§8) | 0.85 | 0.80 | 0.80 | 4 trigger cases |
| INSTALL/SHARE/COLLECT/GRAPH (§9) | n/a | n/a | 0.80 | 4 each mode |

A skill may add domain-specific test cases beyond these minimums.

---

## §10a  Frozen Benchmark Anchors (Deterministic Phase 3 Scoring)

> **Purpose**: Reduce LLM evaluation variance by replacing heuristic routing tests with a
> fixed set of frozen test cases that never change between evaluations. These cases have
> deterministic expected outputs — no LLM judgment required for pass/fail decision.
>
> **Research basis**: SkillRouter (arxiv:2603.22455) used 35,000 labeled examples with fixed
> correct answers, achieving deterministic 74% routing accuracy with zero evaluation variance.
>
> **Integration**: These cases replace 60 pts of the "Trigger Routing Accuracy" sub-category
> in Phase 3 (eval/rubrics.md §5). The remaining 60 pts of trigger routing remain LLM-evaluated
> against the skill's own benchmark cases. Total Phase 3 max remains 400 pts.
>
> **Stability rule**: Frozen anchor cases are NEVER modified mid-version. Updates only allowed
> at major version bumps (v4.0+) with a 90-day grace period for recertification.

### §10a.1  Frozen Anchor Set — skill-writer meta-skill (20 cases, 60 pts)

Each correct prediction = 3 pts. All 20 correct = 60 pts.

| Anchor ID | Input | Expected Mode | Rationale |
|-----------|-------|--------------|-----------|
| ANC-001 | `"create a skill"` | CREATE | Canonical trigger — must always match |
| ANC-002 | `"创建技能"` | CREATE | ZH canonical — must always match |
| ANC-003 | `"evaluate this skill"` | EVALUATE | Canonical trigger |
| ANC-004 | `"评测技能"` | EVALUATE | ZH canonical |
| ANC-005 | `"lean eval"` | LEAN | Canonical trigger |
| ANC-006 | `"快评"` | LEAN | ZH canonical |
| ANC-007 | `"optimize this skill"` | OPTIMIZE | Canonical trigger |
| ANC-008 | `"优化技能"` | OPTIMIZE | ZH canonical |
| ANC-009 | `"install skill-writer"` | INSTALL | Framework install — must not route to SHARE |
| ANC-010 | `"share my skill"` | SHARE | User's own skill — must not route to INSTALL |
| ANC-011 | `"collect session"` | COLLECT | Canonical trigger |
| ANC-012 | `"graph view"` | GRAPH | Canonical trigger |
| ANC-013 | `"install my skill to claude"` | SHARE | "my skill" → SHARE (not INSTALL) |
| ANC-014 | `"write me a script"` | NONE (negative) | Must NOT trigger any skill mode |
| ANC-015 | `"explain this code"` | NONE (negative) | Must NOT trigger any skill mode |
| ANC-016 | `"build a skill that sends emails"` | CREATE | "build" + "skill" → CREATE |
| ANC-017 | `"score my skill"` | EVALUATE | "score" → EVALUATE |
| ANC-018 | `"improve skill trigger accuracy"` | OPTIMIZE | "improve" → OPTIMIZE |
| ANC-019 | `"read [URL] and install"` | INSTALL | Agent install pattern |
| ANC-020 | `"from failures: agent kept failing on X"` | CREATE (from-failures=true) | Failure-driven create |

### §10a.2  Anchor Scoring Rules

```
For each anchor case:
  predicted_mode = apply skill's mode router to anchor input
  IF predicted_mode == expected_mode (or "NONE" for negative cases): +3 pts
  ELSE: +0 pts

  For negative cases (ANC-014, ANC-015):
    "NONE" means the skill produced a clarifying question or correctly said
    "this doesn't match my scope" — any definite mode assignment = FAIL (0 pts)

anchor_score = sum of all case scores (max 60)
```

### §10a.3  Anchor Fail Analysis

When an anchor case fails, it indicates a structural routing defect — not just a quality gap:

| Failing Anchors | Root Cause | Required Fix |
|-----------------|------------|-------------|
| ANC-001 or ANC-002 (CREATE) | Canonical trigger broken | Check triggers.en/zh field for "create" |
| ANC-009 vs ANC-013 confused | INSTALL/SHARE disambiguation broken | Review §3 Mode Router routing note |
| ANC-014 or ANC-015 (negatives) | No negative boundary | Add Negative Boundaries section |
| Any ZH anchor (ANC-002,004,006,008,012) | Missing ZH triggers | Add ZH trigger keywords |
| ANC-019 (Agent Install) | INSTALL pattern not recognized | Add "read.*install" pattern to INSTALL keywords |

---

## §11  Adding Custom Benchmark Cases

When creating a new skill with `skill-writer.md CREATE mode`, add at least:
- 5 positive cases per mode
- 2 ambiguous / edge cases per mode
- 2 negative / anti-trigger cases
- 2 security-boundary cases (if the skill handles user input)
- 5 Behavioral Verifier cases (auto-generated from Skill Summary; verify manually)
- 3–5 Pragmatic Test samples if skill has real-world utility claims

Format:
```markdown
| ID | Input | Expected Mode | Min Confidence | Notes |
|----|-------|--------------|----------------|-------|
| <SKILL_PREFIX>-<MODE_PREFIX>-01 | "<test input>" | <MODE> | 0.90 | <context> |
```
