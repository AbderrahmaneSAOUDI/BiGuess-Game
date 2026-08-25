#!/usr/bin/env python3
"""
BiGuess Game - Interactive Developer Toolbox Menu
Launches any game maintenance, image processing, manifest generation, or build task.
Supports [0], [Esc], 'q', or 'back' at any prompt to cancel or return to menu.
"""

import json as json_mod
import os
import re
import select
import subprocess
import sys
from pathlib import Path

# ANSI colors
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
PYTHON = sys.executable


# =============================================================================
# Navigation & Input Handling
# =============================================================================

class NavigationBack(Exception):
    """Raised when user wants to go back or cancel (via 0, ESC, q, back, cancel)."""
    pass


def clear_screen() -> None:
    """Clear terminal screen."""
    os.system("cls" if os.name == "nt" else "clear")


def print_banner() -> None:
    """Print BiGuess header banner."""
    print(f"{BOLD}{CYAN}╔══════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{CYAN}║                 🎮  BIGUESS GAME TOOLBOX                     ║{RESET}")
    print(f"{BOLD}{CYAN}║             Developer Utilities & Asset Automation           ║{RESET}")
    print(f"{BOLD}{CYAN}╚══════════════════════════════════════════════════════════════╝{RESET}\n")


def read_line_with_esc(prompt_text: str) -> str:
    """Read a line of text from stdin with full Escape key and backspace support."""
    if not sys.stdin.isatty():
        sys.stdout.write(prompt_text)
        sys.stdout.flush()
        line = sys.stdin.readline()
        if not line:
            raise NavigationBack()
        return line.strip("\r\n")

    if os.name == "nt":
        # Windows terminal
        import msvcrt
        sys.stdout.write(prompt_text)
        sys.stdout.flush()
        buffer = []
        while True:
            ch = msvcrt.getwch()
            if ch in ("\r", "\n"):
                sys.stdout.write("\n")
                sys.stdout.flush()
                return "".join(buffer)
            elif ch == "\x1b":  # ESC key
                sys.stdout.write("\n")
                sys.stdout.flush()
                raise NavigationBack()
            elif ch in ("\x08", "\x7f"):  # Backspace
                if buffer:
                    buffer.pop()
                    sys.stdout.write("\b \b")
                    sys.stdout.flush()
            elif ch == "\x03":  # Ctrl+C
                sys.stdout.write("\n")
                sys.stdout.flush()
                raise NavigationBack()
            elif ord(ch) >= 32:
                buffer.append(ch)
                sys.stdout.write(ch)
                sys.stdout.flush()
    else:
        # POSIX (Linux/macOS) terminal
        import termios
        import tty

        sys.stdout.write(prompt_text)
        sys.stdout.flush()
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        buffer = []
        try:
            tty.setcbreak(fd)
            while True:
                rlist, _, _ = select.select([sys.stdin], [], [])
                if not rlist:
                    continue
                ch = sys.stdin.read(1)
                if not ch:
                    break

                if ch in ("\r", "\n"):
                    sys.stdout.write("\n")
                    sys.stdout.flush()
                    return "".join(buffer)
                elif ch == "\x1b":
                    # Check if there are trailing characters in escape sequence (e.g. arrow keys)
                    r_esc, _, _ = select.select([sys.stdin], [], [], 0.05)
                    if r_esc:
                        # Arrow keys or ANSI sequence — consume and ignore
                        sys.stdin.read(2)
                        continue
                    # Standalone ESC key pressed!
                    sys.stdout.write("\n")
                    sys.stdout.flush()
                    raise NavigationBack()
                elif ch in ("\x7f", "\x08", "\b"):  # Backspace
                    if buffer:
                        buffer.pop()
                        sys.stdout.write("\b \b")
                        sys.stdout.flush()
                elif ch == "\x03":  # Ctrl+C
                    sys.stdout.write("\n")
                    sys.stdout.flush()
                    raise NavigationBack()
                elif ch == "\x04":  # Ctrl+D
                    if not buffer:
                        raise NavigationBack()
                elif ord(ch) >= 32:
                    buffer.append(ch)
                    sys.stdout.write(ch)
                    sys.stdout.flush()
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)


