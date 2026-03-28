# create-with-eval 设计文档

> **版本**: 1.0.0
> **日期**: 2026-03-28
> **作者**: theneoai <lucas_hsueh@hotmail.com>

---

## 一、概述

### 1.1 目标
重构 skill 创建工具，实现**创建时实时评估 + 使用即进化**的闭环。

### 1.2 核心特性
- **实时评估**：每编写一个 section 即时评估
- **双 Agent 循环**：Creator ↔ Evaluator 迭代直到达标
- **使用即进化**：根据使用日志动态进化，成熟度越高迭代越慢
- **多 Agent 并行**：Creator、Evaluator、Evolution Engine 并发执行

---

## 二、系统架构

```
┌──────────────────────────────────────────────────────────────┐
│                      create-with-eval                           │
├──────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                     用户交互层                          │   │
│  │                 ./main.sh --skill "需求"               │   │
│  └──────────────────────────┬───────────────────────────┘   │
│                               │                              │
│  ┌──────────────────────────▼───────────────────────────┐   │
│  │                    Orchestrator                      │   │
│  │              双Agent协调 + 进化引擎                   │   │
│  └──────────────────────────┬───────────────────────────┘   │
│                               │                              │
│         ┌───────────────────┼───────────────────┐           │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   │
│  │   Creator   │   │  Evaluator  │   │  Evolution  │   │
│  │   Agent     │◀─▶│   Agent     │   │   Engine    │   │
│  │ (编写skill) │   │ (实时评估)  │   │  (使用进化) │   │
│  └─────────────┘   └──────┬──────┘   └──────┬──────┘   │
│                             │                    │          │
│                             ▼                    ▼          │
│                    ┌─────────────────┐   ┌─────────────────┐│
│                    │unified-skill-eval│   │   usage.log   ││
│                    └─────────────────┘   └─────────────────┘│
│                                                                  │
└──────────────────────────────────────────────────────────────┘
```

---

## 三、目录结构

```
create-with-eval/
├── main.sh                      # CLI 主入口
├── orchestrator.sh              # 双Agent协调器
│
├── agents/
│   ├── creator.sh              # Creator Agent
│   └── evaluator.sh             # Evaluator Agent (wrapper)
│
├── evolution/
│   ├── engine.sh               # 进化引擎主控
│   ├── analyzer.sh             # LLM 日志分析
│   ├── summarizer.sh           # LLM 总结提炼
│   ├── improver.sh             # LLM 执行改进
│   ├── rollback.sh             # 回滚机制
│   └── threshold.sh            # 动态阈值计算
│
├── prompts/
│   ├── creator-system.md       # Creator 系统提示词
│   ├── creator-user.md         # Creator 用户提示词
│   ├── evaluator-system.md     # Evaluator 系统提示词
│   └── evolution-system.md      # Evolution 系统提示词
│
├── logs/
│   ├── usage.log              # 使用日志 (JSONL)
│   ├── evolution.log          # 进化历史
│   └── error.log             # 错误日志
│
├── lib/
│   ├── integration.sh         # 集成 unified-skill-eval
│   ├── concurrency.sh          # 多Agent并发控制
│   ├── errors.sh              # 错误处理
│   ├── log_rotation.sh         # 日志轮转
│   ├── constants.sh           # 常量定义
│   └── utils.sh               # 工具函数
│
└── tests/
    ├── run_tests.sh           # 测试入口
    ├── test_concurrency.sh     # 并发测试
    ├── test_errors.sh          # 错误处理测试
    ├── test_rollback.sh        # 回滚测试
    └── test_log_rotation.sh    # 日志轮转测试
```

---

## 四、核心流程

### 4.1 创建流程 (CREATE)

```
用户: "帮我创建一个代码审查skill"
    │
    ▼
┌────────────────────────────────────────────────────────┐
│ 1. 初始化                                             │
│    - 解析用户需求，确定skill类型                      │
│    - 读取模板                                        │
│    - 初始化SKILL.md结构                              │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│ 2. 增量编写循环 (双Agent并行)                         │
│                                                        │
│    [Creator Agent] ───────▶ [Evaluator Agent]         │
│         │                          │                   │
│         │ 编写section               │ 评估            │
│         ▼                          ▼                   │
│    ┌────────────────────────────────────────┐        │
│    │  next_action:                         │        │
│    │    - done      → 下一section           │        │
│    │    - improve   → 根据建议修正           │        │
│    │    - continue  → 继续编写              │        │
│    └────────────────────────────────────────┘        │
│                        │                             │
│    ◀─────── 反馈循环 ─────────────────────────       │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│ 3. 最终评估                                           │
│    - 调用 unified-skill-eval 完整评估                 │
│    - 输出: 最终分数 + Tier                           │
└────────────────────────────────────────────────────────┘
```

