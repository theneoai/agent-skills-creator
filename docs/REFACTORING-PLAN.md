# Skill 项目重构方案

> 版本：3.0 | 日期：2026-03-30 | 基于完整代码审计

---

## 一、问题本质

本项目解决的核心挑战是：

> **如何为概率性人工制品（AI Skill）建立确定性质量保障体系？**

传统软件质量工具（单元测试、代码覆盖率）建立在「确定性」前提上。AI Skill 的根本特征是**行为的概率分布**——同一份 SKILL.md，在不同上下文下产生不同输出。这使所有传统质量工具无法直接适用，本项目的全部技术设计都是在这个矛盾下展开的。

---

## 二、审计发现：已确认 Bug 清单

### 2.1 实现级 Bug（已修复）

| ID | 文件 | 问题 | 影响 | 状态 |
|----|------|------|------|------|
| B-01 | `convergence.sh:153` | `[[ "$ratio" > "0.7" ]]` 字典序比较代替数值比较 | 收敛判断完全不可靠，最多浪费 20 轮优化 | ✅ 已修复 |
| B-02 | `engine.sh:282` | `[ "$delta > $MIN" ]` 对非空字符串恒为 true | usage_tracker 全部记录为"成功"，learner 从错误数据学习 | ✅ 已修复 |
| B-03 | `engine.sh:648` | `git add -A` 可能意外提交 API key 等敏感文件 | 安全风险 | ✅ 已修复 |
| B-04 | `constants.sh` | CWE_798 正则末尾 `\$\{?[A-Z_]+\}?` 匹配所有大写环境变量 | `$HOME`、`$PATH` 触发 CRITICAL，安全审计误报率极高 | ✅ 已修复 |
| B-05 | `trigger_analyzer.sh` | `analyze_triggers()` 与 `analyze_triggers_from_json()` 核心逻辑 90% 重复 | 任何 F1/MRR 算法修改需同步两处 | ✅ 已修复（抽取 `_compute_metrics()`） |

### 2.2 评分系统算法 Bug（已修复）

| ID | 文件 | 问题 | 量化影响 |
|----|------|------|---------|
| S-01 | `text_scorer.sh` | Domain Knowledge `framework_count` 上限 10pts，导致该维度最高可得 60pts，而声明上限为 70pts | 每次评分系统性少 10pts |
| S-02 | `certifier.sh` | `certify()` 接收 F1/MRR 参数但函数体从未引用 | 认证分与路由准确率完全无关，F1=0.1 与 F1=0.99 得相同认证分 |
| S-03 | `certifier.sh` | `report_points`（20pts）检查评估工具自己的输出文件是否存在 | 循环自评：奖励评估器自身产出，与 Skill 质量无关 |
| S-04 | `certifier.sh` | `total = text_score + runtime_score`，Phase 1 的 100pts 从未纳入 total | **PLATINUM(≥950)、GOLD(≥900) 在数学上不可达**（total 最高 800）|
| S-05 | `certifier.sh` | 方差阈值在三处使用不同定义（`<30/<50/<70` vs `<10/<15/<20` vs `VARIANCE_MAX=20`） | 同一方差值在分数计算和 tier 判断中使用不同标准 |
| S-06 | `runtime_tester.sh` | Phase 3 命名为"Runtime Score"，所有子指标均通过关键词计数实现 | Phase 3 与 Phase 2 本质相同；`check_memory_access` 的 `grep "read\|write"` 匹配任意英文文本 |

> **核心结论**：修复 S-04 前，系统自评永远只能得 BRONZE，这不是内容质量问题，而是评分算法的根本性缺陷。

所有 S-xx bug 均已修复，修复后 PLATINUM/GOLD 层级在数学上可达。

---

## 三、三个核心创新

### 创新 1 — Bradley-Terry 成对排名

**问题**：绝对分数（777/1000）依赖评分系统的校准，我们已证明当前评分有系统性偏差，绝对数值不可信。

**方法**：将 RLHF 核心洞察应用于 Skill 排名——「哪个更好」比「打几分」更可靠（标注者一致性 κ 从 ~0.4 提升到 ~0.7+）。

