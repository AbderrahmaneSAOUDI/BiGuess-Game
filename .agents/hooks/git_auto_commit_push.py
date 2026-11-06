#!/usr/bin/env python3
"""Commit explicitly selected work and version fields using an isolated Git index."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from version_increment import TRIAD, apply_triad_plan, get_project_root, plan_triad, pubspec_version, rewrite_triad


def run(root: Path, *args: str, env: dict[str, str] | None = None, input: str | None = None) -> str:
    effective = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
    effective.pop("GIT_INDEX_FILE", None)
    if env:
        effective.update(env)
    effective["GIT_LITERAL_PATHSPECS"] = "1"
    return subprocess.run(["git", "-C", str(root), *args], input=input, env=effective,
                          capture_output=True, text=True, timeout=120, check=True).stdout


def checked_paths(root: Path, paths: list[str]) -> list[str]:
    result = []
    for name in paths:
        candidate = Path(name)
        if name.startswith(":") or ".." in candidate.parts:
            raise ValueError(f"Unsafe path: {name}")
        lexical = root / candidate
        if not lexical.is_relative_to(root):
            raise ValueError(f"Path outside repository: {name}")
        # Preserve the final name: Git stages a symlink itself, not its target.
        if lexical != root and not lexical.parent.resolve().is_relative_to(root):
            raise ValueError(f"Parent path escapes repository through a symlink: {name}")
        result.append(lexical.relative_to(root).as_posix())
    return result


def commit_selected(root: Path, summary: str, paths: list[str], *, all_paths: bool = False,
                    dry_run: bool = False, push: bool = True, today: dt.date | None = None) -> str:
    root = root.resolve()
    selected = ["."] if all_paths else checked_paths(root, paths)
    if not selected:
        raise ValueError("Explicit --paths or --all is required")
    branch = run(root, "symbolic-ref", "--quiet", "--short", "HEAD").strip()
    if not branch:
        raise ValueError("Cannot commit on detached HEAD")
    original_head = run(root, "rev-parse", "HEAD").strip()
    # Selected paths and the version fields must start unstaged. Other staged work is retained.
    staged = run(root, "diff", "--cached", "--name-only", "-z", "--", *selected, *TRIAD)
    if staged:
        raise ValueError("Selected paths or version files already have staged changes; preserve/reconcile them first")
    changed = run(root, "diff", "--name-only", "--no-renames", original_head, "-z", "--", *selected)
    untracked = run(root, "ls-files", "--others", "--exclude-standard", "-z", "--", *selected)
    if not changed and not untracked:
        semver = ".".join(map(str, pubspec_version((root / TRIAD[0]).read_text())[:3]))
        print(json.dumps({"dry_run": dry_run, "noop": True, "paths": selected,
                          "version": semver, "reason": "No task-owned changes"}))
        return semver
    sources = {name: (root / name).read_text(encoding="utf-8") for name in TRIAD}
    version, planned = plan_triad(root, today, baseline_ref=original_head)
    if run(root, "rev-parse", "HEAD").strip() != original_head:
        raise ValueError("HEAD changed while planning the commit; retry from the new baseline")
    if any((root / name).read_text(encoding="utf-8") != sources[name] for name in TRIAD):
        raise ValueError("Version files changed while planning the commit; retry")
    semver = ".".join(map(str, version[:3]))
    summary = re.sub(r"^\d+\.\d+\.\d+\s*[-:]\s*", "", summary.strip())
    if not summary or "\n" in summary:
        raise ValueError("Provide a single-line commit summary")
    message = f"{semver} - {summary}"
    if dry_run:
        print(json.dumps({"dry_run": True, "paths": selected, "version_fields": list(TRIAD),
                          "version": semver, "commit": message, "push": push}, indent=2))
        return semver
    original_triad = {name: run(root, "show", f"{original_head}:{name}") for name in TRIAD}
    version_blobs = rewrite_triad(original_triad, version)
    for name in TRIAD:
        if any(path == "." or name == path or name.startswith(path.rstrip("/") + "/")
               for path in selected):
            # Explicit task scope authorizes the whole file, including dependencies,
            # constants, or release metadata. Implicit trio entries get fields only.
            version_blobs[name] = planned[name]
    with tempfile.TemporaryDirectory(prefix="biguess-index-") as temporary:
        environment = {"GIT_INDEX_FILE": str(Path(temporary) / "index")}
        run(root, "read-tree", original_head, env=environment)
        run(root, "add", "-A", "--", *selected, env=environment)
        # Install either explicit task content or implicit version-only entries.
        for name in TRIAD:
            blob = run(root, "hash-object", "-w", "--stdin", input=version_blobs[name]).strip()
            mode = run(root, "ls-tree", original_head, "--", name).split()[0]
            run(root, "update-index", "--add", "--cacheinfo", f"{mode},{blob},{name}", env=environment)
        if run(root, "rev-parse", "HEAD").strip() != original_head:
            raise ValueError("HEAD changed while preparing the commit; retry from the new baseline")
        # Recheck selected staging immediately before mutation.
        if run(root, "diff", "--cached", "--name-only", "-z", "--", *selected, *TRIAD):
            raise ValueError("Selected staging changed while preparing the commit")
        # Sync worktree version fields only after all plans/index entries validate.
        apply_triad_plan(root, planned, sources)
        if run(root, "rev-parse", "HEAD").strip() != original_head:
            raise ValueError("HEAD changed before committing; version files were synchronized but no commit was made")
        output = run(root, "commit", "-m", message, env=environment)
        print(output.strip())
    # Adopt the new commit for selected entries only; unrelated staged blobs remain intact.
    run(root, "reset", "--quiet", "HEAD", "--", *selected, *TRIAD)
    if push:
        print(run(root, "push", "origin", branch).strip())
    return semver


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("summary", help="Conventional commit summary")
    scope = parser.add_mutually_exclusive_group(required=True)
    scope.add_argument("--paths", nargs="+", help="Task-owned files/directories, relative to repository root")
    scope.add_argument("--all", action="store_true", help="Explicitly include all worktree changes")
    parser.add_argument("--dry-run", action="store_true", help="Read-only plan; no writes, commits, or pushes")
    parser.add_argument("--no-push", action="store_true", help="Commit locally without pushing")
    parser.add_argument("--root", type=Path, default=get_project_root())
    parser.add_argument("--date", type=dt.date.fromisoformat, help="Override Africa/Algiers date for deterministic runs")
    args = parser.parse_args()
    try:
        commit_selected(args.root, args.summary, args.paths or [], all_paths=args.all,
                        dry_run=args.dry_run, push=not args.no_push, today=args.date)
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"Git synchronization failed: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            print(error.stderr, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
