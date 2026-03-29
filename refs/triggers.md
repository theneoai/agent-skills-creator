# Trigger Patterns Reference

> **Purpose**: Detailed trigger patterns for skill mode routing
> **Load**: When §2 Invocation is accessed
> **Language**: Bilingual (EN/ZH)

---

## Primary Triggers (中英双语)

### CREATE Mode

| Priority | English Keywords | 中文关键词 | Score |
|----------|-----------------|------------|-------|
| 1 | "create skill", "build skill", "make skill" | "创建技能", "创建skill", "新建技能" | +3 |
| 2 | "new skill", "develop skill", "add skill" | "开发技能", "制作技能", "生成技能" | +2 |
| 3 | "generate skill", "scaffold skill" | "生成技能", "脚手架" | +1 |

### EVALUATE Mode

| Priority | English Keywords | 中文关键词 | Score |
|----------|-----------------|------------|-------|
| 1 | "evaluate skill", "test skill", "score skill" | "评估技能", "测试技能", "打分技能" | +3 |
| 2 | "review skill", "assess skill", "check skill" | "审查技能", "验证技能", "检查技能" | +2 |
| 3 | "validate skill", "benchmark skill" | "评分", "基准测试" | +1 |

### RESTORE Mode

| Priority | English Keywords | 中文关键词 | Score |
|----------|-----------------|------------|-------|
| 1 | "restore skill", "fix skill", "repair skill" | "恢复技能", "修复技能", "还原技能" | +3 |
| 2 | "recover skill", "undo", "rollback skill" | "补救技能", "撤销", "回滚" | +2 |
| 3 | "broken skill", "corrupt skill" | "损坏技能", "失效技能" | +1 |

### SECURITY Mode

| Priority | English Keywords | 中文关键词 | Score |
|----------|-----------------|------------|-------|
| 1 | "security audit", "OWASP", "vulnerability" | "安全审计", "漏洞扫描", "OWASP检查" | +3 |
| 2 | "CWE", "security check", "penetration test" | "安全检查", "渗透测试", "安全扫描" | +2 |
| 3 | "security scan", "exploit check" | "入侵检测", "攻击检测" | +1 |

### OPTIMIZE Mode

| Priority | English Keywords | 中文关键词 | Score |
|----------|-----------------|------------|-------|
| 1 | "optimize skill", "improve skill", "evolve skill" | "优化技能", "改进技能", "进化技能" | +3 |
| 2 | "enhance skill", "tune skill", "refine skill" | "提升技能", "调优技能", "完善技能" | +2 |
| 3 | "upgrade skill", "performance" | "增强技能", "性能优化" | +1 |

---

## Secondary Triggers (上下文触发)

### Context Patterns

| Mode | English Context | 中文上下文 |
|------|----------------|-----------|
| CREATE | "generate", "template", "starter", "boilerplate" | "模板", "起始框架", "脚手架" |
| EVALUATE | "compare", "grade", "rate", "measure" | "比较", "评级", "打分" |
| RESTORE | "broken", "corrupt", "invalid", "damage" | "损坏", "破坏", "崩溃" |
| SECURITY | "injection", "XSS", "CSRF", "breach" | "注入", "跨站", "攻击" |
| OPTIMIZE | "speed", "efficiency", "refactor", "DRY" | "速度", "效率", "重构" |

---

## Negative Patterns (反模式)

### Anti-Triggers by Mode

| Mode | English Negative | 中文反模式 |
|------|----------------|-----------|
| CREATE | "don't create", "skill exists", "check if exists" | "不要创建", "技能已存在" |
| EVALUATE | "evaluate code", "test function", "lint" | "评估代码", "测试函数" |
| RESTORE | "restore file", "recover data" | "恢复文件", "恢复数据" |
| SECURITY | "secure password", "encrypt data" | "加密密码", "保护数据" |
| OPTIMIZE | "optimize algorithm", "speed up" | "优化算法", "加速" |

---

## Confidence Scoring Formula

```
confidence = (
  primary_match * 0.5 +
  secondary_match * 0.2 +
  context_match * 0.2 +
  no_negative * 0.1
)
```

### Confidence Thresholds

| Confidence | Action |
|-----------|--------|
| ≥ 0.80 | Use detected mode |
| ≥ 0.60 | Use with warning |
| < 0.60 | Ask user clarification |
| = 0.30 | Default to EVALUATE |

---

## Disambiguation Rules

### Rule 1: Exact Match First
- Input exactly matches primary keyword → immediate mode selection
- Confidence: 0.95

### Rule 2: Keyword Scoring
- Count matches per mode
- Highest total score wins
- Tie-breaker: higher priority mode

### Rule 3: Context Analysis
- When scores tie, analyze surrounding context
- Secondary keywords provide additional scoring

### Rule 4: Negative Filter
- Any negative pattern excludes that mode
- Re-score remaining modes

### Rule 5: User Clarification
- Confidence < 0.6 → ask user
- Present top 2 candidates with reasoning

### Rule 6: Default Fallback
- Still ambiguous → default to EVALUATE
- Confidence: 0.30

### Rule 7: Language Detection
- EN input: English keywords weight = 1.0, Chinese = 0.3
- ZH input: Chinese keywords weight = 1.0, English = 0.3
- Mixed: both at full weight

### Rule 8: Cross-Language Matching
- Both EN and ZH keywords match → highest confidence
- Example: "创建create skill" → CREATE (both languages)

---

## Example Trigger Analysis

| Input | Mode | Confidence | Reasoning |
|-------|------|-----------|----------|
| "create a new skill" | CREATE | 0.95 | Exact primary match |
| "optimize my skill" | OPTIMIZE | 0.85 | Primary + context |
| "fix the broken skill" | RESTORE | 0.80 | Primary + secondary |
| "don't create skill, evaluate it" | EVALUATE | 0.70 | Negative filter |
| "skill management" | EVALUATE | 0.60 | Default + context |
| "help with skills" | EVALUATE | 0.30 | Low confidence, ask |

---

## Usage

This file is loaded when §2 Invocation section is accessed in SKILL.md.
Load with: `source reference/triggers.md` or include via Markdown reference.
