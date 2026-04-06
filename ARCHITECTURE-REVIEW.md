# Skill-Writer v2.1.0 架构评审报告

> **日期**: 2026-04-06
> **范围**: 全项目设计与技术架构
> **目标**: 评估设计合理性与前瞻性，识别不可实现设计，提出改进路线图

---

## 一、项目概览与度量

Skill-writer 是一个 **prompt-based 元框架**，帮助 AI 平台创建、评估、优化其他 skills。由两大组件构成：

| 组件 | 描述 | 行数 | 文件数 |
|------|------|------|--------|
| 核心框架 (`skill-framework.md`) | AI 消费的 prompt 内容，16个 §-section | 693 | 1 |
| 参考文档 (`refs/`) | 自审协议、进化规范、收敛检测等 | ~500 | 5 |
| Skill 模板 (`templates/`) | CREATE 模式的结构化模板 | ~400 | 5 |
| 评估规范 (`eval/`) | 评分量表与基准 | ~200 | 2 |
| 优化规范 (`optimize/`) | 策略与反模式 | ~200 | 3 |
| Builder 工具链 (`builder/src/`) | Node.js CLI，生成平台输出 | 3,543 | ~15 |
| 平台模板 (`builder/templates/`) | 6 平台的嵌入模板 | 12,628 | 6 |
| 生成输出 (`platforms/`) | Builder 生成的最终文件 | ~12,177 | 6 |

**总计**: 核心内容 ~3,844 行，工具链 ~3,543 行，模板+输出 ~24,805 行。

---

## 二、设计理念深度分析

### 2.0.1 核心设计哲学

框架建立在 5 个基础设计模式（"Google 5"）之上：

| 模式 | 职责 | 实现位置 |
|------|------|----------|
| **Tool Wrapper** | 按需加载外部规范作为权威源 | §1 引用 companion files |
| **Generator** | 基于模板的结构化输出 | §5 CREATE 9 阶段 |
| **Reviewer** | 多遍自审 + 严重度分级（ERROR/WARNING/INFO）| §12 + `refs/self-review.md` |
| **Inversion** | 阻断式需求澄清，先问后做 | §7 Inversion Gate |
| **Pipeline** | 严格阶段排序 + 硬检查点 | §4 LoongFlow |

16 个 §-section 的编排逻辑是**闭环生命周期**而非功能堆砌：

```
§1 (Identity) → §2 (Router) → §3 (Degradation fallback)
    ↓
§4 (LoongFlow meta-pattern: Plan → Execute → Summarize)
    ↓
§5-§9 (5 模式详规: CREATE → LEAN → EVALUATE → OPTIMIZE → 收敛)
    ↓
§10 (Evolution triggers) → §11-§13 (横切关注: Security, Self-Review, Audit)
    ↓
§14 (Usage Examples) → §15 (UTE injection) → §16 (INSTALL deploy)
```

**叙事主线**：创建 skill（含需求澄清和模板）→ 快速验证（LEAN）→ 深度评估（4阶段）→ 失败时优化 → 自进化 → 部署。

### 2.0.2 模式间流转 — 隐式规则问题

模式间的流转是**单向无环**的，但文档存在关键歧义：

```
CREATE ──→ LEAN ──→ EVALUATE ──→ OPTIMIZE
  │          │          │            │
  │     (PASS→done)  (PASS→cert)  (converge→done)
  │     (UNCERTAIN→) (FAIL→)      (stuck→HUMAN_REVIEW)
  └─────────────────────────────────┘
                  INSTALL (独立)
```

**未明确的规则**：
1. OPTIMIZE 完成后是否重新运行 EVALUATE？§9 使用 LEAN 式 7 维重评分，但不触发完整 4 阶段管道。**建议**：明确 OPTIMIZE 后若分数 ≥700 则以 LEAN 评分为准，<700 则触发 full EVALUATE。
2. CREATE 的 CERTIFIED 认证是否绕过 LEAN 的 "24h 内安排 full EVALUATE" 要求？**建议**：在 §2 末尾添加"模式流转规则"小节。
3. §16 INSTALL 与其他模式完全独立——这是合理的，但文档未显式声明。

