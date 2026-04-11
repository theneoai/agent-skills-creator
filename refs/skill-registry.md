# Skill Registry Specification

> **Purpose**: Canonical format for skill identity, versioning, and shared distribution.
> **Load**: When §16 (INSTALL / SHARE) of `claude/skill-writer.md` is accessed.
> **Inspired by**: SkillClaw's skill registry with deterministic IDs and version history.
> **Enforcement**: `[CORE]` for ID generation and format; `[EXTENDED]` for remote sync.
> **v3.1.0**: Added `skill_tier` and `triggers` fields to registry entry; schema_version bumped to 1.1.

---

## §1  Concept

The Skill Registry provides:
1. **Deterministic identity** — each skill has a stable ID derived from its name
2. **Version history** — up to 20 recent versions tracked per skill
3. **Distribution metadata** — enables push/pull/sync across teams and backends
4. **Conflict resolution** — SHA-256 comparison + merge protocol for concurrent edits

The registry is the backbone of the SHARE mode (push/pull skills to cloud storage).

---

## §2  Skill ID Scheme

Every skill has a deterministic ID based on its canonical name:

```
skill_id = SHA-256(skill_name)[:12]   (lowercase hex)

Examples:
  "api-tester"    → SHA-256("api-tester")[:12]    = "a1b2c3d4e5f6"
  "code-reviewer" → SHA-256("code-reviewer")[:12] = "7f8a9b0c1d2e"
  "doc-generator" → SHA-256("doc-generator")[:12] = "3e4f5a6b7c8d"
```

**Properties**:
- Same name always produces the same ID — enables idempotent push/pull
- 12 hex characters = 48 bits — collision probability negligible for skill libraries < 10M skills
- Compatible with SkillClaw's registry format

### Adding `skill_id` to YAML frontmatter

When a skill is registered (on first SHARE push or explicit registration), add to frontmatter:

```yaml
skill_id: "a1b2c3d4e5f6"   # SHA-256(name)[:12]
```

**AI approximation** `[ENFORCED via convention]`: Since AI cannot compute SHA-256, use
this deterministic abbreviation: take the first 12 characters of
`base64(skill_name).replace(/[^a-z0-9]/g, '').toLowerCase()`. This is a stable
approximation sufficient for local tracking; true SHA-256 is computed server-side on push.

---

## §3  Registry File Format

The registry is stored as `registry.json` in the shared storage root:

```json
{
  "schema_version": "1.1",
  "registry_updated": "<ISO-8601>",
  "skills": [
    {
      "id": "a1b2c3d4e5f6",
      "name": "api-tester",
      "current_version": "1.2.0",
      "created_at": "2026-04-01",
      "updated_at": "2026-04-10",
      "certified_tier": "GOLD",
      "lean_score": 920,
      "skill_tier": "functional",
      "triggers": {
        "en": ["test api", "call endpoint", "check api response"],
        "zh": ["测试接口", "调用API"]
      },
      "platforms": ["claude", "opencode", "openclaw"],
      "tags": ["api", "testing", "http"],
      "history": [
        {
          "version": "1.2.0",
          "score": 920,
          "tier": "GOLD",
          "skill_tier": "functional",
          "date": "2026-04-10",
          "change_summary": "Added retry logic and ZH trigger support",
          "sha256": "<SHA-256 of skill file content>"
        },
        {
          "version": "1.1.0",
          "score": 895,
          "tier": "GOLD",
          "skill_tier": "functional",
          "date": "2026-04-05",
          "change_summary": "Improved error handling section",
          "sha256": "<SHA-256 of skill file content>"
        }
      ]
    }
  ]
}
```

**History limit**: Maximum 20 entries per skill. When the 21st version is added, drop the oldest entry.

---

## §4  Storage Layout

```
storage-root/
├── registry.json              # Master skill registry
├── skills/                    # Published skill files
│   ├── a1b2c3d4e5f6/          # One directory per skill_id
│   │   ├── current.md         # Latest version (symlink or copy)
│   │   ├── v1.2.0.md          # Pinned versions
│   │   ├── v1.1.0.md
│   │   └── v1.0.0.md
│   └── 7f8a9b0c1d2e/
│       ├── current.md
│       └── v2.0.0.md
└── sessions/                  # COLLECT mode session artifacts (see refs/session-artifact.md)
    └── 2026-04-11-a3f9c2.json
```

