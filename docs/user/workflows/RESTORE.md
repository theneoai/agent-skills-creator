# Skill Restoration Workflow

**Version:** 1.0  
**Last Updated:** 2026-03-28  
**Workflow Engine:** `engine/agents/restorer.sh`

The skill restoration workflow diagnoses broken skills, lists available snapshots, and restores a working version.

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
    A[Start] --> B[Diagnose Issue]
    B --> C[List Snapshots]
    C --> D{User Selects Snapshot?]
    D -->|No| E[Auto-select Best]
    D -->|Yes| F[Verify Snapshot]
    E --> F
    F --> G{Restore & Validate?]
    G -->|Success| H[End - Restored]
    G -->|Failure| I[Report Error]
    I --> C
```

---

## 2. 触发条件

| Trigger | Condition | Command |
|---------|-----------|---------|
| Manual | User invokes with skill file | `./scripts/restore-skill.sh <skill_file>` |
| List only | List available snapshots | `./scripts/restore-skill.sh <skill_file> --list` |
| Specific | Restore specific snapshot | `./scripts/restore-skill.sh <skill_file> --snapshot ID` |

---

## 3. 前置条件

- [ ] Skill file exists (may be corrupted)
- [ ] Snapshot directory exists and is accessible
- [ ] Git history is available for the skill file
- [ ] Restorer agent (`engine/agents/restorer.sh`) is executable

---

## 4. 完整流程

### Step 1: Diagnose

**Input**: Broken skill file path  
**Output**: Diagnosis report  
**处理逻辑**: Identify corruption type (syntax error, missing sections, invalid schema)

```bash
./scripts/restore-skill.sh ./broken-skill.md
```

### Step 2: List Snapshots

**Input**: Skill file path  
**Output**: List of available snapshots with IDs and timestamps  
**处理逻辑**: Query git history for all commits affecting this file

### Step 3: Select

**Input**: Snapshot list, optional user selection  
**Output**: Selected snapshot ID  
**处理逻辑**: User picks from list, or system auto-selects most recent valid version

### Step 4: Verify

**Input**: Selected snapshot  
**Output**: Verification result  
**处理逻辑**: Confirm snapshot content is valid before restoring

### Step 5: Restore

**Input**: Verified snapshot ID  
**Output**: Restored skill file  
**处理逻辑**: Checkout selected version from git history

### Step 6: Validate

**Input**: Restored skill file  
**Output**: Validation result  
**处理逻辑**: Ensure restored file passes basic validation checks

---

## 5. CLI 参考

```bash
# Basic restore (interactive)
./scripts/restore-skill.sh <skill_file>

# List available snapshots only
./scripts/restore-skill.sh <skill_file> --list

# Restore specific snapshot
./scripts/restore-skill.sh <skill_file> --snapshot abc1234
```

---

## 6. 错误处理

| Error Code | Cause | Handling |
|------------|-------|----------|
| E1 | No snapshots found | Cannot restore; skill may need manual recreation |
| E2 | Snapshot file corrupted | Try next best snapshot, or manual recreation |
| E3 | Validation failure after restore | Attempt restore with different snapshot |
| E4 | Git operation failed | Check git status, file permissions |
| E5 | Skill file not found | Verify path, ensure file exists before restore |

---

## 7. 最佳实践

1. **Always list first**: Use `--list` to see available snapshots before restoring
2. **Prefer recent valid versions**: Unless you know which version was working, pick the most recent
3. **Backup current state**: Commit or save the broken state before restoring, for debugging
4. **Validate after restore**: Run evaluation to confirm restored skill works correctly
5. **Investigate breakage**: Understand why the skill broke to prevent recurrence

---

## 8. 相关文档

- [Auto-Evolution](AUTO-EVOLVE.md)
- [Quick Start](../QUICKSTART.md)
- [Skill Format](../SKILL-FORMAT.md)