### 2.0.3 Inversion 模式的三个设计缺口

§7 定义了阻断式提问（CREATE 6Q / EVALUATE 3Q / OPTIMIZE 2Q），设计动机正确（先问后做），但：

| 缺口 | 说明 | 建议 |
|------|------|------|
| **无答案验证** | 用户回答"输入是文本"算满足吗？无最低完备性要求 | 添加 `answer_validation: minimal\|standard\|strict` 配置 |
| **无拒答处理** | 用户拒绝回答某问题时无 fallback/abort 路径 | 添加 "skip with default / abort" 选项 |
| **无领域自适应** | api-integration 和 data-pipeline 模板使用相同的通用 6 问 | 模板可声明追加问题（`extra_questions` 字段）|

### 2.0.4 评分体系内部不一致

三种不同的评分机制并存，增加了 AI 混淆风险：

| 上下文 | 分制 | 维度数 | 来源 |
|--------|------|--------|------|
| LEAN (§6) | 500 分 → ×2 映射到 1000 | 7 维 | `eval/rubrics.md` |
| EVALUATE (§8) | 原生 1000 分 | 4 阶段（Structure 100 + Dims 300 + Security 200 + Holistic 400）| `eval/rubrics.md` |
| OPTIMIZE re-score (§9) | "re-score all 7 dimensions" | 7 维 | 未明确使用哪个分制 |

**具体问题**：
- Phase 2→3 方差公式 `|(phase2_score/3) - (phase3_score/4)|` 的除法原因未说明（归一化到每分密度），读者必须自行推导
- OPTIMIZE 的 "7 dimensions" 与 EVALUATE Phase 2 的 "6 sub-dimensions" 不一致
- **建议**：在 §8 添加方差公式推导注释；在 §9 明确声明使用 LEAN 7 维权重

### 2.0.5 LoongFlow 错误恢复的外部化风险

§4 定义了 Plan-Execute-Summarize 元模式，但错误恢复完全委托给 `refs/self-review.md §4`：

| 模式 | PLAN 是否显式 | EXECUTE | SUMMARIZE | 错误恢复 |
|------|:---:|:---:|:---:|:---:|
| CREATE (§5) | ✅ Phase 3 | ✅ Phases 4-8 | ✅ Phase 9 | 外部 |
| LEAN (§6) | 隐式 | ✅ | ✅ | 外部 |
| EVALUATE (§8) | 隐式 | ✅ | ✅ | 外部 |
| OPTIMIZE (§9) | ✅ Step 4 | ✅ Steps 5-8 | ✅ Post-loop | 部分内置（step 6: rollback） |

**风险**：如果 companion 文件不可用（如平台不支持外部文件加载），LoongFlow 完全没有错误恢复 fallback。

**建议**：在 §4 内嵌最小错误恢复规则（retry 1 次 + 降级到 HUMAN_REVIEW）。

---

## 三、设计合理性评估（原评估 + 扩展）

### 3.1 模式分离 — ✅ 合理

5 个模式（CREATE / LEAN / EVALUATE / OPTIMIZE / INSTALL）职责边界清晰：

- **CREATE**: 9 阶段从需求到完整 skill，包含 Inversion（阻断式需求澄清）
- **LEAN**: 500 分快速评估，适合迭代中的轻量检查
- **EVALUATE**: 1000 分 4 阶段完整评估管道
- **OPTIMIZE**: 7 维度 9 步循环，带收敛检测
- **INSTALL**: 多平台部署，与 Builder 工具链对接

**LoongFlow 编排**（Plan-Execute-Summarize）比状态机更适合 LLM 的自然工作方式。
**自审协议**（3-pass: Generate/Review/Reconcile）替代了不可实现的 Multi-LLM 合议，是 v2.1.0 最重要的务实改进。

