#!/usr/bin/env python3
"""
BiGuess Game - Release Automation Pipeline
Build a universal Shorebird APK, upload release assets, then publish update metadata.
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.request
from pathlib import Path
from typing import Optional, Tuple
from zoneinfo import ZoneInfo

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
GITHUB_REPO = "BiGuess"
APK_NAMES = {"universal": "app-release.apk"}


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


def find_shorebird_bin() -> Optional[str]:
    """Find shorebird executable path."""
    sb = shutil.which("shorebird")
    if sb:
        return sb
    home = Path.home()
    candidate = home / ".shorebird" / "bin" / "shorebird"
    if candidate.exists():
        return str(candidate)
    return None


def check_android_release_signing() -> bool:
    """Fail before builds, metadata writes or publishing if signing is unavailable."""
    command = [str(REPO_ROOT / "android/gradlew"), "-p", str(REPO_ROOT / "android"),
               ":app:validateReleaseSigning", "-PrequireReleaseSigning=true", "--quiet"]
    print("Checking Android release-signing configuration...")
    try:
        result = run(command, capture=True, timeout=90)
    except (OSError, subprocess.TimeoutExpired):
        print(f"{RED}Could not run the signing check. Check Java and the Android SDK.{RESET}")
        return False
    if result.returncode:
        print(f"{RED}Android release signing is not ready. Release stopped before building.{RESET}")
        print("Configure android/key.properties from android/key.properties.example, or set:")
        print("  ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD,")
        print("  ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD")
        print("Use your existing release key for updates to previously signed APKs.")
        print("Details: docs/migration/RELEASE_SAFETY_AND_DISTRIBUTION.md")
        return False
    return True


def check_shorebird_builder(use_shorebird: bool) -> bool:
    """Require the requested OTA engine rather than silently changing builders."""
    if use_shorebird and not find_shorebird_bin():
        print(f"{RED}Shorebird CLI is required for the OTA-enabled release.{RESET}")
        print("Install Shorebird, or explicitly use --no-shorebird for a standard Flutter APK.")
        return False
    return True


def get_shorebird_active_releases(sb_bin: str) -> list[str]:
    """Query Shorebird for registered active releases."""
    res = run([sb_bin, "releases", "list"], capture=True)
    releases = []
    if res.returncode == 0:
        for line in res.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) >= 2:
                for p in parts:
                    if re.match(r"^\d+\.\d+\.\d+", p):
                        if p not in releases:
                            releases.append(p)
                        break
    return releases


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


BASE_DATE = datetime.date(2025, 5, 27)


def bump_version(current: str, bump_type: str) -> str:
    """Bump the version string by major, minor, or patch with date-based minor calculation."""
    major, minor, patch, build = parse_semver(current)
    today = datetime.datetime.now(ZoneInfo("Africa/Algiers")).date()
    expected_minor = max(0, (today - BASE_DATE).days)

    if bump_type == "major":
        major += 1
        minor = expected_minor
        patch = 0
    elif bump_type == "minor":
        minor = expected_minor
        patch = 0
    elif bump_type == "patch":
        minor = expected_minor
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


# Only Android native platform files require a full APK base release.
# Changes to web/, doc files, assets, or pure Dart are fully compatible with Shorebird OTA Patches.
NATIVE_DIRECTORIES = ("android/",)


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
            # Check diff ignoring whitespace and empty lines
            diff_cmd = ["git", "diff", f"{since_tag}..HEAD", "--", f_norm] if since_tag else ["git", "diff", "HEAD", "--", f_norm]
            diff_res = run(diff_cmd, capture=True)
            has_real_diff = False
            if diff_res.returncode == 0 and diff_res.stdout.strip():
                for diff_line in diff_res.stdout.splitlines():
                    if (diff_line.startswith("+") or diff_line.startswith("-")) and not diff_line.startswith("+++") and not diff_line.startswith("---"):
                        content = diff_line[1:].strip()
                        if content and not content.startswith("//") and not content.startswith("#"):
                            has_real_diff = True
                            break
            elif diff_res.returncode != 0:
                has_real_diff = True

            if has_real_diff:
                native_files.append(f_norm)
        elif f_norm == "pubspec.yaml":
            # Check diff in pubspec.yaml excluding version bump, comments, and shorebird asset
            diff_cmd = ["git", "diff", f"{since_tag}..HEAD", "--", "pubspec.yaml"] if since_tag else ["git", "diff", "HEAD", "--", "pubspec.yaml"]
            diff_res = run(diff_cmd, capture=True)
            if diff_res.returncode == 0:
                for diff_line in diff_res.stdout.splitlines():
                    if (diff_line.startswith("+") or diff_line.startswith("-")) and not diff_line.startswith("+++") and not diff_line.startswith("---"):
                        content = diff_line[1:].strip()
                        if not content or content.startswith("#"):
                            continue
                        if re.search(r"^version:\s*", content) or "shorebird.yaml" in content:
                            continue
                        native_files.append("pubspec.yaml (dependencies modified)")
                        break

    has_native = len(native_files) > 0
    return has_native, native_files


def sync_version_json(
    version: str,
    has_native_changes: Optional[bool] = None,
    release_notes: str = "",
    min_required_version: Optional[str] = None,
    apk_files: Optional[list[Path]] = None,
    base_apk_metadata: Optional[dict] = None,
) -> dict:
    """
    Generate version metadata and hashes for the selected universal artifact.
    OTA patches retain the already-published base artifact metadata.
    """
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

    # Build number MUST match the binary built from pubspec.yaml (single source of truth)
    build_number = build

    apk_base = f"https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/download/v{ver_part}"
    
    # One immutable universal artifact serves every supported device ABI.
    apk_urls = {kind: f"{apk_base}/{name}" for kind, name in APK_NAMES.items()}
    default_apk_url = apk_urls["universal"]

    payload = {
        "latest_version": ver_part,
        "build_number": build_number,
        "min_required_version": min_required_version,
        "has_native_changes": has_native_changes,
        "apk_urls": apk_urls,
        "apk_url": default_apk_url,
        "release_notes": release_notes,
    }

    if apk_files is not None:
        by_name = {path.name: path for path in apk_files}
        if (len(apk_files) != 1 or set(by_name) != set(APK_NAMES.values())
                or any(not path.is_file() or path.stat().st_size == 0 for path in apk_files)):
            raise ValueError("Exactly one nonempty app-release.apk is required")
        payload["sha256_hashes"] = {
            abi: calculate_sha256(by_name[name]) for abi, name in APK_NAMES.items()
        }
        payload["sha256"] = payload["sha256_hashes"]["universal"]
    elif (existing.get("latest_version") == ver_part and existing.get("build_number") == build
          and existing.get("apk_url") == default_apk_url and existing.get("apk_urls") == apk_urls):
        for key in ("sha256_hashes", "sha256"):
            if key in existing:
                payload[key] = existing[key]
    if base_apk_metadata is not None:
        if apk_files is not None:
            raise ValueError("A patch cannot replace its base APK")
        for key in ("apk_url", "apk_urls", "sha256", "sha256_hashes"):
            payload.pop(key, None)
            if key in base_apk_metadata:
                payload[key] = base_apk_metadata[key]
    VERSION_JSON.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"{GREEN}✅ version.json → v{ver_part}+{build_number} (has_native_changes: {has_native_changes}){RESET}")
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

def find_release_apks(built_after: Optional[float] = None) -> list[Path]:
    """Find the universal APK, rejecting empty or stale output from a partial build."""
    directories = [
        REPO_ROOT / "build/app/outputs/flutter-apk",
        REPO_ROOT / "build/app/outputs/apk/release",
        REPO_ROOT / "build/app/outputs/apk",
    ]
    selected = []
    for name in APK_NAMES.values():
        candidates = [directory / name for directory in directories]
        artifact = next((path for path in candidates if path.is_file()
                         and path.stat().st_size > 0
                         and (built_after is None or path.stat().st_mtime >= built_after - 1)), None)
        if artifact is None:
            print(f"Missing or stale release artifact: {name}. A fresh universal APK is required.")
            return []
        selected.append(artifact)
    return selected


def build_apks(
    skip_checks: bool = False,
    clean: bool = False,
    use_shorebird: bool = True,
    dry_run: bool = False,
    verbose: bool = False,
) -> list[Path]:
    """Build one universal release APK via Shorebird or explicit standard Flutter."""
    sb_bin = find_shorebird_bin() if use_shorebird else None
    if use_shorebird and not sb_bin:
        print("Shorebird was requested but is unavailable. No build was started.")
        return []
    builder_label = "Shorebird Engine" if sb_bin else "Standard Flutter"
    print(f"\n{BOLD}{BLUE}▶ Building one universal release APK via {builder_label}...{RESET}")

    if clean and run(["flutter", "clean"]).returncode != 0:
        return []

    if run(["flutter", "pub", "get"]).returncode != 0:
        return []

    if not skip_checks:
        for command in (["flutter", "analyze"], ["flutter", "test"]):
            result = run(command)
            if result.returncode != 0:
                print(f"{RED}Validation failed. Release build stopped.{RESET}")
                return []

    if sb_bin:
        # Build and register base release with Shorebird
        cmd = [sb_bin, "release", "android", "--artifact", "apk"]
        if dry_run:
            cmd.append("--dry-run")
        if verbose:
            cmd.append("--verbose")
    else:
        cmd = ["flutter", "build", "apk", "--release"]
        if verbose:
            cmd.append("--verbose")

    start = time.time()
    result = run(cmd)
    elapsed = time.time() - start

    if result.returncode != 0:
        print(f"{RED}❌ APK build failed after {elapsed:.1f}s{RESET}")
        return []

    apk_files = find_release_apks(built_after=start)

    if not apk_files:
        print(f"{RED}❌ Could not find built APKs in outputs directory{RESET}")
        return []

    total_size = sum(f.stat().st_size for f in apk_files)
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{GREEN}✅ {len(apk_files)} APK(s) built in {elapsed:.1f}s (Total: {format_bytes(total_size)}):{RESET}")
    for apk_file in sorted(apk_files):
        size = apk_file.stat().st_size
        sha = calculate_sha256(apk_file)
        print(f"   📦 {BOLD}{apk_file.name}{RESET} ({format_bytes(size)} / {size:,} bytes)")
        print(f"      🔑 SHA256: {DIM}{sha}{RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    return apk_files


# =============================================================================
# GitHub Release
# =============================================================================

def check_gh_cli() -> bool:
    """Check if the GitHub CLI (gh) is installed and authenticated, or GITHUB_TOKEN exists."""
    if not shutil.which("gh"):
        print("GitHub CLI is not installed. Install gh before publishing a release.")
        return False
    if os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN"):
        return True
    result = run(["gh", "auth", "status"], capture=True)
    if result.returncode != 0:
        print(f"{YELLOW}⚠️  GitHub CLI not authenticated. Run: {BOLD}gh auth login{RESET}")
        print(f"{DIM}   (Or set GITHUB_TOKEN or GH_TOKEN environment variable){RESET}")
        return False
    return True


def create_github_release(
    version: str,
    apk_paths: list[Path],
    release_notes: str,
    draft: bool = False,
    prerelease: bool = False,
) -> bool:
    """Create a GitHub release and upload all APK binaries with live progress and byte metrics."""
    tag = f"v{version.split('+')[0]}"
    total_bytes = sum(p.stat().st_size for p in apk_paths if p.exists())

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{BLUE}▶ Uploading {len(apk_paths)} Asset(s) to GitHub Release {tag}{RESET}")
    print(f"   📊 Total Batch Size: {format_bytes(total_bytes)} ({total_bytes:,} bytes)")
    print(f"   🔗 Target Repo:       {GITHUB_USER}/{GITHUB_REPO}")
    print(f"{CYAN}──────────────────────────────────────────────────────────────{RESET}")
    for p in sorted(apk_paths):
        if p.exists():
            sz = p.stat().st_size
            sha = calculate_sha256(p)
            print(f"   • {GREEN}{BOLD}{p.name}{RESET} ({format_bytes(sz)} / {sz:,} bytes)")
            print(f"     🔑 SHA256: {DIM}{sha}{RESET}")
    print(f"{CYAN}──────────────────────────────────────────────────────────────{RESET}\n")

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

    # Run without capturing so gh's live progress bar (showing %, speed, bytes) streams to terminal
    result = run(cmd, capture=False)

    if result.returncode != 0:
        print("GitHub release creation or upload failed. Existing release assets were not overwritten.")
        return False

    print(f"\n{GREEN}✅ GitHub Release {tag} published with {len(apk_paths)} APK(s) attached ({format_bytes(total_bytes)}){RESET}")
    print(f"   🔗 https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/tag/{tag}")
    return True


# =============================================================================
# Git Operations
# =============================================================================

def git_commit_and_push(version: str, files: list[str], push_branch: bool = True) -> bool:
    """Stage, commit, and push release files."""
    tag = f"v{version.split('+')[0]}"

    print(f"\n{BOLD}{BLUE}▶ Committing release files...{RESET}")

    if run(["git", "diff", "--cached", "--quiet"]).returncode != 0:
        print(f"{RED}Commit stopped: existing staged changes must be handled separately.{RESET}")
        return False
    for f in files:
        if run(["git", "add", "--", f]).returncode != 0:
            return False

    result = run(["git", "commit", "-m", f"release: {tag}"])
    if result.returncode != 0:
        print(f"{RED}Release commit failed. Tagging and push stopped.{RESET}")
        return False

    # Tag the commit
    if run(["git", "tag", "-a", tag, "-m", f"Release {tag}"]).returncode != 0:
        return False

    # Push
    print(f"\n{BOLD}{BLUE}▶ Pushing to remote...{RESET}")
    command = (["git", "push", "--follow-tags"] if push_branch
               else ["git", "push", "origin", f"refs/tags/{tag}"])
    result = run(command)

    if result.returncode != 0:
        print(f"{RED}❌ Git push failed{RESET}")
        return False

    print(f"{GREEN}Pushed {'branch and tag' if push_branch else 'tag only'} {tag}{RESET}")
    return True


def ensure_committed_app_source() -> bool:
    """A release tag must describe every source file used to build its binaries."""
    paths = ["lib", "assets", "android", "ios", "linux", "macos", "windows", "web",
             "pubspec.yaml", "pubspec.lock", "pubspec_overrides.yaml", "shorebird.yaml",
             ":(exclude)pubspec.yaml", ":(exclude)lib/core/constants/app_constants.dart",
             ":(exclude)shorebird.yaml"]
    changed = []
    for command in (
        ["git", "diff", "--name-only", "-z", "HEAD", "--", *paths],
        ["git", "ls-files", "--others", "--exclude-standard", "-z", "--", *paths],
    ):
        result = run(command, capture=True)
        if result.returncode != 0:
            print("Release stopped: Git could not verify the app source.")
            return False
        changed.extend(path for path in result.stdout.split("\0") if path)
    if changed:
        print("Release stopped: commit app source changes before building so the tag matches the binary.")
        for path in sorted(set(changed)):
            print(f"  {path!r}")
        return False
    return True


def ensure_draft_branch() -> bool:
    """Keep draft metadata commits away from the branch serving active updates."""
    result = run(["git", "symbolic-ref", "--quiet", "--short", "HEAD"], capture=True)
    branch = result.stdout.strip() if result.returncode == 0 else ""
    if not branch or branch in ("main", "master"):
        print("Drafts and prereleases require a separate named release-preparation branch.")
        print("Create or switch to that branch before publishing; main/master must keep the active manifest.")
        return False
    return True


# =============================================================================
# Main Pipeline
# =============================================================================

def pipeline_preview(args: argparse.Namespace, mode: Optional[str] = None) -> int:
    """Describe an operation without writing files or invoking pipeline commands."""
    if mode is None:
        mode = ("patch" if args.patch else "full release" if args.full_release
                else "version sync" if args.version_only else "automatic release")
    if mode == "automatic release" and getattr(args, "no_shorebird", False):
        mode = "full release"
    current = read_pubspec_version()
    version = args.set_version or (bump_version(current, args.bump) if args.bump else current)
    print("Release plan only: no commands will run and no files will change.")
    print(f"Mode: {mode}")
    print(f"Current version: {current}")
    print(f"Requested version: {version}")
    if mode == "automatic release":
        print("Execution chooses a patch or base release from native changes and available tooling.")
    print("Validation during execution: flutter analyze and flutter test"
          if not args.skip_checks else "Validation during execution: skipped by request")
    if mode == "patch":
        print("Artifact: retain the universal base APK URL and checksum; no new APK.")
    elif getattr(args, "no_shorebird", False):
        print("Artifact: one universal app-release.apk without Shorebird OTA.")
    else:
        print("Artifact: one universal app-release.apk with Shorebird OTA.")
    print("Build, upload, version writes, Git commit, tag, and push are all skipped.")
    return 0


def pipeline_full_release(args: argparse.Namespace) -> int:
    """Run the full release pipeline."""
    if getattr(args, "dry_run", False):
        return pipeline_preview(args, "full release")
    if args.skip_github and not args.skip_git and not (args.draft or args.prerelease):
        print("Active update metadata cannot be pushed without uploading its APKs. Use --skip-git for a local build.")
        return 1
    if not ensure_committed_app_source():
        return 1
    if (args.draft or args.prerelease) and not ensure_draft_branch():
        return 1
    if not args.skip_build and not check_android_release_signing():
        return 1
    if not args.skip_build and not check_shorebird_builder(not getattr(args, "no_shorebird", False)):
        return 1
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         🚀  BiGuess Full Release Pipeline                    {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    # Step 0: Pre-flight checks
    if not args.skip_github:
        if not check_gh_cli():
            return 1

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

    # Step 2: Initial sync version.json & app_constants.dart
    payload = sync_version_json(
        version,
        has_native_changes=args.native,
        release_notes=args.notes or "",
        min_required_version=args.min_version,
    )
    update_app_constants(version)

    # Step 3: Build APKs
    use_sb = not getattr(args, "no_shorebird", False)
    dry_run = getattr(args, "dry_run", False)
    if not args.skip_build:
        apk_paths = build_apks(
            skip_checks=args.skip_checks,
            clean=args.clean,
            use_shorebird=use_sb,
            dry_run=dry_run,
            verbose=getattr(args, "verbose", False),
        )
        if not apk_paths:
            return 1
    else:
        # Look for existing APKs
        apk_paths = find_release_apks()
        if not apk_paths:
            print("No universal app-release.apk found. Remove --skip-build to build it.")
            return 1
        print(f"{YELLOW}⏭️  Skipping build — using {len(apk_paths)} existing APK(s){RESET}")

    # Step 4: Resync version.json with actual built APK outputs
    payload = sync_version_json(
        version,
        has_native_changes=args.native,
        release_notes=args.notes or "",
        min_required_version=args.min_version,
        apk_files=apk_paths,
    )

    # Upload against the new tag, while main still serves the prior valid manifest.
    publish_manifest = not args.skip_git and not args.draft and not args.prerelease
    if not args.skip_git:
        files_to_commit = ["pubspec.yaml", "version.json", "lib/core/constants/app_constants.dart"]
        if (REPO_ROOT / "shorebird.yaml").exists():
            files_to_commit.append("shorebird.yaml")
        if not git_commit_and_push(version, files_to_commit, push_branch=False):
            return 1
    else:
        print("Skipping Git commit and tag preparation.")

    # Step 6: GitHub Release
    if not args.skip_github:
        notes = payload.get("release_notes", "Bug fixes and improvements.")
        if not create_github_release(
            version, apk_paths, notes,
            draft=args.draft, prerelease=args.prerelease,
        ):
            return 1
    else:
        print(f"{YELLOW}⏭️  Skipping GitHub release{RESET}")

    if publish_manifest and run(["git", "push"]).returncode != 0:
        print("APK upload succeeded, but publishing the update manifest failed. Retry the branch push.")
        return 1

    # Done!
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{GREEN}{BOLD}🎉 Release v{ver_part} complete!{RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")
    return 0


def read_patch_apk_metadata(version: str) -> dict:
    """A patch uses the immutable universal APK already published for its base."""
    try:
        manifest = json.loads(VERSION_JSON.read_text())
        base_version = version.split("+", 1)[0]
        expected = f"https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/download/v{base_version}/app-release.apk"
        hashes = manifest.get("sha256_hashes", {})
        digest = hashes.get("universal") if isinstance(hashes, dict) else None
        if (manifest.get("apk_url") != expected
                or manifest.get("apk_urls") != {"universal": expected}
                or not isinstance(digest, str) or not re.fullmatch(r"[0-9a-fA-F]{64}", digest)
                or manifest.get("sha256") != digest):
            raise ValueError("Missing matching universal base APK metadata")
    except (OSError, ValueError, TypeError, AttributeError) as error:
        raise ValueError("Publish the matching universal Shorebird base release before creating an OTA patch.") from error
    return {key: manifest[key] for key in ("apk_url", "apk_urls", "sha256", "sha256_hashes")}


def pipeline_patch_release(args: argparse.Namespace) -> int:
    """Publish a Shorebird OTA patch (pure Dart/UI/assets update without APK reinstall)."""
    if getattr(args, "dry_run", False):
        return pipeline_preview(args, "patch")
    if not ensure_committed_app_source():
        return 1
    if not check_android_release_signing():
        return 1
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         🚀  BiGuess Shorebird OTA Patch Pipeline             {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    sb_bin = find_shorebird_bin()
    if not sb_bin:
        print(f"{RED}❌ Shorebird CLI not found. Please install Shorebird or run 'shorebird init'.{RESET}")
        return 1

    current = read_pubspec_version()
    ver_part = current.split("+")[0]
    print(f"📋 Current release version: {BOLD}{current}{RESET}")

    # Check Shorebird active releases
    active_releases = get_shorebird_active_releases(sb_bin)
    target_version = current
    if active_releases and current not in active_releases:
        latest_active = active_releases[0]
        print(f"\n{YELLOW}⚠️  Note: Version '{current}' is not an active base release on Shorebird.{RESET}")
        print(f"   Registered active base release is: {BOLD}{latest_active}{RESET}")
        print(f"   {GREEN}🎯 Auto-targeting active release {BOLD}{latest_active}{RESET} for this OTA patch.{RESET}\n")
        target_version = latest_active
        current = target_version
        ver_part = current.split("+")[0]

    # Check for native changes
    has_native, changed_files = detect_native_changes()
    if has_native and not getattr(args, "allow_native_diffs", False):
        print(f"{YELLOW}⚠️  Warning: Native changes detected in {len(changed_files)} file(s):{RESET}")
        for f in changed_files[:5]:
            print(f"   • {f}")
        print(f"{RED}❌ Shorebird OTA patches cannot contain native code changes.{RESET}")
        print(f"   To publish native changes, create a Full Base Release instead (Option 3 in menu).")
        print(f"   (Or pass --allow-native-diffs to override if you are sure).")
        return 1

    try:
        base_apk_metadata = read_patch_apk_metadata(target_version)
    except ValueError as error:
        print(f"{RED}{error}{RESET}")
        return 1

    if not args.skip_checks:
        for command in (["flutter", "analyze"], ["flutter", "test"]):
            result = run(command)
            if result.returncode != 0:
                print(f"{RED}Validation failed. Patch stopped.{RESET}")
                return 1

    # Step 1: Run Shorebird patch
    print(f"\n{BOLD}{BLUE}▶ Creating Shorebird OTA Patch for Android (Release: {target_version})...{RESET}")
    cmd = [sb_bin, "patch", "android", f"--release-version={target_version}"]
    if getattr(args, "dry_run", False):
        cmd.append("--dry-run")
    if getattr(args, "allow_native_diffs", False):
        cmd.append("--allow-native-diffs")
    if getattr(args, "verbose", False):
        cmd.append("--verbose")

    version_paths = [PUBSPEC, REPO_ROOT / "lib/core/constants/app_constants.dart"]
    originals = {path: path.read_bytes() for path in version_paths if path.exists()}
    if read_pubspec_version() != target_version:
        write_pubspec_version(target_version)
        update_app_constants(target_version)
    start = time.time()
    try:
        result = run(cmd)
    except BaseException:
        for path, data in originals.items():
            path.write_bytes(data)
        raise
    elapsed = time.time() - start

    if result.returncode != 0:
        for path, data in originals.items():
            path.write_bytes(data)
        print(f"{RED}❌ Shorebird patch failed after {elapsed:.1f}s{RESET}")
        return 1

    print(f"\n{GREEN}✅ Shorebird patch created & published to Shorebird CDN in {elapsed:.1f}s!{RESET}")

    # Step 2: Sync version.json with has_native_changes = False
    print(f"\n{BOLD}{BLUE}▶ Updating version.json (has_native_changes: false)...{RESET}")
    notes = args.notes or f"OTA Patch for v{ver_part}"
    sync_version_json(
        current,
        has_native_changes=False,
        release_notes=notes,
        min_required_version=args.min_version,
        base_apk_metadata=base_apk_metadata,
    )

    # Step 3: Git commit & push version.json if requested
    if not args.skip_git:
        print(f"\n{BOLD}{BLUE}▶ Committing synchronized version files...{RESET}")
        if run(["git", "diff", "--cached", "--quiet"]).returncode != 0:
            print(f"{RED}Commit stopped: existing staged changes must be handled separately.{RESET}")
            return 1
        for f in ("pubspec.yaml", "version.json", "lib/core/constants/app_constants.dart"):
            if run(["git", "add", "--", f]).returncode != 0:
                return 1
        if run(["git", "commit", "-m", f"patch: shorebird OTA update for v{current}"]).returncode != 0:
            return 1
        print(f"\n{BOLD}{BLUE}▶ Pushing version.json to remote...{RESET}")
        res = run(["git", "push"])
        if res.returncode == 0:
            print(f"{GREEN}✅ Pushed version.json to GitHub{RESET}")
        else:
            print(f"{RED}Git push failed. The patch is published; its metadata remains in a local commit.{RESET}")
            return 1
    else:
        print(f"{YELLOW}⏭️  Skipping git commit/push{RESET}")

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{GREEN}{BOLD}🎉 Shorebird OTA Patch for v{ver_part} published!{RESET}")
    print(f"{CYAN}📱 Active players will receive this update instantly on their next launch!{RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")
    return 0


def pipeline_auto_release(args: argparse.Namespace) -> int:
    """
    Intelligently auto-select between Shorebird OTA Patch and Full Base Release:
    - If native code changed or native dependencies modified or major/minor bump -> Full Base Release
    - If pure Dart/UI/assets changed and no major/minor bump -> Instant Shorebird OTA Patch
    """
    if getattr(args, "dry_run", False):
        return pipeline_preview(args, "automatic release")
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         ⚡  BiGuess Smart Release Pipeline (Auto-Detect)     {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    if getattr(args, "no_shorebird", False):
        return pipeline_full_release(args)

    current = read_pubspec_version()
    print(f"📋 Current release version: {BOLD}{current}{RESET}")

    # Check if a major or minor bump is explicitly requested
    is_major_or_minor = args.bump in ("major", "minor")

    # If user explicitly passed --native or --no-native
    if args.native is not None:
        has_native = args.native
        changed_files = ["Manual override via --native flag"] if has_native else []
    else:
        has_native, changed_files = detect_native_changes()

    print(f"\n{BOLD}{BLUE}🔍 Analyzing changes since last release...{RESET}")
    if has_native:
        print(f"   {YELLOW}📦 Native platform changes detected ({len(changed_files)} file(s)):{RESET}")
        for f in changed_files[:5]:
            print(f"      • {f}")
        if len(changed_files) > 5:
            print(f"      ... and {len(changed_files) - 5} more")
        print(f"\n{BOLD}{MAGENTA}➡️  Auto-selected Mode: 📦 FULL BASE RELEASE (universal APK + GitHub Release){RESET}")
        print(f"{DIM}   Reason: Native platform code/dependencies were modified.{RESET}\n")
        return pipeline_full_release(args)

    elif is_major_or_minor:
        print(f"   {YELLOW}🏷️  Major/Minor version bump requested ({args.bump}){RESET}")
        print(f"\n{BOLD}{MAGENTA}➡️  Auto-selected Mode: 📦 FULL BASE RELEASE (universal APK + GitHub Release){RESET}")
        print(f"{DIM}   Reason: Major/Minor version transitions require a new base release.{RESET}\n")
        return pipeline_full_release(args)

    else:
        sb_bin = find_shorebird_bin()
        if sb_bin:
            print(f"   {GREEN}✨ Pure Dart/UI/asset changes detected (No native diffs){RESET}")
            print(f"\n{BOLD}{GREEN}➡️  Auto-selected Mode: 🚀 INSTANT SHOREBIRD OTA PATCH (Code Push){RESET}")
            print(f"{DIM}   Reason: No native changes; update will apply silently over the air without APK download.{RESET}\n")
            return pipeline_patch_release(args)
        else:
            print(f"   {YELLOW}⚠️  Pure Dart changes detected, but Shorebird CLI is not installed.{RESET}")
            print(f"\n{BOLD}{MAGENTA}➡️  Fallback Mode: 📦 FULL BASE RELEASE{RESET}\n")
            return pipeline_full_release(args)


def pipeline_doctor() -> int:
    """Run shorebird doctor for diagnostics."""
    sb_bin = find_shorebird_bin()
    if not sb_bin:
        print(f"{RED}❌ Shorebird CLI not found at ~/.shorebird/bin/shorebird{RESET}")
        return 1
    print(f"\n{BOLD}{BLUE}▶ Running Shorebird Doctor...{RESET}\n")
    res = run([sb_bin, "doctor"])
    return res.returncode


def pipeline_version_only(args: argparse.Namespace) -> int:
    """Just bump version and sync files — no build or release."""
    if getattr(args, "dry_run", False):
        return pipeline_preview(args, "version sync")
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


def pipeline_check_update() -> int:
    """Fetch remote version.json and diagnose update pipeline health."""
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         🔍  BiGuess Update Pipeline Diagnostics               {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    current_pubspec = read_pubspec_version()
    major, minor, patch, build = parse_semver(current_pubspec)
    ver_str = f"{major}.{minor}.{patch}"

    print(f"📦 Local pubspec.yaml:        {BOLD}v{ver_str}+{build}{RESET}")

    # Check version triad
    constants_file = REPO_ROOT / "lib" / "core" / "constants" / "app_constants.dart"
    if constants_file.exists():
        match = re.search(r"static const String defaultVersion = '([^']*)';", constants_file.read_text())
        const_ver = match.group(1) if match else "unknown"
        status = f"{GREEN}synced{RESET}" if const_ver == ver_str else f"{RED}MISMATCH ({const_ver}){RESET}"
        print(f"📄 lib/.../app_constants.dart: {BOLD}v{const_ver}{RESET} ({status})")

    if VERSION_JSON.exists():
        try:
            local_vj = json.loads(VERSION_JSON.read_text())
            local_vj_ver = f"{local_vj.get('latest_version')}+{local_vj.get('build_number')}"
            is_synced = local_vj.get('latest_version') == ver_str and local_vj.get('build_number') == build
            status = f"{GREEN}synced{RESET}" if is_synced else f"{YELLOW}differs ({local_vj_ver}){RESET}"
            print(f"📋 Local version.json:         {BOLD}v{local_vj_ver}{RESET} ({status})")
        except Exception as e:
            print(f"📋 Local version.json:         {RED}Error reading ({e}){RESET}")

    # Remote check
    remote_url = f"https://raw.githubusercontent.com/{GITHUB_USER}/{GITHUB_REPO}/main/version.json"
    print(f"\n{BOLD}{BLUE}▶ Querying Remote Update Manifest...{RESET}")
    print(f"   URL: {DIM}{remote_url}{RESET}")

    try:
        req = urllib.request.Request(remote_url, headers={"User-Agent": "BiGuess-Updater/1.0"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                remote_ver = data.get("latest_version", "0.0.0")
                remote_build = data.get("build_number", 0)
                native_changes = data.get("has_native_changes", False)
                min_req = data.get("min_required_version", "0.0.0")
                apk_urls = data.get("apk_urls", {})
                release_notes = data.get("release_notes", "")

                print(f"   {GREEN}✓ Fetched live version.json successfully!{RESET}")
                print(f"\n   🌐 Remote Latest Version:   {BOLD}v{remote_ver}+{remote_build}{RESET}")
                print(f"   🔒 Min Required Version:   {BOLD}v{min_req}{RESET}")
                print(f"   ⚙️  Has Native Changes:     {BOLD}{native_changes}{RESET}")
                print(f"   📝 Release Notes:           {DIM}{release_notes}{RESET}")
                print(f"   📦 APK targets:       {', '.join(apk_urls.keys()) if apk_urls else 'None'}")

                # Evaluation
                remote_major, remote_minor, remote_patch, remote_b = parse_semver(f"{remote_ver}+{remote_build}")
                local_tuple = (major, minor, patch, build)
                remote_tuple = (remote_major, remote_minor, remote_patch, remote_b)

                print(f"\n{BOLD}{CYAN}📊 Comparison & Status:{RESET}")
                if remote_tuple > local_tuple:
                    if native_changes or (remote_major, remote_minor) > (major, minor):
                        print(f"   {YELLOW}⚠️  Full APK update available for users (v{remote_ver}){RESET}")
                    else:
                        print(f"   {GREEN}⚡ Shorebird OTA patch update available for users (v{remote_ver}){RESET}")
                elif local_tuple > remote_tuple:
                    print(f"   {BLUE}🚀 Local version (v{ver_str}+{build}) is ahead of remote (v{remote_ver}+{remote_build}). Ready to release!{RESET}")
                else:
                    print(f"   {GREEN}✅ Local version exactly matches remote production manifest.{RESET}")

    except Exception as e:
        print(f"   {RED}❌ Failed to fetch remote version.json: {e}{RESET}")

    # Shorebird status
    sb_bin = find_shorebird_bin()
    if sb_bin:
        print(f"\n{BOLD}{BLUE}▶ Shorebird Code-Push Status:{RESET}")
        releases = get_shorebird_active_releases(sb_bin)
        if releases:
            print(f"   Active Base Releases: {', '.join(releases)}")
        else:
            print(f"   {DIM}No registered Shorebird releases found (or offline).{RESET}")

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="BiGuess Release Automation — Smart Shorebird Code-Push & Full Base Release.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
{BOLD}Examples:{RESET}
  python3 release.py                              # Auto-detects: Pure Dart → Shorebird Patch, Native → Full Release
  python3 release.py --notes "Updated animations" # Auto-detect with release notes
  python3 release.py --patch --notes "UI fix"     # Force Shorebird OTA Patch
  python3 release.py --full-release --bump patch  # Force Full Base Release
  python3 release.py --version-only --bump minor  # Just bump version
  python3 release.py --doctor                     # Diagnose Shorebird
  python3 release.py --check-update               # Verify remote version.json manifest
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
        "--patch", action="store_true",
        help="Force Shorebird OTA Patch (pure Dart/UI update without building APK)",
    )
    pipe_group.add_argument(
        "--full-release", "--release", action="store_true",
        help="Build a universal Shorebird base APK and create a GitHub release",
    )
    pipe_group.add_argument(
        "--version-only", action="store_true",
        help="Only bump version and sync files — skip build/git/release",
    )
    pipe_group.add_argument(
        "--doctor", action="store_true",
        help="Run Shorebird doctor to check tooling health",
    )
    pipe_group.add_argument(
        "--check", "--check-update", action="store_true",
        help="Verify remote version.json manifest & update pipeline status",
    )
    pipe_group.add_argument("--split-apk", "--split-per-abi", action="store_true", help="Unsupported for universal releases; use build_app.py for local split builds")
    pipe_group.add_argument("--no-shorebird", action="store_true", help="Build one standard Flutter universal APK without Shorebird OTA")
    pipe_group.add_argument("--dry-run", action="store_true", help="Preview the plan only; do not build, write files, upload, commit, tag, or push")
    pipe_group.add_argument("--allow-native-diffs", action="store_true", help="Force patch even if native diffs are detected")
    pipe_group.add_argument("--skip-build", action="store_true", help="Skip APK build (use existing)")
    pipe_group.add_argument("--skip-checks", action="store_true", help="Skip flutter analyze and flutter test")
    pipe_group.add_argument("--skip-git", action="store_true", help="Skip git commit/push/tag")
    pipe_group.add_argument("--skip-github", action="store_true", help="Skip GitHub release creation")
    pipe_group.add_argument("--clean", action="store_true", help="Run flutter clean before build")
    pipe_group.add_argument("--draft", action="store_true", help="Create GitHub release as draft")
    pipe_group.add_argument("--prerelease", action="store_true", help="Mark GitHub release as pre-release")
    pipe_group.add_argument("-v", "--verbose", action="store_true", help="Show detailed network transfer and upload logs")

    args = parser.parse_args()

    if args.split_apk:
        parser.error("Universal releases do not support --split-apk/--split-per-abi. Use scripts/build_app.py for local split builds.")
    if args.dry_run:
        return pipeline_preview(args)
    if getattr(args, "check", False):
        return pipeline_check_update()
    elif args.doctor:
        return pipeline_doctor()
    elif args.patch:
        return pipeline_patch_release(args)
    elif getattr(args, "full_release", False):
        return pipeline_full_release(args)
    elif args.version_only:
        return pipeline_version_only(args)
    else:
        return pipeline_auto_release(args)


if __name__ == "__main__":
    sys.exit(main())
