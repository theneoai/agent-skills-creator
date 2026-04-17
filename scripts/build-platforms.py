#!/usr/bin/env python3
"""
scripts/build-platforms.py — Generate all 8 platform files from the canonical source.

Eliminates the manual "edit 8 files in lockstep" burden identified in the v3.4 review.

Usage:
    make build-platforms                     # regenerate all outputs
    python3 scripts/build-platforms.py        # same
    python3 scripts/build-platforms.py --check
                                              # generate to temp + diff against
                                              # committed files; exit 1 if drift.
                                              # Intended for CI and pre-commit.
    python3 scripts/build-platforms.py --only cursor
                                              # generate a single platform

The manifest `platforms.yaml` declares the transforms. See that file for DSL docs.

Design choices:
  - Stdlib-only (no PyYAML) — keeps install surface small. We only read a
    narrow subset of YAML (mappings + block scalars).
  - Transforms are plain string ops (replace, prepend, append) — not templating.
    This mirrors how the platform files actually differ and keeps the generator
    auditable.
"""

from __future__ import annotations

import argparse
import difflib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "platforms.yaml"


# ── Minimal YAML parser (just enough for platforms.yaml) ─────────────────────

def _parse_manifest(text: str) -> dict:
    """Parse the narrow subset of YAML used by platforms.yaml.
    Supports: top-level scalar `key: value`, `platforms:` list of mappings,
    nested mappings, and `|` literal block scalars on `content:` keys.
    """
    lines = text.splitlines()
    out: dict = {"platforms": []}

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if not stripped or stripped.startswith("#"):
            i += 1
            continue

        if line == "canonical:" or line.startswith("canonical:"):
            m = re.match(r"^canonical:\s*(.*)$", line)
            if m:
                out["canonical"] = m.group(1).strip()
            i += 1
            continue

        if line.startswith("platforms:"):
            i += 1
            # Parse list of platform entries
            while i < len(lines):
                line = lines[i]
                if line.startswith("  - name:"):
                    entry, i = _parse_platform_entry(lines, i)
                    out["platforms"].append(entry)
                elif line.strip() == "" or line.strip().startswith("#"):
                    i += 1
                elif not line.startswith(" "):
                    # Back to top level
                    break
                else:
                    i += 1
            continue

        i += 1

    return out


def _parse_platform_entry(lines: list[str], start: int) -> tuple[dict, int]:
    """Parse one `  - name: X` entry and return (dict, next_index)."""
    entry: dict = {"transforms": []}
    i = start

    # First line: "  - name: X"
    m = re.match(r"^  - name:\s*(.*)$", lines[i])
    if m:
        entry["name"] = m.group(1).strip()
    i += 1

    while i < len(lines):
        line = lines[i]
        if not line.startswith("    ") and not line.startswith("      ") and line.strip():
            # Either next platform ("  - name:") or EOF
            break
        if line.strip() == "":
            i += 1
            continue

        # Top-level entry keys indented 4 spaces
        m = re.match(r"^    ([a-z_]+):\s*(.*)$", line)
        if m:
            k, v = m.group(1), m.group(2).strip()
            if k == "transforms":
                if v == "[]":
                    entry["transforms"] = []
                    i += 1
                    continue
                entry["transforms"] = []
                i += 1
                while i < len(lines) and (lines[i].startswith("      - op:") or
                                          lines[i].startswith("        ") or
                                          lines[i].strip() == ""):
                    if lines[i].startswith("      - op:"):
                        op, i = _parse_transform_op(lines, i)
                        entry["transforms"].append(op)
                    else:
                        i += 1
                continue
            else:
                entry[k] = v
                i += 1
                continue
        i += 1

    return entry, i


def _parse_transform_op(lines: list[str], start: int) -> tuple[dict, int]:
    """Parse one `      - op: X` transform entry."""
    op: dict = {}
    i = start
    m = re.match(r"^      - op:\s*(.*)$", lines[i])
    if m:
        op["op"] = m.group(1).strip()
    i += 1

    while i < len(lines):
        line = lines[i]
        # Continuation lines indented 8 spaces
        if line.startswith("        "):
            sub = line[8:]
            m = re.match(r"^([a-z_]+):\s*(.*)$", sub)
            if m:
                k, v = m.group(1), m.group(2).strip()
                if v == "|":
                    # Block scalar — collect following lines indented 10+
                    block: list[str] = []
                    i += 1
                    while i < len(lines) and (lines[i].startswith("          ") or
                                              lines[i].strip() == ""):
                        if lines[i].strip() == "":
                            block.append("")
                        else:
                            block.append(lines[i][10:])
                        i += 1
                    op[k] = "\n".join(block) + ("\n" if block and block[-1] != "" else "")
                    continue
                op[k] = v.strip('"').strip("'")
                i += 1
                continue
            i += 1
            continue
        break

    return op, i


# ── Transform engine ─────────────────────────────────────────────────────────

