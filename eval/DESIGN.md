# unified-skill-eval v1.0

> Agent Skill 统一评估框架设计文档
> 
> **总分**: 1000pts
> **更新时间**: 2026-03-28

---

## 一、框架概述

```
┌──────────────────────────────────────────────────────────────────────┐
│                    unified-skill-eval v1.0                           │
│                    Agent Skill 统一评估框架                             │
├──────────────────────────────────────────────────────────────────────┤
│  INPUT                                                              │
│    └─ SKILL.md 或 skill-directory 或 remote git URL                 │
├──────────────────────────────────────────────────────────────────────┤
│  PIPELINE (4 phases)                                                │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌──────────┐ │
│  │   PARSE &    │→ │    TEXT       │→ │   RUNTIME     │→ │  CERTIFY  │ │
│  │   VALIDATE   │  │    SCORE      │  │    SCORE      │  │  & REPORT │ │
│  │   100pts     │  │   350pts      │  │   450pts      │  │  100pts   │ │
│  └───────────────┘  └───────────────┘  └───────────────┘  └──────────┘ │
├──────────────────────────────────────────────────────────────────────┤
│  OUTPUT                                                             │
│    ├─ report.json     # Machine-readable (LLM consumption)           │
│    └─ report.html     # Human-readable (browser, bilingual zh/en)    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 二、评估分项明细

### Phase 1: Parse & Validate (100pts)

| 检查项 | 分值 | 通过标准 |
|--------|------|---------|
| YAML Frontmatter | 30pts | name + description + license 完整 |
| 三节结构 | 30pts | §1.1 + §1.2 + §1.3 齐全 |
| Trigger 列表 | 25pts | CREATE/EVALUATE/RESTORE/TUNE 各 ≥5 |
| 无占位符 | 15pts | 0 个 [TODO]/[FIXME]/TBD |

### Phase 2: Text Score (350pts)

| 维度 | 分值 | 权重 | 卓越标准 |
|------|------|------|---------|
| System Prompt | 70pts | 20% | §1.1 + §1.2 + §1.3 + 约束条件 |
| Domain Knowledge | 70pts | 20% | 具体数据 ≥10 处 |
| Workflow | 70pts | 20% | 4-6 阶段 + Done/Fail |
| Error Handling | 55pts | 15% | ≥5 具名失败 + 恢复策略 |
| Examples | 55pts | 15% | ≥5 场景 + 输入/输出/验证 |
| Metadata | 30pts | 10% | agentskills-spec 合规 |

### Phase 3: Runtime Score (450pts)

| 检查项 | 分值 | 权重 | 测量方法 |
|--------|------|------|---------|
| Identity Consistency | 80pts | 18% | 角色混淆测试 (20+ 轮对话) |
| Framework Execution | 70pts | 16% | 工具调用/记忆结构访问 |
| Output Actionability | 70pts | 16% | 参数完整性检测 |
| Knowledge Accuracy | 50pts | 11% | 幻觉检测 (factual queries) |
| Conversation Stability | 50pts | 11% | MultiTurnPassRate (≥85%) |
| Trace Compliance | 50pts | 11% | AgentPex 行为规则遵从 |
| Long-Document | 30pts | 7% | 100K token 处理稳定性 |
| Multi-Agent | 25pts | 5% | 协作模式测试 |
| Trigger Accuracy | 25pts | 5% | F1/MRR 综合 |

### Phase 4: Certify & Report (100pts)

| 检查项 | 分值 | 标准 |
|--------|------|------|
| Variance 控制 | 40pts | \|Text - Runtime\| < 20pts |
| 认证等级 | 30pts | 等级判定正确 |
| 报告完整性 | 20pts | JSON + HTML 双输出 |
| 安全门槛 | 10pts | CWE-798/89/78/22 全过 |

---

## 三、核心指标阈值

| 指标 | 阈值 | 备注 |
|------|------|------|
| F1 Score | ≥ 0.90 | Anthropic Skills (2024) |
| MRR | ≥ 0.85 | Anthropic Skills (2024) |
| Trigger Accuracy | ≥ 0.99 | Anthropic Skills 内部基准 |
| Text Score | ≥ 280pts | 350pts 制下 ≥80% |
| Runtime Score | ≥ 360pts | 450pts 制下 ≥80% |
| Variance | < 150pts | \|Text - Runtime\| |

---

## 四、认证等级 (1000pts制)

| 等级 | 总分门槛 | Text | Runtime | Variance |
|------|----------|------|---------|----------|
| **PLATINUM** | ≥ 950pts | ≥ 330pts | ≥ 430pts | < 20pts |
| **GOLD** | ≥ 900pts | ≥ 315pts | ≥ 405pts | < 50pts |
| **SILVER** | ≥ 800pts | ≥ 280pts | ≥ 360pts | < 80pts |
| **BRONZE** | ≥ 700pts | ≥ 245pts | ≥ 315pts | < 150pts |

> **注意**: 方差阈值已调整为更宽松的值，因为 LLM 评估本身有随机性。真实 LLM 评估与文本评分的方差在 100-150 之间是正常的。

---

## 四.1、方差评分 (40pts制)

| Variance | 得分 | 说明 |
|----------|------|------|
| < 30 | 40/40 | 优秀 |
| < 50 | 30/40 | 良好 |
| < 70 | 20/40 | 一般 |
| < 100 | 10/40 | 较差 |
| < 150 | 5/40 | 可接受 |
| ≥ 150 | 0/40 | 不可接受 |

---

## 五、安全检查

### CWE 覆盖

| CWE | 检查项 | 检查阶段 |
|-----|--------|---------|
| CWE-798 | 硬编码凭证 (API keys, passwords) | Parse |
| CWE-89 | SQL 注入风险 | Text Score |
| CWE-78 | 命令注入 (eval/exec) | Text Score |
| CWE-22 | 路径遍历 (../etc/passwd) | Parse |
| CWE-200 | 日志泄露敏感信息 | Runtime |

### 安全门槛

```
P0 问题 → 立即拒绝认证
其他安全问题 → 扣分但不阻止认证
```

---

## 六、触发准确度技术手段

| 技术手段 | 说明 | 测试方法 |
|---------|------|---------|
| 双向匹配 | "skill" ∩ 关键词 (顺序无关) | corpus 测试 |
| 同义词覆盖 | 中/英文同义词全量覆盖 | 词库覆盖率 |
| 防注入 | prompt injection 清洗 | 注入样本测试 |
| 防滥用 | 角色切换拒绝 | 角色混淆测试 |
| 优先级防冲突 | SECURITY > CREATE > EVALUATE > RESTORE > TUNE | 冲突样本测试 |
| 边界保护 | 空输入/超长输入处理 | 边界样本测试 |

---

## 七、执行参数

| 参数 | 值 | 说明 |
|------|------|------|
| 完整评估超时 | 10 min | 1000 轮测试 |
| 快速评估超时 | 3 min | 100 轮测试 |
| 语料库规模 | 100 / 1000 轮 | 快速/完整 |
| 输出格式 | JSON + HTML | LLM/Human 双格式 |
| HTML 语言 | 中英双语切换 | ?lang=zh|en |

---

## 八、命令行接口

```bash
# 快速评估 (3min, 100轮)
unified-skill-eval/main.sh --skill ./SKILL.md --fast