### 3.2 SSOT 架构 — ⚠️ 基本合理，存在缺口

Builder 的 Reader→Embedder→Adapter 管道实现了 Single Source of Truth：

```
refs/, templates/, eval/, optimize/  (权威源)
        ↓  reader.js
    coreData 对象
        ↓  embedder.js
    平台无关的嵌入内容
        ↓  platform adapters
    6 个平台特定输出文件
```

**缺口**: `validate.js` 检查 12 个 companion 文件的存在性，但 `reader.js` 只嵌入其中 7 个：

| 文件 | validate 检查 | reader 嵌入 | 状态 |
|------|:---:|:---:|------|
| `refs/security-patterns.md` | ✅ | ✅ | 正常 |
| `refs/convergence.md` | ✅ | ✅ | 正常 |
| `refs/use-to-evolve.md` | ✅ | ❌ | **缺口** |
| `refs/self-review.md` | ✅ | ❌ | **缺口** |
| `refs/evolution.md` | ✅ | ❌ | **缺口** |
| `eval/rubrics.md` | ✅ | ✅ | 正常 |
| `eval/benchmarks.md` | ✅ | ✅ | 正常 |
| `optimize/strategies.md` | ✅ | ✅ | 正常 |
| `optimize/anti-patterns.md` | ✅ | ✅ | 正常 |
| `templates/*.md` (4个) | ✅ | ✅ | 正常 |

**建议**: 要么扩展 reader 嵌入所有文件，要么在 validate 中区分 "必须嵌入" 和 "仅需存在"。

### 3.3 平台适配器模式 — ✅ 合理，可优化

6 个适配器（opencode / openclaw / claude / cursor / openai / gemini）统一接口：

```javascript
{ name, template, formatSkill(), getInstallPath(), generateMetadata(), validateSkill() }
```

**优点**: 多态使用，新增平台只需创建 adapter + template。

**问题**:
- `claude.js`（137行）与 `gemini.js`（132行）代码 **95% 重复**，应提取共享基类
- `openclaw.js` 第 32-33 行 features 数组有重复 `self-review` 条目
- `openclaw.js`（337行）显著复杂于其他适配器，因为硬编码了 LoongFlow 和自审注入逻辑

### 3.4 安全模型 — ✅ 合理

- CWE 矩阵（`refs/security-patterns.md`）嵌入所有生成输出
- Red Lines（严禁条款）在 §11 中定义，validate 命令验证其存在
- `security-scan.yml` CI 管道包含 npm audit + TruffleHog + CodeQL

### 3.5 评分体系 — ⚠️ 部分合理

- 1000 分 4 阶段评估管道：**设计合理**，AI 可遵循评分量表打分
- 认证分级（PLATINUM ≥ 950 / GOLD ≥ 850 / SILVER ≥ 700 / BRONZE ≥ 500 / FAIL）：**合理**
- **问题**: 方差门控（variance_gates: platinum=10, gold=15...）要求跨维度分数标准差在阈值内，AI 难以精确计算标准差

---

## 四、不可实现 / 理想化设计识别

> 标记为"理想化"并非批评。在 prompt 工程中，理想化规格可以起到 **方向指引** 作用。
> 但需要明确区分 **AI 可严格遵循** 和 **AI 尽力模拟** 的边界。

### 3.1 §2 模式路由器置信度公式 — 理想化

```
confidence = primary_match × 0.5 + secondary_match × 0.2
           + context_match × 0.2 + no_negative × 0.1
```

- AI 无法对 `primary_match` 等因子赋精确 0-1 数值
- 实际效果：AI 使用 **直觉匹配** 而非数学计算
- **建议**: 改为决策树或加权清单格式，例如：
  ```
  1. 用户请求是否明确包含模式关键词？(最重要)
  2. 上下文是否暗示该模式？(次要)
  3. 是否有排除该模式的信号？(一票否决)
  ```
