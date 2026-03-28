# Skill Type Detection

> Automatic Skill Type Classification for Appropriate Validation

---

## Skill Types

| Type | Detection | Runtime Validator | Variance Threshold |
|------|-----------|-------------------|-------------------|
| **manager** | Has CREATE/EVALUATE/RESTORE/TUNE modes | `runtime-validate.sh` | 2.0 |
| **content** | Domain role, examples, scenarios | `runtime-validate-content.sh` | 2.5 |
| **tool** | Commands, utilities, API calls | `runtime-validate.sh` | 2.0 |

---

## Detection Heuristics

### Manager Type

**Indicators**:
- Contains workflow modes (CREATE, EVALUATE, TUNE, RESTORE)
- Uses orchestrator pattern
- Multi-agent coordination present
- Skill lifecycle management

### Content Type

**Indicators**:
- Domain role definition (e.g., "You are a code reviewer")
- Rich examples with scenarios
- Explanatory content
- Learning/teaching focus

### Tool Type

**Indicators**:
- Command execution patterns
- API integration
- Utility functions
- Single-purpose operations

---

## Type-Specific Validation

| Type | Focus Areas |
|------|-------------|
| manager | Mode routing accuracy, Multi-turn handling, Skill collaboration |
| content | Role consistency, Example quality, Domain accuracy |
| tool | Command correctness, Parameter handling, Error reporting |

---

## Variance Thresholds by Type

| Type | Variance Threshold | Rationale |
|------|-------------------|------------|
| manager | 2.0 | Complex workflows may show larger text-runtime gaps |
| content | 2.5 | Content quality varies more naturally |
| tool | 2.0 | Concrete commands are more predictable |
