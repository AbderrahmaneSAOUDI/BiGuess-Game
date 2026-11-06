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
import shlex
import shutil
import subprocess
import sys
import unicodedata
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


class ScriptFailed(Exception):
    """A tool failed; preserve its exit status for command-line callers."""

    def __init__(self, returncode: int):
        self.returncode = returncode if returncode > 0 else 128 - returncode


def clear_screen() -> None:
    """Clear terminal screen."""
    if sys.stdout.isatty():
        os.system("cls" if os.name == "nt" else "clear")


def _display_width(text: str) -> int:
    """Count terminal cells for our labels, including emoji and ANSI colors."""
    width = previous = 0
    for character in re.sub(r"\x1b\[[0-9;]*m", "", text):
        if character == "\ufe0f":
            # Emoji presentation makes otherwise narrow symbols two cells wide.
            if previous == 1:
                width += 1
                previous = 2
        elif not unicodedata.combining(character):
            previous = 2 if unicodedata.east_asian_width(character) in ("W", "F") else 1
            width += previous
    return width


def print_banner() -> None:
    """Center the title and subtitle inside equal-width borders."""
    width = 62
    print(f"{BOLD}{CYAN}╔{'═' * width}╗{RESET}")
    for text in ("🎮  BIGUESS GAME TOOLBOX", "Developer Utilities & Asset Automation"):
        padding = width - _display_width(text)
        left = padding // 2
        print(f"{BOLD}{CYAN}║{' ' * left}{text}{' ' * (padding - left)}║{RESET}")
    print(f"{BOLD}{CYAN}╚{'═' * width}╝{RESET}\n")


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
    hint_str = f" {DIM}(0/Esc: back){RESET}" if not is_main_menu else f" {DIM}(0/Esc: exit){RESET}"
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
    if val.lower() in ("0", "q", "exit", "back", "cancel"):
        raise NavigationBack()

    return val if val else default


def run_command(cmd: list) -> None:
    """Run one tool and preserve failures."""
    try:
        result = subprocess.run(cmd, cwd=str(REPO_ROOT))
        if result.returncode:
            raise ScriptFailed(result.returncode)
    except KeyboardInterrupt:
        raise ScriptFailed(130)
    except FileNotFoundError:
        print(f"Command not found: {cmd[0]}. Install it or add it to PATH.", file=sys.stderr)
        raise ScriptFailed(127)


def run_script(script_name: str, args: list) -> None:
    """Execute a Python script within scripts/."""
    run_command([PYTHON, str(SCRIPTS_DIR / script_name)] + args)


# =============================================================================
# Tasks
# =============================================================================

def task_manage_topics() -> None:
    """Task: Manage Topics & Packs (CRUD)."""
    run_script("manage_topics.py", [])


def task_baseline() -> None:
    print("Check the app and save a log for every check.")
    full = prompt_input("Include Android debug build and SDK diagnostics? (y/n)", "n").lower() == "y"
    output = prompt_input("Log folder (blank uses .agents/cache/baseline)")
    args = [] if full else ["--fast"]
    if output:
        args.append(output)
    run_command(["bash", str(SCRIPTS_DIR / "baseline_check.sh"), *args])


def task_export_pack() -> None:
    print("Create an offline .biguesspack file from a cleared test fixture.")
    source = prompt_input("Fixture metadata file", "test/fixtures/cleared_shapes/pack.json")
    output = prompt_input("New output file", ".agents/cache/shapes.biguesspack")
    run_script("export_pack.py", ["fixture", source, "--output", output])


def task_offline_gate() -> None:
    print("Test gameplay after a forced app restart with external networking disabled.")
    print("Requires Linux network namespaces and the Flutter SDK.")
    evidence = prompt_input("Save logs to folder (blank uses temporary storage)")
    run_script("check_offline_gameplay.py", ["--evidence", evidence] if evidence else [])


