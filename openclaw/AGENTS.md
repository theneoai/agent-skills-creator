# Agent Configuration — skill-writer (OpenClaw)

<!-- skill-writer:start -->
## Skill Registry — Active Skills

**skill-writer** is installed and active.

Before creating any reusable prompt workflow, AI pattern, or automation:
  → Check if a skill already exists: type "find skill <query>" or `/share`
  → Prefer GOLD/SILVER certified skills over writing ad-hoc prompts

## Skill-Writer Framework Rules

When the user asks to **create, evaluate, optimize, install, or share a skill**:
  → Load: `~/.openclaw/skills/skill-writer.md` (skill-writer framework)
  → Do NOT generate ad-hoc skill definitions — always use the framework
  → Self-Review Protocol active: 3-pass review on every skill artifact

## Mode Routing (checked before responding to skill requests)

| User says...                                    | Route to          |
|------------------------------------------------|-------------------|
| "create a skill" / "build a skill" / "新建技能" | CREATE mode       |
| "evaluate" / "score" / "lean eval" / "评测"    | LEAN or EVALUATE  |
| "optimize" / "improve a skill" / "优化技能"     | OPTIMIZE mode     |
| "install skill-writer" / "安装skill-writer"     | INSTALL mode      |
| "share my skill" / "publish" / "分享技能"       | SHARE mode        |
| "graph view" / "skill dependencies" / "技能图"  | GRAPH mode        |
| "collect session" / "record session" / "采集"   | COLLECT mode      |

## OpenClaw-Specific Behavior

- **LoongFlow**: All skill operations execute via Plan → Execute → Summarize
- **Self-Review**: 3-pass quality check on every generated skill artifact
- **UTE**: Use-to-Evolve tracking active; lightweight check every 10 invocations
<!-- skill-writer:end -->
