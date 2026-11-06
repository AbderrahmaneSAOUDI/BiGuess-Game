#!/usr/bin/env python3
"""Idempotent, validated synchronization of the BiGuess version triad."""
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
from zoneinfo import ZoneInfo

BASE_DATE = dt.date(2025, 5, 27)
TRIAD = ("pubspec.yaml", "version.json", "lib/core/constants/app_constants.dart")
PUBSPEC_RE = re.compile(r"^(version:[ \t]*)(\d+\.\d+\.\d+(?:\+\d+)?)([ \t]*(?:#.*)?)$", re.MULTILINE)
CONSTANT_RE = re.compile(r"(static\s+const\s+String\s+defaultVersion\s*=\s*['\"])(\d+\.\d+\.\d+)(['\"]\s*;)")


def get_project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def git(root: Path, *args: str) -> str:
    env = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
    return subprocess.run(["git", "-C", str(root), *args], check=True,
                          capture_output=True, text=True, timeout=20, env=env).stdout


def parse_version(value: str) -> tuple[int, int, int, int]:
    if not isinstance(value, str):
        raise ValueError(f"Invalid version: {value!r}")
    numeric = r"(0|[1-9]\d*)"
    match = re.fullmatch(rf"{numeric}\.{numeric}\.{numeric}(?:\+{numeric})?", value)
    if not match:
        raise ValueError(f"Invalid version: {value!r}")
    return tuple(int(part or 0) for part in match.groups())


def pubspec_version(text: str) -> tuple[int, int, int, int]:
    matches = list(PUBSPEC_RE.finditer(text))
    if len(matches) != 1:
        raise ValueError("pubspec.yaml must contain exactly one numeric version field")
    return parse_version(matches[0].group(2))


def get_head_version(root: Path) -> tuple[int, int, int, int]:
    return pubspec_version(git(root, "show", "HEAD:pubspec.yaml"))


def get_expected_minor(today: dt.date | None = None) -> int:
    today = today or dt.datetime.now(ZoneInfo("Africa/Algiers")).date()
    return max(0, (today - BASE_DATE).days)


def rewrite_triad(texts: dict[str, str], version: tuple[int, int, int, int]) -> dict[str, str]:
    """Validate all sources before returning replacements; retain all other text."""
    pubspec_version(texts[TRIAD[0]])
    data = json.loads(texts[TRIAD[1]])
    if not isinstance(data, dict):
        raise ValueError("version.json must be an object")
    parse_version(data.get("latest_version", ""))
    build = data.get("build_number")
    if not isinstance(build, int) or isinstance(build, bool) or build < 0:
        raise ValueError("version.json build_number must be a nonnegative integer")
    constants = list(CONSTANT_RE.finditer(texts[TRIAD[2]]))
    if len(constants) != 1:
        raise ValueError("app_constants.dart must contain exactly one defaultVersion")
    parse_version(constants[0].group(2))
    major, minor, patch, build = version
    semver = f"{major}.{minor}.{patch}"
    result = dict(texts)
    result[TRIAD[0]] = PUBSPEC_RE.sub(lambda m: f"{m[1]}{semver}+{build}{m[3]}", texts[TRIAD[0]])
    # Replace only top-level fields after validating JSON. Duplicate keys are refused.
    for field, value in (("latest_version", json.dumps(semver)), ("build_number", str(build))):
        pattern = re.compile(r'("' + field + r'"\s*:\s*)("[^"\\]*(?:\\.[^"\\]*)*"|\d+)')
        if len(list(pattern.finditer(result[TRIAD[1]]))) != 1:
            raise ValueError(f"version.json must contain exactly one {field} field")
        result[TRIAD[1]] = pattern.sub(lambda m: m[1] + value, result[TRIAD[1]])
    result[TRIAD[2]] = CONSTANT_RE.sub(lambda m: m[1] + semver + m[3], texts[TRIAD[2]])
    # Ensure the preserved JSON formatting still represents the requested values.
    updated_data = json.loads(result[TRIAD[1]])
    if updated_data["latest_version"] != semver or updated_data["build_number"] != build:
        raise ValueError("Could not safely replace version.json fields")
    return result


def plan_triad(root: Path, today: dt.date | None = None) -> tuple[tuple[int, int, int, int], dict[str, str]]:
    texts = {name: (root / name).read_text(encoding="utf-8") for name in TRIAD}
    current = pubspec_version(texts[TRIAD[0]])
    head = get_head_version(root)
    candidate = (head[0], max(head[1], get_expected_minor(today)), head[2] + 1)
    # Keep an explicitly prepared higher version/build; reruns remain HEAD+1.
    semantic = max(candidate, current[:3])
    target = (*semantic, max(head[3] + 1, current[3]))
    return target, rewrite_triad(texts, target)


def sync_triad(root: Path, today: dt.date | None = None) -> tuple[bool, str]:
    version, planned = plan_triad(root, today)
    pending: list[tuple[Path, Path]] = []
    try:
        # Validate and prepare every replacement before touching any source file.
        for name, content in planned.items():
            destination = root / name
            if destination.read_text(encoding="utf-8") == content:
                continue
            fd, temporary = tempfile.mkstemp(prefix=".version-", dir=destination.parent)
            temporary_path = Path(temporary)
            pending.append((temporary_path, destination))
            with os.fdopen(fd, "w", encoding="utf-8") as stream:
                stream.write(content)
            temporary_path.chmod(destination.stat().st_mode & 0o777)
        for temporary, destination in pending:
            temporary.replace(destination)
    finally:
        for temporary, _ in pending:
            temporary.unlink(missing_ok=True)
    return True, ".".join(map(str, version[:3]))


def git_has_substantive_changes(root: Path) -> bool:
    tracked = git(root, "diff", "--name-only", "--no-renames", "-z", "HEAD").split("\0")
    untracked = git(root, "ls-files", "--others", "--exclude-standard", "-z").split("\0")
    for name in set(tracked + untracked) - {""}:
        if name.startswith(".agents/cache/") or "__pycache__/" in name or name.endswith((".log", ".pyc")):
            continue
        if name not in TRIAD:
            return True
        # Ignore version-only edits, but detect dependency/metadata/code changes.
        work = {p: (root / p).read_text(encoding="utf-8") for p in TRIAD}
        original = {p: git(root, "show", f"HEAD:{p}") for p in TRIAD}
        sentinel = get_head_version(root)
        if rewrite_triad(work, sentinel)[name] != rewrite_triad(original, sentinel)[name]:
            return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=get_project_root())
    parser.add_argument("--date", type=dt.date.fromisoformat, help="Override the Africa/Algiers date (YYYY-MM-DD)")
    args = parser.parse_args()
    try:
        if git_has_substantive_changes(args.root):
            sync_triad(args.root, args.date)
        print("{}")
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"Version synchronization failed: {error}", file=sys.stderr)
        print("{}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
