#!/usr/bin/env python3
"""
BiGuess Game - Character Analytics, Typo Detector & Dataset Exporter
Analyzes character names across all categories, checks for near-duplicates or typos,
and exports character datasets to JSON or CSV.
"""

import argparse
import csv
import json
import os
import sys
import unicodedata
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ANSI Colors
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"


@dataclass
class CharacterInfo:
    name: str
    category: str
    asset_path: str
    file_size_kb: float
    name_length: int


def levenshtein_distance(s1: str, s2: str) -> int:
    """Calculate the Levenshtein edit distance between two strings."""
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)
    if len(s2) == 0:
        return len(s1)

    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row

    return previous_row[-1]


def collect_characters(images_dir: Path) -> List[CharacterInfo]:
    """Scan images directory and collect all character info."""
    valid_exts = {".webp", ".png", ".jpg", ".jpeg"}
    characters: List[CharacterInfo] = []

    if not images_dir.exists():
        return characters

    for subdir in sorted([d for d in images_dir.iterdir() if d.is_dir()]):
        category_name = subdir.name.replace("_", " ").title()
        for item in sorted(subdir.iterdir()):
            if item.is_file() and item.suffix.lower() in valid_exts:
                char_name = unicodedata.normalize("NFC", item.stem)
                sz_kb = item.stat().st_size / 1024.0
                rel_path = f"assets/images/{subdir.name}/{item.name}"

                characters.append(
                    CharacterInfo(
                        name=char_name,
                        category=category_name,
                        asset_path=rel_path,
                        file_size_kb=round(sz_kb, 2),
                        name_length=len(char_name),
                    )
                )

    return characters


def find_similar_names(
    characters: List[CharacterInfo], max_distance: int = 2
) -> List[Tuple[CharacterInfo, CharacterInfo, int]]:
    """Find pairs of characters with very similar names (potential typos or duplicates)."""
    similar_pairs: List[Tuple[CharacterInfo, CharacterInfo, int]] = []
    n = len(characters)

    for i in range(n):
        for j in range(i + 1, n):
            c1 = characters[i]
            c2 = characters[j]

            # Normalize for comparison
            n1 = unicodedata.normalize("NFD", c1.name).encode("ascii", "ignore").decode("utf-8").lower()
            n2 = unicodedata.normalize("NFD", c2.name).encode("ascii", "ignore").decode("utf-8").lower()

            if n1 == n2:
                similar_pairs.append((c1, c2, 0))
            else:
                dist = levenshtein_distance(n1, n2)
                # Only flag if distance <= max_distance and names are not trivially short
                if dist <= max_distance and min(len(n1), len(n2)) >= 4:
                    similar_pairs.append((c1, c2, dist))

    return similar_pairs


def print_stats_table(characters: List[CharacterInfo]) -> None:
    """Print statistical breakdown by category."""
    by_category: Dict[str, List[CharacterInfo]] = {}
    for c in characters:
        by_category.setdefault(c.category, []).append(c)

    print(f"{BOLD}{'Category':<24} | {'Count':>6} | {'Avg Size':>9} | {'Min / Max Name Length':>22}{RESET}")
    print("─" * 70)

    total_chars = len(characters)
    total_kb = sum(c.file_size_kb for c in characters)

    for cat, items in sorted(by_category.items()):
        count = len(items)
        avg_sz = sum(x.file_size_kb for x in items) / count if count else 0
        min_len = min(x.name_length for x in items) if items else 0
        max_len = max(x.name_length for x in items) if items else 0
        shortest = next(x.name for x in items if x.name_length == min_len)
        longest = next(x.name for x in items if x.name_length == max_len)

        print(
            f"{BOLD}{cat:<24}{RESET} | {count:>6} | {avg_sz:>6.1f} KB | "
            f"{min_len} ('{shortest[:10]}') / {max_len} ('{longest[:10]}...')"
        )

    print("─" * 70)
    avg_total_sz = (total_kb / total_chars) if total_chars else 0
    print(f"{BOLD}{'TOTAL':<24} | {total_chars:>6} | {avg_total_sz:>6.1f} KB | {total_kb/1024:.2f} MB total{RESET}\n")


def search_character(characters: List[CharacterInfo], query: str) -> None:
    """Search for characters matching query."""
    q_norm = query.lower().strip()
    matches = [c for c in characters if q_norm in c.name.lower()]

    print(f"\n{BOLD}🔍 Search results for '{query}' ({len(matches)} match(es)):{RESET}")
    if not matches:
        print(f"  {YELLOW}No character found matching '{query}'{RESET}\n")
        return

    for c in matches:
        print(f"  • {GREEN}{BOLD}{c.name}{RESET} [{CYAN}{c.category}{RESET}] ({c.file_size_kb} KB)")
        print(f"    ↳ {DIM}{c.asset_path}{RESET}")
    print()


def export_dataset(characters: List[CharacterInfo], json_path: Optional[Path], csv_path: Optional[Path]) -> None:
    """Export character list to JSON or CSV."""
    if json_path:
        data = [asdict(c) for c in characters]
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"{GREEN}💾 JSON export saved to: {json_path}{RESET}")

    if csv_path:
        with open(csv_path, "w", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(
                f, fieldnames=["name", "category", "asset_path", "file_size_kb", "name_length"]
            )
            writer.writeheader()
            for c in characters:
                writer.writerow(asdict(c))
        print(f"{GREEN}💾 CSV export saved to:  {csv_path}{RESET}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Character analytics, similarity check & database export for BiGuess Game.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    repo_root = Path(__file__).resolve().parent.parent
    default_images = repo_root / "assets" / "images"

    parser.add_argument(
        "-i", "--images-dir",
        type=Path,
        default=default_images,
        help="Path to assets/images folder",
    )
    parser.add_argument(
        "-s", "--search",
        type=str,
        default=None,
        help="Search for a character by name",
    )
    parser.add_argument(
        "--check-duplicates",
        action="store_true",
        help="Check for duplicate or near-duplicate character names (typos)",
    )
    parser.add_argument(
        "--export-json",
        type=Path,
        default=None,
        help="Export all characters to a JSON file",
    )
    parser.add_argument(
        "--export-csv",
        type=Path,
        default=None,
        help="Export all characters to a CSV file",
    )

    args = parser.parse_args()

    characters = collect_characters(args.images_dir)

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         📊  BiGuess Character Analytics & Stats               {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    if not characters:
        print(f"{RED}❌ No character images found in {args.images_dir}{RESET}")
        return 1

    if args.search:
        search_character(characters, args.search)
        return 0

    print_stats_table(characters)

    if args.check_duplicates:
        print(f"{BOLD}🔍 Checking for potential typos & near-duplicate names...{RESET}\n")
        similar = find_similar_names(characters, max_distance=2)
        if not similar:
            print(f"{GREEN}✅ No duplicate or confusingly similar character names found!{RESET}\n")
        else:
            print(f"{YELLOW}⚠️  Found {len(similar)} potential name similarities / typos:{RESET}")
            for c1, c2, dist in similar:
                tag = f"{RED}Exact Match / Duplicate{RESET}" if dist == 0 else f"{YELLOW}Distance: {dist}{RESET}"
                print(f"  • '{c1.name}' ({c1.category}) vs '{c2.name}' ({c2.category}) -> {tag}")
            print()

    if args.export_json or args.export_csv:
        export_dataset(characters, args.export_json, args.export_csv)

    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
