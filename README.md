# Skill Framework 🏆

> **让 AI 技能像软件一样可测试、可迭代**

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/github/stars/theneoai/skill-framework?style=social" alt="Stars">
  <img src="https://img.shields.io/github/last-commit/theneoai/skill-framework" alt="Last Commit">
  <img src="https://img.shields.io/badge/Framework-PLATINUM-950%2B-brightgreen" alt="Framework PLATINUM">
  <img src="https://img.shields.io/badge/version-1.0.0-blue" alt="Version">
</p>

<p align="center">
  <strong>生产级 AI 技能的 CI/CD 系统</strong>
</p>

---

## 🚀 30秒快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/theneoai/skill-framework.git
cd skill-framework

# 2. 创建你的第一个技能
skill create --template api-integration --name my-api-skill

# 3. 快速评估
skill evaluate my-api-skill.md

# 4. 查看报告
cat my-api-skill.eval.json
```

### 💡 代码示例

```yaml
---
name: weather-query
version: "1.0.0"
description: "Query weather data from OpenWeather API"
description_i18n:
  zh: "从 OpenWeather API 查询天气数据"
  en: "Query weather data from OpenWeather API"

interface:
  input: city-name
  output: temperature-humidity-conditions
  modes: [query, batch]
---

## §1 Identity

**Name**: weather-query
**Role**: Weather Data Fetcher
**Purpose**: Retrieve current weather conditions for any city worldwide.

## §2 Mode Router

```
User Input
    │
    ▼
PARSE: extract city name, detect language (ZH / EN)
    │
    ▼
ROUTE
  query  [查询,天气,温度 | weather,forecast,temp]
  batch  [批量,多个城市 | batch,multiple,cities]
```

## §3 Red Lines (严禁)

- 严禁 hardcoded API keys (CWE-798) — use env var `OPENWEATHER_API_KEY`
- 严禁 return raw API responses without validation
- 严禁 cache data longer than 10 minutes
```

### 📊 评估报告示例

```json
{
  "skill": "weather-query",
  "version": "1.0.0",
  "total_score": 940,
  "tier": "GOLD",
  "phases": {
    "parse_validate": 95,
    "text_quality": 285,
    "runtime_testing": 385,
    "certification": 175
  },
  "variance": 1.25,
  "f1": 0.94,
  "mrr": 0.91,
  "status": "CERTIFIED"
}
```

---

## 🤔 为什么选择 Skill Framework？

| 痛点 | 传统方式 | Skill Framework |
|------|---------|----------------|
| **质量不可控** | 凭感觉写 Prompt | 1000分量化评估 |
| **迭代无方向** | 盲目修改 | 7维度精准优化 |
| **审核靠人工** | 单点检查 | 3LLM交叉验证 |
| **维护困难** | 改一处崩一处 | 自进化系统监控 |
| **团队协作** | 文档不同步 | 标准化模板 |

**适合谁用？**
- 🧑‍💻 **AI 应用开发者** - 需要可靠的 Prompt 工程
- 🎯 **Prompt Engineer** - 追求可量化的质量提升
- 🏢 **技术团队负责人** - 需要团队协作标准
- 🔬 **AI 研究员** - 需要可复现的实验环境

---

## 🏗️ 架构概览

Skill Framework 采用 **4模式工作流**，覆盖技能全生命周期：

```mermaid
flowchart TB
    subgraph CREATE["🛠️ CREATE - 创建"]
        C1[ELICIT<br/>需求澄清] --> C2[SELECT<br/>模板选择]
        C2 --> C3[PLAN<br/>多LLM审议]
        C3 --> C4[GENERATE<br/>生成技能]
        C4 --> C5[SECURITY<br/>安全扫描]
    end

    subgraph LEAN["⚡ LEAN - 快评"]
        L1[HEURISTIC<br/>启发式检查] --> L2[500分评估]
        L2 --> L3{≥ 350?}
        L3 -->|YES| L4[LEAN_CERT]
        L3 -->|NO| L5[路由到OPTIMIZE]
    end

    subgraph EVALUATE["🧪 EVALUATE - 深度评测"]
        E1[Phase1<br/>解析验证<br/>100分] --> E2[Phase2<br/>文本质量<br/>300分]
        E2 --> E3[Phase3<br/>运行时测试<br/>400分]
        E3 --> E4[Phase4<br/>认证<br/>200分]
    end

    subgraph OPTIMIZE["🔧 OPTIMIZE - 优化"]
        O1[7维度分析] --> O2[9步循环]
        O2 --> O3[自动修复]
        O3 --> O4[重新评估]
    end

    CREATE --> LEAN
    LEAN -->|UNCERTAIN| EVALUATE
    EVALUATE -->|FAIL| OPTIMIZE
    OPTIMIZE --> EVALUATE
    EVALUATE -->|PASS| CERTIFIED[(🏆 CERTIFIED)]
