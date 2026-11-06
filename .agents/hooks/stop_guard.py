#!/usr/bin/env python3
"""Report checks without starting tests, modifying files, or looping."""
from __future__ import annotations

import json
import subprocess

from hook_common import context, git, project_root, read_event
from project_check import version_issues


def main() -> int:
    read_event()
    root = project_root()
    notes = version_issues(root)
    try:
        if git(root, "status", "--porcelain", "--untracked-files=normal"):
            notes.append("Working tree has changes; preserve unrelated work and report task validation and Git sync status")
    except (OSError, subprocess.SubprocessError):
        notes.append("Git status unavailable")
    # A dirty tree can belong to the user; do not request a continuation to clean it.
    print(json.dumps(context("Stop", "; ".join(notes)) if notes else {}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
