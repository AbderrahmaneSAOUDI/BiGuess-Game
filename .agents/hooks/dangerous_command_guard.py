#!/usr/bin/env python3
"""BiGuess PreToolUse Guardrail.

Intercepts bash and terminal tool calls to prevent catastrophic system commands,
accidental source code/asset deletion, and dangerous git operations on main.
"""

from __future__ import annotations
import json
import re
import sys

DANGEROUS_PATTERNS = [
    # Catastrophic system commands
    (re.compile(r'\brm\s+-[rf]{1,2}\s+[/~]'), "Blocked root or home directory deletion"),
    (re.compile(r'\bgit\s+push\s+.*--force\b.*(main|master)'), "Blocked force push to primary branch"),
    (re.compile(r'\bgit\s+reset\s+--hard\b'), "Blocked destructive git reset --hard without user approval"),
    (re.compile(r'\b(mkfs|dd\s+if=)'), "Blocked low-level drive overwrite command"),
    (re.compile(r':\(\)\s*\{\s*:\|:&\s*\};:'), "Blocked fork bomb"),

    # BiGuess project invariants
    (re.compile(r'\brm\s+-[rf]{1,2}\s+(lib|assets|test|scripts)\b'), "Blocked deletion of project source code, assets, or tests"),
    (re.compile(r'\brm\s+(pubspec\.yaml|shorebird\.yaml|version\.json)\b'), "Blocked deletion of core project manifests"),
]

def deny(reason: str) -> None:
    output = {
        "decision": "deny",
        "reason": reason,
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason
        }
    }
    print(json.dumps(output))
    sys.exit(0)

def main() -> int:
    event = {}
    if not sys.stdin.isatty():
        try:
            event = json.load(sys.stdin)
        except Exception:
            event = {}

    tool_call = event.get("toolCall") or event.get("tool_call") or {}
    tool_name = tool_call.get("name", "")
    args = tool_call.get("args") or tool_call.get("arguments") or {}

    if tool_name in ("run_command", "execute_command", "terminal", "bash"):
        cmd = args.get("CommandLine") or args.get("command") or ""
        for pattern, reason in DANGEROUS_PATTERNS:
            if pattern.search(cmd):
                deny(reason)

    print(json.dumps({"decision": "allow"}))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
