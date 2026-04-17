# mcp-bridge example

A minimal **tool-wrapper** skill showing how to delegate GitHub read operations
to an MCP server rather than re-implementing them in the skill body.

## What this example demonstrates

1. **Thin-skill pattern** — the Markdown body is *routing + framing + rendering*
   only; heavy lifting lives in the MCP tool.
2. **Router table** (§4) that maps natural-language intent to a specific MCP
   tool name with a whitelist (no fallthrough → no accidental write-tool calls).
3. **Read-only contract** as a red line — the skill refuses write intents even
   when a write tool is available in the host.
4. **Degraded-mode UX** — if the MCP server isn't registered, the skill prints
   a concrete install hint instead of failing opaquely.
5. **Injection-aware rendering** — tool output goes into a Markdown blockquote,
   never re-interpreted as instructions.

## How to run it

This skill is designed for an MCP-aware host:

- **Claude Desktop** — add the GitHub MCP server to
  `claude_desktop_config.json` (see §8 of `skill.md`).
- **Cursor** — add it to `.cursor/mcp.json`.
- **VS Code Copilot + MCP** — add it to `.vscode/settings.json`.

Then install the skill:

```bash
cp examples/mcp-bridge/skill.md ~/.claude/skills/mcp-github-bridge/SKILL.md
# or via skill-writer's install helpers
```

## Pairing with the skill-writer MCP server

This example intentionally uses the **GitHub** MCP server (third-party) rather
than `skill-writer`'s own server (see `mcp/README.md`). The point is that a
thin skill can bridge *any* MCP tool — skill-writer itself is just one host.

If you also attach the skill-writer MCP server, you can chain:

```
user → mcp-github-bridge (reads issue) → skill_writer__lean (evaluates a skill described in it)
```

## Files

- `skill.md` — the skill definition (spec_version: "1.0", CLEAR production
  fields, mode router, error table, security baseline, 5 benchmark tests).

## Related examples

- `examples/data-pipeline-demo/` — heavier, in-process skill (CSV → JSON
  validator) for comparison with this delegation-style skill.
- `examples/00-starter/` — simplest "hello world" skill.
