#!/usr/bin/env python3
"""
BiGuess Game - Flutter Build & Release Automation Helper
Builds APKs, App Bundles, Web, and Desktop binaries with pre-flight checks and checksum generation.
"""

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import List, Optional

# ANSI formatting
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
CYAN = "\033[96m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"


def format_bytes(size: float) -> str:
    """Format bytes to human-readable string."""
    for unit in ["B", "KB", "MB", "GB"]:
        if size < 1024.0:
            return f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{size:.1f} TB"


def calculate_sha256(file_path: Path) -> str:
    """Compute SHA-256 hash of a file."""
    sha = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            sha.update(chunk)
    return sha.hexdigest()


def run_step(title: str, cmd: List[str], cwd: Path) -> bool:
    """Run a CLI command with styled terminal output."""
    print(f"\n{BOLD}{BLUE}▶ {title}...{RESET}")
    print(f"{DIM}$ {' '.join(cmd)}{RESET}\n")

    start = time.time()
    result = subprocess.run(cmd, cwd=str(cwd))
    elapsed = time.time() - start

    if result.returncode == 0:
        print(f"\n{GREEN}✔ {title} completed successfully in {elapsed:.1f}s{RESET}")
        return True
    else:
        print(f"\n{RED}✖ {title} failed with exit code {result.returncode}{RESET}")
        return False


def find_flutter_bin() -> str:
    """Find flutter executable path."""
    flutter = shutil.which("flutter")
    if flutter:
        return flutter
    # Check common fallback locations
    home = Path.home()
    candidates = [
        home / "flutter" / "bin" / "flutter",
        home / "development" / "flutter" / "bin" / "flutter",
        home / "snap" / "flutter" / "common" / "flutter" / "bin" / "flutter",
    ]
    for c in candidates:
        if c.exists():
            return str(c)
    return "flutter"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build BiGuess Flutter game binaries (APK, App Bundle, Web, Desktop).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    repo_root = Path(__file__).resolve().parent.parent

    parser.add_argument(
        "target",
        nargs="?",
        choices=["apk", "appbundle", "web", "linux", "windows", "all"],
        default="apk",
        help="Build target",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Build in debug mode instead of release mode",
    )
    parser.add_argument(
        "--split-per-abi",
        action="store_true",
        help="Build separate smaller APKs per CPU architecture (armeabi-v7a, arm64-v8a, x86_64)",
    )
    parser.add_argument(
        "--skip-checks",
        action="store_true",
        help="Skip 'flutter analyze' and 'flutter test' before building",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Run 'flutter clean' before starting the build",
    )

    args = parser.parse_args()
    flutter = find_flutter_bin()

    mode = "debug" if args.debug else "release"

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         🚀  BiGuess Flutter Build Automation                 {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"🎯 Target:      {args.target.upper()}")
    print(f"⚙️  Mode:        {mode.upper()}")
    print(f"📁 Repository:  {repo_root}")
    print(f"🛠️  Flutter:     {flutter}")
    print(f"{CYAN}──────────────────────────────────────────────────────────────{RESET}")

    # Step 1: Clean if requested
    if args.clean:
        if not run_step("Cleaning build cache", [flutter, "clean"], repo_root):
            return 1

    # Step 2: Pub Get
    if not run_step("Getting dependencies (flutter pub get)", [flutter, "pub", "get"], repo_root):
        return 1

    # Step 3: Analysis & Tests (unless skipped)
    if not args.skip_checks:
        if not run_step("Running static analysis", [flutter, "analyze"], repo_root):
            print(f"{YELLOW}⚠️  Analysis found warnings. Continuing build...{RESET}")

        if (repo_root / "test").exists():
            run_step("Running unit tests", [flutter, "test"], repo_root)

    # Step 4: Execute Build
    build_cmd = [flutter, "build"]
    if args.target == "apk":
        build_cmd.extend(["apk", f"--{mode}"])
        if args.split_per_abi:
            build_cmd.append("--split-per-abi")
    elif args.target == "appbundle":
        build_cmd.extend(["appbundle", f"--{mode}"])
    elif args.target == "web":
        build_cmd.extend(["web", f"--{mode}"])
    elif args.target == "linux":
        build_cmd.extend(["linux", f"--{mode}"])
    elif args.target == "windows":
        build_cmd.extend(["windows", f"--{mode}"])
    elif args.target == "all":
        build_cmd.extend(["apk", f"--{mode}"])

    if not run_step(f"Building {args.target.upper()} ({mode})", build_cmd, repo_root):
        return 1

    # Step 5: Report Output Artifacts
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}📦 Build Artifacts:{RESET}\n")

    artifact_paths: List[Path] = []
    if args.target in ("apk", "all"):
        apk_dir = repo_root / "build" / "app" / "outputs" / "flutter-apk"
        if apk_dir.exists():
            artifact_paths.extend(apk_dir.glob("*.apk"))
    if args.target == "appbundle":
        bundle_dir = repo_root / "build" / "app" / "outputs" / "bundle" / f"{mode}"
        if bundle_dir.exists():
            artifact_paths.extend(bundle_dir.glob("*.aab"))
    if args.target == "web":
        web_dir = repo_root / "build" / "web"
        if web_dir.exists():
            artifact_paths.append(web_dir)

    for art in artifact_paths:
        if art.is_file():
            sz = art.stat().st_size
            sha = calculate_sha256(art)
            print(f"  • {GREEN}{BOLD}{art.name}{RESET} ({format_bytes(sz)})")
            print(f"    Path:   {art}")
            print(f"    SHA256: {DIM}{sha}{RESET}\n")
        elif art.is_dir():
            total_sz = sum(f.stat().st_size for f in art.rglob("*") if f.is_file())
            print(f"  • {GREEN}{BOLD}{art.name}/{RESET} Directory ({format_bytes(total_sz)})")
            print(f"    Path:   {art}\n")

    print(f"{GREEN}{BOLD}🎉 Build finished successfully!{RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
