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
import shutil
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
    use_shorebird: bool = True,
    dry_run: bool = False,
) -> list[Path]:
    """Build release APKs (with split-per-abi by default) via Shorebird or standard Flutter."""
    sb_bin = find_shorebird_bin() if use_shorebird else None
    builder_label = "Shorebird Engine" if sb_bin else "Standard Flutter"
    mode_desc = "Split-per-ABI (arm64, armeabi, x86_64)" if split_per_abi else "Universal (Fat APK)"
    print(f"\n{BOLD}{BLUE}▶ Building Release APKs via {builder_label} [{mode_desc}]...{RESET}")

    if clean:
        run(["flutter", "clean"])

    run(["flutter", "pub", "get"])

    if not skip_checks:
        result = run(["flutter", "analyze"], capture=True)
        if result.returncode != 0:
            print(f"{YELLOW}⚠️  Analysis warnings detected. Continuing...{RESET}")

    if sb_bin:
        # Build and register base release with Shorebird
        cmd = [sb_bin, "release", "android", "--artifact", "apk"]
        if dry_run:
            cmd.append("--dry-run")
        if split_per_abi:
            cmd.extend(["--", "--split-per-abi"])
    else:
        if use_shorebird:
            print(f"{YELLOW}⚠️  Shorebird CLI not found. Falling back to standard flutter build apk.{RESET}")
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
    use_sb = not getattr(args, "no_shorebird", False)
    dry_run = getattr(args, "dry_run", False)
    if not args.skip_build:
        apk_paths = build_apks(
            split_per_abi=split_abi,
            skip_checks=args.skip_checks,
            clean=args.clean,
            use_shorebird=use_sb,
            dry_run=dry_run,
        )
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
        if (REPO_ROOT / "shorebird.yaml").exists():
            files_to_commit.append("shorebird.yaml")
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


def pipeline_patch_release(args: argparse.Namespace) -> int:
    """Publish a Shorebird OTA patch (pure Dart/UI/assets update without APK reinstall)."""
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

    # Check for native changes
    has_native, changed_files = detect_native_changes()
    if has_native and not getattr(args, "allow_native_diffs", False):
        print(f"{YELLOW}⚠️  Warning: Native changes detected in {len(changed_files)} file(s):{RESET}")
        for f in changed_files[:5]:
            print(f"   • {f}")
        print(f"{RED}❌ Shorebird OTA patches cannot contain native code changes.{RESET}")
        print(f"   To publish native changes, create a Full Base Release instead (Option 1 in menu).")
        print(f"   (Or pass --allow-native-diffs to override if you are sure).")
        return 1

    if not args.skip_checks:
        print(f"\n{BOLD}{BLUE}▶ Running static analysis...{RESET}")
        result = run(["flutter", "analyze"], capture=True)
        if result.returncode != 0:
            print(f"{YELLOW}⚠️  Analysis warnings detected. Continuing...{RESET}")

    # Step 1: Run Shorebird patch
    print(f"\n{BOLD}{BLUE}▶ Creating Shorebird OTA Patch for Android...{RESET}")
    cmd = [sb_bin, "patch", "android", f"--release-version={current}"]
    if getattr(args, "dry_run", False):
        cmd.append("--dry-run")
    if getattr(args, "allow_native_diffs", False):
        cmd.append("--allow-native-diffs")

    start = time.time()
    result = run(cmd)
    elapsed = time.time() - start

    if result.returncode != 0:
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
    )

    # Step 3: Git commit & push version.json if requested
    if not args.skip_git:
        files_to_commit = ["version.json"]
        print(f"\n{BOLD}{BLUE}▶ Committing updated version.json to git...{RESET}")
        for f in files_to_commit:
            run(["git", "add", f])
        run(["git", "commit", "-m", f"patch: shorebird OTA update for v{current}"])
        print(f"\n{BOLD}{BLUE}▶ Pushing version.json to remote...{RESET}")
        run(["git", "push"])
        print(f"{GREEN}✅ Pushed version.json to GitHub{RESET}")
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
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         ⚡  BiGuess Smart Release Pipeline (Auto-Detect)     {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

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
        print(f"\n{BOLD}{MAGENTA}➡️  Auto-selected Mode: 📦 FULL BASE RELEASE (APKs + GitHub Release){RESET}")
        print(f"{DIM}   Reason: Native platform code/dependencies were modified.{RESET}\n")
        return pipeline_full_release(args)

    elif is_major_or_minor:
        print(f"   {YELLOW}🏷️  Major/Minor version bump requested ({args.bump}){RESET}")
        print(f"\n{BOLD}{MAGENTA}➡️  Auto-selected Mode: 📦 FULL BASE RELEASE (APKs + GitHub Release){RESET}")
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
        help="Force Full Base Release (always build Shorebird Split APKs and GitHub Release)",
    )
    pipe_group.add_argument(
        "--version-only", action="store_true",
        help="Only bump version and sync files — skip build/git/release",
    )
    pipe_group.add_argument(
        "--doctor", action="store_true",
        help="Run Shorebird doctor to check tooling health",
    )
    pipe_group.add_argument("--universal", action="store_true", help="Build single fat universal APK instead of Split-per-ABI")
    pipe_group.add_argument("--no-shorebird", action="store_true", help="Build with standard Flutter instead of Shorebird")
    pipe_group.add_argument("--dry-run", action="store_true", help="Validate build/patch without uploading to Shorebird")
    pipe_group.add_argument("--allow-native-diffs", action="store_true", help="Force patch even if native diffs are detected")
    pipe_group.add_argument("--skip-build", action="store_true", help="Skip APK build (use existing)")
    pipe_group.add_argument("--skip-checks", action="store_true", help="Skip flutter analyze")
    pipe_group.add_argument("--skip-git", action="store_true", help="Skip git commit/push/tag")
    pipe_group.add_argument("--skip-github", action="store_true", help="Skip GitHub release creation")
    pipe_group.add_argument("--clean", action="store_true", help="Run flutter clean before build")
    pipe_group.add_argument("--draft", action="store_true", help="Create GitHub release as draft")
    pipe_group.add_argument("--prerelease", action="store_true", help="Mark GitHub release as pre-release")

    args = parser.parse_args()

    if args.doctor:
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
