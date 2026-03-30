# Skill 项目重构优化计划 v3

**版本**: v3  
**日期**: 2026-03-30  
**状态**: 已确认

---

## 执行摘要

本计划为 Skill 项目制定全面的重构优化方案，核心目标：

1. **评价体系重构** — 引入真值基准数据集 + 多维度评估指标 + 研究成果融合
2. **SKILL.md 管理规范化** — 模块化文档结构 + YAML→MD 自动生成
3. **全面 Python 化** — 移除所有 Bash，实现纯 Python 技术栈

**总周期**: 12 周

---

## 项目现状分析

### 目录结构

```
skill/
├── SKILL.md                    # 技能规范（689行，待精简至≤400行）
├── README.md, CHANGELOG.md
│
├── docs/
│   ├── REFACTORING-PLAN.md     # 重构方案（303行）
│   ├── REVIEW-REPORT.md        # Review 报告（168行）
│   ├── ARCHITECTURE.md
│   └── design/, guide/, reports/, standards/
│
├── tools/                      # 当前实现（全部 .sh）
│   ├── orchestrator.sh         # 主入口
│   ├── agents/                 # create/evaluate/restore/security
│   ├── engine/                 # engine.sh(716L)/analyzer/convergence/
│   ├── lib/                    # agent_executor.sh(887L)/triggers.sh(376L)...
│   └── eval/                   # certifier.sh(251L)/scorer/
│
├── engine/                     # ⚠️ 全部为符号链接，指向 tools/
├── scripts/                     # 用户CLI（14个脚本）
├── refs/                       # 参考文档
└── tests/                      # unit/integration/e2e/business 四层测试
```

### 已确认 Bug 修复状态

| Bug ID | 描述 | 状态 |
|--------|------|------|
| B-01 ~ B-05 | 5个实现级 bug | ✅ 已修复 |
| S-01 ~ S-06 | 5个评分系统算法 bug | ✅ 已修复 |

修复后 PLATINUM/GOLD 层级在数学上可达。

### 关键问题

1. `engine/` 根目录全为符号链接，结构混乱
2. `tools/prompts` 存在循环引用（指向 `../engine/prompts`）
3. SKILL.md 689行，违背自身"≤400行"原则
4. 最大文件：agent_executor.sh (887行)、engine.sh (716行)
5. 全部 Bash 实现，缺少现代 Python 生态支持

---

## 优先级框架

| 优先级 | 阶段 | 周数 | 核心内容 |
|--------|------|------|----------|
| **P0** | 基础设施准备 | Week 1-2 | 目录重组 + Python 环境 |
| **P1** | 评价体系重构 | Week 3-7 | 真值基准 + 研究成果融合 |
| **P2** | SKILL.md 管理 | Week 8-9 | 文档规范化 |
| **P3** | Python 化实现 | Week 10-12 | 全面重构 |

---

## 12 周执行计划

### Phase 0: 基础设施准备（Week 1-2）

#### Week 1 — Phase 0.1: 目录重组

**目标**: 清理符号链接混乱，建立清晰目录结构

**任务**:
- [ ] 移除 `engine/` 符号链接目录
- [ ] 修复 `tools/prompts` 循环引用
- [ ] 重组目录结构，建立 `skill/` 包目录

**交付物**: 清晰的目录结构，无符号链接，无循环引用

#### Week 2 — Phase 0.2: Python 环境初始化

**目标**: 建立 Python 项目基础

**任务**:
- [ ] 创建 `skill/` Python 包骨架
- [ ] 引入 `uv` 包管理器
- [ ] 创建 `pyproject.toml`
- [ ] 搭建基础 Python 环境

**交付物**: 可 `import skill` 的 Python 项目

---

### Phase 1: 评价体系重构 + 研究成果融合（Week 3-7）

#### Week 3 — Phase 1.1: 真值基准评测框架

**目标**: 构建可绝对度量的评估标准

**任务**:
- [ ] 集成 `lm-evaluation-harness`（60+ 标准基准）
- [ ] 集成 `SWE-bench Verified`（代码技能绝对评测）
- [ ] 集成 `GPQA`（专家级知识问答）
- [ ] 集成 `IFEval`（指令遵循评测）

**真值数据集选择**:

| 数据集 | 用途 | 格式 | 许可证 |
|--------|------|------|--------|
| SWE-bench Verified | 代码技能 | 补丁级真值 | MIT |
| GPQA | 专家知识 | 多选+专家验证 | Apache-2.0 |
| IFEval | 指令遵循 | 二值 pass/fail | Apache-2.0 |
| lm-evaluation-harness | 标准化基准 | MMLU/GSM8K 等 | MIT |
| BIG-Bench Lite | 多样化任务 | JSON 输入/目标对 | Apache-2.0 |

**交付物**: 真值基准评测框架

#### Week 4 — Phase 1.2: 多维度评估指标