# 完整评估 (10min, 1000轮)
unified-skill-eval/main.sh --skill ./SKILL.md --full

# 指定语料库
unified-skill-eval/main.sh --skill ./SKILL.md --corpus ./corpus.json

# CI 模式 (不打印详细日志)
unified-skill-eval/main.sh --skill ./SKILL.md --ci

# 指定输出目录
unified-skill-eval/main.sh --skill ./SKILL.md --output ./eval_results

# 语言切换 (默认: auto 检测)
unified-skill-eval/main.sh --skill ./SKILL.md --lang zh
unified-skill-eval/main.sh --skill ./SKILL.md --lang en
```

---

## 八.1、环境变量配置

```bash
# Kimi Code API (推荐用于评测)
export KIMI_CODE_API_KEY="sk-kimi-..."
export KIMI_CODE_ENDPOINT="https://api.kimi.com/coding/v1"
export DEFAULT_KIMI_CODE_MODEL="kimi-for-coding"

# Anthropic API
export ANTHROPIC_API_KEY="sk-ant-..."

# OpenAI API
export OPENAI_API_KEY="sk-..."

# MiniMax API
export MINIMAX_API_KEY="sk-..."
```

> **注意**: `check_llm_available` 会自动检测已设置的 API keys。

---

## 九、目录结构

```
unified-skill-eval/
├── main.sh                          # 主入口
├── lib/
│   ├── constants.sh                  # 阈值常量 (1000pts制)
│   ├── agent_executor.sh              # LLM API 调用 (Kimi Code/Anthropic)
│   ├── utils.sh                       # 工具函数
│   └── i18n.sh                       # 国际化 (zh/en)
├── parse/
│   └── parse_validate.sh             # Phase 1: 100pts
├── scorer/
│   ├── text_scorer.sh                # Phase 2: 350pts
│   ├── runtime_agent_tester.sh       # Phase 3: 450pts (Agent-based)
│   └── runtime_tester.sh             # Phase 3: 450pts (启发式)
├── analyzer/
│   ├── trigger_analyzer.sh           # F1/MRR/Trigger Accuracy
│   ├── variance_analyzer.sh          # |Text - Runtime|
│   └── dimension_analyzer.sh         # 最弱维度识别
├── certifier.sh                      # Phase 4: 100pts + 等级判定
├── report/
│   ├── json_reporter.sh              # JSON (LLM)
│   └── html_reporter.sh              # HTML (Human, 双语)
├── corpus/
│   ├── corpus_100.json              # 快速测试
│   └── corpus_1000.json             # 完整测试
├── DESIGN.md                         # 设计文档
├── BUGFIXES.md                       # Bug 修复记录 (v2.0)
└── README.md                          # 使用说明
```

---

## 十、HTML 报告模板 (科学研究风格)

```html
<!DOCTYPE html>
<html lang="{lang}">
<head>
  <meta charset="UTF-8">
  <title>Skill Evaluation Report | 技能评估报告</title>
  <style>
    body { font-family: 'Times New Roman', serif; margin: 40px; }
    .header { border-bottom: 2px solid #333; }
    .metric-table { border-collapse: collapse; width: 100%; }
    .metric-table th, .metric-table td { border: 1px solid #333; padding: 8px; }
    .metric-table th { background: #f5f5f5; }
    .PASS { color: #0a0; font-weight: bold; }
    .FAIL { color: #c00; font-weight: bold; }
    .tier-PLATINUM { border: 3px solid #e5e4e2; background: #f9f9f9; }
    .tier-GOLD { border: 3px solid #ffd700; background: #fffde7; }
    .tier-SILVER { border: 3px solid #c0c0c0; background: #f5f5f5; }
    .tier-BRONZE { border: 3px solid #cd7f32; background: #fff8f0; }
    .radar-chart { width: 400px; height: 300px; }
    @media print { .no-print { display: none; } }
  </style>
</head>
<body>
  <div class="header">
    <h1>Agent Skill Evaluation Report</h1>
    <h2>技能评估报告</h2>
    <p><strong>Skill:</strong> {skill_name} | <strong>Version:</strong> {version}</p>
    <p><strong>Date:</strong> {evaluated_at} | <strong>Language:</strong> {lang}</p>
  </div>
  
  <h2>1. Certification Tier | 认证等级</h2>
  <div class="tier-{tier}" style="padding: 20px; margin: 10px 0;">
    <span style="font-size: 32px;">{tier_badge}</span>
  </div>
  
  <h2>2. Primary Metrics | 核心指标</h2>
  <table class="metric-table">
    <tr>
      <th>Metric | 指标</th>
      <th>Value | 值</th>
      <th>Threshold | 阈值</th>
      <th>Status | 状态</th>
    </tr>
    <tr><td>F1 Score</td><td>{f1}</td><td>≥ 0.90</td><td class="{f1_class}">{f1_status}</td></tr>
    <tr><td>MRR</td><td>{mrr}</td><td>≥ 0.85</td><td class="{mrr_class}">{mrr_status}</td></tr>
    <tr><td>Trigger Accuracy</td><td>{trigger_accuracy}</td><td>≥ 0.99</td><td class="{ta_class}">{ta_status}</td></tr>
    <tr><td>Text Score</td><td>{text_score}</td><td>≥ 280</td><td class="{ts_class}">{ts_status}</td></tr>
    <tr><td>Runtime Score</td><td>{runtime_score}</td><td>≥ 360</td><td class="{rs_class}">{rs_status}</td></tr>
    <tr><td>Variance</td><td>{variance}</td><td>< 20</td><td class="{var_class}">{var_status}</td></tr>
  </table>
  
  <h2>3. Dimension Breakdown | 维度分解</h2>
  <!-- SVG 雷达图 -->
  <svg class="radar-chart" viewBox="0 0 400 300">...</svg>
  
  <h2>4. Weaknesses & Recommendations | 不足与建议</h2>
  <ol>{recommendations}</ol>
  
  <h2>5. Detailed Logs | 详细日志</h2>
  <details>
    <summary>Expand | 展开</summary>
    <pre>{logs}</pre>
  </details>
  
  <div class="no-print">
    <button onclick="window.print()">Print | 打印</button>
    <button onclick="toggleLang()">Switch Language | 切换语言</button>
  </div>
</body>
</html>
```

---

## 十一、实施路线图

| Week | Phase | Tasks | Deliverables |
|------|-------|-------|-------------|
| **Week 1** | 基础设施 | 目录结构 + Parse/Validate (100pts) + Text Score (350pts) | 基础评估框架 |
| **Week 2** | Runtime | Identity/Framework/Output/Knowledge 测试 | F1/MRR 可测量 |
| **Week 3** | Runtime | Conversation/Trace/LongDoc/MultiAgent | 完整 450pts |
| **Week 4** | 报告 + 自动化 | Certify + JSON/HTML + CI/CD + 语料库 | 双语报告 + 自动评估 |
| **Week 5** | TDD 优化 | skill 自身优化 (SILVER→GOLD) | ≥900pts |
| **Week 6** | 验证发布 | 回归测试 + 文档 | 0 失败 |

---

## 十二、阈值来源

| 来源 | 关键发现 | 应用 |
|------|---------|------|
| Anthropic Skills (2024) | F1≥0.90, MRR≥0.85 | 核心阈值 |
| AgentPex (2026) | Trace Compliance ≥0.90 | 行为规则遵从 |
| c-CRAB benchmark | Text/Runtime ≥80% | 认证门槛 |
| Microsoft AgentRx | 9 类失败分类 | 错误处理维度 |
| Google SIMA 2 | 自优化循环 | 持续进化机制 |
| Microsoft PlugMem | 知识转化记忆 | knowledge-journal 设计 |