def prompt_input(prompt: str, default: str = "", is_main_menu: bool = False) -> str:
    """
    Get input from user with default value.
    Pressing [Esc], entering '0', 'back', 'cancel', 'q', or 'exit' triggers backward navigation.
    """
    def_str = f" [{default}]" if default else ""
    hint_str = f" {DIM}(0/Esc to back){RESET}" if not is_main_menu else f" {DIM}(0/Esc to exit){RESET}"
    prompt_text = f"{BOLD}{prompt}{def_str}{hint_str}:{RESET} "

    try:
        val = read_line_with_esc(prompt_text).strip()
    except (NavigationBack, KeyboardInterrupt, EOFError):
        if is_main_menu:
            return "0"
        raise NavigationBack()

    if is_main_menu:
        return val if val else default

    # In sub-menus and task prompts:
    if val in ("0", "q", "exit", "back", "cancel"):
        raise NavigationBack()

    return val if val else default


def run_script(script_name: str, args: list) -> None:
    """Execute a python script within scripts/."""
    cmd = [PYTHON, str(SCRIPTS_DIR / script_name)] + args
    try:
        subprocess.run(cmd, cwd=str(REPO_ROOT))
    except KeyboardInterrupt:
        print(f"\n{YELLOW}⚠️  Operation cancelled by user.{RESET}")


# =============================================================================
# Tasks
# =============================================================================

def task_convert_images() -> None:
    """Task 1: Convert & Compress Images."""
    print(f"\n{BOLD}{BLUE}▶ Convert & Compress Images to WebP{RESET}")
    print(f"{DIM}Target can be assets/images, a specific category, or a single file.{RESET}")

    target = prompt_input("Target path", "assets/images")
    quality = prompt_input("Quality (1-100)", "82")
    max_dim = prompt_input("Max dimension px (leave blank to keep original)", "")
    del_orig = prompt_input("Delete original non-WebP files? (y/n)", "n").lower() == "y"
    dry_run = prompt_input("Dry run only? (y/n)", "n").lower() == "y"

    args = [target, "-q", quality]
    if max_dim:
        args.extend(["-m", max_dim])
    if del_orig:
        args.append("-d")
    if dry_run:
        args.append("--dry-run")

    run_script("convert_and_optimize.py", args)


def task_generate_manifest() -> None:
    """Task 2: Generate / Sync Manifest."""
    print(f"\n{BOLD}{BLUE}▶ Generate & Sync assets_manifest.dart{RESET}")
    sync_pubspec = prompt_input("Also check/sync pubspec.yaml asset paths? (y/n)", "y").lower() == "y"

    args = []
    if sync_pubspec:
        args.append("--sync-pubspec")

    run_script("generate_manifest.py", args)


def task_audit_assets() -> None:
    """Task 3: Audit Assets."""
    print(f"\n{BOLD}{BLUE}▶ Audit Asset Health & Integrity{RESET}")
    gen_report = prompt_input("Save report to Markdown file? (y/n)", "n").lower() == "y"

    args = []
    if gen_report:
        report_file = prompt_input("Report file path", "audit_report.md")
        args.extend(["-r", report_file])

    run_script("audit_assets.py", args)


def task_normalize_filenames() -> None:
    """Task 4: Normalize & Clean Filenames."""
    print(f"\n{BOLD}{BLUE}▶ Normalize Character Image Filenames{RESET}")
    print(f"  {CYAN}[1]{RESET} Preview changes (Dry Run)")
    print(f"  {CYAN}[2]{RESET} Apply changes and sync manifest")
    print(f"  {CYAN}[0]{RESET} ↩️  Back to main menu\n")

    choice = prompt_input("Select mode", "1")
    if choice == "2":
        run_script("normalize_filenames.py", ["--apply", "--sync-manifest"])
    elif choice == "1":
        run_script("normalize_filenames.py", [])