### 4.2 进化流程 (EVOLUTION)

```
触发条件: usage.log 累积 ≥ 动态阈值
    │
    ▼
┌────────────────────────────────────────────────────────┐
│ 动态阈值计算:                                         │
│   eval_count < 10  → 新手期  → threshold = 10     │
│   eval_count 10-50 → 成长期  → threshold = 50     │
│   eval_count > 50   → 稳定期  → threshold = 100    │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│              Evolution Pipeline                        │
│                                                        │
│   1. LLM Analyzer ─▶ 分析日志，识别模式               │
│           │                                          │
│           ▼                                          │
│   2. LLM Summarizer ─▶ 总结提炼，生成建议           │
│           │                                          │
│           ▼                                          │
│   3. LLM Improver ─▶ 执行改进，更新SKILL.md         │
│           │                                          │
│           ▼                                          │
│   4. unified-skill-eval ─▶ 验证改进                 │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 五、多Agent并发控制

### 5.1 锁机制

```bash
# lib/concurrency.sh

LOCK_DIR="/tmp/create-with-eval/locks"

# 获取锁 (带超时和过期检测)
acquire_lock() {
    local lock_name="$1"
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    local timeout="${2:-30}"
    local start_time=$(date +%s)
    
    while true; do
        if mkdir "$lock_file" 2>/dev/null; then
            echo $$ > "$lock_file"
            return 0
        fi
        
        # 检测过期锁
        if [[ -f "$lock_file" ]]; then
            local pid=$(cat "$lock_file")
            if ! kill -0 "$pid" 2>/dev/null; then
                rm -rf "$lock_file"
                continue
            fi
        fi
        
        # 超时检测
        local elapsed=$(($(date +%s) - start_time))
        [[ $elapsed -ge $timeout ]] && return 1
        
        sleep 1
    done
}

# 释放锁
release_lock() {
    local lock_name="$1"
    local lock_file="${LOCK_DIR}/${lock_name}.lock"
    [[ -f "$lock_file" ]] && rm -rf "$lock_file"
}

# 封装执行
with_lock() {
    local lock_name="$1"
    local timeout="$2"
    shift 2
    
    acquire_lock "$lock_name" "$timeout" || return 1
    trap "release_lock $lock_name" EXIT
    "$@"
}
```

### 5.2 Agent 锁策略

| Agent | 锁名 | 超时 | 说明 |
|-------|------|------|------|
| Creator | `creator` | 60s | 编写时独占 |
| Evaluator | `evaluator` | 30s | 评估时独占 |
| Evolution | `evolution` | 120s | 进化时独占 |
| SKILL.md | `skill_file` | 10s | 文件修改时 |

### 5.3 并行执行

```bash
# Orchestrator 并行协调
parallel_execute() {
    local task_creator="$1"
    local task_evaluator="$2"
    
    # 启动 Creator
    $task_creator &
    local pid_creator=$!
    
    # 启动 Evaluator
    $task_evaluator &
    local pid_evaluator=$!
    
    # 等待结果
    wait $pid_creator
    local exit_creator=$?
    
    wait $pid_evaluator
    local exit_evaluator=$?
    
    # 返回结果
    [[ $exit_creator -eq 0 ]] && [[ $exit_evaluator -eq 0 ]]
}
```

---

## 六、错误处理

### 6.1 错误类型

```bash
# lib/errors.sh

declare -A ERROR_TYPES=(
    ["LLM_TIMEOUT"]="LLM调用超时"
    ["LLM_ERROR"]="LLM返回错误"
    ["INVALID_FORMAT"]="SKILL.md格式无效"
    ["EVAL_FAILURE"]="评估失败"
    ["FILE_ERROR"]="文件操作失败"
    ["NETWORK_ERROR"]="网络错误"
    ["LOCK_FAILED"]="获取锁失败"
    ["SNAPSHOT_ERROR"]="快照保存失败"
)

declare -A ERROR_RECOVERY=(
    ["LLM_TIMEOUT"]="retry:3:exp_backoff:1,2,4"
    ["LLM_ERROR"]="retry:2:exp_backoff:1,2"
    ["INVALID_FORMAT"]="rollback"
    ["EVAL_FAILURE"]="skip"
    ["FILE_ERROR"]="alert"
    ["NETWORK_ERROR"]="retry:3:exp_backoff:5,10,15"
    ["LOCK_FAILED"]="fail"
    ["SNAPSHOT_ERROR"]="fail"
)
```

### 6.2 错误处理流程

```
错误发生
    │
    ▼
日志记录 ──▶ 分析错误类型
    │
    ▼
