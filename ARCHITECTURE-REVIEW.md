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

## 二、设计合理性评估

### 2.1 模式分离 — ✅ 合理

5 个模式（CREATE / LEAN / EVALUATE / OPTIMIZE / INSTALL）职责边界清晰：

- **CREATE**: 9 阶段从需求到完整 skill，包含 Inversion（阻断式需求澄清）
- **LEAN**: 500 分快速评估，适合迭代中的轻量检查
- **EVALUATE**: 1000 分 4 阶段完整评估管道
- **OPTIMIZE**: 7 维度 9 步循环，带收敛检测
- **INSTALL**: 多平台部署，与 Builder 工具链对接

**LoongFlow 编排**（Plan-Execute-Summarize）比状态机更适合 LLM 的自然工作方式。
**自审协议**（3-pass: Generate/Review/Reconcile）替代了不可实现的 Multi-LLM 合议，是 v2.1.0 最重要的务实改进。

### 2.2 SSOT 架构 — ⚠️ 基本合理，存在缺口

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

### 2.3 平台适配器模式 — ✅ 合理，可优化

6 个适配器（opencode / openclaw / claude / cursor / openai / gemini）统一接口：

```javascript
{ name, template, formatSkill(), getInstallPath(), generateMetadata(), validateSkill() }
```

**优点**: 多态使用，新增平台只需创建 adapter + template。

**问题**:
- `claude.js`（137行）与 `gemini.js`（132行）代码 **95% 重复**，应提取共享基类
- `openclaw.js` 第 32-33 行 features 数组有重复 `self-review` 条目
- `openclaw.js`（337行）显著复杂于其他适配器，因为硬编码了 LoongFlow 和自审注入逻辑

### 2.4 安全模型 — ✅ 合理

- CWE 矩阵（`refs/security-patterns.md`）嵌入所有生成输出
- Red Lines（严禁条款）在 §11 中定义，validate 命令验证其存在
- `security-scan.yml` CI 管道包含 npm audit + TruffleHog + CodeQL

### 2.5 评分体系 — ⚠️ 部分合理

- 1000 分 4 阶段评估管道：**设计合理**，AI 可遵循评分量表打分
- 认证分级（PLATINUM ≥ 950 / GOLD ≥ 850 / SILVER ≥ 700 / BRONZE ≥ 500 / FAIL）：**合理**
- **问题**: 方差门控（variance_gates: platinum=10, gold=15...）要求跨维度分数标准差在阈值内，AI 难以精确计算标准差

---

## 三、不可实现 / 理想化设计识别

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

## 四、Builder 工具链评估

### 总体评分: 8.5 / 10

**架构优势**:
- 模块化清晰：reader / embedder / platforms / commands 四层分离
- 错误隔离好：单平台构建失败不影响其他平台
- validate 命令检查全面（12 文件 + 占位符 + §N sections + Red Lines + UTE 11 字段）
- inspect 命令提供丰富的诊断信息

### 问题清单

| # | 严重度 | 问题 | 文件 | 详情 |
|---|--------|------|------|------|
| B1 | **高** | 无测试套件 | — | 整个 builder 零单元/集成测试 |
| B2 | 中 | SSOT 缺口 | `reader.js` | 3 个 refs 文件验证但不嵌入 |
| B3 | 中 | embedder 死代码 | `embedder.js` | `extractPlaceholders()`, `applyPlatformTransforms()`, `validateEmbeddedContent()` 导出但未使用 |
| B4 | 中 | adapter 代码重复 | `claude.js` / `gemini.js` | 95% 相同代码 |
| B5 | 低 | features 重复 | `openclaw.js:32-33` | `self-review` 出现两次 |
| B6 | 低 | 双重格式化 | `build.js:139` | `formatForPlatform()` 在 `generateSkillFile()` 之后再次调用 |
| B7 | 低 | CI 环境兼容 | `dev.js:147` | `getInstallPath()` 在受限环境可能失败 |
| B8 | 低 | 占位符正则 | `validate.js:54` | 只匹配 `{{UPPERCASE_UNDERSCORE}}`，不捕获其他格式 |

---

## 五、CI/CD 与文档评估

### 5.1 CI 死代码

`.github/workflows/security-scan.yml` 第 52-71 行的 `cwe-validation` job 引用了 v2.1.0 中已删除的 `core/shared/security/cwe-patterns.yaml`。该 job 设置了 `continue-on-error: true` 所以不会阻塞，但属于死代码。

**建议**: 删除该 job，或改为验证 `refs/security-patterns.md` 的格式。

### 5.2 文档一致性

- `README.md` 中 code-reviewer 示例显示 820/SILVER，但实际 eval 报告为 947/GOLD
- **建议**: 统一评分数据，或在示例中标注 "仅供演示"

### 5.3 CI 管道覆盖

当前 CI 包含 validate → build → release → deploy-docs，**缺少自动化测试步骤**（因为没有测试）。

---

## 六、前瞻性评估

### 6.1 可扩展性 — ✅ 良好

| 扩展场景 | 复杂度 | 说明 |
|----------|--------|------|
| 新增平台 | 低 | 创建 adapter.js + template.md，注册到 index.js |
| 新增模式 | 中 | skill-framework.md 添加 §N + 路由器 + companion files |
| 新增模板类型 | 低 | `templates/` 下添加 .md 文件 |
| 新增评估维度 | 低 | 修改 `eval/rubrics.md` |

### 6.2 风险矩阵

| 风险 | 可能性 | 影响 | 缓解方案 |
|------|--------|------|----------|
| **模板膨胀** — 5 个 MD 模板共 12,628 行，大量重复内容 | 高 | 中 | 提取共享 sections 到 `builder/templates/shared/`，模板只包含平台差异 |
| **无测试覆盖** — 重构风险高，回归无保障 | 已发生 | 高 | 优先为 reader、embedder、validate 写单元测试 |
| **理想化设计积累** — 新贡献者混淆"必须遵循"和"尽力而为" | 中 | 中 | 在文档中用 `[ENFORCED]` / `[ASPIRATIONAL]` 标签明确区分 |
| **AI 平台差异化加速** — 各平台 prompt 格式、能力持续分化 | 高 | 中 | adapter 自动化测试 + 平台差异对比报告 |
| **Prompt 长度增长** — 生成输出已达 2,400-2,700 行 | 中 | 高 | 考虑按需加载（仅嵌入用户请求的模式） |

### 6.3 演进路线图

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

## 七、总结

### 设计合理性：8/10

Skill-writer 的核心设计——模式分离、LoongFlow 编排、SSOT 构建管道——是 **合理且务实的**。v2.1.0 用自审协议替代 Multi-LLM 合议是一个关键的务实转向。主要扣分项是 SSOT 缺口和理想化设计缺乏标注。

### 前瞻性：7/10

平台扩展性良好，但面临三个中长期风险：模板膨胀、prompt 长度增长、无测试保障。路线图中的按需加载和模板去重是关键演进方向。

### 最需要立即行动的 3 件事

1. **为 builder 添加测试套件** — 这是当前最大的技术债，阻碍所有后续重构
2. **标注理想化设计** — 区分 `[ENFORCED]` 和 `[ASPIRATIONAL]`，降低新贡献者困惑
3. **修复 CI 死代码和小 bug** — cwe-validation job、openclaw 重复 features
