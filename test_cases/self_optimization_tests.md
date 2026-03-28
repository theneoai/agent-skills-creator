# Self-Optimization Loop Test Cases

> Test suite for agent-skill-creator self-optimization feature
> Covers trigger detection, 6-step loop, multi-agent coordination, anti-patterns, and variance detection

---

## 1. Trigger Tests

### Test: Chinese Trigger Detection
- **Input**: 用户输入 "对当前 Skill 执行自优化"
- **Expected**: 系统识别 "自优化" 关键词，激活自优化循环
- **Validation**: 检查系统是否进入 OPTIMIZATION_LOOP 模式，调用 score.sh

### Test: English Trigger Detection
- **Input**: "Run self-optimize on the current skill"
- **Expected**: 系统识别 "self-optimize" 关键词，激活自优化循环
- **Validation**: 检查系统是否进入 OPTIMIZATION_LOOP 模式

### Test: Mixed Language Trigger
- **Input**: "请帮我 self-optimize 这个 skill"
- **Expected**: 系统识别英文关键词 self-optimize，激活自优化循环
- **Validation**: 混合语言场景下仍能正确触发

### Test: Trigger with Extra Whitespace
- **Input**: "自优化   " (multiple spaces after)
- **Expected**: 系统正确识别 "自优化" 关键词，不受空格影响
- **Validation**: 验证 trim 处理是否正确

### Test: Non-Trigger False Positive Prevention
- **Input**: "这个 skill 需要正常优化性能"
- **Expected**: 系统不触发自优化循环（缺少 "自优化" 或 "self-optimize"）
- **Validation**: 系统保持原有行为，不进入优化循环

### Test: Substring False Positive Prevention
- **Input**: "自动优化是个好东西"
- **Expected**: 系统不误触发自优化循环
- **Validation**: 必须精确匹配 "自优化" 或 "self-optimize"，而非包含关系

---

## 2. Loop Tests

### Test: 6-Step Loop Execution
- **Input**: "自优化" + SKILL.md (Text Score 6.5/10)
- **Expected**: 
  1. ANALYZE → score.sh 定位最弱维度 (Error Handling 5/10)
  2. PLAN → 并行部署 3-5 个专项 Agent
  3. IMPLEMENT → 定向修改 Error Handling
  4. VERIFY → score.sh + score-v3.sh 双验证
  5. LOG → 记录至 results.tsv
  6. COMMIT → 每 10 轮 Git 提交
- **Validation**: 检查 6 个步骤是否按顺序执行，每个步骤输出正确

### Test: Loop Termination at 9.5 Score
- **Input**: "自优化" + SKILL.md (Text Score 9.5/10)
- **Expected**: 循环立即终止，输出 "★★★ 达到 EXEMPLARY 标准"
- **Validation**: 验证终止条件和输出消息

### Test: Loop Termination at 5 Consecutive No-Improvement
- **Input**: "自优化" + 连续 5 轮无改善
- **Expected**: 循环终止，输出 "陷入局部最优" 警告
- **Validation**: 检查 early termination 逻辑

### Test: Loop Continuation After Improvement
- **Input**: "自优化" + 第 3 轮分数从 7.0 → 7.3
- **Expected**: 循环继续，计数器重置
- **Validation**: 验证计数器重置机制

### Test: Loop Maximum Rounds Enforcement
- **Input**: "自优化" + 设置 max_rounds=100
- **Expected**: 达到 100 轮后强制终止
- **Validation**: 验证循环不会无限执行

### Test: Weakest Dimension Identification
- **Input**: "自优化" + score.sh 输出：
  - System Prompt 8/10
  - Domain Knowledge 6/10 ⚠
  - Workflow 7/10
  - Error Handling 5/10 ⚠
  - Examples 4/10 ⚠
  - Metadata 10/10
- **Expected**: 识别 Examples (4/10) 为最弱维度，优先处理
- **Validation**: 验证权重优先级 (System > Domain > Workflow > Error > Examples > Metadata)

---

## 3. Multi-Agent Tests

### Test: Parallel Agent Deployment
- **Input**: "自优化" + 启动多 Agent 模式
- **Expected**: Security Agent、Trigger Agent、Runtime Agent、Quality Agent 并行启动
- **Validation**: 验证 4 个 Agent 同时运行，聚合结果

