#!/usr/bin/env python3
"""Automated Git Commit & Push Assistant for BiGuess.

Stages all repository changes, ensures the patch version is incremented,
constructs a semantic commit message prefixed with the version, and pushes to remote.

Usage:
    python3 .agents/hooks/git_auto_commit_push.py "feat: description here"
    or:
    python3 .agents/hooks/git_auto_commit_push.py
"""

from __future__ import annotations
import json
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

def run_cmd(cmd: list[str], cwd: Path | None = None) -> tuple[int, str, str]:
    res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, check=False)
    return res.returncode, res.stdout.strip(), res.stderr.strip()

def get_current_version(root: Path) -> str:
    pubspec = root / "pubspec.yaml"
    if pubspec.exists():
        try:
            m = re.search(r"^version:\s*(\d+\.\d+\.\d+)", pubspec.read_text(encoding="utf-8"), re.MULTILINE)
            if m:
                return m.group(1).strip()
        except Exception:
            pass
    ver = root / "VERSION"
    if ver.exists():
        return ver.read_text(encoding="utf-8").strip()
    return "1.0.0"

def get_branch_name(root: Path) -> str:
    code, stdout, _ = run_cmd(["git", "branch", "--show-current"], cwd=root)
    return stdout if code == 0 and stdout else "main"

def auto_generate_message(root: Path) -> str:
    code, stdout, _ = run_cmd(["git", "status", "--porcelain"], cwd=root)
    if not stdout:
        return "chore: update project configuration"

    files = [l.strip()[3:] for l in stdout.splitlines() if l.strip()]
    if any(".agents/hooks" in f for f in files):
        return "feat(agents): update lifecycle hooks and automation"
    if any(".agents/sidecars" in f for f in files):
        return "feat(agents): update sidecar indexer and services"
    if any(".agents/rules" in f for f in files):
        return "docs(rules): refine workspace agent rules"
    if any(".agents/skills" in f for f in files):
        return "feat(skills): add and refine agent skills"
    if any("lib/presentation" in f for f in files):
        return "feat(ui): update screens and widget presentation"
    if any("lib/providers" in f for f in files):
        return "feat(state): update game and settings controllers"
    if any("lib/domain" in f for f in files):
        return "feat(domain): update game models and use cases"
    if any("lib/services" in f for f in files):
        return "feat(services): enhance ota and version services"
    if any("assets/" in f for f in files):
        return "feat(assets): update game character cards and assets"
    if any("test/" in f for f in files):
        return "test: update unit and widget test suite"
    if any("pubspec.yaml" in f for f in files):
        return "chore: update dependencies and configuration"
    return "feat: apply substantive project enhancements"

def get_project_root() -> Path:
    p = Path(__file__).resolve()
    for parent in p.parents:
        if (parent / ".git").exists() or (parent / "pubspec.yaml").exists():
            return parent
    return Path.cwd()

def main() -> int:
    root = get_project_root()

    code, stdout, _ = run_cmd(["git", "status", "--porcelain"], cwd=root)
    if not stdout:
        print("[git_auto_commit_push] Working tree clean. Nothing to commit.")
        return 0

    try:
        from version_increment import sync_triad, git_has_substantive_changes
        if git_has_substantive_changes(root):
            sync_triad(root)
    except Exception as e:
        print(f"[git_auto_commit_push] Warning: version increment check: {e}", file=sys.stderr)

    version = get_current_version(root)
    branch = get_branch_name(root)

    custom_msg = " ".join(sys.argv[1:]).strip() if len(sys.argv) > 1 else ""
    if not custom_msg:
        custom_msg = auto_generate_message(root)

    # Strip any redundant version prefix from the provided message
    cleaned_msg = re.sub(r'^\d+\.\d+\.\d+\s*[-:]\s*', '', custom_msg)
    final_commit_msg = f"{version} - {cleaned_msg}"

    print("[git_auto_commit_push] Staging changes...")
    code, _, err = run_cmd(["git", "add", "."], cwd=root)
    if code != 0:
        print(f"[git_auto_commit_push] Error staging: {err}", file=sys.stderr)
        return code

    print(f"[git_auto_commit_push] Committing: '{final_commit_msg}'...")
    code, out, err = run_cmd(["git", "commit", "-m", final_commit_msg], cwd=root)
    if code != 0:
        print(f"[git_auto_commit_push] Commit output: {out} {err}")
        return code

    print(f"[git_auto_commit_push] Pushing to origin/{branch}...")
    code, out, err = run_cmd(["git", "push", "origin", branch], cwd=root)
    if code != 0:
        print(f"[git_auto_commit_push] Push error: {err}", file=sys.stderr)
        return code

    print(f"[git_auto_commit_push] Successfully committed and pushed version {version}!")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
