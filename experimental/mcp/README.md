# skill-writer MCP server

> **Status**: v3.5.0 — skeleton + tool surface shipped; full MCP SDK integration
>   and published Desktop/Cursor/VS Code configs pending v3.6.0.
> **Full docs**: `docs/mcp-integration.md` and `skill-framework.md §17b`

---

## Why MCP

Through v3.4.x, skill-writer was a Markdown-based framework — an LLM read the
skill file and executed the modes in-conversation. With MCP (Anthropic's Model
Context Protocol, now an open standard adopted by 20+ platforms), skill-writer
can expose its modes as **callable tools** to any MCP-aware host.

Tools exposed:

| Tool name                        | Purpose |
|----------------------------------|---|
| `skill_writer__lean`             | Produce a LEAN fast-eval plan for the host's LLM to run |
| `skill_writer__evaluate`         | Produce a 4-phase EVALUATE plan (+ CLEAR dims if --clear) |
| `skill_writer__optimize`         | Produce OPTIMIZE plan (dimension-loop or GEPA `[ROADMAP]`) |
| `skill_writer__check_spec`       | Validate skill files against agentskills.io v1.0 spec |
| `skill_writer__build_platforms`  | Drift-check 8 platform files vs. canonical |
| `skill_writer__verify_sig`       | Verify Ed25519 signatures on release artifacts |
| `skill_writer__list_skills`      | Enumerate installed skill files in ~/.claude/skills/ |

---

## Design: zero-LLM server

skill-writer's MCP server **does not itself invoke an LLM**. It returns
structured plans that the host's LLM executes. Rationale:

- Zero-build philosophy (v3.3.0+): no runtime LLM dependency in skill-writer
- Any MCP host already has an LLM session (Claude Desktop, Cursor, etc.)
- Avoids baking in a specific model/provider choice
- Stateless → no per-user session storage

If you want LLM-in-the-loop optimization (e.g., autonomous OPTIMIZE), wrap this
server in a second MCP proxy that adds LLM execution. Out of scope for v3.5.0.

---

## Install

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`
(macOS) or the equivalent Windows/Linux path:

```json
{
  "mcpServers": {
    "skill-writer": {
      "command": "python3",
      "args": ["/path/to/skill-writer/mcp/server.py"]
    }
  }
}
```

### Cursor

`.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "skill-writer": {
      "command": "python3",
      "args": ["/path/to/skill-writer/mcp/server.py"]
    }
  }
}
```

### VS Code (Copilot + MCP)

`.vscode/settings.json`:

```json
{
  "mcp.servers": {
    "skill-writer": {
      "command": "python3",
      "args": ["/path/to/skill-writer/mcp/server.py"]
    }
  }
}
```

---

## Smoke test

```bash
python3 mcp/server.py --selftest
```

Expected output lists each tool with ✓ — verifies the handler table without
starting a full MCP loop.

---

## Dependencies

- Stdlib-only for the fallback stdio loop (minimal JSON-RPC)
- Optional: `pip install mcp` for the official Anthropic MCP Python SDK

The server detects the SDK at startup; if missing, it falls back to a minimal
stdio protocol that still answers tool calls (useful for CI smoke tests).
