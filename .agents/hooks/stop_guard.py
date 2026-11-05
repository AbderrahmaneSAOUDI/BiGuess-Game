#!/usr/bin/env python3
"""BiGuess Stop Event Guard.

Fires when the agent execution loop terminates.
Verifies git status to ensure working tree changes are properly managed.
"""

from __future__ import annotations
import json
import os
import subprocess
import sys
from pathlib import Path

CURRENT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = CURRENT_DIR.parents[1]

def run_cmd(cmd: list[str], cwd: Path) -> tuple[int, str, str]:
    res = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, check=False)
    return res.returncode, res.stdout.strip(), res.stderr.strip()

def has_uncommitted_changes(root: Path) -> bool:
    code, out, _ = run_cmd(["git", "status", "--porcelain"], root)
    if code != 0 or not out:
        return False
    lines = [l.strip() for l in out.splitlines() if l.strip()]
    return len(lines) > 0

def main() -> int:
    payload = {}
    if not sys.stdin.isatty():
        try:
            payload = json.load(sys.stdin)
        except Exception:
            payload = {}

    root = PROJECT_ROOT
    if not (root / ".git").exists():
        print(json.dumps({"decision": "allow"}))
        return 0

    output = {
        "decision": "allow",
        "hookSpecificOutput": {
            "hookEventName": "Stop",
            "status": "synchronized" if not has_uncommitted_changes(root) else "uncommitted_changes_present"
        }
    }
    print(json.dumps(output))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
