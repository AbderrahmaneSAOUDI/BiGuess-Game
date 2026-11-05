#!/usr/bin/env python3
"""BiGuess Session Start Hook.

Injects branch, HEAD commit, current version triad, and elapsed days since project inception.
"""

from __future__ import annotations
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

BASE_DATE = datetime.date(2025, 5, 27)

def get_info() -> str:
    root = Path.cwd()
    branch = "unknown"
    commit = "unknown"
    try:
        branch = subprocess.check_output(["git", "branch", "--show-current"], stderr=subprocess.DEVNULL, text=True).strip()
        commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], stderr=subprocess.DEVNULL, text=True).strip()
    except Exception:
        pass

    version = "1.0.0"
    pubspec = root / "pubspec.yaml"
    if pubspec.exists():
        try:
            m = re.search(r"^version:\s*(.+)$", pubspec.read_text(encoding="utf-8"), re.MULTILINE)
            if m:
                version = m.group(1).strip()
        except Exception:
            pass

    today = datetime.date.today()
    days = max(0, (today - BASE_DATE).days)

    return f"Branch: {branch} ({commit}) | Version: {version} | Day: {days} (since 2025-05-27)"

if __name__ == "__main__":
    info = get_info()
    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": f"[BiGuess Environment] {info}"
        }
    }
    print(json.dumps(output))
