#!/usr/bin/env python3
"""
BiGuess Game - Asset Filename Normalizer & Cleaner
Cleans up character image filenames (download artifacts, double spaces, encoding quirks)
and normalizes unicode representation.
"""

import argparse
import os
import re
import sys
import unicodedata
from pathlib import Path
from typing import Dict, List, Tuple

# ANSI Colors
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
CYAN = "\033[96m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"


def clean_character_name(stem: str) -> str:
    """
    Cleans a character filename stem by removing download artifacts,
    normalizing whitespace, and standardizing casing/punctuation.
    """
    # 1. URL decoding if needed
    name = stem.replace("%20", " ")

    # 2. Strip common download/copy suffixes
    patterns_to_strip = [
        r"\s*\(\s*\d+\s*\)$",          # e.g. (1), (2)
        r"_\d+$",                       # e.g. _1, _01
        r"\s*-\s*copy(\s*\d+)?$",       # e.g. - copy, - copy 2
        r"\s*\[\s*(?:HQ|HD|Official|Anime|Render)\s*\]",  # [HQ], [HD]
        r"\.png$",                      # in case of name.png.webp
        r"\.jpg$",
        r"\.jpeg$",
    ]
    for pat in patterns_to_strip:
        name = re.sub(pat, "", name, flags=re.IGNORECASE)

    # 3. Fix double/multiple whitespace and standalone spaced dashes
    name = re.sub(r"\s+", " ", name)
    name = re.sub(r"\s+-\s+", " - ", name)
    name = re.sub(r"-{2,}", " - ", name)

    # 4. Trim leading/trailing whitespace and punctuation
    name = name.strip(" ._-")

    # 5. Unicode normalization (NFC)
    name = unicodedata.normalize("NFC", name)

    return name


def scan_and_plan_renames(images_dir: Path) -> List[Tuple[Path, Path]]:
    """Scan directory and return list of (old_path, new_path) where name changed."""
    plan: List[Tuple[Path, Path]] = []
    valid_exts = {".webp", ".png", ".jpg", ".jpeg"}

    for root, _, files in os.walk(images_dir):
        r_path = Path(root)
        for f in files:
            file_path = r_path / f
            ext = file_path.suffix.lower()
            if ext in valid_exts:
                clean_stem = clean_character_name(file_path.stem)
                new_filename = f"{clean_stem}{ext}"
                new_path = r_path / new_filename

                if file_path != new_path:
                    plan.append((file_path, new_path))

    return plan


def execute_renames(plan: List[Tuple[Path, Path]], dry_run: bool = True) -> int:
    """Execute planned renames."""
    if not plan:
        print(f"{GREEN}✅ All filenames are already clean and normalized!{RESET}")
        return 0

    print(f"\nFound {BOLD}{len(plan)}{RESET} file(s) requiring normalization:\n")

    for idx, (old_p, new_p) in enumerate(plan, 1):
        rel_old = old_p.name
        rel_new = new_p.name
        action_prefix = f"[{idx}/{len(plan)}]"

        if dry_run:
            print(f"{action_prefix} {YELLOW}[DRY-RUN]{RESET} '{rel_old}' ➜ '{GREEN}{rel_new}{RESET}'")
        else:
            if new_p.exists() and new_p.resolve() != old_p.resolve():
                print(f"{action_prefix} {RED}❌ Target already exists: '{rel_new}' (Skipping '{rel_old}'){RESET}")
                continue

            try:
                # Two-step rename for case-only changes on case-insensitive filesystems
                temp_p = old_p.with_name(f"__tmp_rename_{old_p.name}")
                old_p.rename(temp_p)
                temp_p.rename(new_p)
                print(f"{action_prefix} {GREEN}Renamed:{RESET} '{rel_old}' ➜ '{BOLD}{rel_new}{RESET}'")
            except Exception as e:
                print(f"{action_prefix} {RED}Error renaming '{rel_old}': {e}{RESET}")

    return len(plan)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Clean and normalize character filenames in BiGuess assets.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    repo_root = Path(__file__).resolve().parent.parent
    default_target = repo_root / "assets" / "images"

    parser.add_argument(
        "target",
        nargs="?",
        default=str(default_target),
        help="Target folder to clean (default: assets/images/)",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply renames directly (default is dry-run mode)",
    )
    parser.add_argument(
        "--sync-manifest",
        action="store_true",
        help="Automatically regenerate lib/assets_manifest.dart after renaming",
    )

    args = parser.parse_args()
    target_path = Path(args.target).resolve()
    is_dry_run = not args.apply

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         ✏️   BiGuess Asset Filename Normalizer                {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"📁 Target:  {target_path}")
    print(f"⚙️  Mode:    {YELLOW + 'DRY-RUN (Pass --apply to execute)' if is_dry_run else GREEN + 'APPLYING CHANGES'}{RESET}")
    print(f"{CYAN}──────────────────────────────────────────────────────────────{RESET}\n")

    if not target_path.exists():
        print(f"{RED}❌ Target path not found: {target_path}{RESET}")
        return 1

    plan = scan_and_plan_renames(target_path)
    count = execute_renames(plan, dry_run=is_dry_run)

    if not is_dry_run and args.sync_manifest and count > 0:
        print(f"\n{CYAN}🔄 Synchronizing lib/assets_manifest.dart...{RESET}")
        from generate_manifest import default_dart_out, default_images, generate_dart_content, scan_assets

        manifest = scan_assets(default_images)
        dart_code = generate_dart_content(manifest)
        with open(default_dart_out, "w", encoding="utf-8") as f:
            f.write(dart_code)
        print(f"{GREEN}✅ Manifest updated successfully!{RESET}")

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
