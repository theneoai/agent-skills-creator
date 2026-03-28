# Installing Superpowers for OpenCode

## Installation

Add superpowers to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["superpowers@git+https://github.com/theneoai/skill.git"]
}
```

Restart OpenCode. The plugin auto-installs and registers all skills automatically.

Verify by asking: "What can you do with skill?"

## Updating

Superpowers updates automatically when you restart OpenCode.