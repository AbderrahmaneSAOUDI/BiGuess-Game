#!/usr/bin/env python3
"""
BiGuess Game - Interactive Developer Toolbox Menu
Launches any game maintenance, image processing, manifest generation, or build task.
"""

import os
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


def clear_screen() -> None:
    """Clear terminal screen."""
    os.system("cls" if os.name == "nt" else "clear")


def print_banner() -> None:
    """Print BiGuess header banner."""
    print(f"{BOLD}{CYAN}╔══════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{CYAN}║                 🎮  BIGUESS GAME TOOLBOX                     ║{RESET}")
    print(f"{BOLD}{CYAN}║             Developer Utilities & Asset Automation           ║{RESET}")
    print(f"{BOLD}{CYAN}╚══════════════════════════════════════════════════════════════╝{RESET}\n")


def prompt_input(prompt: str, default: str = "") -> str:
    """Get input from user with default value."""
    def_str = f" [{default}]" if default else ""
    try:
        val = input(f"{BOLD}{prompt}{def_str}:{RESET} ").strip()
        return val if val else default
    except (KeyboardInterrupt, EOFError):
        print()
        return default


def run_script(script_name: str, args: list) -> None:
    """Execute a python script within scripts/."""
    cmd = [PYTHON, str(SCRIPTS_DIR / script_name)] + args
    try:
        subprocess.run(cmd, cwd=str(REPO_ROOT))
    except KeyboardInterrupt:
        print(f"\n{YELLOW}⚠️  Operation cancelled by user.{RESET}")


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
    print("1. Preview changes (Dry Run)")
    print("2. Apply changes and sync manifest")

    choice = prompt_input("Select mode", "1")
    if choice == "2":
        run_script("normalize_filenames.py", ["--apply", "--sync-manifest"])
    else:
        run_script("normalize_filenames.py", [])


def task_character_stats() -> None:
    """Task 5: Character Stats & Similarity."""
    print(f"\n{BOLD}{BLUE}▶ Character Analytics & Typo Detector{RESET}")
    print("1. View Character Statistics Summary")
    print("2. Check for Potential Typos / Near-Duplicates")
    print("3. Search for a Character Name")
    print("4. Export Dataset to JSON and CSV")

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
    else:
        run_script("character_stats.py", [])


def task_build_app() -> None:
    """Task 6: Build Game."""
    print(f"\n{BOLD}{BLUE}▶ Build BiGuess Flutter App{RESET}")
    print("1. Android APK (Release)")
    print("2. Android APK (Split per ABI - smaller APKs)")
    print("3. Android App Bundle (AAB - for Google Play)")
    print("4. Web Build")
    print("5. Linux Desktop")

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


def main() -> None:
    """Main interactive menu loop."""
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
        print(f"  {CYAN}[0]{RESET} 🚪  Exit\n")

        choice = prompt_input("Enter selection", "1")

        if choice == "0" or choice.lower() in ("q", "exit"):
            print(f"\n{GREEN}👋 Goodbye! Happy coding.{RESET}\n")
            break
        elif choice == "1":
            task_convert_images()
        elif choice == "2":
            task_generate_manifest()
        elif choice == "3":
            task_audit_assets()
        elif choice == "4":
            task_normalize_filenames()
        elif choice == "5":
            task_character_stats()
        elif choice == "6":
            task_build_app()
        elif choice == "7":
            task_clean_project()
        else:
            print(f"{RED}Invalid option. Please choose 0-7.{RESET}")

        prompt_input("\nPress Enter to return to menu...")


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print(f"\n\n{GREEN}👋 Goodbye!{RESET}\n")
        sys.exit(0)