def task_character_stats() -> None:
    """Task 5: Character Stats & Similarity."""
    print(f"\n{BOLD}{BLUE}▶ Character Analytics & Typo Detector{RESET}")
    print(f"  {CYAN}[1]{RESET} View Character Statistics Summary")
    print(f"  {CYAN}[2]{RESET} Check for Potential Typos / Near-Duplicates")
    print(f"  {CYAN}[3]{RESET} Search for a Character Name")
    print(f"  {CYAN}[4]{RESET} Export Dataset to JSON and CSV")
    print(f"  {CYAN}[0]{RESET} ↩️  Back to main menu\n")

    choice = prompt_input("Select option", "1")
    if choice == "2":
        run_script("character_stats.py", ["--check-duplicates"])
    elif choice == "3":
        q = prompt_input("Enter character name to search")
        if q:
            run_script("character_stats.py", ["-s", q])
    elif choice == "4":
        json_p = prompt_input("JSON output path", "characters_db.json")
        csv_p = prompt_input("CSV output path", "characters_db.csv")
        run_script("character_stats.py", ["--export-json", json_p, "--export-csv", csv_p])
    elif choice == "1":
        run_script("character_stats.py", [])


def task_build_app() -> None:
    """Task 6: Build Game."""
    print(f"\n{BOLD}{BLUE}▶ Build BiGuess Flutter App{RESET}")
    print(f"  {CYAN}[1]{RESET} Android APK (Release)")
    print(f"  {CYAN}[2]{RESET} Android APK (Split per ABI - smaller APKs)")
    print(f"  {CYAN}[3]{RESET} Android App Bundle (AAB - for Google Play)")
    print(f"  {CYAN}[4]{RESET} Web Build")
    print(f"  {CYAN}[5]{RESET} Linux Desktop")
    print(f"  {CYAN}[0]{RESET} ↩️  Back to main menu\n")

    choice = prompt_input("Select build target", "1")
    target_map = {
        "1": (["apk"], "Android APK Release"),
        "2": (["apk", "--split-per-abi"], "Android Split APKs"),
        "3": (["appbundle"], "Android App Bundle"),
        "4": (["web"], "Web"),
        "5": (["linux"], "Linux Desktop"),
    }
    args, label = target_map.get(choice, (["apk"], "Android APK"))

    clean_first = prompt_input("Run flutter clean first? (y/n)", "n").lower() == "y"
    if clean_first:
        args.append("--clean")

    run_script("build_app.py", args)


def task_clean_project() -> None:
    """Task 7: Clean Cache & Temporary Files."""
    print(f"\n{BOLD}{BLUE}▶ Cleaning Project Temporary Files...{RESET}")
    cleaned = 0

    # 1. Python pycache
    for p in REPO_ROOT.rglob("__pycache__"):
        if p.is_dir():
            import shutil
            shutil.rmtree(p, ignore_errors=True)
            cleaned += 1

    # 2. OS junk files (.DS_Store, Thumbs.db)
    for junk in [".DS_Store", "Thumbs.db"]:
        for f in REPO_ROOT.rglob(junk):
            try:
                f.unlink()
                cleaned += 1
            except Exception:
                pass

    print(f"{GREEN}✅ Cleaned {cleaned} cache and temporary file(s).{RESET}")

    clean_flutter = prompt_input("Also run 'flutter clean'? (y/n)", "n").lower() == "y"
    if clean_flutter:
        subprocess.run(["flutter", "clean"], cwd=str(REPO_ROOT))


def task_release_pipeline() -> None:
    """Task 8: Full Release Pipeline."""
    print(f"\n{BOLD}{BLUE}▶ Release Pipeline{RESET}")
    print(f"  {CYAN}[1]{RESET} Full Release (version change → build Split APKs → GitHub release → push)")
    print(f"  {CYAN}[2]{RESET} Build & Release (keep current version)")
    print(f"  {CYAN}[3]{RESET} GitHub Release Only (use existing APKs)")
    print(f"  {CYAN}[0]{RESET} ↩️  Back to main menu\n")

    choice = prompt_input("Select mode", "1")

    args = []
    if choice in ("1", "2"):
        if choice == "1":
            print(f"\n{BOLD}Version selection:{RESET}")
            print(f"  {CYAN}[1]{RESET} patch  (e.g. 0.30.0 → 0.30.1)")
            print(f"  {CYAN}[2]{RESET} minor  (e.g. 0.30.0 → 0.31.0)")
            print(f"  {CYAN}[3]{RESET} major  (e.g. 0.30.0 → 1.0.0)")
            print(f"  {CYAN}[4]{RESET} Enter manual version (e.g. 1.0.0+1)")
            print(f"  {CYAN}[0]{RESET} ↩️  Back\n")
            ver_choice = prompt_input("Select", "1")

            if ver_choice == "4":
                pubspec_text = (REPO_ROOT / "pubspec.yaml").read_text()
                ver_match = re.search(r"^version:\s*(.+)$", pubspec_text, re.MULTILINE)
                current_ver = ver_match.group(1).strip() if ver_match else "0.30.0"
                manual_ver = prompt_input("Enter manual version", current_ver)
                args.extend(["--set-version", manual_ver])
            else:
                bump_map = {"1": "patch", "2": "minor", "3": "major"}
                args.extend(["--bump", bump_map.get(ver_choice, "patch")])

        notes = prompt_input("Release notes", "Bug fixes and improvements.")
        args.extend(["--notes", notes])

        draft = prompt_input("Create as draft release? (y/n)", "n").lower() == "y"
        if draft:
            args.append("--draft")

    elif choice == "3":
        args.extend(["--skip-build"])
        notes = prompt_input("Release notes", "Bug fixes and improvements.")
        args.extend(["--notes", notes])

    run_script("release.py", args)


