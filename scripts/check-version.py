#!/usr/bin/env python3
"""
scripts/check-version.py — Verify version consistency across all platform skill files.

Usage:
    python3 scripts/check-version.py <expected-version>
    python3 scripts/check-version.py  # reads VERSION file automatically

Called by: make check-version, ci.yml
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PLATFORMS = ['claude', 'openclaw', 'opencode', 'cursor', 'gemini', 'openai', 'kimi', 'hermes']


def get_expected_version(argv):
    if len(argv) > 1:
        return argv[1].strip()
    version_file = os.path.join(ROOT, 'VERSION')
    if os.path.exists(version_file):
        return open(version_file).read().strip()
    print('  ✗ no VERSION argument and VERSION file not found', file=sys.stderr)
    sys.exit(1)


def main():
    expected = get_expected_version(sys.argv)
    errors = []

    for p in PLATFORMS:
        ext = 'mdc' if p == 'cursor' else 'md'
        skill_file = os.path.join(ROOT, p, f'skill-writer.{ext}')

        if not os.path.exists(skill_file):
            print(f'  ⚠ {p}/skill-writer.{ext}: missing (skipped)')
            continue

        content = open(skill_file).read()
        m = re.search(r'^version:\s+"?([^"\n]+)"?', content, re.MULTILINE)
        if not m:
            errors.append(f'{p}/skill-writer.{ext}: no version field found in YAML frontmatter')
        elif m.group(1).strip() != expected:
            errors.append(
                f'{p}/skill-writer.{ext}: version {m.group(1).strip()!r} != expected {expected!r}'
            )
        else:
            print(f'  ✓ {p}/skill-writer.{ext}: {m.group(1).strip()}')

    if errors:
        for e in errors:
            print(f'  ✗ {e}', file=sys.stderr)
        sys.exit(1)

    print(f'  ✓ all platform files report version {expected}')


if __name__ == '__main__':
    main()