```

### 工作流程说明

| 模式 | 用途 | 耗时 | 输出 |
|------|------|------|------|
| **CREATE** | 从模板创建新技能 | 5-10分钟 | 初版技能文件 |
| **LEAN** | 快速质量筛查 | ~1秒 | LEAN_CERT / 路由决策 |
| **EVALUATE** | 4阶段1000分深度评测 | 3-5分钟 | 详细评估报告 + 认证等级 |
| **OPTIMIZE** | 7维度9步自动优化 | 10-30分钟 | 改进版技能 + 优化日志 |

---

## ✨ 核心特性

### 🎯 1000分评估体系

行业首个针对 AI 技能的标准化评分系统：

- **Phase 1** (100分): 结构完整性检查
- **Phase 2** (300分): 文本质量分析（6维度）
- **Phase 3** (400分): 运行时测试（触发准确性、边界情况）
- **Phase 4** (200分): 综合认证（方差控制、安全扫描）

### 🤖 多LLM审议机制

借鉴司法陪审团制度，3个LLM独立评分后交叉验证：

| LLM | 角色 | 职责 |
|-----|------|------|
| LLM-1 | Generator | 生成初稿 / Phase 2评分 |
| LLM-2 | Reviewer | 安全审计 / Phase 3测试 |
| LLM-3 | Arbiter | 仲裁分歧 / 最终认证 |

**共识规则**: UNANIMOUS → 通过 | MAJORITY → 通过并记录 | SPLIT → 修订 | UNRESOLVED → 人工审核

### 🔄 自进化系统（3触发器）

| 触发器 | 条件 | 自动行动 |
|--------|------|----------|
| **Threshold** | F1 < 0.90 或 MRR < 0.85 | 标记 → 进入OPTIMIZE队列 |
| **Time** | 30天未更新 | 安排新鲜度检查 |
| **Usage** | 90天内调用 < 5次 | 评估废弃或重新定位 |

### 🌏 原生双语支持

- 所有模板内置中英文触发词
- 评估报告双语输出
- 示例代码支持混合语言输入

---

## 🏅 认证等级

| 等级 | 分数要求 | 最大方差 | 徽章 |
|------|----------|----------|------|
| **PLATINUM** | ≥ 950 | < 10 | 🏆 |
| **GOLD** | ≥ 900 | < 15 | 🥇 |
| **SILVER** | ≥ 800 | < 20 | 🥈 |
| **BRONZE** | ≥ 700 | < 30 | 🥉 |
| **FAIL** | < 700 | — | ❌ |

> **方差说明**: 高方差表示"纸上谈兵"（Phase2 >> Phase3）或"通过测试但文档差"（Phase3 >> Phase2），都表明质量不一致。

---

## 📚 示例技能展示

探索我们精心设计的示例技能，**平均认证分数 938.3/1000**：

### 🏆 [API Tester](examples/api-tester/) - PLATINUM 960/1000
**类型**: API Integration | **用途**: HTTP API 测试自动化

```bash
# 测试单个接口
skill run api-tester --input '{"url": "https://api.example.com/users"}'