def task_convert_images() -> None:
    """Task 2: Convert & Compress Images."""
    print(f"\n{BOLD}{BLUE}Resize and compress images{RESET}")
    print(f"{DIM}Choose the full image folder, one Pack folder, or a single image.{RESET}")

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
    print(f"\n{BOLD}{BLUE}Update the bundled image list{RESET}")
    sync_pubspec = prompt_input("Also check/sync pubspec.yaml asset paths? (y/n)", "y").lower() == "y"

    args = []
    if sync_pubspec:
        args.append("--sync-pubspec")

    run_script("generate_manifest.py", args)


def task_audit_assets() -> None:
    """Task 3: Audit Assets."""
    print(f"\n{BOLD}{BLUE}Check image files{RESET}")
    gen_report = prompt_input("Save report to Markdown file? (y/n)", "n").lower() == "y"

    args = []
    if gen_report:
        report_file = prompt_input("Report file path", "audit_report.md")
        args.extend(["-r", report_file])

    run_script("audit_assets.py", args)


def task_normalize_filenames() -> None:
    """Task 4: Normalize & Clean Filenames."""
    print(f"\n{BOLD}{BLUE}Clean image filenames{RESET}")
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
    print(f"\n{BOLD}{BLUE}Browse names and possible duplicates{RESET}")
    print(f"  {CYAN}[1]{RESET} Show counts by Topic and Pack")
    print(f"  {CYAN}[2]{RESET} Find similar names and possible duplicates")
    print(f"  {CYAN}[3]{RESET} Search for a Character Name")
    print(f"  {CYAN}[4]{RESET} Export names and counts as JSON and CSV")
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


def android_release_signing_ready() -> bool:
    """Validate configured Android signing without building or exposing values."""
    try:
        result = subprocess.run(
            [str(REPO_ROOT / "android/gradlew"), ":app:validateReleaseSigning",
             "-PrequireReleaseSigning=true", "-q"],
            cwd=str(REPO_ROOT / "android"), capture_output=True, text=True, timeout=90,
        )
    except (OSError, subprocess.TimeoutExpired):
        print("Could not check Android signing. Check your Java/Android SDK setup.")
        return False
    if result.returncode:
        print(f"{YELLOW}Android Release requires configured release signing.{RESET}")
        print("Configure android/key.properties using android/key.properties.example,")
        print("or use the signing environment variables in the release safety guide.")
        print("Choose Profile for local testing without a release key.")
        return False
    return True


