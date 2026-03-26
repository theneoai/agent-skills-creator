# Tools Reference

> Complete documentation for all skill-manager scripts.

---

## Validation Scripts

### validate.sh — Spec Compliance Check

```bash
./scripts/validate.sh path/to/SKILL.md
```

**What it checks:**
- Frontmatter completeness (name, description, license, metadata)
- YAML syntax validity
- Required fields presence
- agentskills.io spec compliance

---

## Scoring Scripts

### score.sh — Classic Heuristic (6 dimensions)

```bash
./scripts/score.sh path/to/SKILL.md
```

**Method:** Pure shell grep-based analysis (~5 seconds)

| Dimension | Weight | Detection |
|-----------|--------|-----------|
| System Prompt | 20% | Keyword presence |
| Domain Knowledge | 20% | Specific data count |
| Workflow | 20% | Phase/step detection |
| Error Handling | 15% | Error keyword density |
| Examples | 15% | Section count |
| Metadata | 10% | Frontmatter fields |

**Best for:** CI pipelines, quick feedback

---

### score-v2.sh — V2 Enhanced (6+2 dimensions)

```bash
./scripts/score-v2.sh path/to/SKILL.md
```

**NEW Dimensions:**
- **Internal Consistency (15%)**: Cross-references, versioned, dated, no placeholders
- **Executability (15%)**: Examples with input/output, actionable commands, vague language check

**Improvements:**
- Context-aware keyword detection (not just isolated keywords)
- Steps with actual content validation
- Anti-gaming: placeholder detection
- Version/dating enforcement

| Dimension | Weight |
|-----------|--------|
| System Prompt | 15% |
| Domain Knowledge | 20% |
| Workflow | 20% |
| Consistency | 15% |
| Executability | 15% |
| Metadata | 15% |

**Best for:** Deep analysis, quality improvement guidance

---

### score-secure.sh — Secure LLM Scoring

```bash
./scripts/score-secure.sh path/to/SKILL.md
```

**Security Features:**
- **Input Sanitization**: Removes prompt injection patterns
- **Output Validation**: JSON structure verification, range checking
- **API Key Security**: Minimal exposure in process arguments

**Scoring:**
- 40% base score (from score-v2.sh)
- 60% LLM evaluation (GPT-4o or Claude)

**LLM Evaluation:**
- Clarity
- Usefulness
- Completeness
- Honesty (about limitations)

**Requires:** `OPENAI_API_KEY` or `ANTHROPIC_API_KEY`

**Best for:** Production validation with security

---

### score-llm.sh — LLM-Enhanced (Hybrid)

```bash
./scripts/score-llm.sh path/to/SKILL.md
```

**Method:** Shell format check (30%) + LLM semantic (70%)

**Requirements:**
- `OPENAI_API_KEY` or `ANTHROPIC_API_KEY`

**Best for:** Pre-commit deep evaluation

---

### score-multi.sh — Multi-LLM Cross-Validation

```bash
./scripts/score-multi.sh path/to/SKILL.md
```

**Anti-Gaming Checks:**
1. Keyword density (>5% = suspicious)
2. Repetition detection
3. Empty content detection
4. Placeholder detection
5. Markdown validity

**Multi-LLM:**
- GPT-4o evaluation
- Claude evaluation
- Cross-validated scoring

**Best for:** Critical evaluation, before publishing

---

## Evaluation Scripts

### eval.sh — Interactive Dual-Track

```bash
./scripts/eval.sh path/to/SKILL.md [depth]
```

**Depth:** quick (5 min) | standard (20 min) | deep (60 min) | certification (2 hrs)

---

### certify.sh — Full Certification

```bash
./scripts/certify.sh path/to/SKILL.md
```

**Certification checklist:**
- [ ] Text Score ≥ 8.0
- [ ] Runtime Score ≥ 8.0
- [ ] Variance < 1.0
- [ ] All dimensions ≥ 6.0
- [ ] Security audit passed

---

## Tuning Scripts

### tune.sh — Autonomous Optimization

```bash
./scripts/tune.sh path/to/SKILL.md [rounds]
```

**Autonomous loop:**
1. Read SKILL.md
2. Identify improvement
3. Implement change
4. Run score
5. Keep if improved, reset if worse
6. Log to results.tsv

**Auto-commits every 10 rounds**

---

## Workflow Examples

### Quick (CI)
```bash
./validate.sh SKILL.md && ./score.sh SKILL.md
```

### Deep Analysis
```bash
./validate.sh SKILL.md && ./score-v2.sh SKILL.md
```

### Production Validation
```bash
./validate.sh SKILL.md
./score-secure.sh SKILL.md  # With LLM
./eval.sh SKILL.md standard
./certify.sh SKILL.md
```

### Autonomous Optimization
```bash
./tune.sh SKILL.md 1000
```

---

## API Key Setup

```bash
# OpenAI
export OPENAI_API_KEY="sk-..."

# Anthropic
export ANTHROPIC_API_KEY="sk-ant-..."
```

---

## Version History

| Version | Key Changes |
|---------|-------------|
| v1.0 | Classic 6-dimension scoring |
| v2.0 | Added LLM evaluation |
| v2.1 | Added score-v2.sh with consistency & executability |
| v2.2 | Added score-secure.sh with anti-injection |
