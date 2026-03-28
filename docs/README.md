# Skill Engineering

AI Skill Lifecycle Management 系统，用于创建、评估、优化 AI Agent 技能。

## 功能特性

| 特性 | 说明 |
|------|------|
| **6 Modes** | CREATE, EVALUATE, LEAN, RESTORE, SECURITY, OPTIMIZE |
| **9-Step Loop** | READ → ANALYZE → CURATION → PLAN → IMPLEMENT → VERIFY → HUMAN_REVIEW → LOG → COMMIT |
| **Multi-LLM** | Cross-validation with kimi-code, minimax, openai |
| **Lean Eval** | ~0s, ~$0 (heuristic-based) |
| **4-Tier Cert** | GOLD ≥ 475, SILVER ≥ 425, BRONZE ≥ 350 |

## 安装

### OpenCode

```bash
Fetch and follow instructions from https://raw.githubusercontent.com/theneoai/skill/main/.opencode/INSTALL.md
```

### Codex

```bash
Fetch and follow instructions from https://raw.githubusercontent.com/theneoai/skill/main/.codex/INSTALL.md
```

### Claude Code

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

### Cursor

```
/add-plugin superpowers
```

### Gemini CLI

```
gemini extensions install https://github.com/theneoai/skill
```

## 快速开始

```bash
# Lean 评估 (~0s, ~$0)
./scripts/lean-orchestrator.sh ./SKILL.md

# 完整评估 (~2min, ~$0.50)
./scripts/evaluate-skill.sh ./SKILL.md

# 创建技能
./scripts/create-skill.sh "Create a code review skill"

# 继承创建
./scripts/create-skill.sh "Create a code review skill" --extends skill
```

## 文档

| 文档 | 说明 |
|------|------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | 系统架构 |
| [WORKFLOWS.md](WORKFLOWS.md) | 工作流文档 |
| [technical/core/](technical/core/) | 核心引擎文档 |

## 项目地址

- GitHub: https://github.com/theneoai/skill
- 源码: https://github.com/theneoai/skill/tree/main