def task_run_app() -> None:
    """Choose a device and build mode, keeping the launch flow short."""
    print(f"\n{BOLD}{BLUE}▶ Choose a device to run BiGuess{RESET}")
    try:
        result = subprocess.run(
            ["flutter", "devices", "--machine"], cwd=str(REPO_ROOT),
            capture_output=True, text=True, timeout=30,
        )
    except FileNotFoundError:
        print(f"{RED}Flutter was not found. Add the Flutter SDK to PATH.{RESET}")
        raise ScriptFailed(127)
    except subprocess.TimeoutExpired:
        print(f"{RED}Device discovery timed out. Check your connection and try again.{RESET}")
        raise ScriptFailed(1)
    if result.returncode:
        print(result.stderr or result.stdout, file=sys.stderr)
        raise ScriptFailed(result.returncode)
    try:
        found = json_mod.loads(result.stdout)
        if not isinstance(found, list):
            raise ValueError("Expected a device list")
    except (ValueError, TypeError):
        print(f"{RED}Flutter returned an unreadable device list. Try again.{RESET}")
        raise ScriptFailed(1)
    devices = [
        device for device in found
        if isinstance(device, dict)
        and isinstance(device.get("id"), str) and device["id"].strip()
        and device.get("isSupported") is not False
    ]
    if not devices:
        print("No devices found. Connect a device or start an emulator, then try again.")
        return
    names = [str(device.get("name") or device["id"]) for device in devices]
    name_width = max(_display_width(name) for name in names)
    for index, (device, name) in enumerate(zip(devices, names), 1):
        padding = " " * (name_width - _display_width(name) + 2)
        platform = device.get("targetPlatform", "unknown")
        print(f"  {CYAN}[{index:>2}]{RESET} {name}{padding}{DIM}({platform}, {device['id']}){RESET}")
    print(f"  {CYAN}[ 0]{RESET} Back\n")
    while True:
        choice = prompt_input("Choose device", "1")
        if choice.isascii() and choice.isdigit() and 1 <= int(choice) <= len(devices):
            break
        print(f"Choose a device number from 1 to {len(devices)}.")
    device = devices[int(choice) - 1]
    android = str(device.get("targetPlatform", "")).startswith("android")
    print(f"\n{BOLD}{BLUE}▶ Choose app build type{RESET}")
    print(f"  {CYAN}[1]{RESET} Debug   — development with hot reload")
    print(f"  {CYAN}[2]{RESET} Profile — recommended for local play and performance testing")
    print(f"  {CYAN}[3]{RESET} Release — optimized build; Android requires release signing")
    print(f"  {CYAN}[0]{RESET} Back\n")
    while True:
        build_choice = prompt_input("Build type", "2")
        mode = {"1": "debug", "2": "profile", "3": "release"}.get(build_choice)
        if mode is None:
            print("Choose a build type from 1 to 3.")
            continue
        if android and mode == "release" and not android_release_signing_ready():
            continue
        break
    standalone = android and mode != "debug"
    command = ["flutter", "run", "-d", device["id"], f"--{mode}"]
    if standalone:
        command.append("--no-resident")
    print(f"\n{DIM}$ {shlex.join(command)}{RESET}\n")
    print("Flutter will build, install, and open the app. Cached builds are reused.")
    if standalone:
        print("The menu returns after launch; BiGuess remains installed and running.\n")
    elif android:
        print("After the app opens: d = detach and keep it running; q = stop the app.\n")
    else:
        print("Keep this terminal open while using the app.\n")
    run_command(command)
    if standalone:
        print(f"\n{GREEN}BiGuess installed and launched. Reopen it from your phone's app list.{RESET}")


def task_build_app() -> None:
    """Task 6: Build Game."""
    print(f"\n{BOLD}{BLUE}▶ Build BiGuess Flutter App{RESET}")
    print(f"  {CYAN}[1]{RESET} 📦 Android Split APKs (arm64-v8a, armeabi-v7a, x86_64)")
    print(f"  {CYAN}[2]{RESET} Android App Bundle (.aab)")
    print(f"  {CYAN}[3]{RESET} 🌐 Web Build")
    print(f"  {CYAN}[0]{RESET} ↩️  Back to main menu\n")

    choice = prompt_input("Select build target", "1")
    target_map = {
        "1": (["apk"], "Android Split APKs"),
        "2": (["appbundle"], "Android App Bundle"),
        "3": (["web"], "Web"),
    }
    if choice not in target_map:
        print("Choose 1, 2, or 3.")
        return
    args, label = target_map[choice]

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


def task_shorebird_patch() -> None:
    """Direct Shorebird OTA Patch task."""
    print(f"\n{BOLD}{BLUE}Publish a Shorebird patch{RESET}")
    print(f"{DIM}Publishes a patch for a compatible existing Shorebird base release.{RESET}\n")
    notes = prompt_input("Patch description / Release notes", "Bug fixes and improvements.")
    args = ["--patch", "--notes", notes]
    dry_run = prompt_input("Preview the plan only? (y/n)", "n").lower() == "y"
    if dry_run:
        args.append("--dry-run")
    run_script("release.py", args)


