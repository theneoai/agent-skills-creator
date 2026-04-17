#!/usr/bin/env python3
"""
mcp/server.py — Model Context Protocol server for skill-writer (v3.5.0 skeleton).

Status: SKELETON — wires up the MCP tool surface but delegates actual mode
        execution to the caller's LLM session via `request_llm_delegation`.
        This keeps skill-writer zero-build: the MCP server doesn't itself
        invoke an LLM; it hands structured prompts back to the MCP host.

Tools exposed (MCP convention):
  - skill_writer__lean            — LEAN fast-eval (returns prompt for host LLM)
  - skill_writer__evaluate        — full EVALUATE (host runs EVALUATE plan)
  - skill_writer__optimize        — OPTIMIZE loop invocation
  - skill_writer__check_spec      — run scripts/check-spec-compat.py locally
  - skill_writer__build_platforms — run scripts/build-platforms.py --check-warn
  - skill_writer__verify_sig      — run scripts/verify-signature.sh
  - skill_writer__list_skills     — list installed skills in ~/.claude/skills/

Requires (optional):
    pip install mcp            # official Anthropic MCP Python SDK
    # or the compatible "modelcontextprotocol" package

Run:
    python3 mcp/server.py              # stdio transport (default)
    python3 mcp/server.py --sse        # SSE transport for remote hosts

Integrates with:
  - Claude Desktop        (via claude_desktop_config.json)
  - Cursor                (via .cursor/mcp.json)
  - VS Code Copilot       (via mcp: block in settings.json)
  - Gemini CLI            (via gemini mcp add)
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


# ── Tool implementations (thin wrappers around existing scripts) ─────────────

def tool_check_spec(args: dict) -> dict:
    """Run scripts/check-spec-compat.py and return structured result."""
    files = args.get("files") or []
    cmd = [sys.executable, str(ROOT / "scripts" / "check-spec-compat.py")]
    if args.get("strict"):
        cmd.append("--strict")
    cmd.extend(files)
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return {
        "exit_code": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "pass": proc.returncode == 0,
    }


def tool_build_platforms(args: dict) -> dict:
    mode = args.get("mode", "check-warn")
    cmd = [sys.executable, str(ROOT / "scripts" / "build-platforms.py")]
    if mode == "check":
        cmd.append("--check")
    elif mode == "check-warn":
        cmd.append("--check-warn")
    # else: full build
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return {
        "exit_code": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "pass": proc.returncode == 0,
    }


def tool_verify_sig(args: dict) -> dict:
    files = args.get("files") or []
    if not files:
        return {"error": "no files provided"}
    cmd = ["bash", str(ROOT / "scripts" / "verify-signature.sh")]
    trust = args.get("trust_store")
    if trust:
        cmd.extend(["--trust-store", trust])
    cmd.extend(files)
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return {
        "exit_code": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "pass": proc.returncode == 0,
    }


def tool_list_skills(args: dict) -> dict:
    """Enumerate installed skill files in the user's Claude skill directory.
    Stateless helper useful for "what skills do I have?" queries.
    """
    root = Path(os.path.expanduser(args.get("root", "~/.claude/skills")))
    if not root.exists():
        return {"skills": [], "root": str(root), "note": "root does not exist"}
    skills = []
    for p in sorted(root.glob("*.md")):
        try:
            head = p.read_text(encoding="utf-8")[:1500]
        except OSError:
            continue
        name = _extract_frontmatter_value(head, "name") or p.stem
        version = _extract_frontmatter_value(head, "version") or "unknown"
        desc = _extract_frontmatter_value(head, "description") or ""
        skills.append({
            "path": str(p),
            "name": name,
            "version": version,
            "description": desc[:200],
        })
    return {"skills": skills, "root": str(root), "count": len(skills)}


def _extract_frontmatter_value(text: str, key: str) -> str | None:
    import re
    m = re.search(rf"^{re.escape(key)}:\s*(.*)$", text, re.MULTILINE)
    if m:
        return m.group(1).strip().strip('"').strip("'")
    return None


# ── LEAN / EVALUATE / OPTIMIZE: return plan, not execute ─────────────────────
# These tools return structured prompts that the MCP host's LLM can execute.
# Rationale: the MCP server must stay stateless + zero-build; the host already
# has an LLM session that can carry out the plan (e.g., Claude via Claude Desktop).

def tool_lean_plan(args: dict) -> dict:
    skill_path = args.get("skill_path")
    return {
        "mode": "lean",
        "plan": [
            "1. Read the skill file and its frontmatter",
            "2. Score dimensions D1–D7 per `eval/rubrics.md §10`",
            "3. Emit lean_score (out of 500) + PASS|UNCERTAIN|FAIL verdict",
            "4. If D8 graph block present, add up to +20 bonus",
        ],
        "skill_path": skill_path,
        "rubric_ref": "eval/rubrics.md §10",
        "target_budget_ms": 5000,
    }


def tool_evaluate_plan(args: dict) -> dict:
    skill_path = args.get("skill_path")
    clear = args.get("clear", False)
    return {
        "mode": "evaluate",
        "skill_path": skill_path,
        "phases": [
            {"phase": 1, "name": "Parse & Validate", "max_points": 100},
            {"phase": 2, "name": "Text Quality",      "max_points": 300},
            {"phase": 3, "name": "Runtime Testing",   "max_points": 400},
            {"phase": 4, "name": "Certification",     "max_points": 200},
        ] + ([
            {"phase": "D9",  "name": "Cost Efficiency",    "max_points": 50},
            {"phase": "D10", "name": "Latency Efficiency", "max_points": 50},
        ] if clear else []),
        "rubric_ref": "eval/rubrics.md",
        "target_budget_ms": 60000,
        "clear_enabled": clear,
    }


def tool_optimize_plan(args: dict) -> dict:
    skill_path = args.get("skill_path")
    strategy = args.get("strategy", "dimension-loop")
    if strategy == "gepa":
        return {
            "mode": "optimize",
            "skill_path": skill_path,
            "strategy": "gepa",
            "status": "ROADMAP v3.6.0 — skeleton at scripts/gepa-optimize.py",
            "fallback": "dimension-loop",
        }
    return {
        "mode": "optimize",
        "skill_path": skill_path,
        "strategy": "dimension-loop",
        "loop_ref": "optimize/strategies.md §2",
        "max_rounds": args.get("max_rounds", 20),
        "convergence_ref": "refs/convergence.md",
    }


# ── MCP server shim (attempts real SDK, falls back to stdio JSON-RPC) ────────

TOOL_TABLE = {
    "skill_writer__lean":            tool_lean_plan,
    "skill_writer__evaluate":        tool_evaluate_plan,
    "skill_writer__optimize":        tool_optimize_plan,
    "skill_writer__check_spec":      tool_check_spec,
    "skill_writer__build_platforms": tool_build_platforms,
    "skill_writer__verify_sig":      tool_verify_sig,
    "skill_writer__list_skills":     tool_list_skills,
}

TOOL_DESCRIPTIONS = {
    "skill_writer__lean": "Produce a LEAN fast-eval plan for a skill file (host LLM executes).",
    "skill_writer__evaluate": "Produce an EVALUATE 4-phase plan for a skill file (host LLM executes).",
    "skill_writer__optimize": "Produce an OPTIMIZE plan (dimension-loop or GEPA).",
    "skill_writer__check_spec": "Run scripts/check-spec-compat.py locally.",
    "skill_writer__build_platforms": "Run scripts/build-platforms.py in check mode.",
    "skill_writer__verify_sig": "Verify Ed25519 signatures on release artifacts.",
    "skill_writer__list_skills": "Enumerate installed skill files.",
}


def _try_real_mcp() -> bool:
    """Attempt to start via the official MCP Python SDK. Returns True on success."""
    try:
        from mcp.server import Server  # type: ignore
        from mcp.types import Tool  # type: ignore
    except ImportError:
        return False

    server = Server("skill-writer")

    @server.list_tools()
    async def list_tools():
        return [
            Tool(
                name=name,
                description=TOOL_DESCRIPTIONS.get(name, name),
                inputSchema={"type": "object", "additionalProperties": True},
            )
            for name in TOOL_TABLE
        ]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        fn = TOOL_TABLE.get(name)
        if fn is None:
            return [{"type": "text", "text": json.dumps({"error": f"unknown tool: {name}"})}]
        result = fn(arguments or {})
        return [{"type": "text", "text": json.dumps(result, indent=2)}]

    # Start stdio transport
    import asyncio
    from mcp.server.stdio import stdio_server  # type: ignore

    async def main():
        async with stdio_server() as (read_stream, write_stream):
            await server.run(read_stream, write_stream, server.create_initialization_options())

    asyncio.run(main())
    return True


def _fallback_stdio_loop() -> int:
    """Minimal JSON-RPC-ish stdio loop for when the MCP SDK isn't installed.
    Accepts line-delimited JSON {"method":"tools/call","params":{"name":..,"arguments":..}}
    and echoes back a line-delimited JSON result. Not a full MCP impl; good
    enough for smoke-testing the tool handlers without pip install mcp.
    """
    print(json.dumps({
        "event": "server.started",
        "tools": list(TOOL_TABLE),
        "note": "official MCP SDK not installed; using minimal stdio fallback",
    }), flush=True)

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError as e:
            print(json.dumps({"error": f"invalid JSON: {e}"}), flush=True)
            continue

        method = msg.get("method") or msg.get("tool")
        params = msg.get("params") or {}
        name = params.get("name") if isinstance(params, dict) else None
        if not name and method and method.startswith("skill_writer__"):
            name = method
            args = params if isinstance(params, dict) else {}
        else:
            args = params.get("arguments") if isinstance(params, dict) else {}

        fn = TOOL_TABLE.get(name or "")
        if fn is None:
            print(json.dumps({"error": f"unknown tool: {name}"}), flush=True)
            continue

        try:
            result = fn(args or {})
            print(json.dumps({"result": result}), flush=True)
        except Exception as e:
            print(json.dumps({"error": str(e)}), flush=True)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sse", action="store_true", help="Use SSE transport (requires SDK)")
    ap.add_argument("--selftest", action="store_true", help="Run the tool table smoke test")
    args = ap.parse_args()

    if args.selftest:
        print("  skill-writer MCP server — self-test")
        for name, fn in TOOL_TABLE.items():
            try:
                sample = {"skill_path": "examples/00-starter/skill.md"}
                out = fn(sample)
                ok = isinstance(out, dict)
                print(f"    {'✓' if ok else '✗'} {name}: {type(out).__name__}")
            except Exception as e:
                print(f"    ✗ {name}: {e}")
        return 0

    if _try_real_mcp():
        return 0
    return _fallback_stdio_loop()


if __name__ == "__main__":
    sys.exit(main())
