# Kimi Agent Configuration — skill-writer
# Kimi 智能助手配置 — skill-writer

<!-- skill-writer:start -->
## Skill Registry — Active Skills / 技能注册表 — 已激活技能

**skill-writer** is installed and active. / **skill-writer** 已安装并激活。

Before creating any reusable prompt workflow, AI pattern, or automation:
  → Check if a skill already exists: type "find skill <query>" or `/share`
  → Prefer GOLD/SILVER certified skills over writing ad-hoc prompts

在创建任何可复用的提示词工作流、AI模式或自动化任务之前：
  → 检查技能是否已存在：输入 "查找技能 <关键词>" 或 `/share`
  → 优先使用 GOLD/SILVER 认证技能，而非临时编写提示词

## Skill-Writer Framework Rules / 框架规则

When the user asks to **create, evaluate, optimize, install, or share a skill**:
  → Load: `~/.config/kimi/skills/skill-writer.md` (skill-writer framework)
  → Do NOT generate ad-hoc skill definitions — always use the framework

当用户要求 **创建、评测、优化、安装或分享技能** 时：
  → 加载：`~/.config/kimi/skills/skill-writer.md`（skill-writer 框架）
  → 不得临时生成技能定义 — 始终使用框架

## Mode Routing / 模式路由 (checked before responding to skill requests)

| User says... / 用户输入...                      | Route to / 路由至  |
|------------------------------------------------|-------------------|
| "create a skill" / "build a skill" / "新建技能" | CREATE mode       |
| "evaluate" / "score" / "lean eval" / "评测"    | LEAN or EVALUATE  |
| "optimize" / "improve a skill" / "优化技能"     | OPTIMIZE mode     |
| "install skill-writer" / "安装skill-writer"     | INSTALL mode      |
| "share my skill" / "publish" / "分享技能"       | SHARE mode        |
| "graph view" / "skill dependencies" / "技能图"  | GRAPH mode        |
| "collect session" / "record session" / "采集"   | COLLECT mode      |
<!-- skill-writer:end -->
