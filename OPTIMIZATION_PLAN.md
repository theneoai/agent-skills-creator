# agent-skill-creator 优化方案

> 基于与 skill-manager (awesome-skills) 对比分析

---

## 现状问题

| 问题 | 当前状态 | skill-manager 状态 |
|------|---------|-------------------|
| SKILL.md 长度 | 642 行 | 421 行 (含 references/) |
| 渐进式披露 | 全在主文件 | SKILL.md ≤300 行，细节在 references/ |
| 路径安全 | 无限制 | 强制 `/Users/lucas/.agents/skills/` 白名单 |
| 模式数量 | 6 种 (含 SECURITY/CI/CD) | 4 种 (纯 lifecycle) |
| 测试通过率 | 90% | 90% |

---

## 优化方案

### 1. 结构优化：渐进式披露

**目标**: SKILL.md 422 行 → ≤300 行

```
agent-skill-creator/
├── SKILL.md                 # ≤300 行 (当前 642)
├── references/              # 新增
│   ├── create.md           # CREATE 详细流程
│   ├── evaluate.md         # EVALUATE 详细流程
│   ├── restore.md          # RESTORE 详细流程
│   ├── tune.md             # TUNE 详细流程
│   ├── security.md         # SECURITY 模式详情
│   ├── cicd.md             # CI/CD 模式详情
│   ├── multi-agent.md      # 多智能体协作模式
│   ├── long-context.md     # 长文本处理
│   ├── quality-metrics.md  # 质量指标详解
│   └── benchmarks.md       # 基准数据
├── scripts/
└── test_results/
```

**执行**:
- 移动 §4.6-§4.10 (约 150 行) → references/
- 移动 §5 (Error Handling) → references/
- 移动 §6.1 (Worked Example) → references/
- 移动 §8.3-§8.5 (约 80 行) → references/

---

### 2. 安全强化

**对比**: skill-manager 在 tune.sh 中有路径白名单限制

**当前代码** (agent-skill-creator/scripts/skill-manager/tune.sh:16-21):
```bash
REAL_PATH=$(realpath "$SKILL_FILE" 2>/dev/null || echo "$SKILL_FILE")
SKILL_FILE="$REAL_PATH"  # 无路径验证！
```

**优化后**:
```bash
REAL_PATH=$(realpath "$SKILL_FILE" 2>/dev/null || echo "$SKILL_FILE")
if [[ ! "$REAL_PATH" =~ ^/Users/lucas/.agents/skills/ ]]; then
  echo "Error: Path outside allowed directory"
  exit 1
fi
SKILL_FILE="$REAL_PATH"
```

**应用到所有脚本**:
- [ ] score.sh
- [ ] score-v2.sh
- [ ] score-v3.sh
- [ ] validate.sh
- [ ] runtime-validate.sh
- [ ] tune.sh

---

### 3. 模式精简

**分析**: 当前 6 模式过于复杂

| 模式 | 建议 | 理由 |
|------|------|------|
| SECURITY | 合并至 EVALUATE | 始终作为前置检查 |
| CI/CD | 合并至 CREATE | 创建时自动生成 .github/workflows/ |
| CREATE/EVALUATE/RESTORE/TUNE | 保留 | 核心 lifecycle |

**优化后触发词**:
| 模式 | 触发词 |
|------|--------|
| CREATE | write, create, make, build, develop, generate |
| EVALUATE | evaluate, test, score, certify, assess, audit, review |
| RESTORE | restore, repair, recover, fix (质量相关) |
| TUNE | optimize, tune, autotune, boost, improve score |

---

### 4. 评分系统统一

**问题**: agent-skill-creator 有 9 维度，skill-manager 有 6 维度

**统一方案** (采用 skill-manager 6 维度):

| 维度 | 权重 | Floor | 说明 |
|------|------|-------|------|
| System Prompt | 20% | 6.0 | §1.1 + §1.2 + §1.3 |
| Domain Knowledge | 20% | 6.0 | 具体数据/基准 |
| Workflow | 20% | 6.0 | Done/Fail 条件 |
| Error Handling | 15% | 5.0 | 失败模式+恢复 |
| Examples | 15% | 5.0 | 5+ 场景 |
| Metadata | 10% | 5.0 | spec 合规 |