匹配恢复策略
    │
    ├─ retry ──▶ 指数退避重试
    ├─ rollback ──▶ 回滚到快照
    ├─ skip ──▶ 跳过继续
    └─ fail ──▶ 终止并告警
```

---

## 七、回滚机制

### 7.1 快照管理

```bash
# evolution/rollback.sh

SNAPSHOT_DIR="/tmp/create-with-eval/snapshots"
MAX_SNAPSHOTS=10

# 创建快照
create_snapshot() {
    local skill_file="$1"
    local reason="${2:-auto}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot="${SNAPSHOT_DIR}/skill_${timestamp}_${reason}.md"
    
    cp "$skill_file" "$snapshot"
    cleanup_snapshots
    
    echo "$snapshot"
}

# 回滚
rollback_to() {
    local snapshot="$1"
    local skill_file="$2"
    cp "$snapshot" "$skill_file"
}

# 自动回滚条件
AUTO_ROLLBACK=(
    "INVALID_FORMAT: 生成内容无法解析"
    "SCORE_REGRESSION: 分数下降 > 20分"
)
```

### 7.2 回滚触发

| 条件 | 触发 | 动作 |
|------|------|------|
| INVALID_FORMAT | 立即 | 回滚到最新快照 |
| SCORE_REGRESSION | 分数下降>20 | 回滚并告警 |
| EVAL_CRASH | 评估崩溃 | 回滚到稳定版本 |

---

## 八、日志轮转

### 8.1 日志配置

```bash
# lib/log_rotation.sh

declare -A LOG_CONFIG=(
    ["usage.log"]="size:100M,days:7,keep:30"
    ["evolution.log"]="size:10M,days:30,keep:12"
    ["error.log"]="size:50M,days:14,keep:24"
)

# 轮转检查
should_rotate() {
    local log="$1"
    local config="${LOG_CONFIG[$log]}"
    local size_limit="${config%%,*}"
    size_limit="${size_limit#size:}"
    size_limit="${size_limit%M}"
    
    local file_size=$(stat -f%z "$log" 2>/dev/null || echo 0)
    local size_mb=$((file_size / 1024 / 1024))
    
    [[ $size_mb -ge $size_limit ]]
}
```

### 8.2 轮转策略

| 日志 | 大小限制 | 时间限制 | 保留数量 |
|------|----------|----------|----------|
| usage.log | 100MB | 7天 | 30份 |
| evolution.log | 10MB | 30天 | 12份 |
| error.log | 50MB | 14天 | 24份 |

---

## 九、单元测试

### 9.1 测试结构

```bash
# tests/run_tests.sh

TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    
    ((TEST_COUNT++))
    if [[ "$expected" == "$actual" ]]; then
        ((TEST_PASSED++))
        echo "  ✓ $msg"
        return 0
    else
        ((TEST_FAILED++))
        echo "  ✗ $msg"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        return 1
    fi
}

run_tests() {
    echo "========================================"
    echo "  Running Tests"
    echo "========================================"
    
    test_concurrency
    test_errors
    test_rollback
    test_log_rotation
    
    echo "========================================"
    echo "  Results: $TEST_PASSED/$TEST_COUNT passed"
    [[ $TEST_FAILED -gt 0 ]] && echo "  FAILED: $TEST_FAILED"
    echo "========================================"
}
```

### 9.2 测试用例

| 测试 | 内容 |
|------|------|
| test_lock_acquire | 获取锁成功 |
| test_lock_timeout | 锁超时检测 |
| test_lock_release | 释放锁 |
| test_error_log | 错误日志记录 |
| test_retry | 重试机制 |
| test_snapshot_create | 创建快照 |
| test_rollback | 回滚功能 |
| test_log_rotate | 日志轮转 |

---

## 十、CLI 接口

```bash
# 创建新 skill
./create-with-eval/main.sh --skill "创建一个代码审查skill"

# 指定目标 tier
./create-with-eval/main.sh --skill "创建skill" --target GOLD

# 手动触发进化
./create-with-eval/main.sh --evolve

# 查看统计
./create-with-eval/main.sh --stats

# 运行测试
./create-with-eval/main.sh --test
```

---

## 十一、依赖关系

```
create-with-eval
    │
    ├── unified-skill-eval/     # 评估引擎
    │       ├── main.sh
    │       └── lib/agent_executor.sh
    │
    └── agentskills.io v2.1.0   # 格式标准
```

---

## 十二、预期效果

| 指标 | 改进前 | 改进后 |
|------|---------|---------|
| 创建+评估耗时 | 30min+ | ~5min |
| 一次通过率 | ~30% | ~70% |
| 进化周期(新skill) | N/A | 10次使用 |
| 进化周期(稳定skill) | N/A | 100次使用 |
