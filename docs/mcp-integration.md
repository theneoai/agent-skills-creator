# MCP Integration Guide


> MCP (Model Context Protocol) is fundamentally different from Markdown-based platforms.
> Read this section if you are integrating skill-writer into an MCP server for a team.

### MCP vs. Markdown platforms

| Aspect | Claude / OpenCode / Cursor | MCP |
|--------|---------------------------|-----|
| Skill format | Markdown + YAML frontmatter | JSON manifest |
| Context | Chat conversation | API call |
| User feedback | Present in chat | Not directly available |
| UTE auto-trigger | ✅ (observes chat) | ❌ (no chat context) |
| COLLECT auto-persist | ✅ with hooks | Requires explicit API call |

### Install

```bash
# Via install.sh
./install.sh --platform mcp
# Writes to: ~/.mcp/servers/skill-writer/mcp-manifest.json

# Via Agent Install
read https://github.com/theneoai/skill-writer/releases/latest/download/skill-writer-mcp.json and install to mcp
```

### After install — team usage

After the MCP manifest is installed, restart your MCP host. Team members can invoke
skill-writer via MCP calls. All 6 modes are available via MCP. Output is returned as structured JSON.

**Testing installation** — run this first to confirm MCP is working:
```json
{"tool": "skill-writer", "mode": "lean", "input": "a skill that returns json"}
```
Expected response: `{"lean_score": N, "status": "PASS|UNCERTAIN|FAIL", ...}`
If no response or error → verify `~/.mcp/servers/skill-writer/mcp-manifest.json` exists.

### CREATE mode via MCP (important — read before using)

CREATE uses an 8-question elicitation interview (§8 Inversion). In chat-based platforms
(Claude, Cursor), questions are asked one at a time interactively. **MCP is stateless**, so
all 8 answers must be provided in a single call using `elicitation_answers`:

```json
{
  "tool": "skill-writer",
  "mode": "create",
  "input": "a skill that validates REST API responses",
  "elicitation_answers": {
    "q1_problem": "Validate JSON structure and status codes in API responses",
    "q2_users": "Backend developers testing REST integrations",
    "q3_input": "HTTP response object (status code, headers, JSON body)",
    "q4_output": "Validation report: PASS/FAIL with specific field errors",
    "q5_constraints": "Must handle 2xx/4xx/5xx status families; no external calls",
    "q6_acceptance": "Catches missing required fields, wrong types, unexpected status codes",
    "q7_negative_boundaries": "Do NOT use for streaming responses; Do NOT validate auth tokens",
    "q8_trigger_phrases": "validate api response, check response, api assertion, verify response"
  }
}
```

If `elicitation_answers` is omitted, skill-writer will return a **questionnaire prompt**
(the 8 questions as text) for the caller to collect and re-submit with answers. This enables
a two-step MCP flow:

```
Step 1 — Initiate CREATE, get questions:
  Request:  {"tool": "skill-writer", "mode": "create", "input": "..."}
  Response: {"status": "NEEDS_ELICITATION", "session_id": "sw-xxxx",
             "questions": ["Q1: ...", "Q2: ...", ..., "Q8: ..."]}

Step 2 — Re-submit with answers:
  Request:  {"tool": "skill-writer", "mode": "create", "input": "...",
             "session_id": "sw-xxxx",   ← include to resume context
             "elicitation_answers": {"q1_problem": "...", ...}}
  Response: {"status": "COMPLETE", "skill_content": "---\nname: ..."}
```

**`session_id` state management**: The `session_id` returned in Step 1 can be stored
in your application to associate the pending questionnaire with a user. `session_id` values
are valid for 24 hours. After 24 hours, start a new CREATE call. If your MCP host has
no session state, omit `session_id` and always provide `elicitation_answers` in one call (batch mode).

### Team Backend Choice for MCP Deployments

If your team needs automatic tracking (COLLECT auto-persist, AGGREGATE across team members),
choose a backend based on team size and infrastructure:

| Backend | Best for | Setup complexity | Scale limit | Notes |
|---------|----------|-----------------|-------------|-------|
| **File system** (`~/.skill-artifacts/`) | Single developer, single host | None | Unlimited (local) | Write JSON to `~/.skill-artifacts/YYYYMMDD_{skill}.jsonl` |
| **GitHub Gist** (private) | Small team (2–5 people), no ops | Low | < 1 artifact/day/user; API rate limit 5000 req/hr | POST artifact JSON; share Gist URL for AGGREGATE |
| **SQLite** | Team on shared server | Low-medium | Up to ~10K artifacts; single-writer only | One DB file; episodic memory schema (see §17) |
| **PostgreSQL** | Large team, multi-host MCP | Medium | Unlimited with proper indexing | Full query capability; recommended for >20 developers |
| **Vector DB** (Qdrant/Pinecone) | Semantic search across sessions | High | Depends on plan | Required for §17 L4 episodic memory |