**移除维度**:
- Consistency → 合并至 Metadata
- Executability → 合并至 Workflow
- Recency → 合并至 Domain Knowledge
- LongContext → 作为可选扩展

---

### 5. 脚本增强

**5.1 添加 lib/ 模块化**

```
scripts/skill-manager/lib/
├── weights.sh          # 评分权重配置
├── trigger_patterns.sh # 触发词正则
└── constants.sh       # 常量定义
```

**5.2 改进 tune.sh**

| 特性 | 当前 | 优化后 |
|------|------|--------|
| 路径安全 | ❌ | ✅ 白名单验证 |
| CURATION 步骤 | 有 | 每 10 轮知识整合 |
| HUMAN_REVIEW | 10 轮后 | 条件触发 |
| Variance 检查 | 有 | ≥1.0 警告，≥2.0 中断 |

**5.3 添加新脚本**

```bash
# 快速验证
scripts/skill-manager/quick-validate.sh   # < 10s 快速检查

# 批量评分
scripts/skill-manager/batch-score.sh       # 批量处理多个 skill

# 报告生成
scripts/skill-manager/report.sh            # 生成评估报告
```

---

### 6. 测试覆盖增强

**当前**: test_cases/ 约 100 个测试用例

**优化目标**: 覆盖所有边界情况

| 测试类别 | 当前 | 目标 | 优先级 |
|----------|------|------|--------|
| 触发词测试 | 10 | 20 | 高 |
| 边界条件 | 15 | 30 | 高 |
| 多轮对话 | 10 | 20 | 中 |
| 安全注入 | 5 | 15 | 高 |
| 路径遍历 | 3 | 10 | 高 |
| 并发测试 | 2 | 8 | 中 |

---

### 7. 文档优化

**7.1 统一术语**

| 当前术语 | 统一术语 |
|----------|----------|
| 9-step loop | 9 步优化循环 |
| dual-track validation | 双轨验证 |
| CERTIFIED | 认证通过 |
| TraceCompliance | 追踪合规 |

**7.2 增加检查清单**

```markdown
## § 部署前检查清单

- [ ] validate.sh 通过
- [ ] score.sh ≥ 8.0
- [ ] score-v2.sh ≥ 8.0
- [ ] variance < 1.0
- [ ] 无 hardcoded credentials
- [ ] F1 ≥ 0.90 (如适用)
- [ ] MRR ≥ 0.85 (如适用)
```

---

## 实施计划

### Phase 1: 核心修复 (1 周)

| 任务 | 负责人 | 交付物 |
|------|--------|--------|
| 路径安全修复 | - | 所有脚本增加白名单 |
| 渐进式拆分 | - | references/ 目录 |
| 触发词统一 | - | SKILL.md 更新 |

### Phase 2: 脚本增强 (1 周)

| 任务 | 负责人 | 交付物 |
|------|--------|--------|
| lib/ 模块化 | - | 3 个共享模块 |
| tune.sh 增强 | - | CURATION + HUMAN_REVIEW |
| 快速验证脚本 | - | quick-validate.sh |

### Phase 3: 测试覆盖 (2 周)

| 任务 | 负责人 | 交付物 |
|------|--------|--------|
| 安全注入测试 | - | 15 个测试用例 |
| 路径遍历测试 | - | 10 个测试用例 |
| 并发测试 | - | 8 个测试用例 |

### Phase 4: 文档完善 (1 周)

| 任务 | 负责人 | 交付物 |
|------|--------|--------|
| 检查清单 | - | 部署前检查清单 |
| 术语统一 | - | 术语表 |
| 示例扩展 | - | references/examples.md |

---

## 预期效果

| 指标 | 当前 | 目标 | 提升 |
|------|------|------|------|
| SKILL.md 行数 | 642 | ≤300 | -53% |
| 路径安全 | 无 | 白名单 | +100% |
| 测试覆盖 | 100 | 150 | +50% |
| 脚本模块化 | 0 | 3 lib | +300% |
| 触发词准确率 | 99.7% | 99.9% | +0.2% |

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 拆分后引用断裂 | 高 | 自动化验证脚本 |
| 模式精简影响功能 | 中 | 保留别名兼容 |
| 测试覆盖未达标 | 中 | 优先边界用例 |

---

**生成日期**: 2026-03-27  
**版本**: 1.0  
**基于**: skill-manager v2.3.0 对比分析