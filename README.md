# Superpowers

Multi-agent optimization architecture with 9-step autonomous improvement loop for AI agent skills.

## Installation

### OpenCode
Add to `opencode.json`:
```json
{
  "plugin": ["superpowers@git+https://github.com/theneoai/skill.git"]
}
```

### Codex
```bash
git clone https://github.com/theneoai/skill.git ~/.codex/skill
mkdir -p ~/.agents/skills
ln -s ~/.codex/skill/skills ~/.agents/skills/skill
```

## Quick Start

```bash
# Fast evaluation (~$0, ~0s)
./scripts/lean-orchestrator.sh ./SKILL.md

# Full evaluation (~$0.50, ~2min)
./scripts/evaluate-skill.sh ./SKILL.md

# Create skill
./scripts/create-skill.sh "Create a code review skill"
```

## Core Features

- **6 Modes**: CREATE, EVALUATE, LEAN, RESTORE, SECURITY, OPTIMIZE
- **9-Step Loop**: READ → ANALYZE → CURATION → PLAN → IMPLEMENT → VERIFY → HUMAN_REVIEW → LOG → COMMIT
- **Multi-LLM**: Cross-validation with Anthropic, OpenAI, Kimi
- **Lean Eval**: ~0s, ~$0 (heuristic-based)
- **4-Tier Cert**: GOLD ≥ 475 | SILVER ≥ 425 | BRONZE ≥ 350