### Test: Agent Priority Aggregation
- **Input**: Security Agent (P0) vs Quality Agent (P3) 建议冲突
- **Expected**: Security Agent 建议优先采用
- **Validation**: 验证优先级矩阵 (Security > Runtime > Quality)

### Test: Agent Consensus Detection
- **Input**: 3/5 Agent 认为 Examples 最弱，2/5 认为 Error Handling 最弱
- **Expected**: 识别共识弱点 (Examples)，避免分歧时随机选择
- **Validation**: 验证共识算法，避免 RANDOM 选择

### Test: Agent Communication Failure Handling
- **Input**: Runtime Agent 无响应超时
- **Expected**: 降级处理，使用其他 Agent 结果，继续优化
- **Validation**: 验证 graceful degradation

### Test: EdgeCase Agent Execution
- **Input**: "自优化" + 启动 EdgeCase Agent
- **Expected**: 执行 5 类边缘用例测试（空输入、极端值、矛盾输入、角色混淆、资源限制）
- **Validation**: 验证 RESILIENCE_SCORE 输出

---

## 4. Anti-Pattern Tests

### Test: RANDOM Selection Prevention
- **Input**: 两次运行相同的 SKILL.md 和 score.sh 输出
- **Expected**: 两次优化路径完全一致（确定性）
- **Validation**: 验证不使用 RANDOM 选择改进类型

### Test: Over-Optimization Detection (9.8→9.9)
- **Input**: "自优化" + Examples 维度已达 9.8/10
- **Expected**: 跳过该维度优化，输出 "跳过已达标维度"
- **Validation**: 验证 ceiling threshold (9.5) 机制

### Test: Premature Optimization Prevention
- **Input**: "自优化" + System Prompt 8/10, Examples 4/10
- **Expected**: 优先优化 Examples (4/10)，而非 System Prompt (8/10)
- **Validation**: 验证优先队列机制

### Test: Redundant Content Detection
- **Input**: "自优化" + 添加 "accuracy > 90%" (generic placeholder)
- **Expected**: 拒绝添加，扣分处理
- **Validation**: 验证 generic content 检测

### Test: Line Count Limit Enforcement
- **Input**: "自优化" + 优化后 SKILL.md > 300 行
- **Expected**: 拒绝优化，输出 "超过 300 行限制"
- **Validation**: 验证 line count 检查

### Test: Silent Failure Detection
- **Input**: "自优化" + score.sh 返回码 ≠ 0
- **Expected**: 立即终止，记录错误日志
- **Validation**: 验证错误处理 (Fail: 任意步骤返回码 ≠ 0)

### Test: Cascade Failure Prevention
- **Input**: "自优化" + 某个 Agent 失败
- **Expected**: 熔断模式触发，隔离失败组件
- **Validation**: 验证熔断机制 (5 failures → 60s cooldown)

---

## 5. Variance Tests

### Test: Text vs Runtime Divergence Detection
- **Input**: "自优化" + Text Score 9/10, Runtime Score 5/10
- **Expected**: 检测方差 > 2.0，输出警告 "Text vs Runtime 方差过大"
- **Validation**: 验证方差计算 (Variance = |Text - Runtime|)

### Test: Variance Threshold Enforcement
- **Input**: "自优化" + 改进后方差增加 0.5
- **Expected**: 拒绝该改进，回滚更改
- **Validation**: 验证 variance < 0.5 约束

### Test: Dual-Track Evaluation Always
- **Input**: "自优化" + 只运行 score.sh
- **Expected**: 强制同时运行 runtime-validate.sh
- **Validation**: 验证双轨评估机制

### Test: Variance Check in Loop
- **Input**: "自优化" + 任何一轮方差 > 2.0
- **Expected**: 立即 alert 并 halt 循环
- **Validation**: 验证循环内 variance 检查

### Test: Score Instability Detection
- **Input**: 同一 SKILL.md 两次运行 score.sh 分数不同
- **Expected**: 检测稳定性问题，输出 "评分不稳定"
- **Validation**: 验证评分稳定性检查

### Test: Variance Impact on Certification
- **Input**: Text ≥ 8.0 AND Runtime ≥ 8.0 AND Variance < 2.0
- **Expected**: CERTIFIED = true
- **Validation**: 验证认证条件

### Test: Variance Impact on Certification (Fails)
- **Input**: Text ≥ 8.0 AND Runtime ≥ 8.0 AND Variance = 3.0
- **Expected**: CERTIFIED = false (Variance must be < 2.0)
- **Validation**: 验证方差超标拒绝认证