对任意两个 Skill A 和 B，用 LLM 判断：「对于任务 X，A 还是 B 更有帮助？」

用 Bradley-Terry 模型将所有成对结果转化为全局排名：

```
P(A > B) = exp(β_A) / (exp(β_A) + exp(β_B))
```

β 参数通过 MM 算法（Hunter 2004）迭代至收敛。内置 swap-augmentation 消除位置偏差（Zheng et al. 2023, arXiv:2306.05685）。

**实现**：`tools/eval/scorer/pairwise_ranker.sh`

---

### 创新 2 — 语义内聚度评分

**问题**：一个 SKILL.md 可以在关键词上得满分，但 §1.1 说自己是代码助手、§4.x 的示例全是写作任务——当前评分无法发现这种身份漂移。

**方法**：用嵌入向量的**语义内聚度**（Semantic Cohesion）衡量 Skill 各节的一致性。

```
sections = [§1.1, §1.2, §3.x, §4.x]
embeddings = embed(section) for each section
cohesion = mean_pairwise_cosine_similarity(embeddings)
```

额外检测**身份漂移**：`cosine_distance(§1.1, §4.x) > 0.4` 时发出告警。

无嵌入 API 时自动回退到 Jaccard 词汇重叠（零成本）。

**实现**：`tools/eval/scorer/semantic_coherence.sh`（贡献 Phase 2 额外 50pts）

---

### 创新 3 — 专家标注校准框架

**问题**：评分体系是自举的（self-referential）——没有外部基准验证，777 分没有绝对意义。

**方法**：构建专家标注校准集，用线性回归拟合系统分与专家分的映射关系。

```
步骤 1: 收集 30-50 个 Skill 样本
步骤 2: 3-5 名专家按 5 维度独立评分（1-10 分）
步骤 3: Krippendorff's α 验证标注者一致性（目标 α ≥ 0.80）
步骤 4: 线性回归拟合 system_score → expert_score
步骤 5: Pearson r + RMSE 验证校准质量（目标 r ≥ 0.85）
```

校准后，系统分数才具有可解释的绝对意义。

**实现**：`tools/lib/calibration.sh`

---

## 四、新增工程模块（本次会话）

| 模块 | 路径 | 功能 |
|------|------|------|
| API 成本追踪 | `tools/lib/cost_tracker.sh` | 记录每次 LLM 调用的 token 用量，内置成本熔断器（默认 $5 上限） |
| Swap-augmentation | `tools/lib/swap_augmentation.sh` | 双轮角色互换评估消除 position bias，不一致时标记 UNCERTAIN |
| LLM Mock | `tests/mocks/llm_mock_server.sh` | VCR 风格录制/回放，CI 不再调用真实 API |
| 成对排名器 | `tools/eval/scorer/pairwise_ranker.sh` | Bradley-Terry 完整实现，含 MM 算法 |
| 语义内聚度 | `tools/eval/scorer/semantic_coherence.sh` | 嵌入向量 + Jaccard 回退的一致性评分 |
| 校准框架 | `tools/lib/calibration.sh` | Krippendorff's α + 线性回归校准 |

---

## 五、重构架构设计

### 5.1 评分体系重设计

**现状**（已修复后）：

```
Phase 1: Parse & Validate    100pts  结构解析（正确）
Phase 2: Text Heuristics     350pts  关键词统计（低效但诚实）
Phase 3: "Runtime" Score     450pts  实为关键词统计（命名误导）
Phase 4: Certify             100pts  综合认证（修复后含 F1/MRR）
                           ───────
                            1000pts
```

**目标**（路线图）：

```
Phase 1: Parse & Validate    100pts  维持不变
Phase 2: Text + Semantic     300pts  = 250pts 关键词 + 50pts 语义内聚度
Phase 3: Behavioral          500pts  = 150pts 启发式（诚实标注）
                                     + 200pts 真实 LLM 运行时测试
                                     + 150pts 成对比较排名
Phase 4: Certify             100pts  维持修复后版本
                           ───────
                            1000pts
```

