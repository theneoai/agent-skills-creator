# Youtu-Agent + LoongFlow 设计规范

**日期**: 2026-03-30  
**状态**: 已确认  
**Phase**: Phase 1.5 (Week 7)

---

## 1. 概述

### 1.1 目标

实现 Youtu-Agent 双模式进化系统与 LoongFlow 认知架构，替换现有 9-Step Loop 作为主要认知引擎。

### 1.2 核心贡献

| 组件 | 核心贡献 | 实现方式 |
|------|---------|----------|
| **LoongFlow** | Plan-Execute-Summarize 认知范式 | 认知架构 + 进化记忆 |
| **Youtu-Agent** | Agent Practice/RL 双模式 | 监督式学习 + 强化学习双模式 |

### 1.3 设计决策

- LoongFlow 替换 9-Step Loop 作为认知引擎
- Youtu-Agent Practice 模式：监督式学习，从成功轨迹中提取模式
- Youtu-Agent 作为 skill 进化的核心引擎，LoongFlow 提供认知架构

---

## 2. 架构

### 2.1 整体架构

```
LoongFlow (认知引擎)
├── Plan: 理解任务 → 生成认知图谱
├── Execute: 在认知图谱上执行推理
└── Summarize: 反思结果 → 更新记忆

Youtu-Agent (进化引擎)  
├── Practice 模式: 监督式学习，从成功轨迹中提取模式
└── RL 模式: Reward shaping 探索最优策略
```

### 2.2 组件列表

| 组件 | 文件路径 | 职责 |
|------|----------|------|
| `LoongFlowOrchestrator` | `skill/orchestrator/loongflow.py` | Plan-Execute-Summarize 认知循环 |
| `CognitiveGraph` | `skill/orchestrator/cognitive_graph.py` | 认知图谱数据结构 |
| `YoutuAgent` | `skill/agents/youtu.py` | Practice/RL 双模式 |
| `EvolutionMemory` | `skill/agents/evolution_memory.py` | 进化记忆存储 |
| `TrajectoryCollector` | `skill/agents/trajectory.py` | 轨迹收集与标注 |

---

## 3. LoongFlow 详细设计

### 3.1 CognitiveGraph 数据结构

```python
@dataclass
class CognitiveNode:
    id: str
    type: str  # "task" | "subtask" | "decision" | "action"
    content: str
    status: str  # "pending" | "executing" | "completed" | "failed"
    children: list[str]  # child node ids
    parent: str | None
    metadata: dict[str, Any]

@dataclass
class CognitiveGraph:
    nodes: dict[str, CognitiveNode]
    root: str | None
    edges: list[tuple[str, str]]  # (parent_id, child_id)
```

### 3.2 Plan-Execute-Summarize 循环

```python
class LoongFlowOrchestrator:
    def plan(self, task: str) -> CognitiveGraph:
        """Parse task and build cognitive graph"""
        
    def execute(self, graph: CognitiveGraph) -> ExecutionResult:
        """Execute tasks on the cognitive graph"""
        
    def summarize(self, result: ExecutionResult, graph: CognitiveGraph) -> MemoryUpdate:
        """Reflect on result and update memory"""
```

### 3.3 进化记忆 (EvolutionMemory)

```python
@dataclass
class MemoryEntry:
    timestamp: float
    task_type: str
    trajectory: list[dict]
    outcome: str  # "success" | "failure"
    reward: float
    lessons: list[str]

class EvolutionMemory:
    def add(self, entry: MemoryEntry) -> None
    def get_similar(self, task: str, k: int = 5) -> list[MemoryEntry]
    def get_successful_trajectories(self, task_type: str) -> list[list[dict]]
```

---

## 4. Youtu-Agent 详细设计

### 4.1 双模式架构

```python
class YoutuAgent:
    def __init__(self, memory: EvolutionMemory, exploration_rate: float = 0.1):
        self.memory = memory
        self.exploration_rate = exploration_rate
        
    def decide_mode(self, context: dict) -> Literal["practice", "rl"]:
        """根据上下文决定使用 Practice 还是 RL 模式"""
        
    def practice(self, task: str, context: dict) -> AgentAction:
        """监督式学习：从成功轨迹中提取模式"""
        
    def rl_step(self, state: dict, reward: float) -> AgentAction:
        """强化学习：使用 reward shaping 探索最优策略"""
```

### 4.2 Practice 模式

- 从 EvolutionMemory 获取相似成功轨迹
- 使用 KNN 或规则提取最佳动作模式
- 输出推荐动作及置信度

### 4.3 RL 模式

- 使用 reward shaping 平衡探索与利用
- Q-learning 或策略梯度方法
- 与 BOAD 的 UCB1 结合实现自适应探索

---

## 5. 数据流

### 5.1 执行流程

```
1. Plan 阶段
   └─> LoongFlow.plan(task) → CognitiveGraph
   
2. Execute 阶段
   ├─> YoutuAgent.decide_mode(context)
   │   ├─> Practice: 从成功轨迹提取动作
   │   └─> RL: 使用 reward shaping 选择动作
   └─> TrajectoryCollector 记录轨迹
   
3. Summarize 阶段
   ├─> 轨迹存入 EvolutionMemory
   └─> 触发 Practice 模式学习更新
```

### 5.2 与 BOAD/ROAD 集成

- **BOAD**: Youtu-Agent 的 agent 选择使用 BOAD 的 UCB1 评分
- **ROAD**: 错误恢复使用 ROAD 的决策树

---

## 6. 文件结构

```
skill/
├── orchestrator/
│   ├── __init__.py
│   ├── loongflow.py           # LoongFlowOrchestrator
│   └── cognitive_graph.py     # CognitiveGraph, CognitiveNode
├── agents/
│   ├── __init__.py
│   ├── youtu.py               # YoutuAgent
│   ├── evolution_memory.py    # EvolutionMemory, MemoryEntry
│   └── trajectory.py          # TrajectoryCollector
```

---

## 7. 测试策略

| 测试文件 | 覆盖内容 |
|----------|----------|
| `test_loongflow.py` | Plan-Execute-Summarize 循环 |
| `test_cognitive_graph.py` | 认知图谱构建与遍历 |
| `test_youtu.py` | Practice/RL 双模式切换 |
| `test_evolution_memory.py` | 记忆存储与检索 |

---

## 8. 实现顺序

1. **CognitiveGraph** - 基础数据结构
2. **EvolutionMemory** - 记忆存储
3. **TrajectoryCollector** - 轨迹收集
4. **LoongFlowOrchestrator** - Plan-Execute-Summarize
5. **YoutuAgent** - Practice 模式
6. **YoutuAgent** - RL 模式
7. **集成测试** - BOAD/ROAD 集成

---

## 9. 成功标准

- [ ] LoongFlow 成功执行 Plan-Execute-Summarize 循环
- [ ] Youtu-Agent Practice 模式能从成功轨迹中提取有效模式
- [ ] Youtu-Agent RL 模式能通过 reward shaping 优化策略
- [ ] 与 BOAD 的 UCB1 探索机制正确集成
- [ ] 所有新增测试通过 (≥40 tests)
