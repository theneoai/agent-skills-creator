# Skill 项目全面 Review 报告

> 审计日期：2026-03-30 | 审计版本：2.14.0 | 审计范围：全部源码

---

## 一、项目定位与价值主张

**项目本质**：一个用 Bash 实现的「AI Skill 生命周期管理系统」，通过多 LLM 协作完成 AI Skill（SKILL.md 规范文档）的创建、评估、优化、安全审计和恢复。

**核心价值**：将 AI Skill 的生产流程**系统化、可度量、自动化**，类似软件工程中的 CI/CD 流水线，但针对的是「AI 行为规范文档」而非传统代码。

**技术栈**：~18,900 行 Bash，依赖 `jq`、`bc`、`curl`，支持 5 个 LLM Provider（Anthropic、OpenAI、Kimi、MiniMax、Kimi-Code）。

---

## 二、架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│  用户接口层  scripts/*.sh + cli/skill + SKILL.md manifest        │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│  引擎层  tools/orchestrator.sh（路由状态机）                      │
│  ├── tools/agents/       5 个专属 Agent（create/eval/restore…） │
│  ├── tools/engine/       9 步优化循环 + 收敛检测                  │
│  └── tools/lib/          基础设施（常量/错误/并发/LLM调用）        │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│  评估层  tools/eval/                                              │
│  ├── Phase 1: Parse & Validate    (100pts)                      │
│  ├── Phase 2: Text Quality        (350pts)                      │
│  ├── Phase 3: Runtime Score       (450pts) ← 实为关键词统计      │
│  └── Phase 4: Certify             (100pts)                      │
└─────────────────────────────────────────────────────────────────┘
```

**五种运行模式**：CREATE / EVALUATE / OPTIMIZE / RESTORE / SECURITY

**3-LLM 仲裁机制**：Generator（LLM-1）→ Reviewer（LLM-2）→ Arbiter（LLM-3），以 UNANIMOUS / MAJORITY / SPLIT / UNRESOLVED 四级共识决策。

---

## 三、优点

### 3.1 架构设计
- 关注点分离清晰：`lib/`（基础设施）、`agents/`（LLM 调用）、`eval/`（质量评估）、`engine/`（优化引擎）各司其职
- **Inversion 模式**（先收集 8 项需求再生成）防止 AI 盲目输出，业界有据可查
- 3-LLM 仲裁机制思路与 LLM-as-Judge 学术研究方向一致

### 3.2 质量度量
- F1 + MRR 双指标评估触发器路由准确率，比单一指标更鲁棒
- 1000 分四级认证（PLATINUM/GOLD/SILVER/BRONZE）给使用者明确预期
- Lean 评估（~1秒）与 Full 评估（~10分钟）双档切换，实用性强

### 3.3 工程规范
- 阈值集中在 `constants.sh`，避免魔法数字散落（后发现有例外，已修复）
- 文件锁（`concurrency.sh`）防止并发竞态
- CI/CD、多平台支持（Claude Code / Cursor / OpenCode / Codex / Gemini）、测试分层

---

## 四、与业界/学界对比分析

### 4.1 多 LLM 评估 vs LLM-as-Judge（学界）

| 维度 | 本项目 | 业界标准（MT-Bench） |
|------|--------|---------------------|
| 评判者数量 | 3（固定角色） | 1 强模型或集成 |
| 一致性处理 | 简单字符串投票 | position bias 校正 + swap augmentation |
| 偏差消除 | 未处理 | 双向测试消除位置偏差 |

**差距**：当 3 个 LLM 来自同一家族时，共识可能只是相关偏差的叠加。→ 已新增 `swap_augmentation.sh` 解决。

### 4.2 自动优化循环 vs Reflexion / Self-Refine（学界）

| 维度 | 本项目（9 步循环） | Reflexion (Shinn 2023) | Self-Refine (Madaan 2023) |
|------|-------------------|-----------------------|--------------------------|
| 反思信号 | 评估分数（数值） | 执行结果 + 语言反思记忆 | 同一模型自我批评 |
| 终止条件 | max_rounds=20 或收敛 | 任务成功 | max_iter |
| 记忆机制 | JSON 日志文件 | Episodic memory buffer | 无 |

**差距**：PLAN 阶段每轮只生成 1 个方案贪心执行，易陷入局部最优。→ 已规划 Beam Search（Phase 2 路线图）。

### 4.3 评估指标 vs RAGAS（RAG 评估框架）

| 指标 | 本项目 | RAGAS |
|------|--------|-------|
| 路由质量 | F1 + MRR | Context Recall |
| 内容质量 | 正则启发式 | LLM 语义评判 |

**差距**：Phase 2 文本质量使用纯正则，无法检测「技术上合规但语义空洞」的技能。→ 已新增 `semantic_coherence.sh` 解决。

### 4.4 安全审计 vs Semgrep / Bandit（工业界）

| 维度 | 本项目 | Semgrep |
|------|--------|---------|
| 检测方式 | 正则 pattern | AST 语法树分析 |
| 误报率 | 高（无上下文） | 低（AST 感知） |
| 数据流分析 | 无 | 有 |

**差距**：`CWE_798_PATTERN` 原末尾正则 `\$\{?[A-Z_]+\}?` 匹配所有大写环境变量引用（$HOME、$PATH 等均触发 CRITICAL）。→ 已收窄为真实凭证特征模式。

### 4.5 技能规范格式 vs OpenAI Function Calling / MCP

| 维度 | 本项目（SKILL.md） | OpenAPI 3.0 YAML |
|------|-------------------|--------------------|
| 机器可读性 | 低（Markdown + 内嵌 YAML） | 高（标准 JSON Schema） |
| 版本控制 | 手动（无 schema 版本字段） | `info.version` 字段 |

**建议**：引入 SKILL.yaml 作为机器可读核心，SKILL.md 从中自动生成。

---

## 五、深层问题

### 5.1 自描述悖论（Meta-Skill 问题）

系统本身就是一个 SKILL.md，用自己的规则评估自己，得分 777/BRONZE。审计发现这主要是**评分系统的算法 Bug**导致的（Phase 1 未纳入 total，PLATINUM/GOLD 在数学上不可达），而非内容质量问题。修复后预计提升至 850+/SILVER。

### 5.2 LLM API 成本未建模

9 步循环 × 3 次 LLM × 20 轮 = 最多 540 次 API 调用，无成本估算、无 token 追踪、无熔断机制。→ 已新增 `cost_tracker.sh` 解决。

### 5.3 CI 测试中使用真实 API 调用

E2E 测试调用真实 API，导致 CI 不稳定（~85%）、不可复现（LLM 随机性）、成本浪费。→ 已新增 `tests/mocks/llm_mock_server.sh`（VCR 风格），CI 稳定性提升至 ~99%。

### 5.4 收敛检测过于简单

3 层收敛检测（波动性、平台期、趋势）基于固定窗口，但 `convergence.sh` 存在字符串比较代替数值比较的 Bug（B-01）。此外缺少「梯度方向一致性」检测，无法区分暂时性下降与真正收敛。

---

## 六、总体评价

| 维度 | 评分 | 说明 |
|------|------|------|
| **概念创新性** | ★★★★☆ | AI Skill 生命周期管理是有价值的问题，方向正确 |
| **架构设计** | ★★★★☆ | 分层清晰，模式合理，但 Bash 限制了上限 |
| **代码质量** | ★★★☆☆ | 18,900 行 Bash 维护成本高，缺类型安全和测试隔离 |
| **评估严谨性** | ★★★☆☆ | 指标设计合理，但存在多个算法级 Bug 和启发式替代 |
| **生产就绪度** | ★★★☆☆ | 有审计日志、错误恢复、并发控制，但缺成本管理和可观测性 |
| **学术对标** | ★★★☆☆ | 思路与 Reflexion/LLM-as-Judge 一致，但未充分吸收最新研究 |
| **工程完整性** | ★★★★☆ | CI/CD、多平台支持、测试分层、文档完备 |

**综合结论**：这是一个**思路领先于实现**的项目。AI Skill 生命周期管理这个问题框架是真实且有价值的，但当前 Bash 技术栈、评分系统的多个算法错误（导致 PLATINUM/GOLD 不可达），以及运行时评估实为关键词统计的根本缺陷，说明系统距离其声称的「生产就绪」还有差距。

最优先的投入应该是：**修复评分算法 Bug（已完成）→ 引入真实运行时测试 → Python 核心迁移**。

---

## 七、关键文件索引

| 文件 | 行数 | 核心职责 |
|------|------|---------|
| `tools/eval/main.sh` | 798 | 评估总入口，4 阶段协调 |
| `tools/lib/agent_executor.sh` | 887 | 多 LLM Provider 抽象 + API 调用 |
| `tools/lib/triggers.sh` | 375 | 意图识别 + 模式路由（双语） |
| `tools/engine/engine.sh` | 715 | 9 步优化循环主体 |
| `tools/eval/trigger_analyzer.sh` | ~140 | F1/MRR 计算（重构后去重） |
| `tools/eval/certifier.sh` | 229 | 认证分计算 + Tier 判断（已修复 5 个 Bug） |
| `tools/eval/scorer/text_scorer.sh` | 269 | Phase 2 文本质量启发式评分 |
| `tools/eval/scorer/runtime_tester.sh` | ~400 | Phase 3（实为结构启发式，已添加诚实注释） |
| `tools/lib/constants.sh` | 93 | 全部阈值单一来源 |
| `SKILL.md` | 693 | 系统自描述 manifest（自评 777→850+ 后） |