- **位置**: `skill-framework.md` §2

### 3.2 convergence.md Python 伪代码 — 理想化

`volatility_check()` 和 `plateau_check()` 用 Python 编写，包含标准差计算：

```python
stddev = variance ** 0.5
return stddev < 2.0  # 2.0 分阈值，基于 1000 分量表
```

- AI 执行 OPTIMIZE 循环时 **不能运行 Python**
- 实际效果：AI 读懂意图后用 **自然语言推理** 判断是否收敛
- **建议**: 改为自然语言规则（"如果最近 10 轮分数变化幅度均小于 2 分，判定收敛"）
- **位置**: `refs/convergence.md` §2-§4

### 3.3 审计跟踪 (.skill-audit/) — 理想化

- `refs/evolution.md` 引用 `.skill-audit/framework.jsonl` 和 `usage.jsonl`
- §13 定义了审计日志的 JSON schema
- prompt-based AI **没有持久文件系统**，无法跨会话写入/读取 JSONL

**建议**: 将审计跟踪重新定位为 **"输出格式规范"**——当 AI 被要求生成审计记录时应遵循此格式，而非期望 AI 自动维护持久存储。

**位置**: `refs/evolution.md` §1 检测方法, `skill-framework.md` §13

### 3.4 UTE 累计调用计数器 — 理想化

- `cumulative_invocations` 字段在 UTE frontmatter 中定义
- cadence-gated 健康检查（每 N 次调用执行一次）依赖此计数器
- AI 会话间 **计数器重置为 0**

**建议**: 改为 "每次调用时检查 UTE 健康" 或 "依赖外部 CI 管道触发检查"。

**位置**: `refs/use-to-evolve.md`

### 3.5 自进化三触发系统 — 部分理想化

| 触发器 | 可实现性 | 依赖 |
|--------|----------|------|
| Trigger 1 — 阈值降级 | ❌ 理想化 | 需要 `.skill-audit/` 持久存储 |
| Trigger 2 — 时间过期 | ✅ 可实现 | 对比 frontmatter `updated` 字段与当前日期 |
| Trigger 3 — 使用量不足 | ❌ 理想化 | 需要调用计数持久存储 |

**建议**: 保留 Trigger 2 作为核心机制，将 Trigger 1/3 标注为 "需要外部工具链支持才能实现"。

**位置**: `refs/evolution.md` §1

---

## 五、Builder 工具链评估

### 总体评分: 7.5 / 10（从 8.5 下调，基于深度分析）

**架构优势**:
- 模块化清晰：reader / embedder / platforms / commands 四层分离
- 错误隔离好：单平台构建失败不影响其他平台
- validate 命令检查全面（12 文件 + 占位符 + §N sections + Red Lines + UTE 11 字段）
- inspect 命令提供丰富的诊断信息

### 数据流深度分析

```
Source Files (refs/, templates/, eval/, optimize/)
    ↓  reader.js: glob 发现 → parseFile() → flat object {create, evaluate, optimize, shared}
    ↓  [有损转换] YAML anchors/aliases → yaml.dump(lineWidth:-1, noRefs:true) 丢弃
    ↓
coreData 对象
    ↓  embedder.js: generateSkillFile()
    ↓  Template load → Metadata placeholder → Mode embedding → Shared resources → Frontmatter → UTE
    ↓  [静默失败] 缺失 placeholder → 保留 {{KEY}} 原文，不报错
    ↓
Platform-agnostic content
    ↓  adapters: formatSkill() → getInstallPath() → generateMetadata() → validateSkill()
    ↓  [接口违反] OpenAI 返回 JSON，其余返回 Markdown string
    ↓
6 个平台输出文件 (platforms/)
```

**有损转换**：`yaml.dump({noRefs: true})` 丢弃 YAML anchors/aliases，如果源文件使用 `&anchor` / `*ref` 语法，嵌入结果会丢失引用关系。