# 批量测试
skill run api-tester --mode batch --input '{"endpoints": [...]}'
```

**亮点**: 
- 支持 TEST/VALIDATE/BATCH 三种模式
- 自动环境变量注入
- 完整的错误处理（HTTP 4xx/5xx/超时）

---

### 🥇 [Code Reviewer](examples/code-reviewer/) - GOLD 935/1000
**类型**: Workflow Automation | **用途**: 智能代码审查

```bash
# 审查代码文件
skill run code-reviewer --input './src/main.py'

# 安全扫描
skill run code-reviewer --mode scan --input './src/'
```

**亮点**:
- 多步骤工作流（解析→分析→扫描→检查→生成报告）
- 安全漏洞检测（CWE-798/89/78/22）
- 自动回滚机制

---

### 🥇 [Doc Generator](examples/doc-generator/) - GOLD 920/1000
**类型**: Data Pipeline | **用途**: 自动化文档生成

```bash
# 生成单文件文档
skill run doc-generator --input './src/utils.py'

# 批量生成整个项目
skill run doc-generator --mode batch --input './src/'
```

**亮点**:
- ETVF 数据管道（Extract→Transform→Validate→Format）
- 支持 Markdown/JSON/HTML 多格式输出
- 完整的输入输出 Schema 验证

---

**每个示例都包含**:
- ✅ 完整的技能定义文件 (`skill.md`)
- ✅ 详细评估报告 (`eval-report.md`)
- ✅ 使用说明文档 (`README.md`)
- ✅ 真实可运行的代码示例

---

## 🚀 快速开始（详细版）

### 安装

```bash
# 通过 pip 安装
pip install skill-framework

# 或通过源码安装
git clone https://github.com/theneoai/skill-framework.git
cd skill-framework
pip install -e .
```

### 创建第一个技能

```bash
# 步骤1: 初始化项目
skill init my-project
cd my-project

# 步骤2: 选择模板类型
# - api-integration: API集成类技能
# - data-pipeline: 数据处理类技能
# - workflow-automation: 工作流自动化
# - base: 基础模板

skill create --template api-integration --name weather-query

# 步骤3: 回答6个需求澄清问题
# 1. 这个skill要解决什么核心问题？
# 2. 主要用户是谁，技术水平如何？
# 3. 输入是什么形式？
# 4. 期望的输出是什么？
# 5. 有哪些安全或技术约束？
# 6. 验收标准是什么？

# 步骤4: 运行评估
skill evaluate weather-query.md

# 步骤5: 查看结果
skill report weather-query.md --format html
```

### 评估报告示例

```
SKILL EVALUATION REPORT
=======================
Skill:      weather-query v1.0.0
Evaluated:  2026-03-31T10:30:00Z
Evaluator:  skill-framework v2.0.0

PHASE SCORES
  Phase 1 — Parse & Validate:   95 / 100
  Phase 2 — Text Quality:       285 / 300
    System Design:     57/60   Error Handling: 42/45
    Domain Knowledge:  56/60   Examples:       43/45
    Workflow:          57/60   Metadata:       30/30
  Phase 3 — Runtime Testing:    385 / 400
    Trigger Routing:   116/120  Output Contract:   58/60
    Bilingual:         78/80   Error Handling RT: 48/50
    Negative/Edge:     58/60   Security Boundary: 27/30
  Phase 4 — Certification:      175 / 200
    Variance Gate:    40/40    F1 Gate:    40/40
    Security Scan:    55/60    MRR Gate:   30/30
    Consensus:        30/30