---

## 6. Integration Tests

### Test: score.sh Integration
- **Input**: "自优化" + 执行 score.sh
- **Expected**: 正确解析六维度输出 (System/Domain/Workflow/Error/Examples/Metadata)
- **Validation**: 验证输出格式解析

### Test: tune.sh Integration
- **Input**: "自优化" + 调用 tune.sh
- **Expected**: 正确传递 skill_file 和 max_rounds 参数
- **Validation**: 验证参数传递

### Test: validate.sh Pre-Flight Check
- **Input**: "自优化" + validate.sh
- **Expected**: 格式验证通过后才进入优化循环
- **Validation**: 验证 pre-flight check

### Test: results.tsv Logging
- **Input**: "自优化" + 完成一轮优化
- **Expected**: 记录 round, score, delta, status, weakest, improvement
- **Validation**: 验证日志格式和内容

### Test: Git Commit Every 10 Rounds
- **Input**: "自优化" + 完成第 10 轮
- **Expected**: 自动 git add + commit + push
- **Validation**: 验证 commit 消息格式 "Autotuner round N: ..."

---

## 7. Edge Case Tests

### Test: Empty SKILL.md
- **Input**: "自优化" + SKILL.md 内容为空
- **Expected**: 返回错误 "SKILL.md 不存在或为空"
- **Validation**: 验证空文件处理

### Test: Malformed Score Output
- **Input**: "自优化" + score.sh 输出格式异常
- **Expected**: 优雅降级，使用默认值继续
- **Validation**: 验证健壮的错误处理

### Test: Concurrent Optimization Requests
- **Input**: 同时发送两个 "自优化" 请求
- **Expected**: 第二个请求被拒绝或排队
- **Validation**: 验证并发控制

### Test: Score Decrease After Improvement
- **Input**: "自优化" + 改进后分数下降 7.0 → 6.8
- **Expected**: 自动回滚到改进前状态
- **Validation**: 验证回滚机制

### Test: Zero Improvement Threshold
- **Input**: "自优化" + 改进后分数不变 7.0 → 7.0
- **Expected**: 标记为 no-improvement，5 轮后终止
- **Validation**: 验证相同分数处理

### Test: Missing Dependencies
- **Input**: "自优化" + bc 命令不存在
- **Expected**: 启动前检测依赖，缺失则报错退出
- **Validation**: 验证依赖检查 (command -v bc)

### Test: Score Script Path Validation
- **Input**: "自优化" + score.sh 路径无效
- **Expected**: 预检失败，输出 "score.sh not found"
- **Validation**: 验证路径验证逻辑

---

## 8. Regression Tests

### Test: Original Anti-Pattern 1 Not Reproduced
- **Input**: 使用 score.sh 和 score-v2.sh 评分同一文件
- **Expected**: v1 和 v2 分数差异 < 1.5
- **Validation**: 验证评分一致性

### Test: Original Anti-Pattern 2 Not Reproduced
- **Input**: 多次运行相同输入的优化
- **Expected**: 优化路径完全可复现
- **Validation**: 验证确定性

### Test: Original Anti-Pattern 7 Not Reproduced
- **Input**: "自优化" + 维度已达 9.8
- **Expected**: 不会过度优化，输出 "跳过已达标维度"
- **Validation**: 验证 ceiling threshold

---

## Test Summary

| Category | Test Count | Critical Tests |
|----------|------------|----------------|
| Trigger Tests | 6 | Chinese/English trigger detection |
| Loop Tests | 6 | 6-step execution, termination conditions |
| Multi-Agent Tests | 5 | Parallel execution, priority aggregation |
| Anti-Pattern Tests | 7 | RANDOM prevention, over-optimization |
| Variance Tests | 7 | Text vs Runtime divergence |
| Integration Tests | 5 | score.sh, tune.sh, logging |
| Edge Case Tests | 8 | Empty file, concurrent requests |
| Regression Tests | 3 | Previous anti-patterns |
| **Total** | **47** | |

---

## Validation Commands

```bash
# Run trigger tests
./scripts/skill-manager/score.sh SKILL.md

# Run variance check
./scripts/skill-manager/runtime-validate.sh SKILL.md

# Run full optimization
./scripts/skill-manager/tune.sh SKILL.md 100

# Verify certification
./scripts/skill-manager/certify.sh SKILL.md
```