def task_content_inventory() -> None:
    """Run content inventory and rights quarantine check."""
    clear_screen()
    print_banner()
    print(f"{BOLD}{CYAN}             Content counts and publication rights               {RESET}\n")
    print(f"  {CYAN}[1]{RESET} Check image counts and integrity")
    print(f"  {CYAN}[2]{RESET} Check that repeated exports are identical")
    print(f"  {CYAN}[3]{RESET} Export JSON and Markdown reports (with fixtures)")
    print(f"  {CYAN}[4]{RESET} Export only cleared test images to temporary storage")
    print(f"  {CYAN}[0]{RESET} Back to Main Menu\n")

    choice = prompt_input("Select an option", "1")
    if choice == "1":
        run_script("content_inventory.py", ["--check"])
    elif choice == "2":
        run_script("content_inventory.py", ["--check-reproducible"])
    elif choice == "3":
        run_script("content_inventory.py", [
            "--output", "docs/migration/content_inventory.json",
            "--markdown", "docs/migration/CONTENT_INVENTORY_AND_RIGHTS.md",
            "--include-fixtures",
            "--check",
        ])
    elif choice == "4":
        import tempfile
        with tempfile.TemporaryDirectory() as td:
            run_script("content_inventory.py", ["--include-fixtures", "--export-public-test", td])


def task_release_pipeline() -> None:
    """Task 8: Full Release Pipeline."""
    print(f"\n{BOLD}{BLUE}▶ Release Pipeline{RESET}")
    print(f"  {GREEN}{BOLD}[1]{RESET} Choose patch or base release automatically")
    print(f"  {CYAN}[2]{RESET} Publish a Shorebird patch")
    print(f"  {CYAN}[3]{RESET} Build and publish a base release with a version bump")
    print(f"  {CYAN}[4]{RESET} Build and publish using the current version")
    print(f"  {CYAN}[5]{RESET} Publish existing APKs to GitHub")
    print(f"  {CYAN}[6]{RESET} Check the Shorebird installation")
    print(f"  {CYAN}[7]{RESET} Check the published update manifest")
    print(f"  {CYAN}[0]{RESET} ↩️  Back to main menu\n")

    choice = prompt_input("Select mode", "1")

    args = []
    if choice == "1":
        # Auto Release Pipeline
        notes = prompt_input("Release notes / Patch description", "Bug fixes and improvements.")
        if notes:
            args.extend(["--notes", notes])

    elif choice == "2":
        # Force Shorebird OTA Patch
        args.append("--patch")
        notes = prompt_input("Patch description / Release notes", "Bug fixes and improvements.")
        if notes:
            args.extend(["--notes", notes])
        dry_run = prompt_input("Preview the plan only? (y/n)", "n").lower() == "y"
        if dry_run:
            args.append("--dry-run")

    elif choice == "3":
        # Force Full Base Release
        args.append("--full-release")
        print(f"\n{BOLD}Version selection:{RESET}")
        print(f"  {CYAN}[1]{RESET} patch  (e.g. 0.30.3 → 0.30.4)")
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
            if ver_choice not in bump_map:
                print("Choose a version option from 1 to 4.")
                return
            args.extend(["--bump", bump_map[ver_choice]])

        notes = prompt_input("Release notes", "Bug fixes and improvements.")
        args.extend(["--notes", notes])

        draft = prompt_input("Create as draft release? (y/n)", "n").lower() == "y"
        if draft:
            args.append("--draft")

    elif choice == "4":
        # Build & Release without version bump
        args.append("--full-release")
        notes = prompt_input("Release notes", "Bug fixes and improvements.")
        args.extend(["--notes", notes])
        draft = prompt_input("Create as draft release? (y/n)", "n").lower() == "y"
        if draft:
            args.append("--draft")

    elif choice == "5":
        args.extend(["--skip-build", "--full-release"])
        notes = prompt_input("Release notes", "Bug fixes and improvements.")
        args.extend(["--notes", notes])

    elif choice == "6":
        args.append("--doctor")

    elif choice == "7":
        args.append("--check-update")
    else:
        print("Choose a release option from 1 to 7.")
        return

    if choice in ("1", "2", "3", "4", "5"):
        verbose = prompt_input("Show detailed upload logs? (y/n)", "n").lower() == "y"
        if verbose:
            args.append("-v")

    run_script("release.py", args)