TOTAL SCORE:     940 / 1000
VARIANCE:        1.25  (threshold for tier: <15)
F1:              0.94  (threshold: ≥ 0.90)  [PASS]
MRR:             0.91  (threshold: ≥ 0.85)  [PASS]
TRIGGER ACC:     0.93  (threshold: ≥ 0.90)  [PASS]

SECURITY SCAN
  P0: CLEAR
  P1: CLEAR

CERTIFICATION TIER:  GOLD
STATUS:              CERTIFIED
NEXT ACTION:         Ready for production deployment
```

---

## 🗺️ 路线图

### ✅ 已完成 (v1.0.0)
- [x] 1000分评估体系
- [x] 多LLM审议机制
- [x] 3个认证示例技能
- [x] 完整GitHub社区配置
- [x] 双语支持

### 🚧 进行中 (v1.1.0)
- [ ] CLI工具 (`skill create/evaluate/optimize`)
- [ ] VS Code插件
- [ ] 更多示例技能（5+）
- [ ] 在线评估服务

### 📅 计划中 (v2.0.0)
- [ ] 技能市场/注册表
- [ ] Web IDE
- [ ] 团队协作功能
- [ ] 企业版（SSO、审计日志）

---

## 📖 文档

| 文档 | 描述 |
|------|------|
| [skill-framework.md](skill-framework.md) | 框架完整规范（582行） |
| [eval/rubrics.md](eval/rubrics.md) | 1000分评估细则（237行） |
| [optimize/strategies.md](optimize/strategies.md) | 7维度9步优化策略（319行） |

### 参考文档

- [refs/deliberation.md](refs/deliberation.md) - 多LLM审议协议
- [refs/evolution.md](refs/evolution.md) - 自进化系统规范
- [refs/security-patterns.md](refs/security-patterns.md) - CWE安全模式
- [refs/convergence.md](refs/convergence.md) - 收敛检测算法
- [refs/use-to-evolve.md](refs/use-to-evolve.md) - UTE自进化机制

---

## 🌟 社区与生态

### 社区统计

<p align="center">
  <img src="https://img.shields.io/github/stars/theneoai/skill-framework?style=social" alt="Stars">
  <img src="https://img.shields.io/github/forks/theneoai/skill-framework?style=social" alt="Forks">
  <img src="https://img.shields.io/github/contributors/theneoai/skill-framework" alt="Contributors">
</p>

### 加入社区

- 💬 [Discussions](https://github.com/theneoai/skill-framework/discussions) - 提问、分享想法
- 🐛 [Issues](https://github.com/theneoai/skill-framework/issues) - 报告Bug、请求功能
- 🎉 [Releases](https://github.com/theneoai/skill-framework/releases) - 查看最新版本

### 使用 Skill Framework 的项目

> 如果你的项目使用了 Skill Framework，欢迎提交 PR 添加到列表！

*暂无 - 成为第一个！*

---

## 🤝 贡献

我们欢迎所有形式的贡献！

```bash
# Fork 仓库
git clone https://github.com/YOUR_USERNAME/skill-framework.git

# 创建分支
git checkout -b feature/amazing-feature

# 提交更改
git commit -m "Add amazing feature"

# 推送分支
git push origin feature/amazing-feature

# 创建 Pull Request
```

### 贡献指南

1. **新技能模板**: 参考 [templates/](templates/) 目录
2. **优化策略**: 添加到 [optimize/strategies.md](optimize/strategies.md)
3. **评估基准**: 更新 [eval/benchmarks.md](eval/benchmarks.md)
4. **Bug修复**: 确保通过所有测试

---

## 📄 许可证

[MIT License](LICENSE) © 2026 theneoai

---

<p align="center">
  <strong>Skill Framework</strong> — 让每一次 Prompt 都值得信赖
</p>

<p align="center">
  <a href="https://github.com/theneoai/skill-framework">GitHub</a> •
  <a href="https://skill-framework.readthedocs.io">文档</a> •
  <a href="https://discord.gg/skill-framework">Discord</a>
</p>
