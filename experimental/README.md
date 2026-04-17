# Experimental

Features that are **not yet shipped** and should not influence production
workflows. Prior skill-writer releases listed these under `[ROADMAP]` in the
main README, which created a false impression that they were operational.

What lives here:

| Subfolder | Status | Notes |
|-----------|--------|-------|
| `mcp/` | Skeleton only | MCP tool server that delegates mode execution back to the host LLM. Not wired to an installed MCP host. Do not base integrations on this. |

Deprecation policy: if an experimental feature has not moved out of this
directory after two minor releases, it is removed entirely.

Anything in this directory is **not referenced** by the main skill file, the
install scripts, or the Makefile's default target. If you import or depend
on it, you accept that it may change or disappear without notice.
