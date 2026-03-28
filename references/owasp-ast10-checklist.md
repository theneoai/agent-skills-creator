# OWASP Agentic Skills Top 10 (AST10) + Agentic Applications 2026 检查清单

本清单基于 OWASP Agentic Skills Top 10（AST10）和 OWASP Top 10 for Agentic Applications 2026 整理，用于审查 Agent Skill 的安全性。

## 核心检查项（推荐在 Skill 创建/优化时执行）

### 1. Agent Goal Hijack（ASI01）
- [ ] description 和 Red Lines 中明确禁止目标修改或隐藏指令
- [ ] 所有外部输入视为不可信，添加 Intent 校验步骤
- [ ] 关键目标变更需 Human-in-the-Loop（HITL）

### 2. Tool Misuse & Exploitation（ASI02）
- [ ] 使用全限定 MCP 工具名（ServerName:tool_name）
- [ ] 参数在调用前进行严格 schema 校验
- [ ] 敏感工具（写、网络、执行）必须用户确认

### 3. Identity & Privilege Abuse（ASI03）
- [ ] 最小权限原则：Skill 只声明必要权限
- [ ] 使用短期、会话级凭证（避免持久化高权限）
- [ ] 禁止 Skill 自行提升权限

### 4. Agentic Supply Chain Vulnerabilities（ASI04）
- [ ] 只从 vetted registry 安装 Skill
- [ ] 启用代码签名和版本 pinning
- [ ] 新 Skill 必须经过人工 + 自动化扫描

### 5. Unexpected Code Execution（ASI05）
- [ ] scripts/ 必须在沙箱（Docker / Firecracker / Wasm）中运行
- [ ] network 默认 deny，仅允许显式授权端点
- [ ] 禁止 eval/exec 等动态代码执行

### 6. Memory & Context Poisoning（ASI06）
- [ ] 重要状态变更需校验和确认
- [ ] 定期清理或总结长期上下文
- [ ] 避免将不可信数据持久化到 memory

### 7. Insecure Inter-Agent Communication（ASI07）
- [ ] 多 Agent 协作时使用结构化、签名的消息格式
- [ ] 禁止直接传递未验证的自然语言指令

### 8. Cascading Failures（ASI08）
- [ ] 关键步骤添加失败恢复和回滚机制
- [ ] 设置超时和熔断保护

### 9. Human-Agent Trust Exploitation（ASI09）
- [ ] 避免过度自信的语气导致用户盲目信任
- [ ] 所有高风险操作必须明确说明风险

### 10. Rogue Agents（ASI10）
- [ ] Red Lines 中明确禁止自主偏离目标行为
- [ ] 实现可审计日志和人工干预机制

## 快速审查流程（推荐在 agent-skill-creator 中自动执行）
1. 检查 SKILL.md 是否包含清晰 Red Lines
2. 验证 scripts/ 是否使用环境变量注入密钥
3. 确认 MCP 工具调用使用全限定名 + 参数校验
4. 测试敏感操作是否强制 HITL
5. 运行沙箱测试

**参考来源**：OWASP Agentic Skills Top 10 (2026) 和 OWASP Top 10 for Agentic Applications 2026

