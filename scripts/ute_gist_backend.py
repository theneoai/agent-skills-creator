#!/usr/bin/env python3
"""
scripts/ute_gist_backend.py — GitHub Gist as zero-infrastructure UTE episodic memory

Upgrades UTE L2 [EXTENDED] cross-session tracking to near-[CORE] for any user
with a GitHub personal access token. No database, no server, no setup beyond
`export GITHUB_TOKEN=...`.

What this enables:
  - Persistent cumulative_invocations counter (survives session restarts)
  - Cadence-gated health check notifications (every 10/50/100 invocations)
  - Cross-session session artifact storage (feeds AGGREGATE pipeline)
  - Patch history log (micro-patches applied across sessions)
  - Skill health dashboard via GitHub Gist URL (shareable with teammates)

Architecture:
  One GitHub Gist per skill (private by default). The Gist contains a single
  JSON file `<skill-name>-ute-state.json` with the full UTE state. Every
  operation reads the latest version, mutates, and writes back atomically.

Requires: pip install requests (or: pip install anthropic which includes it transitively)

Usage
-----
    export GITHUB_TOKEN=ghp_your_token_here

    # Initialize a new UTE state Gist for a skill
    python3 scripts/ute_gist_backend.py init --skill my-skill --lean-score 380

    # Record one invocation (call after each skill use)
    python3 scripts/ute_gist_backend.py record --skill my-skill

    # Read current state and check if cadence events are pending
    python3 scripts/ute_gist_backend.py status --skill my-skill

    # Add a session artifact (JSON from COLLECT mode)
    python3 scripts/ute_gist_backend.py add-artifact --skill my-skill --artifact session.json

    # Record a micro-patch applied to the skill
    python3 scripts/ute_gist_backend.py add-patch --skill my-skill --patch "Added ZH trigger: 调用API"

    # Export all session artifacts for AGGREGATE mode
    python3 scripts/ute_gist_backend.py export-artifacts --skill my-skill --out artifacts/

Exit codes: 0 = success, 1 = error, 2 = cadence event pending (check required)
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    import urllib.request
    import urllib.error
    HAS_URLLIB = True
except ImportError:
    HAS_URLLIB = False

# Optional: use requests if available (better error messages)
try:
    import requests as _requests  # type: ignore
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

GITHUB_API = "https://api.github.com"
GIST_DESC_PREFIX = "skill-writer UTE state:"

# Cadence thresholds (mirrors refs/use-to-evolve.md §4)
CADENCE = {
    "lightweight":   10,   # every 10 invocations
    "full_recompute": 50,  # every 50
    "tier_drift":    100,  # every 100
}


# ── GitHub Gist API wrapper ────────────────────────────────────────────────────

class GistClient:
    def __init__(self, token: str):
        self.token = token
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }

    def _request(self, method: str, url: str, data: dict | None = None) -> dict:
        """Make a GitHub API request with retry on rate-limit."""
        if HAS_REQUESTS:
            return self._request_via_requests(method, url, data)
        return self._request_via_urllib(method, url, data)

    def _request_via_requests(self, method: str, url: str, data: dict | None) -> dict:
        for attempt in range(3):
            resp = _requests.request(method, url, headers=self.headers, json=data, timeout=15)
            if resp.status_code == 429:
                wait = int(resp.headers.get("Retry-After", 10))
                print(f"  ↺ Rate limited — waiting {wait}s…", file=sys.stderr)
                time.sleep(wait)
                continue
            resp.raise_for_status()
            return resp.json() if resp.text else {}
        raise RuntimeError("GitHub API rate limit exceeded after retries")

    def _request_via_urllib(self, method: str, url: str, data: dict | None) -> dict:
        import urllib.request, urllib.error
        body = json.dumps(data).encode() if data else None
        req = urllib.request.Request(url, data=body, headers={
            **self.headers,
            "Content-Type": "application/json",
        }, method=method)
        for attempt in range(3):
            try:
                with urllib.request.urlopen(req, timeout=15) as resp:
                    body = resp.read()
                    return json.loads(body.decode()) if body else {}
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    time.sleep(10 * (attempt + 1))
                    continue
                raise
        raise RuntimeError("GitHub API rate limit exceeded after retries")

    def list_gists(self) -> list[dict]:
        return self._request("GET", f"{GITHUB_API}/gists?per_page=100")  # type: ignore

    def create_gist(self, filename: str, content: str, description: str, public: bool = False) -> dict:
        return self._request("POST", f"{GITHUB_API}/gists", {
            "description": description,
            "public": public,
            "files": {filename: {"content": content}},
        })

    def get_gist(self, gist_id: str) -> dict:
        return self._request("GET", f"{GITHUB_API}/gists/{gist_id}")

    def update_gist(self, gist_id: str, filename: str, content: str) -> dict:
        return self._request("PATCH", f"{GITHUB_API}/gists/{gist_id}", {
            "files": {filename: {"content": content}},
        })

    def find_skill_gist(self, skill_name: str) -> dict | None:
        """Find the UTE state Gist for a given skill name."""
        target_desc = f"{GIST_DESC_PREFIX} {skill_name}"
        gists = self.list_gists()
        for g in gists:
            if g.get("description", "") == target_desc:
                return g
        return None


# ── State management ──────────────────────────────────────────────────────────

def _empty_state(skill_name: str, certified_lean_score: int = 0) -> dict:
    return {
        "schema_version": "1.0",
        "skill_name": skill_name,
        "cumulative_invocations": 0,
        "certified_lean_score": certified_lean_score,
        "last_ute_check": None,
        "pending_patches": 0,
        "total_micro_patches_applied": 0,
        "session_artifacts": [],
        "patch_log": [],
        "cadence_events": [],
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


def _read_state(gist_client: GistClient, skill_name: str) -> tuple[dict, str, str]:
    """
    Returns (state_dict, gist_id, filename).
    Raises RuntimeError if gist not found.
    """
    gist = gist_client.find_skill_gist(skill_name)
    if not gist:
        raise RuntimeError(
            f"No UTE state Gist found for skill '{skill_name}'. "
            f"Run: python3 scripts/ute_gist_backend.py init --skill {skill_name}"
        )
    gist_id = gist["id"]
    full_gist = gist_client.get_gist(gist_id)
    files = full_gist.get("files", {})
    filename = f"{skill_name}-ute-state.json"
    file_data = files.get(filename, {})
    content = file_data.get("content", "{}")
    state = json.loads(content)
    return state, gist_id, filename


def _write_state(gist_client: GistClient, gist_id: str, filename: str, state: dict) -> None:
    state["updated_at"] = datetime.now(timezone.utc).isoformat()
    gist_client.update_gist(gist_id, filename, json.dumps(state, indent=2))


# ── Commands ──────────────────────────────────────────────────────────────────

def cmd_init(client: GistClient, skill_name: str, lean_score: int) -> int:
    existing = client.find_skill_gist(skill_name)
    if existing:
        print(f"✓ UTE state Gist already exists for '{skill_name}' (id: {existing['id']})")
        print(f"  URL: {existing['html_url']}")
        return 0

    state = _empty_state(skill_name, lean_score)
    filename = f"{skill_name}-ute-state.json"
    gist = client.create_gist(
        filename=filename,
        content=json.dumps(state, indent=2),
        description=f"{GIST_DESC_PREFIX} {skill_name}",
        public=False,
    )
    print(f"✓ UTE state Gist created for '{skill_name}'")
    print(f"  Gist ID : {gist['id']}")
    print(f"  URL     : {gist['html_url']}")
    print(f"  File    : {filename}")
    print(f"\nNext step: add Gist ID to your skill's YAML frontmatter:")
    print(f"  use_to_evolve:")
    print(f"    gist_id: \"{gist['id']}\"  # UTE backend (ute_gist_backend.py)")
    return 0


def cmd_record(client: GistClient, skill_name: str) -> int:
    """Record one invocation. Returns exit 2 if cadence event is now pending."""
    state, gist_id, filename = _read_state(client, skill_name)
    state["cumulative_invocations"] += 1
    inv = state["cumulative_invocations"]
    ts = datetime.now(timezone.utc).isoformat()

    pending_events = []
    for event_name, threshold in CADENCE.items():
        if inv % threshold == 0:
            event = {"at": ts, "event": f"{event_name}_due", "inv": inv}
            state["cadence_events"].append(event)
            pending_events.append(event_name)

    _write_state(client, gist_id, filename, state)
    print(f"✓ Recorded invocation #{inv} for '{skill_name}'")

    if pending_events:
        print(f"\n⚠ UTE cadence events pending:")
        for name in pending_events:
            if name == "lightweight":
                print(f"  → Lightweight check due (every {CADENCE['lightweight']} invocations)")
                print(f"     Review recent interactions for recurring trigger misses or corrections.")
            elif name == "full_recompute":
                print(f"  → Quality assessment due (every {CADENCE['full_recompute']} invocations)")
                print(f"     Run: /eval to re-certify skill health.")
            elif name == "tier_drift":
                print(f"  → Tier drift check due (every {CADENCE['tier_drift']} invocations)")
                print(f"     Run: /eval and compare to certified_lean_score={state.get('certified_lean_score', 'N/A')}")
        return 2

    return 0


def cmd_status(client: GistClient, skill_name: str) -> int:
    state, gist_id, _ = _read_state(client, skill_name)
    inv = state["cumulative_invocations"]
    lean = state.get("certified_lean_score", 0)

    print(f"\nUTE State — {skill_name}")
    print(f"  Invocations      : {inv}")
    print(f"  Lean score       : {lean}/500")
    print(f"  Last check       : {state.get('last_ute_check') or 'never'}")
    print(f"  Pending patches  : {state.get('pending_patches', 0)}")
    print(f"  Patches applied  : {state.get('total_micro_patches_applied', 0)}")
    print(f"  Artifacts stored : {len(state.get('session_artifacts', []))}")
    print(f"  Updated          : {state.get('updated_at', 'unknown')}")

    events = state.get("cadence_events", [])
    due_events = [e for e in events if e["event"].endswith("_due")]
    if due_events:
        print(f"\n  Pending cadence events ({len(due_events)}):")
        for e in due_events[-3:]:
            print(f"    • {e['event']} (at inv #{e['inv']})")

    next_events = []
    for name, threshold in CADENCE.items():
        next_inv = ((inv // threshold) + 1) * threshold
        next_events.append((next_inv, name))
    next_events.sort()
    print(f"\n  Next cadence events:")
    for next_inv, name in next_events[:3]:
        print(f"    • {name} at invocation #{next_inv} (in {next_inv - inv} uses)")

    return 2 if due_events else 0


def cmd_add_artifact(client: GistClient, skill_name: str, artifact_path: Path) -> int:
    state, gist_id, filename = _read_state(client, skill_name)

    artifact_data = json.loads(artifact_path.read_text())
    artifact_data.setdefault("stored_at", datetime.now(timezone.utc).isoformat())

    state.setdefault("session_artifacts", []).append(artifact_data)
    # Keep only the most recent 50 artifacts to avoid Gist size limits
    state["session_artifacts"] = state["session_artifacts"][-50:]

    _write_state(client, gist_id, filename, state)
    print(f"✓ Session artifact added for '{skill_name}'")
    print(f"  Total artifacts stored: {len(state['session_artifacts'])}")
    print(f"\nWhen you have 2+ artifacts, run: aggregate skill feedback")
    return 0


def cmd_add_patch(client: GistClient, skill_name: str, patch_description: str) -> int:
    state, gist_id, filename = _read_state(client, skill_name)

    patch_entry = {
        "at": datetime.now(timezone.utc).isoformat(),
        "description": patch_description,
        "inv_at_patch": state["cumulative_invocations"],
    }
    state.setdefault("patch_log", []).append(patch_entry)
    state["total_micro_patches_applied"] = state.get("total_micro_patches_applied", 0) + 1
    state["pending_patches"] = max(0, state.get("pending_patches", 0) - 1)

    _write_state(client, gist_id, filename, state)
    print(f"✓ Patch recorded for '{skill_name}': {patch_description}")
    print(f"  Total patches applied: {state['total_micro_patches_applied']}")
    return 0


def cmd_export_artifacts(client: GistClient, skill_name: str, out_dir: Path) -> int:
    state, _, _ = _read_state(client, skill_name)
    artifacts = state.get("session_artifacts", [])

    if not artifacts:
        print(f"No session artifacts stored for '{skill_name}'")
        return 0

    out_dir.mkdir(parents=True, exist_ok=True)
    for i, artifact in enumerate(artifacts):
        out_file = out_dir / f"{skill_name}-artifact-{i+1:03d}.json"
        out_file.write_text(json.dumps(artifact, indent=2))

    combined = out_dir / f"{skill_name}-artifacts-all.json"
    combined.write_text(json.dumps(artifacts, indent=2))

    print(f"✓ Exported {len(artifacts)} artifacts for '{skill_name}'")
    print(f"  Individual: {out_dir}/{skill_name}-artifact-*.json")
    print(f"  Combined  : {combined}")
    print(f"\nNext step: paste {combined} into AGGREGATE mode:")
    print(f"  aggregate skill feedback [{combined}]")
    return 0


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description="GitHub Gist UTE backend — zero-infrastructure episodic memory for skill-writer UTE L2"
    )
    sub = ap.add_subparsers(dest="command", required=True)

    p_init = sub.add_parser("init", help="Create a new UTE state Gist for a skill")
    p_init.add_argument("--skill", required=True)
    p_init.add_argument("--lean-score", type=int, default=0,
                        help="Current certified LEAN score (0–500)")

    p_record = sub.add_parser("record", help="Record one skill invocation")
    p_record.add_argument("--skill", required=True)

    p_status = sub.add_parser("status", help="Show current UTE state and pending events")
    p_status.add_argument("--skill", required=True)

    p_artifact = sub.add_parser("add-artifact", help="Store a COLLECT session artifact")
    p_artifact.add_argument("--skill", required=True)
    p_artifact.add_argument("--artifact", type=Path, required=True,
                            help="Path to session artifact JSON (output of COLLECT mode)")

    p_patch = sub.add_parser("add-patch", help="Record a micro-patch applied to the skill")
    p_patch.add_argument("--skill", required=True)
    p_patch.add_argument("--patch", required=True, help="One-line description of the patch")

    p_export = sub.add_parser("export-artifacts", help="Export all artifacts for AGGREGATE mode")
    p_export.add_argument("--skill", required=True)
    p_export.add_argument("--out", type=Path, default=Path("artifacts"),
                          help="Output directory (default: artifacts/)")

    args = ap.parse_args()

    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        print("✗ GITHUB_TOKEN not set.", file=sys.stderr)
        print("  Create a Personal Access Token at: https://github.com/settings/tokens", file=sys.stderr)
        print("  Required scope: gist", file=sys.stderr)
        print("  Then: export GITHUB_TOKEN=ghp_your_token", file=sys.stderr)
        return 1

    client = GistClient(token)

    try:
        if args.command == "init":
            return cmd_init(client, args.skill, args.lean_score)
        elif args.command == "record":
            return cmd_record(client, args.skill)
        elif args.command == "status":
            return cmd_status(client, args.skill)
        elif args.command == "add-artifact":
            return cmd_add_artifact(client, args.skill, args.artifact)
        elif args.command == "add-patch":
            return cmd_add_patch(client, args.skill, args.patch)
        elif args.command == "export-artifacts":
            return cmd_export_artifacts(client, args.skill, args.out)
    except RuntimeError as e:
        print(f"✗ {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"✗ Unexpected error: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