**目标**: 建立全面、可交叉验证、可绝对比较的评估系统

**评估维度与权重**:

| 维度 | 权重 | 测量方法 | 数据来源 |
|------|------|----------|----------|
| **LLM 运行时评价** | 55% | GEPA 轨迹级评分、成对排名 | 动态执行结果 |
| **静态文本质量** | 20% | 语义内聚度、可读性、结构化 | 专家规则 |
| **真值基准对比** | 15% | SWE-bench/GPQA/IFEval 交叉验证 | 开源数据集 |
| **交叉验证** | 10% | 多数据集、多维度相互印证 | 内部标准 |

**评估系统架构**:

```
skill evaluate <target>
├── 1. 静态分析 (20%)
│   ├── 语义内聚度评分
│   ├── 结构化程度评分
│   └── 可读性评分
│
├── 2. 真值基准对比 (15%)
│   ├── SWE-bench Verified (代码技能)
│   ├── GPQA (专家知识)
│   └── IFEval (指令遵循)
│
├── 3. LLM 运行时评价 (55%)
│   ├── 执行轨迹采集
│   ├── 轨迹级 GEPA 评分
│   └── Bradley-Terry 成对排名
│
└── 4. 交叉验证 (10%)
    ├── 多数据集一致性
    ├── 多维度相关性
    └── 绝对分数校准
```

**交付物**: 多维度评估系统

#### Week 5 — Phase 1.3: 研究成果 — GEPA + SAE

**目标**: 引入最新研究成果强化评估体系

**GEPA (Generalized Policy Evaluation and Adaptation)**:
- 融合位置: `eval/scorer`
- 核心贡献: 轨迹级评分替代点估计
- 实现方式: 联合优化 prompt + 轨迹级 reward

**SAE (Survivability-Aware Execution)**:
- 融合位置: `certifier`
- 核心贡献: skill 供应链安全检测
- 实现方式: 评估 skill 在各种环境下生存能力

**任务**:
- [ ] 集成 GEPA 轨迹级评分到 eval/scorer
- [ ] 引入 SAE survivability 检测到认证流程
- [ ] 优化 pairwise_ranker (Bradley-Terry)
- [ ] 强化 semantic_coherence 语义分析

**交付物**: 基于研究成果的增强评估体系

#### Week 6 — Phase 1.4: 研究成果 — BOAD + ROAD

**BOAD (Bandit Optimization for Agent Design)**:
- 融合位置: `agent_create`
- 核心贡献: 自动发现分层 agents
- 实现方式: Bandit 算法自动探索 agent 层次结构

**ROAD (Retrospective Optimization with Agentic Decisions)**:
- 融合位置: `engine/error_recovery`
- 核心贡献: 失败日志→决策树
- 实现方式: 零样本反思式优化

**任务**:
- [ ] 实现 BOAD 分层 agent 自动发现
- [ ] 实现 ROAD 失败日志→决策树错误恢复
- [ ] 增强 engine/convergence 收敛检测
- [ ] 优化 swap_augmentation 消除 position bias

**交付物**: 智能 agent 创建与错误恢复系统

#### Week 7 — Phase 1.5: 研究成果 — Youtu-Agent + LoongFlow

**Youtu-Agent**:
- 融合位置: `skill 自进化`
- 核心贡献: Agent Practice/RL 双模式
- 实现方式: 自动化 Agent 生成 + 强化学习双模式

**LoongFlow**:
- 融合位置: `orchestrator`
- 核心贡献: Plan-Execute-Summarize 认知范式
- 实现方式: 认知架构 + 进化记忆

**任务**:
- [ ] 集成 Youtu-Agent 双模式到 skill 自进化
- [ ] 引入 LoongFlow Plan-Execute-Summarize 到 orchestrator
- [ ] 完善 calibration 专家校准框架

**交付物**: 自进化 skill 系统 + 认知 orchestrator

---

### Phase 2: SKILL.md 文件管理与组织系统（Week 8-9）

#### Week 8 — Phase 2.1: SKILL.md 精简

**目标**: 遵循 SKILL.md "≤400行"原则

**任务**:
- [ ] 拆分 SKILL.md → 核心(≤400行) + `refs/` 运行时引用
- [ ] 建立模块化文档结构
- [ ] 整理核心概念与运行时引用分离

**精简策略**:
- 核心部分: 技能定义、接口规范、核心逻辑
- refs/ 部分: 详细参考、示例、变体

#### Week 9 — Phase 2.2: SKILL 管理规范化

**目标**: 建立标准化 skill 管理流程

**任务**:
- [ ] 实现 `SKILL.yaml` → `SKILL.md` 自动生成
- [ ] 建立 skill 元数据管理系统
- [ ] 创建 `skill generate` CLI 工具
- [ ] 规范化 skill 生命周期管理

