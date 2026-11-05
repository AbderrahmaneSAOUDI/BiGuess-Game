#!/usr/bin/env python3
"""BiGuess Stop Event Guard.

Fires when the agent execution loop terminates.
Verifies git status to ensure working tree changes are properly managed.
"""

from __future__ import annotations
import json
import subprocess
import sys
from pathlib import Path

def get_project_root() -> Path:
    p = Path(__file__).resolve()
    for parent in p.parents:
        if (parent / ".git").exists() or (parent / "pubspec.yaml").exists():
            return parent
    return Path.cwd()

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

    root = get_project_root()
    if not (root / ".git").exists():
        print(json.dumps({"decision": "allow"}))
        return 0

    uncommitted = has_uncommitted_changes(root)
    output = {
        "decision": "allow",
        "hookSpecificOutput": {
            "hookEventName": "Stop",
            "status": "synchronized" if not uncommitted else "uncommitted_changes_present"
        }
    }
    print(json.dumps(output))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
