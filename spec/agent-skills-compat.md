# Agent Skills Open Standard — Compatibility Declaration

> **Status**: DRAFT for v3.5.0 (2026-04)
> **Spec target**: `agentskills.io/specification` v1.0 (Anthropic-led, 2025-12-18 open standard)
> **Scope**: This document declares how skill-writer aligns with (and extends) the
>   Agent Skills open standard adopted by Claude, OpenAI Codex, Gemini CLI, GitHub
>   Copilot, Cursor, VS Code, and 25+ other platforms.

---

## §1  Why spec compatibility matters

Before 2025-12-18, every platform had its own skill format (Claude `SKILL.md`,
Cursor `.mdc`, OpenAI Codex "Skills", Gemini Gems, etc.). On 2025-12-18 Anthropic
released the Agent Skills spec as an open standard hosted at `agentskills.io`.
By 2026-Q1, 30+ platforms had adopted a common subset.

skill-writer pre-dates the open standard and carries a **superset schema** (richer
frontmatter: `skill_tier`, `triggers`, `use_to_evolve`, `graph`, `validation_status`,
`generation_method`). Without an explicit compat layer, strict spec validators on
adopting platforms may reject or silently drop our extensions.

This document defines:

1. Which fields of our schema map 1:1 to the spec.
2. Which fields are **private extensions** (namespaced under `x-skill-writer:`).
3. How to emit a **spec-pure** skill file via `make build-spec`.
4. How `scripts/check-spec-compat.py` validates conformance.

---

## §2  Field mapping — skill-writer ↔ agentskills.io v1.0

### Required by spec (MUST)

| spec field       | skill-writer field | compat notes |
|------------------|--------------------|---|
| `name`           | `name`             | identical; kebab-case identifier |
| `description`    | `description`      | identical; single-line summary |

### Optional in spec (SHOULD)

| spec field       | skill-writer field         | compat notes |
|------------------|----------------------------|---|
| `version`        | `version`                  | semver; identical |
| `license`        | `license`                  | SPDX id; identical |
| `author`         | `author.name`              | spec allows string-or-object; we use object |
| `homepage`       | — (derived from repo)      | optional; populated by build-platforms.py |
| `keywords`       | `tags`                     | renamed on export |
| `spec_version`   | **NEW** in v3.5.0          | `"1.0"` — declares spec conformance target |

### skill-writer private extensions (MUST be under `x-skill-writer:` for spec-pure emit)

| skill-writer field      | purpose                                           |
|-------------------------|---------------------------------------------------|
| `description_i18n`      | bilingual description (en/zh)                     |
| `skill_tier`            | three-tier hierarchy: planning / functional / atomic |
| `triggers.en`/`zh`      | canonical invocation phrases per language         |
| `interface`             | I/O type declaration                              |
| `extends`               | meta-framework extension points                   |
| `graph`                 | GoS dependency/composition block                  |
| `use_to_evolve`         | UTE 2.0 self-improvement state                    |
| `generation_method`     | how this skill was produced (v3.4.0)              |
| `validation_status`     | evaluation gate reached (v3.4.0)                  |

**Rule**: All of the above MUST be moved under `x-skill-writer:` in spec-pure
emission. Adopting platforms treat `x-*` keys as pass-through (per spec §4.2)
without validation failure.

---

## §3  Emission modes

skill-writer produces two flavors of output from a single source:

| Mode       | Command                                   | Target audience |
|------------|-------------------------------------------|-----------------|
| `native`   | `make build-platforms`                    | skill-writer users — full feature set (extensions at top level) |
| `spec+ext` | `make emit-spec-pure SKILL=... OUT=...`   | cross-platform consumers — spec v1.0 pure top level + extensions under `x-skill-writer:` |

The spec-pure flavor is what you publish to agentskills.io registries, share
on the agentskills marketplace, or distribute to unknown consumers. The
runtime-state subset of `use_to_evolve` (`cumulative_invocations`,
`last_ute_check`, `pending_patches`, `total_micro_patches_applied`,
`certified_lean_score`) is stripped to an optional sidecar JSON — those
fields mutate on every invocation and do not belong in the source file.

**New in this release**: the base template emits the `x-skill-writer:`
nested layout by default, so new skills are spec-pure out of the box. The
emit script is for migrating older skills that used the flat layout.

---

## §4  Validation

`scripts/check-spec-compat.py` runs three checks:

1. **Required-field presence**: `name` and `description` are non-empty.
2. **No-unknown-top-level**: every top-level frontmatter key is either a spec
   field or starts with `x-`.
3. **Type conformance**: `name` is kebab-case string; `version` matches semver;
   `license` is a SPDX id (or one of `MIT`/`Apache-2.0`/`BSD-3-Clause`/...).

Usage:

```bash
make check-spec-compat                         # check all platform files
python3 scripts/check-spec-compat.py FILE...   # check specific files
```

CI (`.github/workflows/ci.yml`) runs this on every push.

---

## §5  Upstream spec sources

- Canonical spec: <https://agentskills.io/specification>
- Reference repo: <https://github.com/agentskills/agentskills>
- Anthropic announcement: <https://www.anthropic.com/news/agent-skills-open-standard>
  (2025-12-18)
- Format reference: `SKILL.md` consists of YAML frontmatter + Markdown body.
  Body should remain under 500 lines per Anthropic's authoring best practices.

---

## §6  Roadmap

- v3.5.0: Introduce `spec_version` field; ship `check-spec-compat.py` + `make build-spec`.
- v3.6.0: Dual-publish (`native` + `spec`) on every release; marketplace push.
- v4.0.0: Deprecate private-namespace fields in favor of spec-registered extensions
  where the spec has caught up.