def apply_transforms(content: str, transforms: list[dict]) -> str:
    for t in transforms:
        op = t.get("op")
        if op == "prepend":
            content = t["content"] + content
        elif op == "replace":
            content = content.replace(t["find"], t["replace"])
        elif op == "footer_append":
            marker = t.get("marker", "end_of_file")
            payload = t["content"]
            if marker == "end_of_file":
                if not content.endswith("\n"):
                    content += "\n"
                content += payload
            else:
                # Regex marker — insert after the last matching line
                pattern = re.compile(marker, re.MULTILINE)
                matches = list(pattern.finditer(content))
                if matches:
                    # Insert at end of matched line
                    last = matches[-1]
                    line_end = content.find("\n", last.end())
                    if line_end < 0:
                        content += payload
                    else:
                        content = content[:line_end + 1] + payload + content[line_end + 1:]
                else:
                    if not content.endswith("\n"):
                        content += "\n"
                    content += payload
        elif op == "frontmatter_append":
            # Insert block at end of YAML frontmatter, after given key
            after_key = t.get("after_key")
            payload = t["content"]
            lines = content.splitlines(keepends=True)
            if not lines or lines[0].rstrip() != "---":
                continue
            fm_end_idx = None
            for idx in range(1, len(lines)):
                if lines[idx].rstrip() == "---":
                    fm_end_idx = idx
                    break
            if fm_end_idx is None:
                continue
            insert_idx = fm_end_idx
            if after_key:
                for idx in range(1, fm_end_idx):
                    if re.match(rf"^{re.escape(after_key)}\s*:", lines[idx]):
                        # Skip nested content of the key
                        j = idx + 1
                        while j < fm_end_idx and (lines[j].startswith(" ") or lines[j].startswith("\t")):
                            j += 1
                        insert_idx = j
                        break
            block = payload if payload.endswith("\n") else payload + "\n"
            content = "".join(lines[:insert_idx]) + block + "".join(lines[insert_idx:])
        else:
            raise ValueError(f"unknown transform op: {op!r}")
    return content


# ── Main ─────────────────────────────────────────────────────────────────────

def build_one(plat: dict, canonical_text: str) -> str:
    content = canonical_text
    if plat["transforms"]:
        content = apply_transforms(content, plat["transforms"])
    return content


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="Generate to memory and diff against committed files; exit 1 on drift (strict)")
    ap.add_argument("--check-warn", action="store_true",
                    help="Same as --check but exits 0 with a warning summary (migration mode)")
    ap.add_argument("--only", metavar="PLATFORM", default=None,
                    help="Generate only the named platform")
    args = ap.parse_args()
    if args.check_warn:
        args.check = True

    if not MANIFEST.exists():
        print(f"  ✗ manifest not found: {MANIFEST}", file=sys.stderr)
        return 1

    manifest = _parse_manifest(MANIFEST.read_text(encoding="utf-8"))
    canonical = ROOT / manifest["canonical"]
    canonical_text = canonical.read_text(encoding="utf-8")

    drift = 0
    built = 0
    for plat in manifest["platforms"]:
        if args.only and plat["name"] != args.only:
            continue
        output_path = ROOT / plat["output"]
        new_text = build_one(plat, canonical_text)

        if args.check:
            old_text = output_path.read_text(encoding="utf-8") if output_path.exists() else ""
            if new_text != old_text:
                drift += 1
                print(f"  ✗ {plat['name']}: would be regenerated ({plat['output']})",
                      file=sys.stderr)
                diff = list(difflib.unified_diff(
                    old_text.splitlines(keepends=True),
                    new_text.splitlines(keepends=True),
                    fromfile=f"{plat['output']} (committed)",
                    tofile=f"{plat['output']} (generated)",
                    n=2,
                ))
                for line in diff[:30]:
                    sys.stdout.write(line)
                if len(diff) > 30:
                    print(f"  ... ({len(diff)-30} more diff lines)")
            else:
                print(f"  ✓ {plat['name']}: in sync")
        else:
            if plat["name"] == "claude":
                # claude/ IS the canonical; skip (no-op)
                print(f"  · {plat['name']}: canonical (skipped)")
                continue
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(new_text, encoding="utf-8")
            print(f"  ✓ {plat['name']}: {plat['output']} ({len(new_text):,} bytes)")
            built += 1

    if args.check:
        if drift:
            level = "⚠" if args.check_warn else "✗"
            print(
                f"\n  {level} {drift} platform file(s) differ from canonical + manifest.",
                file=sys.stderr,
            )
            if args.check_warn:
                print(
                    "      (migration mode: platforms.yaml does not yet describe every "
                    "per-platform delta; this is expected during v3.5.0)",
                    file=sys.stderr,
                )
                return 0
            print(
                "      Populate platforms.yaml with the missing transforms "
                "or run: make build-platforms",
                file=sys.stderr,
            )
            return 1
        print("  ✓ all platform files in sync with canonical")
        return 0

    print(f"\n  ✓ built {built} platform file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
