#!/usr/bin/env python3
"""Read-only version check: CLI fails on drift; hook reports context."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from hook_common import context, project_root, read_event


def version_issues(root: Path) -> list[str]:
    try:
        pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
        matches = list(re.finditer(
            r"^version:[ \t]*(\d+\.\d+\.\d+)\+(\d+)[ \t]*(?:#.*)?$", pubspec, re.M,
        ))
        if len(matches) != 1:
            return ["pubspec.yaml needs exactly one numeric version and build number"]
        version, build = matches[0].groups()
        manifest = json.loads((root / "version.json").read_text(encoding="utf-8"))
        if not isinstance(manifest, dict):
            return ["version.json must be an object"]
        constants = (root / "lib/core/constants/app_constants.dart").read_text(encoding="utf-8")
        constants_matches = list(re.finditer(
            r"^[ \t]*static\s+const\s+String\s+defaultVersion\s*=\s*(['\"])([^'\"\r\n]+)\1\s*;",
            constants, re.M,
        ))
        issues = []
        if manifest.get("latest_version") != version:
            issues.append("version.json latest_version differs from pubspec.yaml")
        remote_build = manifest.get("build_number")
        if type(remote_build) is not int or remote_build < 0:
            issues.append("version.json build_number must be a nonnegative integer")
        elif remote_build != int(build):
            issues.append("version.json build_number differs from pubspec.yaml")
        if len(constants_matches) != 1 or constants_matches[0].group(2) != version:
            issues.append("AppConstants.defaultVersion differs from pubspec.yaml")
        return issues
    except (OSError, ValueError, AttributeError) as error:
        return [f"Cannot check version triad: {error}"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail on drift without editing files")
    args = parser.parse_args()
    if not args.check:
        read_event()
    issues = version_issues(project_root())
    if args.check:
        print(json.dumps({"ok": not issues, "issues": issues}))
        return int(bool(issues))
    print(json.dumps(context("PostToolUse", "; ".join(issues)) if issues else {}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
