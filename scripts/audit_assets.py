#!/usr/bin/env python3
"""
BiGuess Game - Asset Health & Integrity Auditor
Scans assets and lib/assets_manifest.dart to detect broken links, missing files,
orphaned assets, corrupt images, and naming issues.
"""

import argparse
import os
import re
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

try:
    from PIL import Image
except ImportError:
    Image = None

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


@dataclass
class Issue:
    category: str
    issue_type: str  # 'MISSING', 'TYPO_MISMATCH', 'ORPHAN', 'CORRUPT', 'NAMING', 'OVERSIZED'
    path: str
    description: str
    suggestion: Optional[str] = None


@dataclass
class AuditReport:
    total_manifest_entries: int = 0
    total_disk_files: int = 0
    categories_checked: int = 0
    issues: List[Issue] = field(default_factory=list)

    @property
    def has_errors(self) -> bool:
        return any(i.issue_type in ("MISSING", "CORRUPT") for i in self.issues)


def parse_dart_manifest(manifest_path: Path) -> Dict[str, List[str]]:
    """Parse categoryAssets map from lib/assets_manifest.dart."""
    if not manifest_path.exists():
        print(f"{RED}❌ Manifest file not found at {manifest_path}{RESET}")
        return {}

    with open(manifest_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    categories: Dict[str, List[str]] = {}
    current_category: Optional[str] = None

    for line in content.splitlines():
        line = line.strip()
        # Match category header: 'Attack on Titan': [ or "Attack on Titan": [
        cat_match = re.match(r'''^\s*(?P<quote>['"])(?P<cat>.*?)(?<!\\)(?P=quote)\s*:\s*\[\s*$''', line)
        if cat_match:
            current_category = cat_match.group("cat").replace("\\'", "'").replace('\\"', '"')
            categories[current_category] = []
            continue

        if line.startswith("],"):
            current_category = None
            continue

        # Match item: 'assets/images/attack_on_titan/Eren YAEGER.webp', or "assets/..."
        if current_category and (line.startswith("'") or line.startswith('"')):
            item_match = re.match(r'''^\s*(?P<quote>['"])(?P<path>.*?)(?<!\\)(?P=quote)\s*,?\s*$''', line)
            if item_match:
                asset_path = item_match.group("path").replace("\\'", "'").replace('\\"', '"')
                categories[current_category].append(asset_path)

    return categories


def find_similar_file(target_filename: str, candidates: List[str]) -> Optional[str]:
    """Find a candidate filename that closely matches target_filename."""
    norm_target = unicodedata.normalize("NFD", target_filename).encode("ascii", "ignore").decode("utf-8").lower()
    for cand in candidates:
        norm_cand = unicodedata.normalize("NFD", cand).encode("ascii", "ignore").decode("utf-8").lower()
        if norm_target == norm_cand:
            return cand
    return None


def audit_project(
    repo_root: Path,
    manifest_path: Path,
    images_dir: Path,
    check_image_data: bool = True,
    max_size_kb: int = 150,
) -> AuditReport:
    """Run full asset audit."""
    report = AuditReport()
    manifest = parse_dart_manifest(manifest_path)
    report.categories_checked = len(manifest)

    all_manifest_paths: Set[str] = set()
    for cat, items in manifest.items():
        report.total_manifest_entries += len(items)
        for item in items:
            all_manifest_paths.add(unicodedata.normalize("NFC", item))

    # Collect all image files on disk
    disk_images_by_dir: Dict[Path, List[str]] = {}
    total_disk = 0

    if images_dir.exists():
        for root, _, files in os.walk(images_dir):
            r_path = Path(root)
            img_files = [
                f for f in files if Path(f).suffix.lower() in {".webp", ".png", ".jpg", ".jpeg"}
            ]
            if img_files:
                disk_images_by_dir[r_path] = img_files
                total_disk += len(img_files)

    report.total_disk_files = total_disk

    # 1. Check all Manifest entries against Disk
    for category, items in manifest.items():
        for asset_rel in items:
            normalized_rel = unicodedata.normalize("NFC", asset_rel)
            full_path = repo_root / normalized_rel

            if not full_path.exists():
                parent_dir = full_path.parent
                cand_files = disk_images_by_dir.get(parent_dir, [])
                similar = find_similar_file(full_path.name, cand_files)

                if similar:
                    report.issues.append(
                        Issue(
                            category=category,
                            issue_type="TYPO_MISMATCH",
                            path=asset_rel,
                            description=f"File exists with different casing/accent: '{similar}'",
                            suggestion=f"assets/images/{parent_dir.name}/{similar}",
                        )
                    )
                else:
                    report.issues.append(
                        Issue(
                            category=category,
                            issue_type="MISSING",
                            path=asset_rel,
                            description="File does not exist on disk",
                            suggestion="Add image file or remove entry from manifest",
                        )
                    )
            else:
                # 2. Check File Health / Integrity
                if check_image_data and Image is not None:
                    try:
                        with Image.open(full_path) as img:
                            img.verify()
                    except Exception as e:
                        report.issues.append(
                            Issue(
                                category=category,
                                issue_type="CORRUPT",
                                path=asset_rel,
                                description=f"Corrupt image file (cannot decode): {e}",
                                suggestion="Re-export or replace corrupted image",
                            )
                        )

                # Check file size
                file_sz_kb = full_path.stat().st_size / 1024.0
                if file_sz_kb > max_size_kb:
                    report.issues.append(
                        Issue(
                            category=category,
                            issue_type="OVERSIZED",
                            path=asset_rel,
                            description=f"File size ({file_sz_kb:.1f} KB) exceeds threshold ({max_size_kb} KB)",
                            suggestion="Run python3 scripts/convert_and_optimize.py to compress",
                        )
                    )

                # Check Naming anomalies
                fname = full_path.name
                if "%20" in fname or "  " in fname or fname.startswith(" ") or fname.endswith(" "):
                    report.issues.append(
                        Issue(
                            category=category,
                            issue_type="NAMING",
                            path=asset_rel,
                            description="Suspicious filename formatting (spaces/URL encoding)",
                            suggestion="Run python3 scripts/normalize_filenames.py",
                        )
                    )

    # 3. Check for Orphaned Assets on Disk (files on disk not in manifest)
    for parent_dir, files in disk_images_by_dir.items():
        rel_parent = parent_dir.relative_to(repo_root) if repo_root in parent_dir.parents else parent_dir
        for f in files:
            norm_f = unicodedata.normalize("NFC", f)
            rel_asset = f"{rel_parent.as_posix()}/{norm_f}"
            if rel_asset not in all_manifest_paths:
                # Find category name from folder
                cat_name = parent_dir.name.replace("_", " ").title()
                report.issues.append(
                    Issue(
                        category=cat_name,
                        issue_type="ORPHAN",
                        path=rel_asset,
                        description="Image on disk is NOT registered in lib/assets_manifest.dart",
                        suggestion="Run python3 scripts/generate_manifest.py to include all assets",
                    )
                )

    return report


def print_cli_report(report: AuditReport) -> None:
    """Print colored summary to terminal."""
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}            🔍  BiGuess Asset Audit Report                     {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"📂 Categories:       {report.categories_checked}")
    print(f"📋 Manifest Entries: {report.total_manifest_entries}")
    print(f"💾 Files on Disk:    {report.total_disk_files}")
    print(f"⚠️  Total Issues:    {len(report.issues)}")
    print(f"{CYAN}──────────────────────────────────────────────────────────────{RESET}\n")

    if not report.issues:
        print(f"{GREEN}{BOLD}🎉 Perfect! All assets are verified, intact, and properly synced.{RESET}\n")
        return

    # Group issues by type
    by_type: Dict[str, List[Issue]] = {}
    for issue in report.issues:
        by_type.setdefault(issue.issue_type, []).append(issue)

    type_colors = {
        "MISSING": RED,
        "TYPO_MISMATCH": YELLOW,
        "CORRUPT": RED,
        "ORPHAN": CYAN,
        "OVERSIZED": MAGENTA,
        "NAMING": YELLOW,
    }

    type_titles = {
        "MISSING": "❌ Missing Assets (in manifest but not on disk)",
        "TYPO_MISMATCH": "⚠️  Typo / Casing Mismatches",
        "CORRUPT": "💥 Corrupted Image Files",
        "ORPHAN": "📦 Orphan Assets (on disk but not registered in manifest)",
        "OVERSIZED": "🐘 Oversized Assets (> threshold)",
        "NAMING": "✏️  Naming Irregularities",
    }

    for issue_type, issues in by_type.items():
        color = type_colors.get(issue_type, YELLOW)
        title = type_titles.get(issue_type, issue_type)
        print(f"{BOLD}{color}{title} ({len(issues)}):{RESET}")
        for i in issues[:20]:  # Limit output to 20 per group to avoid spam
            print(f"  • [{i.category}] {i.path}")
            print(f"    ↳ {DIM}{i.description}{RESET}")
            if i.suggestion:
                print(f"    ↳ {GREEN}Fix: {i.suggestion}{RESET}")
        if len(issues) > 20:
            print(f"    {DIM}... and {len(issues) - 20} more{RESET}")
        print()

    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")