### 命令模块交互问题

| 命令 | 使用 reader.js? | 路径定义来源 | 共享逻辑 |
|------|:---:|------|------|
| build.js | ✅ `readAllCoreData()` | reader.js | — |
| validate.js | ❌ 硬编码路径 | 自身 line 18-22 | 与 reader 路径定义重复 |
| inspect.js | ❌ 直接读文件 | 自身（8 种路径尝试）| — |
| dev.js | ✅ `readAllCoreData()` | reader.js | 与 build.js 重复 metadata 逻辑 |

**SSOT 断裂**：修改文件路径需要同步更新 3 处定义（reader.js、validate.js、inspect.js）。

### 问题清单（扩展版）

| # | 严重度 | 问题 | 文件 | 详情 |
|---|--------|------|------|------|
| B1 | **高** | 无测试套件 | — | 整个 builder 零单元/集成测试 |
| B2 | **高** | 静默失败 | `embedder.js:92-94` | 缺失 placeholder 保留 `{{KEY}}` 原文不报错，输出可能包含裸标记 |
| B3 | **高** | SSOT 三处断裂 | `reader.js` / `validate.js` / `inspect.js` | 文件路径分别硬编码，不同步 |
| B4 | 中 | embedder 死代码 | `embedder.js:667-756` | ~~`extractPlaceholders()`, `applyPlatformTransforms()`, `validateEmbeddedContent()` 导出但未使用~~ **已修复：移除导出** |
| B5 | 中 | adapter 代码重复 | `claude.js` / `gemini.js` | ~90% 相同代码（仅差 name、install path、1 个 frontmatter 校验块）|
| B6 | 中 | Frontmatter 重复风险 | `embedder.js:536+574` | 如果模板已含 `---` frontmatter，拼接后产生双重 frontmatter |
| B7 | 中 | 适配器接口违反 | `openai.js` | `formatSkill()` 返回 JSON，其余返回 Markdown，无类型约束 |
| B8 | 中 | SSOT 缺口 | `reader.js` | 3 个 refs 文件（self-review, evolution, use-to-evolve）验证但不嵌入 |
| B9 | 低 | ~~features 重复~~ | `openclaw.js` | ~~`self-review` 出现两次~~ **已修复** |
| B10 | 低 | 双重格式化 | `build.js:139` | `formatForPlatform()` 在 `generateSkillFile()` 之后再次调用 |
| B11 | 低 | CRLF 敏感 | `inspect.js:63` | 标题正则 `/^(#{1,6})\s+(.+)$/` 在 Windows CRLF 下匹配失败 |
| B12 | 低 | 占位符名称限制 | `embedder.js:39` | `/\{\{(\w+)\}\}/g` 不匹配 `{{OUTER-KEY}}` 或 `{{outer.key}}` |
| B13 | 低 | UTE 注入正则 | `embedder.js:599` | `##\s+§UTE` 过于宽松，注释中的匹配会导致跳过注入 |

---

## 六、Companion 文件质量评估

### 6.1 refs/ 参考文档

| 文件 | 行数 | AI 可操作性 | 主要问题 |
|------|------|:---:|------|
| `self-review.md` | ~120 | ⚠️ | 3-pass 协议结构清晰，但超时策略（60s/pass, 180s total）在 prompt 环境下无法精确计时 |
| `convergence.md` | ~100 | ❌ | Python 伪代码（stddev, plateau_check）AI 不可执行；**建议改为自然语言规则** |
| `evolution.md` | ~90 | ⚠️ | 3 触发器中 2 个依赖持久存储（audit trail + invocation counter），仅时间触发可靠 |
| `use-to-evolve.md` | ~80 | ⚠️ | 11 字段 UTE frontmatter 设计合理，但 cadence-gated 健康检查依赖不可持久的计数器 |
| `security-patterns.md` | ~110 | ✅ | CWE 矩阵全面、结构化良好，是**最具操作性**的 companion 文件 |

