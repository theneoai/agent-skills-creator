# Skill 项目致命问题分析报告

**日期**: 2026-03-29
**版本**: 2.3.0
**状态**: 待修复

---

## 🔴 P0 - 必须立即修复

### 1. 变量作用域错误 (Critical Bug)
**文件**: `engine/orchestrator.sh` 第 43 行
```bash
export PARENT_SKILL_PATH   # 在 workflow_init 调用之后！
workflow_init "$user_prompt" "$output_file" "${PARENT_SKILL_PATH:-}"
```
**问题**: `workflow_init` 在第 46 行被调用时使用 `PARENT_SKILL_PATH`，但该变量在第 43 行才被 export。
**影响**: parent skill 路径传递失败，继承功能失效。
**修复**: 将 export 移到调用之前。

---

### 2. 评分体系不统一 (Critical Design Flaw)
**文件**: `lean-orchestrator.sh` vs `eval/main.sh`

| 维度 | lean-orchestrator.sh | eval/main.sh |
|------|---------------------|--------------|
| 总分 | 600pts (parse:100 + text:350 + runtime:150) | 1155pts (100+505+450+100) |
| Tier阈值 | GOLD≥570, SILVER≥510, BRONZE≥420 | PLATINUM≥950, GOLD≥900, SILVER≥800, BRONZE≥700 |

**问题**: 两个评测系统完全不兼容，无法对比结果。
**修复**: 统一使用 eval/main.sh 作为标准，删除 lean-orchestrator.sh 的重复评分逻辑。

---

### 3. F1/MRR硬编码 (Critical Logic Bug)
**文件**: `eval/main.sh` 第 381-382, 628-633 行
```bash
# Line 381-382: 无论实际结果如何都使用默认值
[[ -z "$f1_score" ]] && f1_score=0.5
[[ -z "$mode_accuracy" ]] && mode_accuracy=0.5

# Line 628-633: HTML报告中的值是硬编码常量
-e "s|%F1%|0.75|g" \
-e "s|%MRR%|0.70|g" \
-e "s|%TRIGGER_ACC%|0.72|g" \
```
**问题**: 无论实际测试结果如何，F1/MRR在最终报告中始终是0.75/0.70/0.72。
**修复**: 使用实际评测结果替换硬编码值。

---

### 4. 路径依赖假设错误 (Critical Path Bug)
**文件**: `engine/lib/bootstrap.sh` 第 17-19 行
```bash
if [[ -z "${EVAL_DIR:-}" ]]; then
    EVAL_DIR="$(cd "$EVAL_DIR_FROM_ENGINE/../eval" && pwd)"
fi
```
**问题**: 假设 eval 目录在 engine 的上一级。但 `lean-orchestrator.sh` 在第 18 行使用 `${EVAL_DIR}/lib/agent_executor.sh`，如果目录结构不同会失败。
**修复**: 使用 `PROJECT_ROOT` 统一计算路径。

---

## 🔴 P1 - 高优先级

### 5. macOS专用sed语法 (Portability Bug)
**文件**: `engine/evolution/engine.sh` 第 436 行
```bash
sed -i '' "${line_num}s/.*/$specific_change/" "$skill_file"
```
**问题**: `sed -i ''` 是 macOS 特有语法，Linux 上需要 `sed -i`。
**修复**: 添加平台检测或使用 GNU sed 兼容语法。

---

### 6. Creator退出码未检查 (Error Handling)
**文件**: `engine/orchestrator/_workflow.sh` 第 147 行
```bash
new_content=$(workflow_run_creator "$evaluator_feedback")
# 退出码 $? 未被检查！
if [[ -n "$new_content" ]]; then
    workflow_append_content "$new_content"
fi
```
**问题**: 即使 `workflow_run_creator` 失败，工作流仍继续执行。
**修复**: 检查退出码并在失败时终止或回滚。

---

### 7. MRR计算错误 (Logic Bug)
**文件**: `eval/analyzer/trigger_analyzer.sh` 第 51-53 行
```bash
if [[ "$rank" -gt 0 ]]; then
    reciprocal_ranks_sum=$(echo "$reciprocal_ranks_sum + 1/$rank" | bc -l)
fi
```
**问题**: MRR只对命中的查询计算1/rank，但标准MRR定义是：
- 命中: rank = 1/rank
- 未命中: rank = 0
- MRR = Σrank / N

