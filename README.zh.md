# Skill Writer

**Language**: [English](README.md) · **简体中文**

一个跨平台的元技能（meta-skill），用自然语言交互方式创建、评估和优化 AI 助手技能。

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-8-orange.svg)](#支持的平台)

## 什么是 skill？

**skill**（技能）是一个小型指令文件（Markdown，`.md`），放入你的 AI 助手的 skills 目录。它告诉助手该如何处理某一类特定请求 —— 例如"总结一段 git diff"、"写一份 PR 描述"或"校验 API 响应"。当你说的话命中这个技能的触发短语时，助手会自动遵循该技能的指令。

可以把它想象成一个自定义命令：你只定义一次它做什么，之后每次提问助手都会一致地执行。

创建完毕后，技能存放在 `~/.claude/skills/`（或你所用平台的等价目录）。重启助手即可激活。

---

## 概览

Skill Writer 是一个元技能，让 AI 助手可以通过自然语言交互来创建、评估和优化其他技能。无需 CLI 命令 —— 直接描述你的需要即可。

### 主要特性

- **Agent 安装**：一行 "read [URL] and install" 命令完成安装 —— 适用于所有支持的平台
- **零 CLI 界面**：自然语言交互，不需要记忆任何命令
- **跨平台**：支持 8 个平台 —— Claude、OpenClaw、OpenCode、Cursor、Gemini、OpenAI、Kimi、Hermes
- **九大模式**：CREATE、LEAN、EVALUATE、OPTIMIZE、BENCHMARK、INSTALL、COLLECT、SHARE、GRAPH
- **模板驱动**：4 个内置模板覆盖常见技能模式
- **质量保证**：1000 分评分体系 + 认证等级
- **分级评估（Tier-Aware）**：按 `planning` / `functional` / `atomic` 三级架构动态调整 Phase 2 权重
- **可靠的 LEAN 评分**：16 项检查，拆分为 `[STATIC]`（确定性，335 分，零方差）和 `[HEURISTIC]`（LLM 启发式，165 分），各阶段方差可追溯
- **内建安全**：基于 CWE + OWASP Agentic Skills Top 10（ASI01–ASI10）的检测，以及拉取技能时的供应链信任校验
- **持续改进**：自动化优化 + 收敛检测 + 协同进化 VERIFY 步骤 + 持久化分数历史
- **自进化**：UTE（Use-to-Evolve）L1 会话内始终开启；L2 集体进化依赖 hooks / 后端
- **实证 A/B 基准测试**：BENCHMARK 模式并行调用 API（有技能 vs 无技能），盲评打分，输出 delta_pass_rate + token 开销 + PASS/FAIL 结论（v3.5.0）
- **诚实技能标签**：`generation_method` + `validation_status` 字段，防止未验证技能悄悄进入生产环境
- **行为验证器**：可选的任务样本测试，产出独立于理论分数的 `pragmatic_success_rate`
- **多遍自审**：Generate / Review / Reconcile 质量协议
- **Graph of Skills (GoS)**：类型化的依赖图，含最小可用的 `depends_on` 运行时；完整 bundle 能力在 v4.0+
- **双语**：全部模式均支持英文和中文。框架文档（refs/ 伴侣文件）以英文为准。

### 功能可用性 — CORE 与 EXTENDED

并非所有功能都需要额外基础设施。下表列出开箱即用 vs. 需要 hooks / 后端的功能。

| 功能 | 可用性 | 前置条件 |
|------|-------|---------|
| CREATE / LEAN / EVALUATE | `[CORE]` | 无 — 任何 LLM 会话均可 |
| OPTIMIZE（最多 20 轮） | `[CORE]` | 无 |
| INSTALL（本地平台部署） | `[CORE]` | 文件系统写权限 |
| 安全扫描（自撰写技能） | `[CORE]` | 无 |
| UTE L1 — 会话内反馈 + 微补丁 | `[CORE]` | 无 |
| COLLECT — 输出 Session Artifact JSON | `[CORE]` | 无（手动保存） |
| Pragmatic Test Phase（任务样本验证） | `[CORE]` | 用户提供 3–5 个任务样本 |
| GoS `depends_on` 依赖解析 | `[CORE]` | 技能 YAML 中有 `graph:` 块 |
| BENCHMARK A/B 实证测试（`scripts/run_benchmark.py`） | `[CORE]` | 需要 `ANTHROPIC_API_KEY` + `anthropic` 包 |
| UTE L1 — 跨会话调用计数 | `[EXTENDED]` | Claude Code hooks（`ute-tracker.js`） |
| UTE L2 — 跨用户集体进化 | `[EXTENDED]` | AGGREGATE 流水线 + 共享后端 |
| SHARE — 推送 / 拉取远程注册表 | `[EXTENDED]` | S3 / OSS / HTTP 后端 |

详见 [`README.md`](README.md) 的 "Feature Availability" 章节。

---

## 快速安装 / Quick Install

推荐使用 Agent 安装方式 —— 一行命令即可：

```
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-claude.md and install to claude
```

其他平台把 URL 末尾的 `-claude.md` 替换为目标平台（`-opencode.md`、`-cursor.mdc`、`-gemini.md` 等）。

或使用安装脚本：

```bash
git clone https://github.com/theneoai/skill-writer.git
cd skill-writer
./install.sh                 # 自动检测并安装到所有已识别的平台
./install.sh --all           # 安装到全部 8 个平台
./install.sh --platform claude
```

---

## 支持的平台

| 平台 | skill 目录 |
|------|-----------|
| Claude | `~/.claude/skills/` |
| OpenClaw | `~/.openclaw/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Cursor | `.cursor/rules/`（项目级）或 `~/.cursor/rules/`（`--global`） |
| Gemini | `~/.gemini/skills/` |
| OpenAI | 项目内 `skills/`（路由规则写入 `AGENTS.md`） |
| Kimi | `~/.config/kimi/skills/` |
| Hermes | `~/.hermes/skills/` |

---

## 核心文档

- [skill-framework.md](skill-framework.md) — 规范主文件（精简主入口 ≤ 500 行，细节拆入 refs/）
- [skill-framework-index.md](skill-framework-index.md) — refs/ 文件索引
- [refs/mode-router.md](refs/mode-router.md) — 9 个模式的路由表
- [refs/modes/](refs/modes/) — 逐模式详细规格（CREATE / LEAN / EVALUATE / OPTIMIZE / BENCHMARK / INSTALL / COLLECT / SHARE / GRAPH）
- [agents/](agents/) — BENCHMARK 模式 Agent 规格（executor / comparator / analyzer / grader）
- [eval/rubrics.md](eval/rubrics.md) — 1000 分评分细则
- [optimize/strategies.md](optimize/strategies.md) — 8 维度 10 步优化方法
- [CHANGELOG.md](CHANGELOG.md) — 更新日志

---

## 贡献 / Community

- [Discussions](https://github.com/theneoai/skill-writer/discussions) — 提问与讨论
- [Issues](https://github.com/theneoai/skill-writer/issues) — Bug 报告与功能请求
- [CONTRIBUTING.md](.github/CONTRIBUTING.md) — 贡献指南
- [CODE_OF_CONDUCT.md](.github/CODE_OF_CONDUCT.md) — 行为准则

---

## 许可

MIT License。详见 [LICENSE](LICENSE)。

> 完整的英文版 README（含所有模式、API 细节、触发词评测、GoS 规格等）见 [README.md](README.md)。
