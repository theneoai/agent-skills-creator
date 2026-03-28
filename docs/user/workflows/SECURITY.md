# Security Audit Workflow

**Version:** 1.0  
**Last Updated:** 2026-03-28  
**Workflow Engine:** `engine/agents/security.sh`

The security audit workflow scans skills for vulnerabilities using OWASP AST10 checklist and generates remediation reports.

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
    A[Start] --> B[OWASP AST10 Checklist]
    B --> C[Scan Skill Content]
    C --> D{Vulnerabilities Found?]
    D -->|No| E[Generate Clean Report]
    E --> F[End - Audit Passed]
    D -->|Yes| G[Generate Vulnerability Report]
    G --> H{Fix Requested?]
    H -->|Yes| I[Apply Fixes]
    H -->|No| J[End - Audit Failed]
    I --> K[Re-validate]
    K --> L{Validation Pass?]
    L -->|Yes| F
    L -->|No| J
```

---

## 2. 触发条件

| Trigger | Condition | Command |
|---------|-----------|---------|
| Manual | User invokes with skill file | `./scripts/security-audit.sh <skill_file> [level]` |
| Critical Only | Scan only critical issues | `./scripts/security-audit.sh <skill_file> BASIC` |
| Full Scan | Comprehensive audit | `./scripts/security-audit.sh <skill_file> FULL` |

---

## 3. 前置条件

- [ ] Skill file exists and is readable
- [ ] Security agent (`engine/agents/security.sh`) is executable
- [ ] LLM API is accessible for content analysis
- [ ] For Full mode: additional dependencies may be required

---

## 4. 完整流程

### Step 1: OWASP AST10 Checklist

**Input**: Skill file path, audit level  
**Output**: Checklist items to scan  
**处理逻辑**: Load OWASP Application Security Testing Top 10 categories

**OWASP AST10 Categories**:

| ID | Category | Description |
|----|----------|-------------|
| A01 | Broken Access Control | Skill can access unauthorized resources |
| A02 | Cryptographic Failures | Sensitive data exposure through weak crypto |
| A03 | Injection | SQL, NoSQL, OS command injection risks |
| A04 | Insecure Design | Architectural flaws in skill logic |
| A05 | Security Misconfiguration | Improper default config, verbose errors |
| A06 | Vulnerable Components | Use of deprecated/unsafe dependencies |
| A07 | Auth Failures | Weak or missing authentication |
| A08 | Data Integrity Failures | Improper serialization, missing validation |
| A09 | Logging Failures | Missing audit trails, tampered logs |
| A10 | SSRF | Server-side request forgery risks |

### Step 2: Scan

**Input**: Skill content, checklist items  
**Output**: Raw scan results  
**处理逻辑**: Analyze skill code, instructions, and configuration for each vulnerability type

### Step 3: Report

**Input**: Scan results  
**Output**: Formatted vulnerability report  
**处理逻辑**: Generate detailed report with severity, location, and remediation hints

### Step 4: Fix (if requested)

**Input**: Vulnerability report  
**Output**: Fixed skill content  
**处理逻辑**: Apply LLM-guided fixes for identified issues

---

## 5. CLI 参考

```bash
# Full security audit (default)
./scripts/security-audit.sh <skill_file>

# Critical issues only
./scripts/security-audit.sh <skill_file> BASIC

# Full comprehensive scan
./scripts/security-audit.sh <skill_file> FULL

# Direct engine usage
engine/agents/security.sh <skill_file> FULL
```

---

## 6. 错误处理

| Error Code | Cause | Handling |
|------------|-------|----------|
| E1 | Vulnerability found | Review report, apply fixes or acknowledge risk |
| E2 | Scan failure (LLM error) | Retry scan, check API quota and connectivity |
| E3 | Invalid skill file | Fix formatting issues before scanning |
| E4 | Dependency missing (Full mode) | Install required dependencies, or use BASIC mode |
| E5 | Fix application failed | Manual remediation required |

---

## 7. 最佳实践

1. **Run before production**: Always audit skills before deploying to production
2. **Use FULL mode for sensitive skills**: Comprehensive scan catches more issues
3. **Review all findings**: Don't ignore LOW severity issues - they may compound
4. **Apply fixes iteratively**: Run audit after each fix to verify remediation
5. **Keep audit history**: Store reports for compliance and debugging

---

## 8. 相关文档

- [Auto-Evolution](AUTO-EVOLVE.md)
- [Quick Start](../QUICKSTART.md)
- [OWASP AST10](https://owasp.org/Top10/)