**PostgreSQL schema for teams** (recommended for >20 developers):
```sql
-- Migration: skill_artifacts table
CREATE TABLE skill_artifacts (
    id            SERIAL PRIMARY KEY,
    skill_name    TEXT NOT NULL,
    invocation_id TEXT UNIQUE,
    trigger_phrase TEXT,
    outcome       TEXT CHECK (outcome IN ('SUCCESS', 'FAILURE', 'PARTIAL')),
    prm_signal    FLOAT CHECK (prm_signal BETWEEN 0.0 AND 1.0),
    lesson_type   TEXT CHECK (lesson_type IN ('strategic_pattern','failure_lesson','neutral')),
    data          JSONB NOT NULL,  -- full Session Artifact JSON
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_skill_artifacts_skill_name ON skill_artifacts (skill_name);
CREATE INDEX idx_skill_artifacts_created_at ON skill_artifacts (created_at);

-- AGGREGATE query (run via skill-writer API or manually):
SELECT skill_name, lesson_type, COUNT(*) as evidence_count,
       AVG(prm_signal) as avg_quality
FROM skill_artifacts
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY skill_name, lesson_type
ORDER BY evidence_count DESC;
```

**Minimum viable team setup** (GitHub Gist, no ops):
```
1. After each skill invocation, call COLLECT via MCP API
2. POST the artifact JSON to a private GitHub Gist
3. Store the Gist URL in your team wiki
4. To run AGGREGATE: fetch 2+ Gist URLs, paste into MCP AGGREGATE call
```

### UTE and COLLECT via MCP

Because MCP operates without a persistent chat context, the COLLECT trigger must be
**built into your application layer** — it does not fire automatically. Here is the
complete integration pattern:

```
MCP UTE/COLLECT Architecture:

  Your application (Slack bot / CI / API gateway)
       │
       │  1. Invoke skill via MCP API
       ▼
  MCP server (skill-writer)
       │  executes the skill
       │
       │  2. Immediately after skill response, your app calls COLLECT:
       ▼
  {"tool": "skill-writer", "mode": "collect",
   "session_context": {
     "skill_name": "weather-query",
     "invocation_id": "uuid",
     "trigger_phrase": "what's the weather in Tokyo",
     "outcome": "SUCCESS",
     "prm_signal": 1.0
   }}
       │
       │  3. skill-writer returns JSON artifact
       │
       │  4. Your app POSTs artifact to backend:
       │     File:  append to ~/.skill-artifacts/YYYYMMDD_weather-query.jsonl
       │     Gist:  PATCH https://api.github.com/gists/{gist_id}
       │     DB:    INSERT INTO skill_artifacts (json_data, created_at)
       │
       │  5. UTE cadence (your app tracks count):
       │     every 10 invocations  → call COLLECT with mode: "ute_lightweight"
       │     every 50 invocations  → call with mode: "ute_full_recompute"
       │     every 100 invocations → call with mode: "ute_tier_drift_check"
       ▼
  AGGREGATE (run on demand):
  {"tool": "skill-writer", "mode": "aggregate",
   "artifacts": [artifact1_json, artifact2_json, ...]}
```

**Who triggers COLLECT?** Your application wrapper (not the end user). Build it as a
post-hook that fires after every successful skill invocation. If using a Slack bot, call
COLLECT in the bot's response handler. If using CI, add a COLLECT step after the skill step.

**Minimal integration example (Python pseudocode)**:
```python
import mcp_client, json, os, datetime

def invoke_skill_and_collect(skill_name, trigger_phrase, user_input):
    # Step 1 — invoke the actual skill
    skill_response = mcp_client.call("skill-writer", {
        "mode": "run",
        "skill": skill_name,
        "input": user_input
    })

    # Step 2 — rate the outcome (your app logic)
    outcome = "SUCCESS" if skill_response.get("status") == "ok" else "FAILURE"
    prm_signal = 1.0 if outcome == "SUCCESS" else 0.0

    # Step 3 — trigger COLLECT immediately after
    collect_response = mcp_client.call("skill-writer", {
        "mode": "collect",
        "session_context": {
            "skill_name": skill_name,
            "invocation_id": skill_response.get("invocation_id"),
            "trigger_phrase": trigger_phrase,
            "outcome": outcome,
            "prm_signal": prm_signal
        }
    })

    # Step 4 — persist artifact to your backend
    artifact = collect_response["artifact"]
    store_artifact(artifact)  # see backend choice table above
    return skill_response

def store_artifact(artifact):
    # PostgreSQL example:
    # cursor.execute("INSERT INTO skill_artifacts (data) VALUES (%s)", [json.dumps(artifact)])
    # File system example:
    today = datetime.date.today().isoformat()
    path = os.path.expanduser(f"~/.skill-artifacts/{today}_{artifact['skill_name']}.jsonl")
    with open(path, "a") as f:
        f.write(json.dumps(artifact) + "\n")

# UTE cadence check (call in your periodic job / cron):
def ute_cadence_check(invocation_count, skill_name):
    if invocation_count % 100 == 0:
        mode = "ute_tier_drift_check"
    elif invocation_count % 50 == 0:
        mode = "ute_full_recompute"
    elif invocation_count % 10 == 0:
        mode = "ute_lightweight"
    else:
        return  # no check needed this invocation
    mcp_client.call("skill-writer", {"mode": mode, "skill": skill_name})
```

- **UTE auto-trigger** does not fire (no chat to observe). Add `use_to_evolve.enabled: true`
  to skill YAML; your application handles the cadence (every 10/50/100 invocations above).
- **COLLECT**: Call explicitly from your application after each skill invocation.
  Output is JSON artifact — store in your chosen backend (see table above).
- **AGGREGATE**: Call with 2+ artifacts to get ranked improvement priorities.
  Provide artifacts as inline JSON in the call body (Method B) or point to a backend path.

---
