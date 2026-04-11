# Multi-Pass Self-Review Protocol

> **Purpose**: Quality assurance through structured multi-pass review within a single AI session.
> **Load**: When §4 (LoongFlow) or §12 (Self-Review) of `claude/skill-writer.md` is accessed.
> **Main doc**: `claude/skill-writer.md §4, §12`

---

> ### Enforcement Level Summary
>
> | Component | Level | Notes |
> |-----------|-------|-------|
> | LoongFlow Plan-Execute-Summarize | `[CORE]` | Fully executable within one session |
> | 3-Pass Review (Generate/Review/Reconcile) | `[CORE]` | Core mechanism, works within prompt |
> | Severity tagging (ERROR/WARNING/INFO) | `[CORE]` | Purely text-based, no external state |
> | Security scan via CWE patterns | `[CORE]` | Patterns embedded in refs/ companion file |
> | Timeout enforcement (60 s / 180 s) | `[EXTENDED]` | LLMs have no internal clock; use turn count as proxy |
> | Review log in `.skill-audit/review.jsonl` | `[EXTENDED]` | Requires external file-system backend |

---

## §1  LoongFlow — Plan-Execute-Summarize `[CORE]`

**Architecture**: Replaces rigid state machines with a flexible 3-phase cognitive loop.

```
PLAN
  ├── Pass 1: Propose approach (focus on completeness and correctness)
  ├── Pass 2: Audit approach (security risks via claude/refs/security-patterns.md + quality)
  ├── Reconcile: Resolve issues → build cognitive graph of steps
  └── Output: reviewed plan or HUMAN_REVIEW

EXECUTE
  ├── Follow cognitive graph step by step
  ├── Hard checkpoint after each step
  ├── Error recovery active (§3 below)
  └── Output: completed artifact or partial + recovery log

SUMMARIZE
  ├── Cross-validate artifact against original requirements
  ├── Update evolution memory (invocation count, result)
  └── Route: CERTIFIED | TEMP_CERT | HUMAN_REVIEW | ABORT
```

---

## §2  Three-Pass Review Process

### Pass 1 — Generate

Produce the initial draft, score, or fix proposal. Focus on:
- Completeness: all requirements addressed
- Correctness: logic and structure sound
- Output: candidate artifact

### Pass 2 — Review

Switch to a reviewer persona. Explicitly re-read the output as if reviewing someone else's work.

**Security audit** (mandatory):
- Scan for CWE patterns from `claude/refs/security-patterns.md`
- P0 patterns (CWE-798, CWE-89, CWE-78) → flag as ERROR

**Quality audit**:
- Tag each finding with severity: **ERROR** / **WARNING** / **INFO**
- ERROR = must fix before delivery (blocks certification)
- WARNING = should fix (score impact, -10 to -50 points)
- INFO = advisory (no score impact)

### Pass 3 — Reconcile

- Address all ERRORs (mandatory — delivery blocked until resolved)
- Address WARNINGs where feasible (improves score)
- Produce final artifact with confidence level

---

## §3  Consensus Outcomes

| Result | Condition | Action |
|--------|-----------|--------|
| **CLEAR** | No ERRORs found in Pass 2 | Proceed with full confidence |
| **REVISED** | ERRORs found and fixed in Pass 3 | Proceed with revision note |
| **UNRESOLVED** | Critical issues remain after Pass 3 | Escalate to HUMAN_REVIEW |

---

## §4  Error Recovery `[CORE]`

| Failure | Recovery |
|---------|---------|
| Security P0 detected | ABORT immediately — no override without human sign-off |
| Review finds structural flaw | Restart from Pass 1 with revised approach (max 2 restarts) |
| Phase timeout (> 60 s) | Deliver with WARNING flag; note incomplete review |
| Repeated issues after 2 revision cycles | Escalate to HUMAN_REVIEW |

> **Timeout note `[EXTENDED]`**: Wall-clock timeouts are not enforceable by AI.
> Use **turn count** as a proxy: each AI turn ≈ one review pass. If more than 6 turns
> have elapsed on a single review cycle, treat as timeout and flag accordingly.

---

## §5  Review Log Entry `[EXTENDED]`

> **`[EXTENDED]`**: The log schema below is the canonical output format.
> In stateless sessions, produce the JSON object as part of your response; the
> integration layer (or user) can persist it to `.skill-audit/review.jsonl`.

Each review cycle logs to `.skill-audit/review.jsonl`:

```json
{
  "timestamp": "<ISO-8601>",
  "mode": "<mode>",
  "skill_name": "<name>",
  "phase": "<phase_name>",
  "pass2_issues": {"ERROR": 0, "WARNING": 0, "INFO": 0},
  "consensus": "CLEAR|REVISED|UNRESOLVED",
  "revisions_applied": 0,
  "duration_ms": 0
}
```
