# data-pipeline-demo example

A reference **data-pipeline** skill: validates a CSV file against a declared
schema and emits a JSON array plus an explicit error report.

## What this example demonstrates

1. **Schema-first, never infer types** — the schema is authoritative; no silent
   coercion.
2. **All errors collected per row** — no short-circuit; downstream sees the full
   picture.
3. **Declared mode router** (VALIDATE-ONLY / CONVERT / FULL) so the same skill
   handles three related jobs without ambiguity.
4. **Hard size bound** (10 MB) and explicit `ABORT` conditions — the skill
   defines its operating envelope rather than failing silently past it.
5. **Security baseline** — CSV formula injection (`=SUM(...)`), path traversal,
   PII redaction in logs (OWASP Agentic ASI02 / ASI07 + CWE-22).
6. **CLEAR production fields** populated in the frontmatter — cost budget,
   latency budget, p50/p95 token estimates (see `eval/rubrics.md §9a`).

## How to run it

This is a **specification** skill — the Markdown defines the contract an LLM
(or a code generator) should follow. To execute it as a standalone tool, pair
it with a thin runner that:

1. Parses the frontmatter to get the skill's declared envelope (size cap,
   supported types).
2. Reads the user's CSV + schema.
3. Runs the validation loop described in §5.
4. Emits the JSON shape described in §7.

A reference runner is out of scope for v3.5.0 (the skill itself is the
artefact); see `[ROADMAP v3.7.0]` for a bundled Python runner.

## Files

- `skill.md` — the skill definition (spec_version: "1.0", full CLEAR block,
  mode router, error table, OWASP security baseline, 5 benchmark tests).

## Related examples

- `examples/mcp-bridge/` — contrasts with this example: delegation-style
  (routes to an MCP tool) vs. in-process (this one).
- `examples/00-starter/` — simplest atomic skill.
- `examples/code-reviewer/` — another functional-tier skill with a richer
  workflow.
