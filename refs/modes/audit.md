<!-- Extracted from claude/skill-writer.md §14 — full reference -->

## §14  Audit Trail `[EXTENDED — requires external persistence]`

> `[CORE]` — Produce the audit JSON object in your response so users can persist it.
> `[EXTENDED]` — Auto-write to `.skill-audit/framework.jsonl` requires file system access.

Every operation produces an audit record with: `timestamp`, `mode`, `skill_name`,
`lean_score`, `total_score`, `tier`, `outcome`, and security/review fields.
Full schema: `refs/edit-audit.md §1`.

---

