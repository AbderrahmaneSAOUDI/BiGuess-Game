#!/usr/bin/env python3
"""BiGuess Project-Aware Version Incrementer.

Automatically increments the patch version upon substantive code or documentation edits,
and calculates the minor version as elapsed days since project inception (2025-05-27).
Synchronizes the version triad: pubspec.yaml, version.json, and app_constants.dart.
"""

from __future__ import annotations
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

BASE_DATE = datetime.date(2025, 5, 27)

def get_expected_minor() -> int:
    today = datetime.date.today()
    return max(0, (today - BASE_DATE).days)

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

    try:
        content = pubspec_path.read_text(encoding="utf-8")
        match = re.search(r'(version:\s*)(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?', content)
        if not match:
            return False, ""

        major = "1"
        old_patch = int(match.group(4))
        old_build = int(match.group(5) or "1")
        new_patch = old_patch + 1
        new_build = old_build + 1

        semver_str = f"{major}.{expected_minor}.{new_patch}"
        full_version = f"{semver_str}+{new_build}"

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

    root = Path.cwd()
    if git_has_substantive_changes(root):
        sync_triad(root)

    print(json.dumps({}))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