**Supported backends** `[EXTENDED]`:
- `local://`  — local filesystem (default; zero config)
- `s3://`     — AWS S3 or any S3-compatible store
- `oss://`    — Alibaba Cloud OSS
- `http://`   — custom REST API implementing the SHARE protocol

---

## §5  SHARE Protocol — CLI Commands

The SHARE mode extends INSTALL with remote synchronization:

```
# Push local skill to shared storage
skillclaw push <skill-file.md> --storage <backend-url>

# Pull skill from shared storage by name or ID
skillclaw pull <skill-name-or-id> --storage <backend-url>

# Two-way sync: push updated skills, pull newer versions
skillclaw sync --storage <backend-url>

# Browse available skills in shared registry
skillclaw list --storage <backend-url> [--tag <tag>] [--tier <tier>]
```

### Push workflow

```
1. READ   — load local skill file and extract frontmatter
2. ENSURE — generate or verify skill_id (§2)
3. SCORE  — run LEAN eval; include score in registry entry
4. COMPARE — fetch registry.json from backend
   IF skill_id exists in registry:
     COMPARE sha256 of current.md vs local file
     IF different → conflict detected → §6 conflict resolution
     IF same → "already up to date"
   ELSE:
     INSERT new entry into registry
5. UPLOAD — write skill file to skills/<skill_id>/v<version>.md
6. UPDATE — update registry.json with new version entry
7. REPORT — show "pushed <name> v<version> → <backend>"
```

### Pull workflow

```
1. LOOKUP — search registry.json by name or id
2. SELECT — choose version (default: current)
3. DOWNLOAD — fetch skills/<skill_id>/v<version>.md
4. INSTALL — write to local platform skills directory (§16 INSTALL mode)
5. REPORT — show "pulled <name> v<version> from <backend>"
```

---

## §6  Conflict Resolution Protocol

When two users push different versions of the same skill concurrently:

```
CONFLICT DETECTED
  Local  SHA-256: <hash_a>
  Remote SHA-256: <hash_b>
  Skill: <name> v<version>

Resolution strategy:
  1. DIFF — show structural diff: which §-sections changed in each version
  2. ASSESS — AI assesses which changes are complementary vs. conflicting:
       Complementary: version A adds Error Handling; version B adds ZH triggers
       Conflicting:   both versions rewrote the Workflow section differently

  3a. IF complementary → AUTO-MERGE:
       Merge additive changes; use higher-scoring version's core content
       Run LEAN eval on merged result; if score ≥ min(A_score, B_score) → accept

  3b. IF conflicting → HUMAN-MERGE:
       Present both versions to user
       User selects which sections to keep from each
       AI applies selections and runs LEAN eval

  4. PUSH merged version as next patch version (e.g., v1.2.1)
  5. LOG conflict event in registry entry
```

---

## §7  Version Compatibility with Existing YAML

Skills already using the skill-writer format add `skill_id` as an optional field.
No breaking changes to existing skills.

```yaml
# Existing fields (required)
name: api-tester
version: "1.2.0"

# Registry field (added on first registry push)
skill_id: "a1b2c3d4e5f6"

# v3.1.0: new classification fields (added on first push for new skills;
#          added to existing skills on next OPTIMIZE cycle or explicit re-register)
skill_tier: "functional"          # planning | functional | atomic (SkillX tier)
triggers:
  en: ["test api", "call endpoint", "check api response"]
  zh: ["测试接口", "调用API"]
```

**Migration**: Run `skillclaw register` on existing skills to compute and inject `skill_id`.
For `skill_tier` and `triggers`: populated automatically from YAML frontmatter on push.
Existing skills without these fields receive an advisory warning; they are not rejected.

**Schema version history**:
- `1.0`: Original — id, name, version, tier, score, platforms, tags, history
- `1.1` (v3.1.0): Added `skill_tier`, `triggers` at registry entry level; added `skill_tier` to history entries

