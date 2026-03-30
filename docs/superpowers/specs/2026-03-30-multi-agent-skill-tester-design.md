# Multi-Agent Skill Tester Design

## Overview

A 1000-round automated testing system using Minimax and Kimi Code agents as "skill users" to create, evaluate, and optimize skills in a continuous loop, discovering and fixing issues iteratively.

## Architecture

```
scripts/multi_agent_tester.py
├── Agent Interface Layer
│   ├── MinimaxAgent (API calls to Minimax)
│   └── KimiAgent (API calls to Kimi Code)
├── Skill Manager
│   ├── create_temp_skill() - 创建临时 skill 文件
│   ├── run_evaluation() - 运行评测
│   └── cleanup() - 清理临时文件
└── Round Orchestrator
    ├── execute_round() - 执行单轮测试
    └── run_loop() - 执行 1000 轮循环
```

## API Configuration

- `MINIMAX_API_KEY` - 环境变量
- `KIMI_API_KEY` - 环境变量
- API base URLs 默认使用官方端点

## Round Flow

```
Round N:
  1. Minimax Agent 创建 Evaluation Skill (eval_results/round_N/minimax_eval_skill.md)
  2. Kimi Agent 创建 Optimization Skill (eval_results/round_N/kimi_opt_skill.md)
  3. 对两个 skill 运行 skill evaluate
  4. 汇总评测结果和问题
  5. 如果发现问题，修复并提交
  6. 清理临时文件
  7. 继续下一轮
```

## Evaluation Dimensions

- **parse**: 是否能正确解析
- **validate**: 是否通过验证
- **score**: 评分 (0-1000)
- **tier**: PLATINUM/GOLD/SILVER/BRONZE
- **errors**: 错误信息

## Issue Tracking

发现的 issues 按严重程度分类：
- **CRITICAL**: 导致程序崩溃或数据丢失
- **HIGH**: 功能严重降级
- **MEDIUM**: 功能部分受影响
- **LOW**: 界面/体验问题

## File Structure

```
eval_results/
├── round_0001/
│   ├── minimax_eval_skill.md
│   ├── kimi_opt_skill.md
│   ├── minimax_eval_result.json
│   ├── kimi_opt_eval_result.json
│   └── issues.json
├── round_0002/
│   └── ...
└── summary.json
```

## Commit Strategy

- 每 10 轮提交一次汇总
- 发现 CRITICAL/HIGH 问题立即修复并提交
- 提交信息包含 round 编号和发现的问题摘要

## Dependencies

- skill CLI (skill evaluate, skill validate)
- requests (API calls)
- python-dotenv (环境变量)