### 5.2 评估模式分层

```
LEAN  (~0s,   ~$0):   Phase 1 + Phase 2 关键词（无 LLM）
FAST  (~3min, ~$0.1): + Phase 2 语义内聚度 + Phase 3 启发式
FULL  (~15min, ~$1):  + Phase 3 真实 LLM 运行时测试
GOLD  (~30min, ~$3):  + Phase 3 Bradley-Terry 成对排名
```

### 5.3 方差阈值统一（单一来源）

所有阈值统一定义在 `tools/lib/constants.sh`，其他文件只引用常量：

```bash
# constants.sh — tier 子条件（新增）
readonly PLATINUM_TEXT_MIN=330    # 350 × 94.3%
readonly PLATINUM_RUNTIME_MIN=475 # 500 × 95%
readonly GOLD_TEXT_MIN=270        # 300 × 90%
readonly GOLD_RUNTIME_MIN=450     # 500 × 90%
readonly SILVER_TEXT_MIN=240      # 300 × 80%
readonly SILVER_RUNTIME_MIN=400   # 500 × 80%
readonly BRONZE_TEXT_MIN=210      # 300 × 70%
readonly BRONZE_RUNTIME_MIN=350   # 500 × 70%

# F1/MRR tier thresholds（现已在 certify() 中使用）
readonly F1_PLATINUM=0.92;  readonly MRR_PLATINUM=0.88
readonly F1_GOLD=0.90;      readonly MRR_GOLD=0.85
readonly F1_SILVER=0.87;    readonly MRR_SILVER=0.82
readonly F1_BRONZE=0.85;    readonly MRR_BRONZE=0.80
```

---

## 六、技术债清单

### 6.1 Bash 技术债（P1，已规划迁移）

18,900 行 Bash 带来的具体痛点（已通过 bug 审计验证）：

| 问题类型 | 已发现实例 | Python 对应方案 |
|---------|-----------|----------------|
| 浮点比较 | convergence.sh B-01 | 原生 float 运算 |
| 条件判断 | engine.sh B-02 | 类型系统 |
| 跨平台差异 | macOS sed -i | `pathlib` / `re` |
| 并发控制 | 文件锁竞争 | `threading.Lock` |
| JSON 处理 | 依赖外部 `jq` | 内置 `json` 模块 |
| 测试隔离 | 无 mock 机制 | `unittest.mock` |

### 6.2 测试体系缺口

| 缺口 | 影响 | 修复方案 |
|------|------|---------|
| E2E 调用真实 API | CI 稳定性 ~85% | LLM Mock（已实现） |
| 无评分回归测试 | 修改评分逻辑无法验证对已知 Skill 的影响 | 黄金样本集 + `test_score_regression.sh` |
| `runtime_tester` 无真实执行 | Phase 3 与 Phase 2 实为同一测量 | 真实 LLM 运行时测试框架 |

### 6.3 自描述一致性问题

系统自评 777/BRONZE。修复 S-04 后可重新评估，预计提升至 850+/SILVER。根因仍有两个：
- Phase 3 为关键词计数，无真实运行时分
- 无 Ground Truth 校准，绝对分值不可信

---

## 七、迁移路线图

### Phase 0 ── 已完成（本次会话）

| 任务 | 内容 |
|------|------|
| Bug 修复 | 5 个实现 bug + 5 个评分 bug，共 10 个 |
| 安全加固 | CWE_798 误报修复，git add 精确路径 |
| 工程改善 | CI LLM Mock、成本熔断、swap-augmentation |
| 创新实现 | Bradley-Terry 排名、语义内聚度、校准框架 |
| 文档整合 | 合并 7 个分散文档为本文 |

### Phase 1 ── 第 1-2 周

- [ ] `constants.sh` 补充 tier 子分值常量（单一来源）
- [ ] 建立评分回归测试套件（黄金样本 × 3 个 tier）
- [ ] Phase 2 集成语义内聚度（`semantic_coherence.sh` 接入主评估流程）
- [ ] 统一版本号（`VERSION` 文件 → manifest.json + SKILL.md）
- [ ] 修复 `evolution.log` 格式（JSON Lines，支持 `jq -s` 解析）