def task_version_management() -> None:
    """Task 9: Version Management."""
    print(f"\n{BOLD}{BLUE}▶ Version Management{RESET}")
    print(f"  {CYAN}[1]{RESET} Bump version (patch / minor / major) & sync all files")
    print(f"  {CYAN}[2]{RESET} Set manual version (e.g. 1.0.0+1) & sync all files")
    print(f"  {CYAN}[3]{RESET} Sync version.json from current pubspec version")
    print(f"  {CYAN}[4]{RESET} View current version info")
    print(f"  {CYAN}[5]{RESET} 🔍 Check remote version.json & OTA update health")
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
        if bump_choice not in bump_map:
            print("Choose a version option from 1 to 3.")
            return
        args = ["--version-only", "--bump", bump_map[bump_choice]]

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

    elif choice == "5":
        run_script("release.py", ["--check-update"])


# =============================================================================
# Task Mapping & CLI Runner
# =============================================================================

TASK_MAP = {
    "topics": task_manage_topics,
    "topic": task_manage_topics,
    "packs": task_manage_topics,
    "pack": task_manage_topics,
    "crud": task_manage_topics,
    "convert": task_convert_images,
    "optimize": task_convert_images,
    "webp": task_convert_images,
    "manifest": task_generate_manifest,
    "sync": task_generate_manifest,
    "audit": task_audit_assets,
    "check": task_audit_assets,
    "normalize": task_normalize_filenames,
    "clean-names": task_normalize_filenames,
    "stats": task_character_stats,
    "analytics": task_character_stats,
    "build": task_build_app,
    "run": task_run_app,
    "launch": task_run_app,
    "clean": task_clean_project,
    "release": task_release_pipeline,
    "publish": task_release_pipeline,
    "patch": task_shorebird_patch,
    "ota": task_shorebird_patch,
    "doctor": lambda: run_script("release.py", ["--doctor"]),
    "check-update": lambda: run_script("release.py", ["--check-update"]),
    "verify-update": lambda: run_script("release.py", ["--check-update"]),
    "status": lambda: run_script("release.py", ["--check-update"]),
    "version": task_version_management,
    "ver": task_version_management,
    "bump": task_version_management,
    "inventory": task_content_inventory,
    "quarantine": task_content_inventory,
    "baseline": task_baseline,
    "export": task_export_pack,
    "offline": task_offline_gate,
}


TOOL_GROUPS = [
    ("Check the app", [
        ("1", "baseline", "Run all checks and save logs", "baseline_check.sh"),
        ("2", "audit", "Find missing or damaged images", "audit_assets.py"),
        ("3", "inventory", "Count content and check publication rights", "content_inventory.py"),
        ("4", "offline", "Test offline play across an app restart", "check_offline_gameplay.py"),
    ]),
    ("Manage content", [
        ("5", "topics", "Add, rename, or remove Topics and Packs", "manage_topics.py"),
        ("6", "manifest", "Update the bundled image list", "generate_manifest.py"),
        ("7", "convert", "Resize and compress images", "convert_and_optimize.py"),
        ("8", "normalize", "Preview or clean image filenames", "normalize_filenames.py"),
        ("9", "stats", "Browse names, counts, and possible duplicates", "character_stats.py"),
        ("10", "export", "Create an offline test Pack", "export_pack.py"),
    ]),
    ("Build and maintain", [
        ("11", "run", "Choose a device and run the app", "flutter run"),
        ("12", "build", "Build APKs, an App Bundle, or the web app", "build_app.py"),
        ("13", "version", "View or synchronize version files", "release.py --version-only"),
        ("14", "clean", "Remove generated caches and temporary files", "menu.py clean"),
        ("15", "release", "Publish a base release or OTA patch", "release.py"),
    ]),
]

# Numeric choices follow the displayed groups; named shortcuts stay stable.
TASK_MAP.update({
    number: TASK_MAP[shortcut]
    for _, entries in TOOL_GROUPS
    for number, shortcut, _, _ in entries
})


