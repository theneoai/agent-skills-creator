#!/usr/bin/env python3
"""
scripts/emit_spec_pure.py — Emit a spec-pure flavor of a skill file.

The agentskills.io v1.0 open standard requires only `name` + `description`.
skill-writer's native frontmatter carries ~20 additional fields for lifecycle,
routing, and evolution tracking. Strict spec validators on adopting platforms
may reject unknown top-level keys.

This script moves every skill-writer-private field under the `x-skill-writer:`
namespace, which spec §4.2 treats as pass-through without validation failure.

Input
-----
A skill file with skill-writer native frontmatter.

Output
------
Same file body + spec-pure frontmatter:
  Top-level: name, description, version, license, author, spec_version, tags
  Under x-skill-writer: description_i18n, skill_tier, triggers, interface,
                        extends, graph, use_to_evolve, generation_method,
                        validation_status, lifecycle_status, deprecated_at,
                        deprecation_reason, replacement_skill, type,
                        created, updated

Runtime-state fields (cumulative_invocations, last_ute_check, pending_patches,
total_micro_patches_applied) are ALSO stripped from use_to_evolve and written
to a sidecar file <skill>.state.json — they change every invocation and should
not live in version control.

Usage
-----
    python3 scripts/emit_spec_pure.py claude/skill-writer.md \\
        --out dist/skill-writer.spec.md \\
        --state-out dist/skill-writer.state.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError:
    yaml = None

# Spec v1.0 canonical top-level fields.
SPEC_TOP_LEVEL = {"name", "description", "version", "license",
                  "author", "spec_version", "tags"}

# Fields that are runtime state, not source — sidecar-only.
RUNTIME_STATE_KEYS = {
    "certified_lean_score", "last_ute_check", "pending_patches",
    "total_micro_patches_applied", "cumulative_invocations",
}


def split_frontmatter(text: str) -> tuple[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        raise ValueError("no YAML frontmatter found")
    return m.group(1), text[m.end():]


def emit_yaml(data: dict) -> str:
    if yaml is None:
        raise RuntimeError("PyYAML required: pip install pyyaml")
    return yaml.safe_dump(data, sort_keys=False, allow_unicode=True,
                          default_flow_style=False)


def migrate(fm: dict) -> tuple[dict, dict]:
    """Return (spec_pure_fm, runtime_state) tuple."""
    spec_pure: dict = {}
    extensions: dict = {}
    runtime: dict = {}

    for key, value in fm.items():
        if key in SPEC_TOP_LEVEL:
            spec_pure[key] = value
        elif key == "use_to_evolve" and isinstance(value, dict):
            # Split runtime state out.
            ute_clean = {}
            for k, v in value.items():
                if k in RUNTIME_STATE_KEYS:
                    runtime[k] = v
                else:
                    ute_clean[k] = v
            extensions[key] = ute_clean
        else:
            extensions[key] = value

    if extensions:
        spec_pure["x-skill-writer"] = extensions
    return spec_pure, runtime


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("skill", help="Input skill .md file")
    p.add_argument("--out", required=True, help="Spec-pure output path")
    p.add_argument("--state-out", default=None,
                   help="Runtime-state sidecar path (JSON)")
    args = p.parse_args()

    if yaml is None:
        print("ERROR: pip install pyyaml", file=sys.stderr)
        return 1

    path = Path(args.skill)
    text = path.read_text(encoding="utf-8")
    fm_raw, body = split_frontmatter(text)
    fm = yaml.safe_load(fm_raw) or {}

    spec_pure, runtime = migrate(fm)

    out_text = "---\n" + emit_yaml(spec_pure) + "---\n" + body
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).write_text(out_text, encoding="utf-8")
    print(f"wrote spec-pure → {args.out}")

    if args.state_out and runtime:
        Path(args.state_out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.state_out).write_text(
            json.dumps(runtime, indent=2, default=str), encoding="utf-8")
        print(f"wrote runtime state → {args.state_out}")

    # Summary: count top-level fields before vs after.
    print(f"  top-level fields: {len(fm)} → {len(spec_pure)} "
          f"(moved {len(spec_pure.get('x-skill-writer', {}))} to x-skill-writer)")
    print(f"  runtime state fields stripped: {len(runtime)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
