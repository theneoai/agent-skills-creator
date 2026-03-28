# Skill Engineering - Documentation

## Installation

### OpenCode

Add superpowers to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["superpowers@git+https://github.com/theneoai/skill.git"]
}
```

Restart OpenCode. The plugin auto-installs and registers all skills automatically.

### Codex

1. **Clone the repository:**
   ```bash
   git clone https://github.com/theneoai/skill.git ~/.codex/skill
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/skill/skills ~/.agents/skills/skill
   ```

3. **Restart Codex** to discover skills.

### Claude Code

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

### Cursor

```
/add-plugin superpowers
```

Or search for "superpowers" in the plugin marketplace.

### Gemini CLI

```
gemini extensions install https://github.com/theneoai/skill
```

## Quick Start

```bash
# Fast evaluation (~$0, ~0s)
./scripts/lean-orchestrator.sh ./SKILL.md

# Full evaluation (~$0.50, ~2min)
./scripts/evaluate-skill.sh ./SKILL.md

# Create skill
./scripts/create-skill.sh "Create a code review skill"

# Create with inheritance
./scripts/create-skill.sh "Create a code review skill" --extends skill
```

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [WORKFLOWS.md](WORKFLOWS.md) - Workflow documentation
- [DESIGN.md](DESIGN.md) - Design decisions
- [technical/core/](technical/core/) - Core engine documentation