def generate_markdown_report(report: AuditReport, out_path: Path) -> None:
    """Write markdown audit report to file."""
    lines = [
        "# 🔍 BiGuess Asset Audit Report",
        "",
        f"- **Categories Checked:** {report.categories_checked}",
        f"- **Manifest Entries:** {report.total_manifest_entries}",
        f"- **Disk Files:** {report.total_disk_files}",
        f"- **Total Issues Found:** {len(report.issues)}",
        "",
        "---",
        "",
    ]

    if not report.issues:
        lines.append("🎉 **All image assets are healthy and in sync!**\n")
    else:
        lines.append("| Category | Issue Type | Path | Details | Suggestion |")
        lines.append("|---|---|---|---|---|")
        for i in report.issues:
            lines.append(f"| {i.category} | `{i.issue_type}` | `{i.path}` | {i.description} | {i.suggestion or ''} |")
        lines.append("")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"{GREEN}📄 Detailed Markdown report saved to: {out_path}{RESET}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit BiGuess asset links, integrity, and orphaned files.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    repo_root = Path(__file__).resolve().parent.parent
    default_manifest = repo_root / "lib" / "assets_manifest.dart"
    default_images = repo_root / "assets" / "images"

    parser.add_argument(
        "-m", "--manifest",
        type=Path,
        default=default_manifest,
        help="Path to lib/assets_manifest.dart",
    )
    parser.add_argument(
        "-i", "--images-dir",
        type=Path,
        default=default_images,
        help="Path to assets/images folder",
    )
    parser.add_argument(
        "-r", "--report",
        type=Path,
        default=None,
        help="Save report to Markdown file path",
    )
    parser.add_argument(
        "--max-size",
        type=int,
        default=200,
        help="Flag images larger than this size in KB",
    )
    parser.add_argument(
        "--no-image-verify",
        action="store_true",
        help="Skip deep image byte validation",
    )

    args = parser.parse_args()

    report = audit_project(
        repo_root=repo_root,
        manifest_path=args.manifest,
        images_dir=args.images_dir,
        check_image_data=not args.no_image_verify,
        max_size_kb=args.max_size,
    )

    print_cli_report(report)

    if args.report:
        generate_markdown_report(report, args.report)

    return 1 if report.has_errors else 0


if __name__ == "__main__":
    sys.exit(main())
