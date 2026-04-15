# Agent Configuration — skill-writer (OpenCode)

<!-- skill-writer:start -->
## Skill Registry — Active Skills

**skill-writer** is installed and active.

Before creating any reusable prompt workflow, AI pattern, or automation:
  → Check if a skill already exists: type "find skill <query>" or `/share`
  → Prefer GOLD/SILVER certified skills over writing ad-hoc prompts

## Skill-Writer Framework Rules

When the user asks to **create, evaluate, optimize, install, or share a skill**:
  → Load: `~/.config/opencode/skills/skill-writer.md` (skill-writer framework)
  → Do NOT generate ad-hoc skill definitions — always use the framework

## Mode Routing (checked before responding to skill requests)

| User says...                                             | Route to                          |
|---------------------------------------------------------|-----------------------------------|
| "create a skill" / "build a skill" / "新建技能"          | CREATE mode                       |
| "create from failures" / "从失败案例创建技能"             | CREATE mode (`--from-failures`)   |
| "evaluate" / "score" / "lean eval" / "评测"             | LEAN or EVALUATE                  |
| "pragmatic test" / "eval --pragmatic" / "实用性测试"     | EVALUATE mode (pragmatic=true)    |
| "optimize" / "improve a skill" / "优化技能"              | OPTIMIZE mode                     |
| "install skill-writer" / "安装skill-writer"              | INSTALL mode                      |
| "share my skill" / "publish" / "分享技能"                | SHARE mode                        |
| "graph view" / "skill dependencies" / "技能图"           | GRAPH mode                        |
| "collect session" / "record session" / "采集"            | COLLECT mode                      |
<!-- skill-writer:end -->