当前实现遗漏了未命中查询的0贡献。
**修复**: 对所有查询遍历，未命中则加0。

---

### 8. CWE检测不完整 (Security Gap)
**文件**: `eval/lib/constants.sh`

| CWE ID | 描述 | 检测状态 |
|--------|------|----------|
| CWE-798 | 硬编码凭证 | 部分(缺少base64,证书,env变量) |
| CWE-89 | SQL注入 | 缺失(无SQL模式检测) |
| CWE-78 | 命令注入 | 部分(只检查函数调用) |
| CWE-306 | 认证缺失 | 缺失 |
| CWE-862 | 授权缺失 | 缺失 |

**修复**: 添加更多CWE模式检测。

---

### 9. 快照格式不一致 (Data Inconsistency)
**文件**: `engine/evolution/engine.sh` vs `engine/evolution/rollback.sh`
```bash
# engine.sh 第 135 行: 创建 .tar.gz
tar -czf "$snapshot_file" ...

# rollback.sh 第 16,30 行: 操作 .md 文件
[[ -f "${SNAPSHOT_DIR}/${skill_name}/${snapshot_name}.md" ]]
```
**问题**: 快照创建是.tar.gz格式，但回滚查找的是.md文件。
**修复**: 统一使用.tar.gz格式。

---

## 🟠 P2 - 中优先级

### 10. 继承失败不传播错误
**文件**: `engine/agents/creator.sh` 第 66-68 行
```bash
if [[ -n "$parent_skill" ]]; then
    inherit_sections "$parent_skill" "$skill_file"  # 不检查返回值！
fi
```
**问题**: 父skill不存在时静默继续，生成不完整的skill文件。
**修复**: 检查返回值，失败时终止。

---

### 11. stuck_count误判
**文件**: `engine/evolution/engine.sh` 第 169-174 行
```bash
if (( $(echo "$delta > 0" | bc -l) )); then
    ((stuck_count=0))
else
    ((stuck_count++))  # 任何下降都累加
fi
```
**问题**: 小幅下降（如-0.01）就累加stuck_count，可能提前终止进化。
**修复**: 设置最小阈值（如-0.5）才累加。

---

### 12. HUMAN_REVIEW不阻塞
**文件**: `engine/evolution/engine.sh` 第 107-109 行
```bash
echo "Human review requested for round $current_round"
read -p "Continue? (y/n): " confirm
# 但即使不输入y也继续执行！
```
**问题**: 请求审查后不等待确认就继续。
**修复**: 阻塞直到收到确认。

---

### 13. 并发写入竞争
**文件**: `engine/evolution/usage_tracker.sh` 第 31-39 行
```bash
echo "$event_json" >> "$usage_file"  # 多worker同时写入会交错
```
**问题**: 多个worker同时写入JSONL文件会导致行交错。
**修复**: 使用文件锁或让每个worker写独立文件。

---

## 🟡 P3 - 建议改进

### 14. Lean与eval架构差异
- lean Runtime max=50, eval Runtime max=450 (9倍差距)
- 建议: 明确lean为预评估，eval为最终认证

### 15. 无收敛判定
- 只用stuck_count，不检查趋于平稳
- 建议: 添加分数波动检测

### 16. 无正向学习
- learner.sh只学失败案例，不记录成功模式
- 建议: 添加strong_triggers记录

### 17. 资源无清理
- 日志、快照、usage文件无限增长
- 建议: 添加TTL和清理机制

---

## 修复优先级

### 第一阶段 (P0)
1. 统一 lean-orchestrator.sh 和 eval/main.sh 的评分体系
2. 修复 F1/MRR 硬编码问题
3. 修复 PARENT_SKILL_PATH export 顺序

### 第二阶段 (P1)
1. 添加 JSON 验证和错误传播
2. 修复 MRR 计算逻辑
3. 统一快照格式和清理逻辑

### 第三阶段 (P2)
1. 添加收敛判定算法
2. 实现正向学习机制
3. 添加资源清理机制

---

## 总结

**最严重的3个问题**:
1. **评分体系不统一** - 无法统一评估标准
2. **F1/MRR硬编码** - 评测结果无实际意义
3. **变量作用域错误** - 继承功能完全失效

**建议修复顺序**:
1. 统一评分体系（删除lean-orchestrator.sh重复逻辑）
2. 修复F1/MRR硬编码
3. 修复orchestrator.sh的export顺序
4. 统一使用PROJECT_ROOT计算路径