### 6.2 eval/ 评估规范

| 文件 | 质量 | 说明 |
|------|------|------|
| `rubrics.md` | ✅ 高 | 6 维度评分量表清晰，权重合理（Security 25% 最高） |
| `benchmarks.md` | ⚠️ 中 | 基准定义合理但**缺少参考 skill 样本**（只有评分标准，无实际基准数据） |

### 6.3 optimize/ 优化规范

| 文件 | 质量 | 说明 |
|------|------|------|
| `strategies.md` | ✅ 高 | 7 策略覆盖全面（结构/安全/性能/可读性/鲁棒性/可维护性/领域适配） |
| `anti-patterns.md` | ✅ 高 | 反模式分类良好，每个附带修复建议 |

### 6.4 templates/ 模板

4 个领域模板 + 1 个 UTE snippet，占位符命名一致（`{{camelCase}}`）。

### 6.5 跨文件一致性问题

- `convergence.md` 使用 Python 变量名 `score_history`，`evolution.md` 使用 YAML 字段 `audit_history`——概念重叠但命名不一致
- `self-review.md` 定义 3-pass 协议，`skill-framework.md` §12 引用它但**摘要与原文存在措辞差异**
- ~~`skill-framework.md` §15 硬编码 `FRAMEWORK_VERSION = "2.0.0"` 但文件头声明 v2.1.0~~ **已修复**

---

## 七、CI/CD 与文档评估

### 7.1 CI 死代码

`.github/workflows/security-scan.yml` 第 52-71 行的 `cwe-validation` job 引用了 v2.1.0 中已删除的 `core/shared/security/cwe-patterns.yaml`。该 job 设置了 `continue-on-error: true` 所以不会阻塞，但属于死代码。

**建议**: 删除该 job，或改为验证 `refs/security-patterns.md` 的格式。

### 7.2 文档一致性

- `README.md` 中 code-reviewer 示例显示 820/SILVER，但实际 eval 报告为 947/GOLD
- **建议**: 统一评分数据，或在示例中标注 "仅供演示"

### 7.3 CI 管道覆盖

当前 CI 包含 validate → build → release → deploy-docs，**缺少自动化测试步骤**（因为没有测试）。

---

## 八、前瞻性评估

### 8.1 可扩展性 — ✅ 良好

| 扩展场景 | 复杂度 | 说明 |
|----------|--------|------|
| 新增平台 | 低 | 创建 adapter.js + template.md，注册到 index.js |
| 新增模式 | 中 | skill-framework.md 添加 §N + 路由器 + companion files |
| 新增模板类型 | 低 | `templates/` 下添加 .md 文件 |
| 新增评估维度 | 低 | 修改 `eval/rubrics.md` |

### 8.2 风险矩阵

| 风险 | 可能性 | 影响 | 缓解方案 |
|------|--------|------|----------|
| **模板膨胀** — 5 个 MD 模板共 12,628 行，大量重复内容 | 高 | 中 | 提取共享 sections 到 `builder/templates/shared/`，模板只包含平台差异 |
| **无测试覆盖** — 重构风险高，回归无保障 | 已发生 | 高 | 优先为 reader、embedder、validate 写单元测试 |
| **理想化设计积累** — 新贡献者混淆"必须遵循"和"尽力而为" | 中 | 中 | 在文档中用 `[ENFORCED]` / `[ASPIRATIONAL]` 标签明确区分 |
| **AI 平台差异化加速** — 各平台 prompt 格式、能力持续分化 | 高 | 中 | adapter 自动化测试 + 平台差异对比报告 |
| **Prompt 长度增长** — 生成输出已达 2,400-2,700 行 | 中 | 高 | 考虑按需加载（仅嵌入用户请求的模式） |
| **LoongFlow 外部依赖** — 错误恢复完全委托 companion file | 中 | 高 | 在 §4 内嵌最小 fallback 规则 |
| **评分体系碎片化** — 500/1000/7维 三套并存 | 高 | 中 | 统一为 1000 分制，LEAN 直接用 7 维子集 |
| **Embedder 静默失败** — 缺失 placeholder 输出 `{{KEY}}` 裸标记 | 已发生 | 中 | 添加严格模式，缺失 placeholder 时报错而非静默 |

