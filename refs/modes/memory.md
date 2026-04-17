<!-- Extracted from claude/skill-writer.md §18 — full reference -->

## §18  Memory Architecture `[EXTENDED — optional backend required for full capability]`

> **Enforcement Level Legend for this section:**
> - `[CORE]` — Available natively in every LLM session (in-context working memory).
> - `[EXTENDED]` — Requires an optional external backend (file system, database, GitHub Gist, vector DB).
>   The framework functions fully without it; these tiers add cross-session persistence and retrieval.

Skill Writer operates across three memory layers. Only Working Memory is natively available
in all LLM sessions. Episodic and Semantic Memory require optional external backends.

```
┌─────────────────────────────────────────────────────────────────────┐
│  WORKING MEMORY  `[CORE]`                                       │
│  Session-scoped in-context state                                    │
│  • Current skill content being processed                            │
│  • LEAN/EVALUATE scores and dimension breakdown                     │
│  • OPTIMIZE round history (within this session)                     │
│  • Self-review draft → reconcile cycle outputs                      │
│  Cleared on: session end                                            │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ optional persistence via backend
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│  EPISODIC MEMORY  `[EXTENDED]`                                  │
│  Persistent event log across sessions                               │
│  • Skill invocation history (cumulative_invocations counter)        │
│  • UTE feedback signals and micro-patch log                         │
│  • EVALUATE/OPTIMIZE audit trail (.skill-audit/framework.jsonl)     │
│  • 3-trigger evolution event log                                    │
│  Backends: SQLite · Redis · GitHub Gist · custom API                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ optional vector indexing
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│  SEMANTIC MEMORY  `[EXTENDED]`                                  │
│  Vectorized knowledge for retrieval-augmented skill generation      │
│  • Skill knowledge base (domain patterns, best practices)           │
│  • Historical optimization strategies and their outcomes            │
│  • CWE pattern embeddings for fuzzy security matching               │
│  Backends: ChromaDB · pgvector · Pinecone                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Minimum Viable Persistence (no infra required)

For projects without a persistence backend, use **GitHub Gist** as a free
cross-session episodic memory:

```
cumulative_invocations  →  update Gist JSON on each invocation
audit_trail             →  append to Gist JSONL file
ute_micro_patches       →  store patch candidates in Gist
```

The skill framework functions fully with Working Memory only. Episodic and
Semantic Memory unlock cadence-gated UTE health checks and RAG-enhanced
skill generation respectively.

---

