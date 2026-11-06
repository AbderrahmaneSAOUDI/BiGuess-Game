"""Shared, standard-library helpers for repository-local lifecycle hooks."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def project_root() -> Path:
    """Resolve the checkout from the script, including Git worktrees."""
    return Path(__file__).resolve().parents[2]


def read_event() -> dict:
    if sys.stdin.isatty():
        return {}
    try:
        line = sys.stdin.readline()
        if not line:
            return {}
        value = json.loads(line)
        return value if isinstance(value, dict) else {}
    except (ValueError, OSError):
        return {}


def git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True,
        text=True, timeout=10, check=True,
    )
    return result.stdout.strip()


def context(event: str, message: str) -> dict:
    return {"hookSpecificOutput": {
        "hookEventName": event, "additionalContext": message,
    }}