def task_version_management() -> None:
    """Task 9: Version Management."""
    print(f"\n{BOLD}{BLUE}▶ Version Management{RESET}")
    print(f"  {CYAN}[1]{RESET} Bump version (patch / minor / major) & sync all files")
    print(f"  {CYAN}[2]{RESET} Set manual version (e.g. 1.0.0+1) & sync all files")
    print(f"  {CYAN}[3]{RESET} Sync version.json from current pubspec version")
    print(f"  {CYAN}[4]{RESET} View current version info")
    print(f"  {CYAN}[0]{RESET} ↩️  Back to main menu\n")

    choice = prompt_input("Select option", "1")

    if choice == "1":
        print(f"\n{BOLD}Version bump type:{RESET}")
        print(f"  {CYAN}[1]{RESET} patch  (e.g. 0.30.0 → 0.30.1)")
        print(f"  {CYAN}[2]{RESET} minor  (e.g. 0.30.0 → 0.31.0)")
        print(f"  {CYAN}[3]{RESET} major  (e.g. 0.30.0 → 1.0.0)")
        print(f"  {CYAN}[0]{RESET} ↩️  Back\n")
        bump_choice = prompt_input("Select", "1")
        bump_map = {"1": "patch", "2": "minor", "3": "major"}

        args = ["--version-only", "--bump", bump_map.get(bump_choice, "patch")]

        notes = prompt_input("Release notes (optional)", "")
        if notes:
            args.extend(["--notes", notes])

        run_script("release.py", args)

    elif choice == "2":
        pubspec_text = (REPO_ROOT / "pubspec.yaml").read_text()
        ver_match = re.search(r"^version:\s*(.+)$", pubspec_text, re.MULTILINE)
        current_ver = ver_match.group(1).strip() if ver_match else "0.30.0"

        print(f"\n{DIM}Current version is: {current_ver}{RESET}")
        manual_ver = prompt_input("Enter manual version (e.g. 0.31.0 or 0.31.0+1)", current_ver)

        args = ["--version-only", "--set-version", manual_ver]

        notes = prompt_input("Release notes (optional)", "")
        if notes:
            args.extend(["--notes", notes])

        run_script("release.py", args)

    elif choice == "3":
        run_script("release.py", ["--version-only"])

    elif choice == "4":
        pubspec_text = (REPO_ROOT / "pubspec.yaml").read_text()
        ver_match = re.search(r"^version:\s*(.+)$", pubspec_text, re.MULTILINE)
        pub_ver = ver_match.group(1).strip() if ver_match else "unknown"

        print(f"\n  📦 pubspec.yaml version: {BOLD}{pub_ver}{RESET}")

        vj_path = REPO_ROOT / "version.json"
        if vj_path.exists():
            vj = json_mod.loads(vj_path.read_text())
            print(f"  📋 version.json:")
            for k, v in vj.items():
                print(f"     {k}: {BOLD}{v}{RESET}")
        else:
            print(f"  {YELLOW}⚠️  version.json not found{RESET}")

        constants_path = REPO_ROOT / "lib" / "core" / "constants" / "app_constants.dart"
        if constants_path.exists():
            ct = constants_path.read_text()
            dv_match = re.search(r"defaultVersion = '([^']*)';", ct)
            if dv_match:
                print(f"  🔧 app_constants.dart defaultVersion: {BOLD}{dv_match.group(1)}{RESET}")
        print()


