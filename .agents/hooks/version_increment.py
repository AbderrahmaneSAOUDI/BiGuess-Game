#!/usr/bin/env python3
"""BiGuess Project-Aware Version Incrementer.

Automatically increments the patch version upon substantive code or documentation edits,
and calculates the minor version as elapsed days since project inception (2025-05-27).
Synchronizes the version triad: pubspec.yaml, version.json, and app_constants.dart.
Guarantees idempotence by using HEAD commit baseline.
"""

from __future__ import annotations
import datetime
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE_DATE = datetime.date(2025, 5, 27)

def get_project_root() -> Path:
    p = Path(__file__).resolve()
    for parent in p.parents:
        if (parent / ".git").exists() or (parent / "pubspec.yaml").exists():
            return parent
    return Path.cwd()

def get_expected_minor() -> int:
    today = datetime.date.today()
    return max(0, (today - BASE_DATE).days)

def get_head_version(root: Path) -> tuple[int, int, int, int]:
    try:
        res = subprocess.run(
            ["git", "-C", str(root), "show", "HEAD:pubspec.yaml"],
            capture_output=True,
            text=True,
            check=False
        )
        if res.returncode == 0:
            m = re.search(r'version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?', res.stdout)
            if m:
                return int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4) or 1)
    except Exception:
        pass
    return 1, 0, 0, 1

def git_has_substantive_changes(root: Path) -> bool:
    try:
        res = subprocess.run(
            ["git", "-C", str(root), "status", "--porcelain"],
            capture_output=True,
            text=True,
            check=False
        )
        lines = [line.strip() for line in res.stdout.strip().splitlines() if line.strip()]
        ignored = (
            "pubspec.yaml", "pubspec.lock", "version.json", "app_constants.dart",
            "package.json", "package-lock.json", "pnpm-lock.yaml", "Cargo.toml",
            "VERSION", "codebase_index.json", "codebase_summary.md", ".agents/cache",
            "indexer_daemon.log"
        )
        meaningful = [
            l for l in lines
            if not any(v in l for v in ignored)
        ]
        return len(meaningful) > 0
    except Exception:
        return False

def sync_triad(root: Path) -> tuple[bool, str]:
    pubspec_path = root / "pubspec.yaml"
    version_json_path = root / "version.json"
    constants_path = root / "lib" / "core" / "constants" / "app_constants.dart"

    if not pubspec_path.exists():
        return False, ""

    expected_minor = get_expected_minor()
    head_major, head_minor, head_patch, head_build = get_head_version(root)

    new_patch = head_patch + 1
    new_build = head_build + 1

    semver_str = f"1.{expected_minor}.{new_patch}"
    full_version = f"{semver_str}+{new_build}"

    try:
        content = pubspec_path.read_text(encoding="utf-8")
        current_m = re.search(r'version:\s*([^\s]+)', content)
        if current_m and current_m.group(1).strip() == full_version:
            # Already strictly in sync with expected target version
            return True, semver_str

        match = re.search(r'(version:\s*).+', content)
        if not match:
            return False, ""

        new_val = f"{match.group(1)}{full_version}"
        pubspec_path.write_text(content[:match.start()] + new_val + content[match.end():], encoding="utf-8")

        # Sync version.json
        if version_json_path.exists():
            try:
                vdata = json.loads(version_json_path.read_text(encoding="utf-8"))
            except Exception:
                vdata = {}
            vdata["latest_version"] = semver_str
            vdata["build_number"] = new_build
            version_json_path.write_text(json.dumps(vdata, indent=2) + "\n", encoding="utf-8")

        # Sync app_constants.dart
        if constants_path.exists():
            c_text = constants_path.read_text(encoding="utf-8")
            c_updated = re.sub(
                r"static const String defaultVersion = '[^']*';",
                f"static const String defaultVersion = '{semver_str}';",
                c_text
            )
            if c_updated != c_text:
                constants_path.write_text(c_updated, encoding="utf-8")

        # Sync VERSION if present
        version_txt = root / "VERSION"
        if version_txt.exists():
            version_txt.write_text(f"{semver_str}\n", encoding="utf-8")

        return True, semver_str
    except Exception as e:
        return False, str(e)

def main() -> int:
    event = {}
    if not sys.stdin.isatty():
        try:
            event = json.load(sys.stdin)
        except Exception:
            event = {}

    root = get_project_root()
    if git_has_substantive_changes(root):
        sync_triad(root)

    print(json.dumps({}))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