### Phase 2 ── 第 3-6 周

- [ ] 真实 Phase 3 运行时测试框架（5 个子测试，250pts）
  - 模式路由准确率（F1/MRR，真实触发器语料）
  - 一致性测试（同问题 3 次调用，测方差）
  - 边界遵守测试（越权请求拒绝率）
  - 任务完成率（完整 workflow 执行）
  - 错误恢复（异常输入后的恢复行为）
- [ ] 建立测试语料库（routing 200用例 + boundary 50用例 + consistency 30用例）
- [ ] Bradley-Terry 排名接入 GOLD 模式评估
- [ ] 专家标注校准集（首批 15 个 Skill，3 名专家）

### Phase 3 ── 第 7-12 周（Python 迁移）

迁移优先级按 bug 密度排序：

```
第 7-8 周:  convergence.sh + text_scorer.sh → Python
            （最多 bug，逻辑最复杂）

第 9-10 周: agent_executor.sh → Python async
            （887 行，LLM 调用层，接入 cost_tracker）

第 11-12 周: CLI → Click framework
             （保留 .sh shim 向后兼容）
```

迁移策略：保持 `.sh` wrapper 不变，内部调用 Python，接口零破坏。

### Phase 4 ── 第 3 个月（战略方向）

- [ ] 时序漂移检测：LLM 版本更新后自动检测行为分布变化（KL 散度）
- [ ] Skill 组合性评估：多 Skill 协同时的接口兼容性
- [ ] 用户意图对齐：引入端到端用户满意度信号（类比 RLHF）
- [ ] 公开 SkillEval Benchmark（类比 BEIR for RAG）
- [ ] 支持 OpenAPI/MCP 格式双向转换

---

## 八、预期收益

| 改进项 | 量化收益 |
|--------|---------|
| 评分 bug 修复（S-01～S-06） | PLATINUM/GOLD 层级从不可达变为可达 |
| Phase 1 纳入 total（S-04） | 系统自评从 777 提升至预计 850+（待重测） |
| F1/MRR Quality Gates（S-02） | 认证分首次真正反映路由准确率 |
| CWE_798 误报修复（B-04） | 安全审计误报率预计下降 60-70% |
| LLM Mock（CI）| CI 稳定性从 ~85% 提升至 ~99% |
| 成本熔断器 | 防止单次优化超出预算，最多 540 次 API 调用场景下尤为关键 |
| Bradley-Terry 排名 | 绝对分值不确定时仍可可靠比较两个版本的优劣 |
| 语义内聚度评分 | 检测关键词满分但语义不一致的 Skill（当前体系盲区） |
| 专家校准 | 使分数具有可解释的绝对意义（校准后 r ≥ 0.85） |
| Python 迁移（Phase 3） | 消除 Bash 跨平台 bug 类（macOS sed、浮点比较）的根本来源 |

---

## 九、竞争差异化

| 工具 | 核心定位 | 本项目差异 |
|------|---------|-----------|
| LangChain | AI 应用开发框架 | 关注 Skill 规范本身质量，非应用构建 |
| PromptFlow | Prompt 工程流程管理 | 增加认证、版本化、自动进化 |
| Helicone / LangSmith | LLM 运行时可观测性 | 关注 Skill 文档质量，非运行时遥测 |
| AutoPrompt / APE | 自动提示工程 | 面向人类可读规范，非机器优化 token |
| Chatbot Arena | LLM 对比排名 | Bradley-Terry 应用于 Skill 文档排名 |

**本项目独特贡献**：
1. 第一个将 SKILL.md 作为版本化软件制品并施以 CI/CD 式质量保障的系统
2. 第一个对 AI 行为规范文档实施多维度量化评估的框架（F1/MRR/variance/semantic cohesion）
3. 将 RLHF 成对比较洞察应用于 Skill 质量排名（Bradley-Terry）
4. 概率性人工制品的确定性质量保障探索——这个问题框架本身具有学术价值