# =============================================================================
# Task Mapping & CLI Runner
# =============================================================================

TASK_MAP = {
    "1": task_convert_images,
    "convert": task_convert_images,
    "optimize": task_convert_images,
    "webp": task_convert_images,
    "2": task_generate_manifest,
    "manifest": task_generate_manifest,
    "sync": task_generate_manifest,
    "3": task_audit_assets,
    "audit": task_audit_assets,
    "check": task_audit_assets,
    "4": task_normalize_filenames,
    "normalize": task_normalize_filenames,
    "clean-names": task_normalize_filenames,
    "5": task_character_stats,
    "stats": task_character_stats,
    "analytics": task_character_stats,
    "6": task_build_app,
    "build": task_build_app,
    "7": task_clean_project,
    "clean": task_clean_project,
    "8": task_release_pipeline,
    "release": task_release_pipeline,
    "publish": task_release_pipeline,
    "9": task_version_management,
    "version": task_version_management,
    "ver": task_version_management,
    "bump": task_version_management,
}


def run_single_task(task_key: str) -> None:
    """Execute a single task directly and exit."""
    task_func = TASK_MAP.get(task_key.lower().strip())
    if not task_func:
        print(f"{RED}Unknown task: '{task_key}'{RESET}")
        print(f"Available tasks: {', '.join(sorted(set(TASK_MAP.keys())))}")
        sys.exit(1)

    print_banner()
    try:
        task_func()
    except NavigationBack:
        print(f"\n{YELLOW}↩️  Cancelled.{RESET}\n")
        return
    print()


def main() -> None:
    """Main interactive menu loop or direct task runner."""
    if len(sys.argv) > 1:
        arg = sys.argv[1].strip()
        if arg in ("-h", "--help"):
            print_banner()
            print(f"{BOLD}Usage:{RESET}")
            print("  ./scripts/run.sh [task_name]")
            print("\nAvailable tasks:")
            print("  release, version, build, convert, manifest, audit, normalize, stats, clean")
            print("Or run without arguments for the full interactive menu.")
            return
        run_single_task(arg)
        return

    while True:
        clear_screen()
        print_banner()

        print(f"{BOLD}Choose a task:{RESET}")
        print(f"  {CYAN}[1]{RESET} 🖼️   Convert & Compress Images to WebP")
        print(f"  {CYAN}[2]{RESET} 📋  Generate / Sync assets_manifest.dart")
        print(f"  {CYAN}[3]{RESET} 🔍  Audit Asset Health (Missing, Broken, Orphans)")
        print(f"  {CYAN}[4]{RESET} ✏️   Normalize & Clean Character Filenames")
        print(f"  {CYAN}[5]{RESET} 📊  Character Analytics & Typo/Duplicate Checker")
        print(f"  {CYAN}[6]{RESET} 🚀  Build Game (APK, App Bundle, Web, Desktop)")
        print(f"  {CYAN}[7]{RESET} 🧹  Clean Cache & Temporary Files")
        print(f"  {MAGENTA}[8]{RESET} 📦  Release Pipeline (build → publish → push)")
        print(f"  {MAGENTA}[9]{RESET} 🏷️   Version Management (bump, sync, view)")
        print(f"  {CYAN}[0]{RESET} 🚪  Exit\n")

        choice = prompt_input("Enter selection", "1", is_main_menu=True)

        if choice == "0" or choice.lower() in ("q", "exit", "back", "cancel"):
            print(f"\n{GREEN}👋 Goodbye! Happy coding.{RESET}\n")
            break

        task_func = TASK_MAP.get(choice)
        if task_func:
            try:
                task_func()
            except NavigationBack:
                print(f"\n{YELLOW}↩️  Returning to menu...{RESET}")
        else:
            print(f"{RED}Invalid option. Please choose 0-9.{RESET}")

        try:
            prompt_input("\nPress Enter to return to menu...", is_main_menu=False)
        except NavigationBack:
            pass


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print(f"\n\n{GREEN}👋 Goodbye!{RESET}\n")
        sys.exit(0)