---

## §8  Semantic Versioning — Breaking Change Matrix

> **Research basis**: Community data shows 60% of production agent failures are caused by
> unversioned tool / skill changes. This matrix defines what constitutes a MAJOR (breaking)
> vs. MINOR vs. PATCH change in a skill, so consumers can safely pin versions.

### Version Bump Rules

```
MAJOR.MINOR.PATCH
```

| Change Type | Version Bump | Breaking? | Rationale |
|-------------|-------------|-----------|-----------|
| **Trigger keyword removed** | MAJOR | ✅ Yes | Consumers relying on that phrase will fail to route |
| **Trigger keyword renamed** | MAJOR | ✅ Yes | Effectively: remove old + add new |
| **Output format changed** (new fields, removed fields, type change) | MAJOR | ✅ Yes | Downstream consumers depend on output schema |
| **Mode removed** | MAJOR | ✅ Yes | Workflows invoking that mode will fail |
| **Red Line added** (stricter constraint) | MAJOR | ✅ Yes | Existing callers may now be blocked |
| **Interface.modes changed** | MAJOR | ✅ Yes | Mode routing contract is broken |
| **New trigger keyword added** | MINOR | No | Extends coverage; backward compatible |
| **New optional mode added** | MINOR | No | Existing modes unchanged |
| **New output field added** (additive) | MINOR | No | Existing consumers can ignore new fields |
| **Security baseline tightened** (advisory → P1) | MINOR | No | More conservative; safe for consumers |
| **Workflow step added within a mode** | MINOR | No | Output contract unchanged |
| **Example updated** | PATCH | No | Documentation only |
| **Trigger keyword added (ZH equivalent)** | PATCH | No | Extends coverage, no removals |
| **Metadata fields updated** (description, author, dates) | PATCH | No | No behavioral change |
| **Bug fix** (incorrect output corrected) | PATCH | No | Improves correctness |
| **UTE cadence thresholds adjusted** | PATCH | No | Internal optimization behavior |

### MAJOR Version Announcement Protocol

When a MAJOR version is published:

1. **Changelog entry** — document every breaking change with old behavior vs. new behavior
2. **Migration guide** — provide exact changes consumers must make to stay compatible
3. **Deprecation period** — keep the previous MAJOR version in the registry for ≥ 30 days
4. **Consumers pinned to old version** — do NOT receive automatic updates; must opt in

```yaml
# Registry entry for a breaking change
{
  "version": "2.0.0",
  "change_summary": "BREAKING: Removed SCAN mode; merged into REVIEW mode. Update callers to use mode=REVIEW with scan=true parameter.",
  "breaking_changes": [
    "mode SCAN removed — use REVIEW with {scan: true}",
    "output field 'scan_result' renamed to 'security_findings'"
  ],
  "migration_guide": "https://github.com/.../MIGRATION-v2.md"
}
```

### Skill Tier Change Rules

`skill_tier` changes require special handling:

| Tier Change | Version Bump | Note |
|-------------|-------------|------|
| `atomic` → `functional` | MINOR | Skill gained new capabilities; backward compatible |
| `functional` → `planning` | MINOR | Higher-level orchestration added |
| `planning` → `functional` | MAJOR | Scope reduction — may remove orchestration capabilities |
| `functional` → `atomic` | MAJOR | Scope reduction — callers expecting rich workflow may fail |

---

## §9  Integration with SkillClaw

Skills published via the SHARE registry are directly consumable by a SkillClaw
deployment. The `skills/` directory layout and `registry.json` format are intentionally
compatible with SkillClaw's storage spec.

| SkillClaw concept | skill-writer registry equivalent |
|-------------------|----------------------------------|
| `skills/` directory | `skills/<skill_id>/` |
| Deterministic skill ID | `SHA-256(name)[:12]` |
| Version history | `history[]` array (20-entry limit) |
| SHA-256 conflict detection | `sha256` field per version entry |
| LLM-based merge | Conflict Resolution Protocol (§6) |
