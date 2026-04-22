#!/usr/bin/env python3
"""Shared utilities for skill-writer scripts.

Imported by run_gepa_optimize.py, run_multi_eval.py, run_aggregate.py,
monitor_skill_drift.py. Eliminates the four copies of _call() / JSON
extraction / global MODEL mutation that were scattered across those files.
"""
from __future__ import annotations

import json
import os
import re
import sys
import time
from dataclasses import dataclass

try:
    import anthropic  # type: ignore
except ImportError:
    anthropic = None

DEFAULT_MODEL = "claude-sonnet-4-6"


@dataclass
class ApiClient:
    """Bundles an anthropic client with a model name.

    Passing this single object instead of (client, model) pairs eliminates the
    global MODEL anti-pattern: callers set the model once at construction time.
    """
    _client: object
    model: str = DEFAULT_MODEL

    def call(
        self,
        system: str,
        user: str,
        max_tokens: int = 1024,
        cache_system: bool = False,
    ) -> str:
        """Call Claude, retrying on transient overload / rate-limit errors."""
        system_param: object
        if cache_system:
            # Prompt caching: mark static system prompts so repeated calls in a
            # loop (e.g. EVAL_SYSTEM called once per variant) benefit from cache hits.
            system_param = [
                {"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}
            ]
        else:
            system_param = system

        for attempt in range(3):
            try:
                resp = self._client.messages.create(
                    model=self.model,
                    max_tokens=max_tokens,
                    system=system_param,
                    messages=[{"role": "user", "content": user}],
                )
                return resp.content[0].text.strip()
            except Exception as e:
                err_name = type(e).__name__
                transient = err_name in ("OverloadedError", "RateLimitError", "APIStatusError")
                if attempt == 2 or not transient:
                    raise
                wait = 2 ** attempt
                print(f"    ↺ {err_name}; retrying in {wait}s…", file=sys.stderr)
                time.sleep(wait)
        return ""  # unreachable


def build_api_client(
    model: str = DEFAULT_MODEL,
    dry_run: bool = False,
) -> "ApiClient | None":
    """Build an ApiClient from ANTHROPIC_API_KEY. Returns None on failure or dry-run."""
    if dry_run:
        return None
    if anthropic is None:
        print("✗ anthropic package not found. Install: pip install anthropic", file=sys.stderr)
        return None
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("✗ ANTHROPIC_API_KEY not set", file=sys.stderr)
        return None
    return ApiClient(_client=anthropic.Anthropic(api_key=api_key), model=model)


def extract_json(raw: str) -> dict | None:
    """Extract the first JSON object from an LLM response. Returns None on failure."""
    m = re.search(r"\{[\s\S]*\}", raw)
    if not m:
        return None
    try:
        return json.loads(m.group())
    except json.JSONDecodeError:
        return None


def extract_json_array(raw: str) -> list | None:
    """Extract the first JSON array from an LLM response. Returns None on failure."""
    m = re.search(r"\[[\s\S]*\]", raw)
    if not m:
        return None
    try:
        return json.loads(m.group())
    except json.JSONDecodeError:
        return None
