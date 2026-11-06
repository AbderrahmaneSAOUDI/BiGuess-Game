#!/usr/bin/env python3
"""Catch obvious destructive shell operations; this is not a shell sandbox."""
from __future__ import annotations

import json
import re
import shlex
from pathlib import Path

from hook_common import project_root, read_event


def command_from_event(event: dict) -> str:
    call = event.get("toolCall") or event.get("tool_call") or {}
    if not isinstance(call, dict):
        call = {}
    args = event.get("tool_input") or call.get("args") or call.get("arguments") or {}
    if isinstance(args, str):
        try:
            args = json.loads(args)
        except ValueError:
            args = {}
    if not isinstance(args, dict):
        args = {}
    value = args.get("command") or args.get("cmd") or args.get("CommandLine") or event.get("command") or ""
    return value if isinstance(value, str) else ""


def dangerous_reason(command: str, root: Path, cwd: Path | None = None, depth: int = 0) -> str | None:
    if depth > 3:
        return None
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()\n")
        lexer.whitespace_split = True
        command_tokens = list(lexer)
        fork_bomb = [":", "()", "{", ":", "|", ":", "&", "}", ";", ":"]
        if any(command_tokens[index:index + len(fork_bomb)] == fork_bomb
               for index in range(len(command_tokens))):
            return "Blocked fork bomb"
        parts: list[list[str]] = [[]]
        for token in command_tokens:
            if token and all(c in ";&|()\n" for c in token):
                parts.append([])
            else:
                parts[-1].append(token)
    except ValueError:
        return None
    location = cwd or root
    protected = {root / name for name in ("lib", "assets", "test", "scripts", ".git")}
    manifests = {root / name for name in ("pubspec.yaml", "version.json", "shorebird.yaml")}
    for tokens in parts:
        while tokens and (tokens[0] in ("sudo", "env", "command", "exec") or re.match(r"^\w+=", tokens[0])):
            tokens = tokens[1:]
        if not tokens:
            continue
        name, args = Path(tokens[0]).name, tokens[1:]
        if name in ("bash", "sh", "zsh"):
            for index, arg in enumerate(args[:-1]):
                if arg.startswith("-") and "c" in arg:
                    reason = dangerous_reason(args[index + 1], root, location, depth + 1)
                    if reason:
                        return reason
        if name == "cd" and args:
            path = Path(args[0]).expanduser()
            location = (path if path.is_absolute() else location / path).resolve()
        if name == "git":
            if "reset" in args and any(arg == "--hard" or arg.startswith("--hard=") for arg in args):
                return "Blocked git reset --hard; it discards working changes"
            if "push" in args:
                forced = any(a in ("-f", "--force", "--force-with-lease") or a.startswith(("--force=", "--force-with-lease=", "+")) for a in args)
                refs = [a for a in args[args.index("push") + 1:] if not a.startswith("-")]
                primary = any(a.lstrip("+").split(":")[-1].split("/")[-1] in ("main", "master") for a in refs)
                if forced and (primary or len(refs) < 2):
                    return "Blocked force push to a primary or implicit branch"
        if name == "rm":
            for arg in args:
                if arg.startswith("-"):
                    continue
                if arg in ("/", "~", "$HOME", "${HOME}"):
                    return "Blocked deletion of root or home directory"
                path = Path(arg).expanduser()
                target = (path if path.is_absolute() else location / path).resolve()
                if target in protected | manifests or target in (root, Path.home()) or target in root.parents:
                    return "Blocked deletion of a project source directory or manifest"
        if name.startswith("mkfs") or (name == "dd" and any(a.startswith("of=/dev/") for a in args)):
            return "Blocked low-level drive overwrite command"
    return None


def main() -> int:
    event = read_event()
    root = project_root()
    cwd = event.get("cwd")
    command = command_from_event(event)
    reason = dangerous_reason(command, root, Path(cwd) if isinstance(cwd, str) else root)
    native = any(key in event for key in ("hook_event_name", "tool_name", "tool_input"))
    legacy = bool(command) and any(key in event for key in ("toolCall", "tool_call", "command"))
    if native:
        # Native hooks never override the host's ordinary permissions on allow.
        output = {"hookSpecificOutput": {
            "hookEventName": "PreToolUse", "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }} if reason else {}
    elif legacy:
        # Preserve the older direct-launch protocol used by existing hosts.
        output = {"decision": "deny", "reason": reason} if reason else {"decision": "allow"}
    else:
        output = {}
    print(json.dumps(output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
