# Skill Optimization Workflow

**Version:** 1.0  
**Last Updated:** 2026-03-28  
**Workflow Engine:** `engine/evolution/engine.sh`

The skill optimization workflow improves a skill's quality through a 9-step iterative loop, without requiring usage data analysis.

---

## Table of Contents

1. [流程概览](#1-流程概览)
2. [触发条件](#2-触发条件)
3. [前置条件](#3-前置条件)
4. [完整流程](#4-完整流程)
5. [CLI 参考](#5-cli-参考)
6. [错误处理](#6-错误处理)
7. [最佳实践](#7-最佳实践)
8. [相关文档](#8-相关文档)

---

## 1. 流程概览

```mermaid
flowchart TD
    A[Start] --> B[Read Skill]
    B --> C[Analyze Quality]
    C --> D[Plan Improvements]
    D --> E[Implement Changes]
    E --> F{Verify Improved?]
    F -->|Yes| G[Log & Continue]
    F -->|No| H[Stuck Detection]
    G --> I{Rounds < Max?]
    H --> I
    I -->|Yes| C
    I -->|No| J[End - Optimized]
```

**Note**: This workflow uses a 9-step optimization loop without usage data analysis. For usage-based optimization, see [Auto-Evolution](AUTO-EVOLVE.md).

---

## 2. 触发条件

| Trigger | Condition | Command |
|---------|-----------|---------|
| Manual | User invokes with skill file | `./scripts/optimize-skill.sh <skill_file> [max_rounds]` |
| API | Programmatic call via engine.sh | `engine/evolution/engine.sh <skill_file> <max_rounds>` |

---

## 3. 前置条件

- [ ] Skill file exists and is readable
- [ ] Lock can be acquired (no concurrent optimization running)
- [ ] LLM API is accessible
- [ ] Sufficient quota for optimization rounds

---

## 4. 完整流程

### Step 1: Read

**Input**: Skill file path  
**Output**: Current skill content  
**处理逻辑**: Load and parse existing skill file

### Step 2: Analyze

**Input**: Current skill content  
**Output**: Quality analysis report  
**处理逻辑**: Identify weaknesses in instructions, examples, configuration

### Step 3: Plan

**Input**: Quality analysis  
**Output**: Improvement plan  
**处理逻辑**: Generate specific changes to address identified issues

### Step 4: Implement

**Input**: Improvement plan  
**Output**: Modified skill content  
**处理逻辑**: Apply LLM-guided changes to skill sections

### Step 5: Verify

**Input**: Modified skill  
**Output**: Verification result  
**处理逻辑**: Score the modified skill to confirm improvement

### Step 6: Log

**Input**: Verification result, changes made  
**Output**: Log entry to evolution history  
**处理逻辑**: Record optimization attempt for tracking

### Step 7 (Loop): Check Rounds

**Input**: Current round, max rounds  
**Output**: Continue or terminate decision  
**处理逻辑**: If improvements continue and rounds remain, loop back to Analyze

### Step 8 (Loop): Stuck Detection

**Input**: Verification results from recent rounds  
**Output**: Stuck detection result  
**处理逻辑**: If no improvement for multiple consecutive rounds, terminate

### Step 9: Complete

**Input**: Final optimized skill  
**Output**: Updated skill file  
**处理逻辑**: Save improved skill, release lock

---

## 5. CLI 参考

```bash
# Basic usage (20 rounds default)
./scripts/optimize-skill.sh <skill_file>

# With custom round limit
./scripts/optimize-skill.sh <skill_file> 20

# Direct engine usage
engine/evolution/engine.sh <skill_file> 20
```

---

## 6. 错误处理

| Error Code | Cause | Handling |
|------------|-------|----------|
| E1 | Score degradation | Revert changes, terminate optimization |
| E2 | Stuck detection (no improvement for 5+ rounds) | Stop loop, report stuck state |
| E3 | Lock failure (another optimization running) | Wait and retry, or run with --force |
| E4 | LLM failure during optimization | Retry round, or abort if persistent |
| E5 | File write error | Check permissions, ensure disk space |

---

## 7. 最佳实践

1. **Set reasonable round limits**: Start with 5-10 rounds, increase if needed
2. **Review after each run**: Don't run unattended for too many rounds
3. **Backup before optimizing**: Keep version control history to revert if needed
4. **Validate after optimization**: Run evaluation to confirm quality improvement
5. **Understand the loop**: This is a 9-step loop without usage analysis - for usage-based evolution, see Auto-Evolution

---

## 8. 相关文档

- [Auto-Evolution](AUTO-EVOLVE.md)
- [Quick Start](../QUICKSTART.md)
- [Skill Format](../SKILL-FORMAT.md)
