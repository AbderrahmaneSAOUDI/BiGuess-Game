#!/usr/bin/env python3
"""Inject a small, read-only project snapshot at session start."""
from __future__ import annotations

import json
import subprocess

from hook_common import context, git, project_root, read_event
from project_check import version_issues


def get_info() -> str:
    root = project_root()
    try:
        branch = git(root, "branch", "--show-current") or "detached HEAD"
        commit = git(root, "rev-parse", "--short", "HEAD")
        status = git(root, "status", "--porcelain", "--untracked-files=normal")
        count = len(status.splitlines()) if status else 0
        snapshot = f"Branch: {branch} ({commit}); {count} pre-existing changed paths."
    except (OSError, subprocess.SubprocessError):
        snapshot = "Git snapshot unavailable."
    issues = version_issues(root)
    return (
        f"BiGuess: {snapshot} Preserve work outside the task. "
        "Read AGENTS.md and .agents/README.md; consult .agents/sidecars/file-map.md as needed. "
        "Current gameplay: GameRoundNotifier + SelectCharacterUseCase + bundled topicPackAssets. "
        "Check live source before treating blueprint features as implemented. "
        + ("Version triad: " + "; ".join(issues) if issues else "Version triad synchronized.")
    )


if __name__ == "__main__":
    read_event()
    print(json.dumps(context("SessionStart", get_info())))