### 8.3 演进路线图

#### 短期 — v2.2.0（维护性改进）

1. 删除 CI 死代码（`security-scan.yml` cwe-validation job）
2. 修复 `openclaw.js` 重复 features
3. 清理 `embedder.js` 未使用导出
4. 统一 README 评分数据
5. 在 SSOT 缺口文件上添加注释说明

#### 中期 — v3.0.0（质量提升）

1. **为 builder 添加测试套件**：reader（SSOT 读取）、embedder（占位符替换）、validate（规则完整性）
2. **提取共享适配器基类**：claude/gemini 继承 `markdownAdapter`
3. **标注理想化设计**：在 `skill-framework.md` 和 companion files 中用 `[ASPIRATIONAL]` / `[ENFORCED]` 标签
4. **改写 convergence.md**：Python 伪代码 → 自然语言规则
5. **审计跟踪重定位**：从 "持久存储要求" 改为 "输出格式规范"

#### 长期 — v4.0.0（架构演进）

1. **按需模式加载**：减少单次 prompt 长度，只嵌入用户请求的模式
2. **模板去重机制**：共享 sections + 平台差异覆盖
3. **外部持久化接口**：定义标准 API，使 audit trail 和 UTE 计数器可选对接外部存储
4. **自动化平台适配测试**：CI 中对比各平台输出的结构一致性

---

## 九、总结

### 设计理念：8.5/10

框架的核心设计哲学——"Google 5" 模式（Tool Wrapper / Generator / Reviewer / Inversion / Pipeline）+ LoongFlow 元编排 + 闭环生命周期——是 **深思熟虑且内在一致的**。v2.1.0 用自审协议替代 Multi-LLM 合议是一个关键的务实转向。

主要扣分项：模式间流转规则隐式化、Inversion 缺乏答案验证、评分体系三套并存。

### 架构实现：7/10

Builder 工具链的模块化设计合理（reader→embedder→adapter），但实现质量存在较多问题：静默失败（placeholder 缺失不报错）、路径定义三处断裂、适配器接口违反（OpenAI JSON vs 其余 Markdown）、零测试覆盖。

### 前瞻性：7/10

平台扩展性良好（新增平台只需 adapter + template），但面临模板膨胀、prompt 长度增长、LoongFlow 外部依赖等中长期风险。

### 本轮评审已修复的问题

| # | 问题 | 修复 |
|---|------|------|
| 1 | ~~CI cwe-validation 死代码~~ | 删除该 job（上一轮） |
| 2 | ~~openclaw.js self-review 重复~~ | 删除重复条目（上一轮） |
| 3 | ~~§15 FRAMEWORK_VERSION = "2.0.0"~~ | 改为 "2.1.0" |
| 4 | ~~embedder.js 3 个未使用导出~~ | 移除导出 |
| 5 | ~~formatFrontmatter null 静默~~ | 添加 warning 日志 |

### 最需要立即行动的 5 件事

1. **为 builder 添加测试套件** — 这是当前最大的技术债，阻碍所有后续重构
2. **统一路径定义** — reader.js / validate.js / inspect.js 三处硬编码路径应收敛到单一来源
3. **添加 embedder 严格模式** — placeholder 缺失时报错而非静默，防止 `{{KEY}}` 泄漏到输出
4. **标注理想化设计** — 区分 `[ENFORCED]` 和 `[ASPIRATIONAL]`，降低新贡献者困惑
5. **明确模式流转规则** — 在 §2 Mode Router 中添加允许/禁止的模式转换路径
