#!/usr/bin/env python3
"""
BiGuess Game - Release Automation Pipeline
Full end-to-end: version bump → version.json sync → build APK → GitHub Release → upload → commit & push.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional, Tuple

# ANSI formatting
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

SCRIPTS_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPTS_DIR.parent
PUBSPEC = REPO_ROOT / "pubspec.yaml"
VERSION_JSON = REPO_ROOT / "version.json"

# GitHub config
GITHUB_USER = "AbderrahmaneSAOUDI"
GITHUB_REPO = "BiGuess-Game"


# =============================================================================
# Helpers
# =============================================================================

def run(cmd: list[str], capture: bool = False, **kwargs) -> subprocess.CompletedProcess:
    """Run a command, printing it for visibility."""
    print(f"{DIM}$ {' '.join(cmd)}{RESET}")
    return subprocess.run(cmd, capture_output=capture, text=True, cwd=str(REPO_ROOT), **kwargs)


def calculate_sha256(file_path: Path) -> str:
    sha = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            sha.update(chunk)
    return sha.hexdigest()


def format_bytes(size: float) -> str:
    for unit in ["B", "KB", "MB", "GB"]:
        if size < 1024.0:
            return f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{size:.1f} TB"


# =============================================================================
# Version Management
# =============================================================================

def read_pubspec_version() -> str:
    """Read the version string from pubspec.yaml."""
    text = PUBSPEC.read_text()
    match = re.search(r"^version:\s*(.+)$", text, re.MULTILINE)
    if not match:
        print(f"{RED}❌ Could not find 'version:' in pubspec.yaml{RESET}")
        sys.exit(1)
    return match.group(1).strip()


def parse_semver(version: str) -> Tuple[int, int, int, int]:
    """Parse version string into (major, minor, patch, build_number)."""
    # Split version and build number: "1.2.3+15" → ("1.2.3", "15")
    parts = version.split("+")
    ver = parts[0]
    build = int(parts[1]) if len(parts) > 1 else 0
    segments = ver.split(".")
    return (
        int(segments[0]) if len(segments) > 0 else 0,
        int(segments[1]) if len(segments) > 1 else 0,
        int(segments[2]) if len(segments) > 2 else 0,
        build,
    )


def bump_version(current: str, bump_type: str) -> str:
    """Bump the version string by major, minor, or patch."""
    major, minor, patch, build = parse_semver(current)

    if bump_type == "major":
        major += 1
        minor = 0
        patch = 0
    elif bump_type == "minor":
        minor += 1
        patch = 0
    elif bump_type == "patch":
        patch += 1

    new_build = build + 1
    return f"{major}.{minor}.{patch}+{new_build}"


def write_pubspec_version(new_version: str) -> None:
    """Update the version in pubspec.yaml."""
    text = PUBSPEC.read_text()
    updated = re.sub(
        r"^version:\s*.+$",
        f"version: {new_version}",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    PUBSPEC.write_text(updated)
    print(f"{GREEN}✅ pubspec.yaml → version: {new_version}{RESET}")


NATIVE_DIRECTORIES = ("android/", "ios/", "linux/", "macos/", "windows/", "web/")


def get_latest_git_tag() -> Optional[str]:
    """Get the most recent git tag."""
    res = run(["git", "describe", "--tags", "--abbrev=0"], capture=True)
    if res.returncode == 0 and res.stdout.strip():
        return res.stdout.strip()
    return None


def detect_native_changes(since_tag: Optional[str] = None) -> Tuple[bool, list[str]]:
    """
    Automatically detect if any native platform files or dependencies changed
    since the last release tag (or HEAD).
    Returns (has_native_changes, list_of_changed_native_files).
    """
    if not since_tag:
        since_tag = get_latest_git_tag()

    changed_files: set[str] = set()

    if since_tag:
        res = run(["git", "diff", "--name-only", f"{since_tag}..HEAD"], capture=True)
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                if line.strip():
                    changed_files.add(line.strip())

    # Include uncommitted working tree changes
    res = run(["git", "status", "--porcelain"], capture=True)
    if res.returncode == 0:
        for line in res.stdout.splitlines():
            parts = line.strip().split(maxsplit=1)
            if len(parts) > 1:
                changed_files.add(parts[1].strip())

    native_files = []
    for f in sorted(changed_files):
        f_norm = f.strip().replace("\\", "/")
        if any(f_norm.startswith(prefix) for prefix in NATIVE_DIRECTORIES):
            native_files.append(f_norm)
        elif f_norm == "pubspec.yaml" and since_tag:
            diff_res = run(["git", "diff", f"{since_tag}..HEAD", "--", "pubspec.yaml"], capture=True)
            if diff_res.returncode == 0:
                for diff_line in diff_res.stdout.splitlines():
                    if (diff_line.startswith("+") or diff_line.startswith("-")) and not diff_line.startswith("+++") and not diff_line.startswith("---"):
                        if not re.search(r"^\s*version:\s*", diff_line):
                            native_files.append("pubspec.yaml (dependencies modified)")
                            break

    has_native = len(native_files) > 0
    return has_native, native_files


def sync_version_json(
    version: str,
    has_native_changes: Optional[bool] = None,
    release_notes: str = "",
    min_required_version: Optional[str] = None,
) -> dict:
    """Generate / update version.json from the given version string with Split-ABI URLs."""
    ver_part = version.split("+")[0]
    major, minor, patch, build = parse_semver(version)

    # Auto-detect native changes if not explicitly provided
    if has_native_changes is None:
        auto_detected, changed_files = detect_native_changes()
        has_native_changes = auto_detected
        if has_native_changes:
            files_preview = ", ".join(changed_files[:3]) + ("..." if len(changed_files) > 3 else "")
            print(f"{YELLOW}🔍 Auto-detected native changes ({len(changed_files)} files: {files_preview}) → has_native_changes: true{RESET}")
        else:
            print(f"{GREEN}🔍 Auto-detected pure Dart/assets update → has_native_changes: false (Shorebird OTA eligible){RESET}")

    # Read existing version.json for defaults
    existing = {}
    if VERSION_JSON.exists():
        try:
            existing = json.loads(VERSION_JSON.read_text())
        except Exception:
            pass

    # Determine min_required_version
    if not min_required_version:
        min_required_version = existing.get("min_required_version", ver_part)

    if not release_notes:
        release_notes = existing.get("release_notes", "Bug fixes and improvements.")

    # Auto-increment build number
    prev_build = existing.get("build_number", 0)
    build_number = max(build, prev_build + 1)

    apk_base = f"https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/latest/download"
    apk_urls = {
        "arm64-v8a": f"{apk_base}/app-arm64-v8a-release.apk",
        "armeabi-v7a": f"{apk_base}/app-armeabi-v7a-release.apk",
        "x86_64": f"{apk_base}/app-x86_64-release.apk",
        "universal": f"{apk_base}/app-release.apk",
    }
    # Default fallback url (arm64-v8a covers 95%+ of modern smartphones)
    default_apk_url = f"{apk_base}/app-arm64-v8a-release.apk"

    payload = {
        "latest_version": ver_part,
        "build_number": build_number,
        "min_required_version": min_required_version,
        "has_native_changes": has_native_changes,
        "apk_urls": apk_urls,
        "apk_url": default_apk_url,
        "release_notes": release_notes,
    }

    VERSION_JSON.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"{GREEN}✅ version.json → v{ver_part}+{build_number} (Split-ABI supported){RESET}")
    return payload


def update_app_constants(version: str) -> None:
    """Update the defaultVersion in app_constants.dart to match pubspec."""
    ver_part = version.split("+")[0]
    constants_file = REPO_ROOT / "lib" / "core" / "constants" / "app_constants.dart"
    if not constants_file.exists():
        return

    text = constants_file.read_text()
    updated = re.sub(
        r"static const String defaultVersion = '[^']*';",
        f"static const String defaultVersion = '{ver_part}';",
        text,
    )
    if updated != text:
        constants_file.write_text(updated)
        print(f"{GREEN}✅ app_constants.dart → defaultVersion: '{ver_part}'{RESET}")


# =============================================================================
# Build
# =============================================================================

def build_apks(
    split_per_abi: bool = True,
    skip_checks: bool = False,
    clean: bool = False,
) -> list[Path]:
    """Build release APKs (with split-per-abi by default) and return their paths."""
    mode_desc = "Split-per-ABI (arm64, armeabi, x86_64)" if split_per_abi else "Universal (Fat APK)"
    print(f"\n{BOLD}{BLUE}▶ Building Release APKs [{mode_desc}]...{RESET}")

    if clean:
        run(["flutter", "clean"])

    run(["flutter", "pub", "get"])

    if not skip_checks:
        result = run(["flutter", "analyze"], capture=True)
        if result.returncode != 0:
            print(f"{YELLOW}⚠️  Analysis warnings detected. Continuing...{RESET}")

    cmd = ["flutter", "build", "apk", "--release"]
    if split_per_abi:
        cmd.append("--split-per-abi")

    start = time.time()
    result = run(cmd)
    elapsed = time.time() - start

    if result.returncode != 0:
        print(f"{RED}❌ APK build failed after {elapsed:.1f}s{RESET}")
        return []

    # Find all generated output APKs
    apk_dir = REPO_ROOT / "build" / "app" / "outputs" / "flutter-apk"
    apk_files = [f for f in apk_dir.glob("*.apk") if "debug" not in f.name]

    if not apk_files:
        print(f"{RED}❌ Could not find built APKs in {apk_dir}{RESET}")
        return []

    print(f"\n{GREEN}✅ {len(apk_files)} APK(s) built in {elapsed:.1f}s:{RESET}")
    for apk_file in sorted(apk_files):
        size = apk_file.stat().st_size
        sha = calculate_sha256(apk_file)
        print(f"   📦 {BOLD}{apk_file.name}{RESET} ({format_bytes(size)})")
        print(f"      🔑 SHA256: {DIM}{sha}{RESET}")

    return apk_files


# =============================================================================
# GitHub Release
# =============================================================================

def check_gh_cli() -> bool:
    """Check if the GitHub CLI (gh) is installed and authenticated."""
    result = run(["gh", "auth", "status"], capture=True)
    if result.returncode != 0:
        print(f"{RED}❌ GitHub CLI not authenticated. Run: gh auth login{RESET}")
        return False
    return True


def create_github_release(
    version: str,
    apk_paths: list[Path],
    release_notes: str,
    draft: bool = False,
    prerelease: bool = False,
) -> bool:
    """Create a GitHub release and upload all APK binaries."""
    tag = f"v{version.split('+')[0]}"

    print(f"\n{BOLD}{BLUE}▶ Creating GitHub Release {tag} ({len(apk_paths)} assets)...{RESET}")

    cmd = [
        "gh", "release", "create", tag,
        *[str(p) for p in apk_paths],
        "--repo", f"{GITHUB_USER}/{GITHUB_REPO}",
        "--title", f"BiGuess {tag}",
        "--notes", release_notes,
    ]

    if draft:
        cmd.append("--draft")
    if prerelease:
        cmd.append("--prerelease")

    result = run(cmd, capture=True)

    if result.returncode != 0:
        stderr = result.stderr or ""
        if "already exists" in stderr:
            print(f"{YELLOW}⚠️  Release {tag} already exists. Uploading APKs to existing release...{RESET}")
            upload_cmd = [
                "gh", "release", "upload", tag,
                *[str(p) for p in apk_paths],
                "--repo", f"{GITHUB_USER}/{GITHUB_REPO}",
                "--clobber",
            ]
            upload_result = run(upload_cmd, capture=True)
            if upload_result.returncode != 0:
                print(f"{RED}❌ Failed to upload APKs: {upload_result.stderr}{RESET}")
                return False
        else:
            print(f"{RED}❌ Failed to create release: {stderr}{RESET}")
            return False

    print(f"{GREEN}✅ GitHub Release {tag} published with {len(apk_paths)} APK(s) attached{RESET}")
    print(f"   🔗 https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/tag/{tag}")
    return True


# =============================================================================
# Git Operations
# =============================================================================

def git_commit_and_push(version: str, files: list[str]) -> bool:
    """Stage, commit, and push release files."""
    tag = f"v{version.split('+')[0]}"

    print(f"\n{BOLD}{BLUE}▶ Committing release files...{RESET}")

    for f in files:
        run(["git", "add", f])

    result = run(["git", "commit", "-m", f"release: {tag}"])
    if result.returncode != 0:
        print(f"{YELLOW}⚠️  Nothing to commit (files may already be staged){RESET}")

    # Tag the commit
    run(["git", "tag", "-a", tag, "-m", f"Release {tag}"])

    # Push
    print(f"\n{BOLD}{BLUE}▶ Pushing to remote...{RESET}")
    result = run(["git", "push", "--follow-tags"])

    if result.returncode != 0:
        print(f"{RED}❌ Git push failed{RESET}")
        return False

    print(f"{GREEN}✅ Pushed commit + tag {tag}{RESET}")
    return True


# =============================================================================
# Main Pipeline
# =============================================================================

def pipeline_full_release(args: argparse.Namespace) -> int:
    """Run the full release pipeline."""
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         🚀  BiGuess Full Release Pipeline                    {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    # Step 1: Version
    current = read_pubspec_version()
    print(f"📋 Current version: {BOLD}{current}{RESET}")

    if args.set_version:
        new_version = args.set_version.strip()
        write_pubspec_version(new_version)
        version = new_version
    elif args.bump:
        new_version = bump_version(current, args.bump)
        write_pubspec_version(new_version)
        version = new_version
    else:
        version = current

    ver_part = version.split("+")[0]
    print(f"🎯 Release version: {BOLD}{ver_part}{RESET}\n")

    # Step 2: Sync version.json
    payload = sync_version_json(
        version,
        has_native_changes=args.native,
        release_notes=args.notes or "",
        min_required_version=args.min_version,
    )

    # Step 3: Sync app_constants.dart
    update_app_constants(version)

    # Step 4: Build APKs
    split_abi = not getattr(args, "universal", False)
    if not args.skip_build:
        apk_paths = build_apks(split_per_abi=split_abi, skip_checks=args.skip_checks, clean=args.clean)
        if not apk_paths:
            return 1
    else:
        # Look for existing APKs
        apk_dir = REPO_ROOT / "build" / "app" / "outputs" / "flutter-apk"
        apk_paths = [f for f in apk_dir.glob("*.apk") if "debug" not in f.name]
        if not apk_paths:
            print(f"{RED}❌ No existing APKs found in {apk_dir}. Remove --skip-build to build.{RESET}")
            return 1
        print(f"{YELLOW}⏭️  Skipping build — using {len(apk_paths)} existing APK(s){RESET}")

    # Step 5: Git commit & push
    if not args.skip_git:
        files_to_commit = ["pubspec.yaml", "version.json", "lib/core/constants/app_constants.dart"]
        if not git_commit_and_push(version, files_to_commit):
            return 1
    else:
        print(f"{YELLOW}⏭️  Skipping git commit/push{RESET}")

    # Step 6: GitHub Release
    if not args.skip_github:
        if not check_gh_cli():
            print(f"{YELLOW}⚠️  Skipping GitHub release (gh CLI not available){RESET}")
        else:
            notes = payload.get("release_notes", "Bug fixes and improvements.")
            if not create_github_release(
                version, apk_paths, notes,
                draft=args.draft, prerelease=args.prerelease,
            ):
                return 1
    else:
        print(f"{YELLOW}⏭️  Skipping GitHub release{RESET}")

    # Done!
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{GREEN}{BOLD}🎉 Release v{ver_part} complete!{RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")
    return 0


def pipeline_version_only(args: argparse.Namespace) -> int:
    """Just bump version and sync files — no build or release."""
    current = read_pubspec_version()
    print(f"📋 Current version: {BOLD}{current}{RESET}")

    if args.set_version:
        new_version = args.set_version.strip()
        write_pubspec_version(new_version)
        version = new_version
    elif args.bump:
        new_version = bump_version(current, args.bump)
        write_pubspec_version(new_version)
        version = new_version
    else:
        version = current

    sync_version_json(
        version,
        has_native_changes=args.native,
        release_notes=args.notes or "",
        min_required_version=args.min_version,
    )
    update_app_constants(version)
    print(f"\n{GREEN}✅ All version files synced to v{version.split('+')[0]}{RESET}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="BiGuess Release Automation — build, version, and publish.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
{BOLD}Examples:{RESET}
  python3 release.py --bump patch --notes "Bug fixes"
  python3 release.py --set-version "1.0.0+1" --notes "First official release"
  python3 release.py --bump minor --native --notes "New anime pack"
  python3 release.py --version-only --set-version "0.31.0"
  python3 release.py --skip-build --skip-github
""",
    )

    # Version controls
    ver_group = parser.add_argument_group("Version")
    ver_group.add_argument(
        "--bump", choices=["major", "minor", "patch"],
        help="Auto-bump version before releasing",
    )
    ver_group.add_argument(
        "--set-version", type=str, default=None,
        help="Explicitly set version (e.g. 1.0.0 or 1.0.0+5)",
    )
    ver_group.add_argument(
        "--native", action=argparse.BooleanOptionalAction, default=None,
        help="Explicitly mark or unmark native code changes (default: auto-detect from git diff)",
    )
    ver_group.add_argument(
        "--notes", type=str, default="",
        help="Release notes text",
    )
    ver_group.add_argument(
        "--min-version", type=str, default=None,
        help="Override min_required_version in version.json",
    )

    # Pipeline controls
    pipe_group = parser.add_argument_group("Pipeline")
    pipe_group.add_argument(
        "--version-only", action="store_true",
        help="Only bump version and sync files — skip build/git/release",
    )
    pipe_group.add_argument("--universal", action="store_true", help="Build single fat universal APK instead of Split-per-ABI")
    pipe_group.add_argument("--skip-build", action="store_true", help="Skip APK build (use existing)")
    pipe_group.add_argument("--skip-checks", action="store_true", help="Skip flutter analyze")
    pipe_group.add_argument("--skip-git", action="store_true", help="Skip git commit/push/tag")
    pipe_group.add_argument("--skip-github", action="store_true", help="Skip GitHub release creation")
    pipe_group.add_argument("--clean", action="store_true", help="Run flutter clean before build")
    pipe_group.add_argument("--draft", action="store_true", help="Create GitHub release as draft")
    pipe_group.add_argument("--prerelease", action="store_true", help="Mark GitHub release as pre-release")

    args = parser.parse_args()

    if args.version_only:
        return pipeline_version_only(args)
    else:
        return pipeline_full_release(args)


if __name__ == "__main__":
    sys.exit(main())