def print_tool_tree(show_files: bool = False) -> None:
    icons = {
        "baseline": "✅", "audit": "🔍", "inventory": "📦", "offline": "📴",
        "topics": "📂", "manifest": "📋", "convert": "🖼️", "normalize": "✏️",
        "stats": "📊", "export": "📤", "build": "🚀", "version": "🏷️",
        "clean": "🧹", "release": "📦", "run": "📱",
    }
    description_width = max(
        _display_width(description)
        for _, entries in TOOL_GROUPS
        for _, _, description, _ in entries
    )
    script_width = max(
        _display_width(f"({script})")
        for _, entries in TOOL_GROUPS
        for _, _, _, script in entries
    )
    columns = shutil.get_terminal_size().columns
    for group, entries in TOOL_GROUPS:
        print(f"\n  {BOLD}{BLUE}▶ {group}{RESET}")
        for number, shortcut, description, script in entries:
            color = MAGENTA if shortcut in ("topics", "release", "version") else CYAN
            icon = icons[shortcut]
            icon_padding = " " * (4 - _display_width(icon))
            prefix = f"  {color}[{number:>2}]{RESET} {icon}{icon_padding}{shortcut:<10} "
            if show_files:
                gap = " " * (description_width - _display_width(description) + 2)
                suffix = f"{DIM}({script}){RESET}"
                line = f"{prefix}{description}{gap}{suffix}"
                if _display_width(prefix) + description_width + 2 + script_width <= columns:
                    print(line)
                else:
                    print(f"{prefix}{description}")
                    print(f"{' ' * _display_width(prefix)}{suffix}")
            else:
                print(f"{prefix}{description}")
    print(f"\n  {CYAN}[ 0]{RESET} 🚪  Exit\n")


def run_single_task(task_key: str) -> int:
    """Execute a single task directly and exit."""
    task_func = TASK_MAP.get(task_key.lower().strip())
    if not task_func:
        print(f"{RED}Unknown task: '{task_key}'{RESET}")
        print(f"Available tasks: {', '.join(sorted(set(TASK_MAP.keys())))}")
        return 1

    print_banner()
    try:
        task_func()
    except NavigationBack:
        print(f"\n{YELLOW}↩️  Cancelled.{RESET}\n")
        return 0
    except ScriptFailed as error:
        print(f"Tool failed (exit {error.returncode}). Read its output above.", file=sys.stderr)
        return error.returncode
    print()
    return 0


def main() -> int:
    """Main interactive menu loop or direct task runner."""
    if len(sys.argv) > 1:
        arg = sys.argv[1].strip()
        if arg in ("-h", "--help", "--list", "help"):
            print_banner()
            print(f"{BOLD}Usage:{RESET}")
            print("  ./scripts/run.sh                     Open the menu")
            print("  ./scripts/run.sh <tool>              Open one tool")
            print("  ./scripts/run.sh <tool> <arguments>  Run a command directly")
            print_tool_tree(show_files=True)
            print("Use ./scripts/run.sh <tool> --help for that tool's options.")
            print("Additional release shortcuts: patch, doctor, check-update.")
            return 0
        return run_single_task(arg)

    while True:
        clear_screen()
        print_banner()

        print_tool_tree()

        choice = prompt_input("Enter selection", "1", is_main_menu=True)

        if choice == "0" or choice.lower() in ("q", "exit", "back", "cancel"):
            print(f"\n{GREEN}👋 Goodbye! Happy coding.{RESET}\n")
            break

        task_func = TASK_MAP.get(choice.lower())
        if task_func:
            try:
                task_func()
            except NavigationBack:
                print(f"\n{YELLOW}↩️  Returning to menu...{RESET}")
            except ScriptFailed as error:
                print(f"Tool failed (exit {error.returncode}). Read its output above.")
        else:
            print("Choose a listed number or tool name.")

        try:
            prompt_input("\nPress Enter to return to menu...", is_main_menu=False)
        except NavigationBack:
            pass
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyboardInterrupt, EOFError):
        print(f"\n\n{GREEN}👋 Goodbye!{RESET}\n")
        sys.exit(0)
