<!-- Extracted from claude/skill-writer.md §16 — full reference -->

## §16  UTE Injection

**Use-to-Evolve (UTE)** is injected into every skill the framework creates or optimizes.
The AI, upon recognizing the UTE section, follows the protocol to observe usage patterns
and propose improvements over time.

Full spec: `refs/use-to-evolve.md`
Snippet: `templates/use-to-evolve-snippet.md`

### Injection Protocol (CREATE Step 8 / OPTIMIZE Pre-loop)

```
1. CHECK   — does skill already have §UTE section?
     YES → UPDATE: refresh certified_lean_score, reset last_ute_check
     NO  → INJECT: proceed below

2. LOAD    — read templates/use-to-evolve-snippet.md

3. FILL PLACEHOLDERS:
     {{SKILL_NAME}}           = skill's `name` YAML field
     {{VERSION}}              = skill's `version` YAML field
     {{FRAMEWORK_VERSION}}    = "3.4.0"
     {{INJECTION_DATE}}       = today ISO-8601
     {{CERTIFIED_LEAN_SCORE}} = LEAN score from Step 6 (or 350 if unknown)

4. APPEND  — add §UTE section after last ## §N section in skill

5. MERGE YAML — add use_to_evolve: block to skill's YAML frontmatter

6. LOG — record in audit trail: {"ute_injected": true, "certified_lean_score": N}
```

### What UTE Enables

After injection, the AI follows the UTE protocol to:

| Capability | Level | How It Works |
|-----------|-------|-----------|
| Feedback detection | `[CORE]` | AI observes user corrections, rephrasing, and approvals |
| Trigger candidate collection | `[CORE]` | Rephrasing patterns noted; ≥3 similar → micro-patch candidate |
| Micro-patch proposals | `[CORE]` | AI suggests keyword additions; user confirms before apply |
| OPTIMIZE suggestions | `[CORE]` | Structural issues flagged for full OPTIMIZE cycle |
| Periodic health checks (every 10/50/100) | `[EXTENDED]` | Requires persistent `cumulative_invocations` counter |
| Cadence-gated tier drift detection | `[EXTENDED]` | Requires cross-session invocation counter |

### UTE Update (on OPTIMIZE)

When optimizing a skill that already has UTE:

```
1. Load current use_to_evolve.certified_lean_score
2. Review any user-reported issues as starting point for dimension analysis
3. After all optimization rounds complete:
     update use_to_evolve.certified_lean_score = final_lean_score
     update use_to_evolve.last_ute_check = today
```

This closes the feedback loop: UTE observes usage → proposes improvements →
OPTIMIZE applies fixes → updates UTE baseline → repeat.

---

## §16a  Skill Deprecation Lifecycle

Every skill has a `lifecycle_status` field in its YAML frontmatter that progresses through
four states. The deprecation lifecycle integrates with UTE Trigger 3 (usage-based) and the
SHARE gate.

### YAML Field

```yaml
lifecycle_status: "active"    # active | maintenance | deprecated | archived
deprecated_at: null           # ISO-8601 timestamp; set when status → deprecated
deprecation_reason: null      # human-readable reason
replacement_skill: null       # name of replacement skill, if any
```

**Injection**: `lifecycle_status: "active"` is injected by CREATE (Phase 9) alongside
the `use_to_evolve` block. Skills created before v3.4.0 default to `active` if field absent.

### Lifecycle States

| Status | Meaning | Routing | SHARE |
|--------|---------|---------|-------|
| `active` | Normal operation | Full routing | Allowed |
| `maintenance` | Receiving only bug fixes; no new features | Full routing with advisory | Allowed with note |
| `deprecated` | Replaced or obsolete; use replacement instead | WARNING on every invocation | HARD BLOCKED |
| `archived` | Removed from active use; registry read-only | Silenced from routing | BLOCKED |

### DEPRECATE Mode `/deprecate` `[CORE]`

Triggered by: `"deprecate skill"`, `"mark skill as deprecated"`, `/deprecate`

```
DEPRECATE SEQUENCE:
  1. CHECK DEPENDENTS [CORE]
     Read graph: depends_on entries across all installed skills.
     IF any active skill lists this skill as a required depends_on:
       → WARN: "N skills depend on <name>. Deprecating will break them."
       → List dependents by name
       → Require user to acknowledge before proceeding

  2. CHECK REGISTRY [EXTENDED]
     If registry is configured: check for downstream dependents not locally installed.
     Report count; if > 0 → recommend notifying registry maintainer.

  3. SET FIELDS [CORE]
     Update skill YAML frontmatter:
       lifecycle_status: "deprecated"
       deprecated_at: "<today ISO-8601>"
       deprecation_reason: "<user-provided or AI-inferred>"
       replacement_skill: "<name of replacement, or null>"

  4. UPDATE GRAPH [CORE]
     If replacement_skill declared: propose similar_to edge with similarity 0.99
     between this skill and replacement (for dedup/routing purposes).

  5. NOTIFY [CORE]
     Output deprecation notice:
       "DEPRECATED: <skill-name> v<version>
        Reason: <reason>
        Replacement: <replacement or 'none'>
        Any skill that depends_on <name> must update its graph: block."

  6. REGISTER [EXTENDED]
     If registry configured: push deprecation flag to registry.json entry.
```

### Routing Behavior for Deprecated Skills

```
IF skill trigger matches AND skill.lifecycle_status == "deprecated":
  → Show WARNING before any output:
    "⚠ This skill (<name>) is deprecated.
     Reason: <deprecation_reason>
     Replacement: <replacement_skill or 'see registry for alternatives'>
     Type 'proceed anyway' to continue, or switch to the replacement skill."
  → Do NOT silently execute a deprecated skill
```

---

