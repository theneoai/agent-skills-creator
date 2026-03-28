# Installing Superpowers for Codex

Enable superpowers skills in Codex via native skill discovery.

## Installation

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

## Updating

```bash
cd ~/.codex/skill && git pull
```