**交付物**: 完整的 SKILL 管理工具链

---

### Phase 3: 全面 Python 化工具实现（Week 10-12）

#### Week 10 — Phase 3.1: orchestrator Python 化

**目标**: 将 orchestrator 模块全面 Python 化

**任务**:
- [ ] Python 化 `orchestrator/state.py`
- [ ] Python 化 `orchestrator/workflow.py`
- [ ] Python 化 `orchestrator/actions.py`
- [ ] Python 化 `orchestrator/parallel.py`

**交付物**: orchestrator 模块纯 Python 实现

#### Week 11 — Phase 3.2: engine + agents Python 化

**任务**:
- [ ] Python 化 `engine/analyzer.py`
- [ ] Python 化 `engine/convergence.py`
- [ ] Python 化 agents 四模块（create/evaluate/restore/security）

**交付物**: engine + agents 模块纯 Python 实现

#### Week 12 — Phase 3.3: lib + eval Python 化 + 收尾

**任务**:
- [ ] Python 化 `lib/triggers.py`
- [ ] Python 化 `lib/calibration.py`
- [ ] Python 化 `lib/swap_augmentation.py`
- [ ] Python 化 `eval/certifier.py`
- [ ] Python 化 `eval/scorer/` 全套
- [ ] **清理所有遗留 .sh 文件**

**交付物**: 纯 Python 项目

---

## 最新研究成果融合表

| 研究 | 年份 | 核心贡献 | 融合位置 | Week |
|------|------|---------|----------|------|
| **MAMuT/GEPA** | 2025-2026 | 轨迹级评分替代点估计 | eval/scorer | 5 |
| **BOAD** | 2025 | 自动发现分层 agents | agent_create | 6 |
| **ROAD** | 2025 | 失败日志→决策树 | engine/error_recovery | 6 |
| **Youtu-Agent** | 2025 | Agent Practice/RL 双模式 | skill 自进化 | 7 |
| **SAE** | 2026 | survivability 供应链安全 | certifier | 5 |
| **LoongFlow** | 2025 | Plan-Execute-Summarize 认知 | orchestrator | 7 |

---

## 评估评价系统详情

### 评估维度详解

#### 1. LLM 运行时评价 (55%)

**GEPA 轨迹级评分**:
- 替代简单的点估计
- 采集完整执行轨迹
- 轨迹级 reward 建模

**Bradley-Terry 成对排名**:
- 已有实现: `pairwise_ranker.sh`
- 迁移至 Python 并增强

#### 2. 静态文本质量 (20%)

**语义内聚度评分**:
- 已有实现: `semantic_coherence.sh`
- 评估 skill 文档内部一致性

**结构化程度评分**:
- YAML/JSON 结构完整性
- 字段齐全度

**可读性评分**:
- 文档清晰度
- 示例完整性

#### 3. 真值基准对比 (15%)

**SWE-bench Verified**:
- 评估代码类 skill
- 补丁级真值对比

**GPQA**:
- 专家级知识问答
- 评估知识类 skill

**IFEval**:
- 指令遵循能力
- 评估 prompt 质量

#### 4. 交叉验证 (10%)

**多数据集一致性**:
- 同一 skill 在不同数据集上的一致性

**绝对分数校准**:
- 与标准锚点对比
- 保证跨时间、跨版本可比

---

## 技术栈变更

| 项目 | 原计划 | 最终方案 |
|------|--------|----------|
| **技术栈** | 渐进式 Python（保留 .sh） | **全面 Python 化（移除所有 .sh）** |
| **包管理** | pip | uv + pyproject.toml |
| **CLI** | shell scripts | Python CLI (click/typer) |
| **测试** | 现有框架 | pytest + 现有测试 |

---

## 里程碑

```
Week 2  → Python 环境就绪（可 import skill）
Week 7  → 评价体系 + 研究成果融合完成
Week 9  → SKILL.md 管理规范化完成
Week 12 → 纯 Python 项目，.sh 全部清除
```

---

## 风险与缓解

| 风险 | 等级 | 缓解措施 |
|------|------|----------|
| 全面重写风险高 | 高 | 分阶段验证，每阶段有交付物 |
| 评估体系复杂 | 中 | 先集成已有模块，再增强 |
| 研究成果适配 | 中 | 选择性采纳，快速原型验证 |

---

## 附录

### A. 开源数据集许可证

| 数据集 | 许可证 |
|--------|--------|
| lm-evaluation-harness | MIT |
| SWE-bench | MIT |
| GPQA | Apache-2.0 |
| IFEval | Apache-2.0 |
| BIG-Bench | Apache-2.0 |
| HELM | Apache-2.0 |

### B. 参考文档

- `docs/REFACTORING-PLAN.md` (原始重构方案)
- `docs/REVIEW-REPORT.md` (Review 报告)
- `docs/ARCHITECTURE.md` (架构文档)
