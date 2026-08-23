#!/usr/bin/env python3
"""
BiGuess Game - Image Converter & Optimizer
Converts image formats (PNG, JPG, JPEG, BMP, GIF, TIFF) to WebP and compresses WebP images.
"""

import argparse
import os
import shutil
import sys
import time
from pathlib import Path
from typing import List, Optional, Tuple

try:
    from PIL import Image, ImageOps
except ImportError:
    print("❌ Pillow is not installed. Please install it using: pip install pillow")
    sys.exit(1)

# ANSI Color codes for clean terminal output
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
CYAN = "\033[96m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"


def format_bytes(size: float) -> str:
    """Format bytes into a human-readable string."""
    for unit in ["B", "KB", "MB", "GB"]:
        if size < 1024.0:
            return f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{size:.1f} TB"


def process_image(
    file_path: Path,
    output_dir: Optional[Path] = None,
    quality: int = 82,
    lossless: bool = False,
    max_dim: Optional[int] = None,
    strip_metadata: bool = True,
    delete_original: bool = False,
    dry_run: bool = False,
    recompress_webp: bool = True,
) -> Tuple[bool, int, int, str]:
    """
    Process a single image file.
    Returns: (success, original_size, new_size, message)
    """
    try:
        orig_size = file_path.stat().st_size
    except OSError as e:
        return False, 0, 0, f"Cannot read file: {e}"

    ext = file_path.suffix.lower()
    is_webp = ext == ".webp"

    if is_webp and not recompress_webp:
        return True, orig_size, orig_size, "Skipped (already WebP)"

    target_dir = output_dir if output_dir else file_path.parent
    target_path = target_dir / f"{file_path.stem}.webp"

    if dry_run:
        return True, orig_size, orig_size, f"[DRY-RUN] Would process -> {target_path.name}"

    try:
        with Image.open(file_path) as img:
            # Handle EXIF orientation if needed
            try:
                img = ImageOps.exif_transpose(img)
            except Exception:
                pass

            # Convert color mode for WebP compatibility
            if img.mode in ("RGBA", "LA") or (img.mode == "P" and "transparency" in img.info):
                img = img.convert("RGBA")
            elif img.mode != "RGB":
                img = img.convert("RGB")

            # Resize if max_dim specified and exceeds boundary
            if max_dim:
                width, height = img.size
                if max(width, height) > max_dim:
                    scale = max_dim / float(max(width, height))
                    new_width = max(1, int(width * scale))
                    new_height = max(1, int(height * scale))
                    img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

            # Save as WebP
            temp_target = target_path.with_suffix(".tmp.webp") if target_path == file_path else target_path

            save_kwargs = {
                "format": "WEBP",
                "quality": quality,
                "lossless": lossless,
                "method": 6,  # Maximum compression effort
            }
            if not strip_metadata and "exif" in img.info:
                save_kwargs["exif"] = img.info["exif"]

            img.save(temp_target, **save_kwargs)

        new_size = temp_target.stat().st_size

        # If recompressing existing webp and new size is bigger, keep the original unless forced
        if target_path == file_path:
            if new_size >= orig_size:
                temp_target.unlink()
                return True, orig_size, orig_size, "Kept original (already optimal)"
            else:
                temp_target.replace(file_path)
                new_size = file_path.stat().st_size
        else:
            if temp_target != target_path:
                temp_target.replace(target_path)
            new_size = target_path.stat().st_size

            # Delete original non-webp file if requested
            if delete_original and file_path != target_path:
                file_path.unlink()

        saved = orig_size - new_size
        pct = (saved / orig_size * 100) if orig_size > 0 else 0
        msg = f"Saved {format_bytes(saved)} ({pct:.1f}%)" if saved > 0 else f"+{format_bytes(-saved)} ({pct:.1f}%)"
        return True, orig_size, new_size, msg

    except Exception as e:
        return False, orig_size, 0, f"Error: {e}"


def collect_images(target_path: Path, recursive: bool = True) -> List[Path]:
    """Collect image paths matching supported formats."""
    valid_exts = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tiff", ".webp"}
    images: List[Path] = []

    if target_path.is_file():
        if target_path.suffix.lower() in valid_exts:
            images.append(target_path)
    elif target_path.is_dir():
        if recursive:
            for root, _, files in os.walk(target_path):
                for f in sorted(files):
                    p = Path(root) / f
                    if p.suffix.lower() in valid_exts:
                        images.append(p)
        else:
            for p in sorted(target_path.iterdir()):
                if p.is_file() and p.suffix.lower() in valid_exts:
                    images.append(p)

    return images


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert images to WebP and compress WebP assets for BiGuess Game.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    default_target = Path(__file__).resolve().parent.parent / "assets" / "images"

    parser.add_argument(
        "target",
        nargs="?",
        default=str(default_target),
        help="Target file or directory to process (default: assets/images/)",
    )
    parser.add_argument(
        "-q", "--quality",
        type=int,
        default=82,
        help="WebP compression quality (0-100)",
    )
    parser.add_argument(
        "-m", "--max-dim",
        type=int,
        default=None,
        help="Maximum width or height in pixels (scales down preserving aspect ratio)",
    )
    parser.add_argument(
        "-l", "--lossless",
        action="store_true",
        help="Encode WebP without loss of quality (larger file size)",
    )
    parser.add_argument(
        "-d", "--delete-original",
        action="store_true",
        help="Delete original non-WebP file after successful conversion",
    )
    parser.add_argument(
        "--no-recompress",
        action="store_true",
        help="Skip re-compressing existing .webp files",
    )
    parser.add_argument(
        "--keep-metadata",
        action="store_true",
        help="Preserve EXIF and color profile metadata",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate conversions without writing or deleting any files",
    )
    parser.add_argument(
        "--no-recursive",
        action="store_true",
        help="Do not scan subdirectories recursively",
    )

    args = parser.parse_args()
    target_path = Path(args.target).resolve()

    if not target_path.exists():
        print(f"{RED}❌ Target path not found: {target_path}{RESET}")
        return 1

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}         🖼️  BiGuess Image Converter & Optimizer               {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"📁 Target:          {target_path}")
    print(f"🎯 Quality:         {args.quality}{' (Lossless)' if args.lossless else ''}")
    print(f"📐 Max Dimension:   {args.max_dim if args.max_dim else 'Original'}")
    print(f"🗑️  Delete Orig:     {'Yes' if args.delete_original else 'No'}")
    print(f"🔍 Dry Run:         {'Yes' if args.dry_run else 'No'}")
    print(f"{CYAN}──────────────────────────────────────────────────────────────{RESET}\n")

    images = collect_images(target_path, recursive=not args.no_recursive)

    if not images:
        print(f"{YELLOW}⚠️  No images found in {target_path}{RESET}")
        return 0

    print(f"Found {BOLD}{len(images)}{RESET} images to process...\n")

    total_orig = 0
    total_new = 0
    success_count = 0
    error_count = 0
    start_time = time.time()

    for idx, img_path in enumerate(images, 1):
        rel_path = img_path.relative_to(target_path.parent) if target_path.parent in img_path.parents else img_path.name
        success, orig_sz, new_sz, msg = process_image(
            file_path=img_path,
            quality=args.quality,
            lossless=args.lossless,
            max_dim=args.max_dim,
            strip_metadata=not args.keep_metadata,
            delete_original=args.delete_original,
            dry_run=args.dry_run,
            recompress_webp=not args.no_recompress,
        )

        total_orig += orig_sz
        total_new += new_sz if new_sz > 0 else orig_sz

        if success:
            success_count += 1
            if "Saved" in msg:
                status_color = GREEN
            elif "Skipped" in msg or "Kept" in msg:
                status_color = DIM
            else:
                status_color = CYAN
            print(f"[{idx}/{len(images)}] {status_color}{rel_path}{RESET} -> {msg}")
        else:
            error_count += 1
            print(f"[{idx}/{len(images)}] {RED}{rel_path}{RESET} -> ❌ {msg}")

    elapsed = time.time() - start_time
    total_saved = total_orig - total_new
    saved_pct = (total_saved / total_orig * 100) if total_orig > 0 else 0

    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}📊 Optimization Summary:{RESET}")
    print(f"⏱️  Time Elapsed:     {elapsed:.2f}s")
    print(f"✅ Processed:        {success_count} files")
    if error_count > 0:
        print(f"❌ Errors:           {RED}{error_count} files{RESET}")
    print(f"📦 Original Size:    {format_bytes(total_orig)}")
    print(f"🎁 Optimized Size:   {format_bytes(total_new)}")
    if total_saved > 0:
        print(f"💾 Total Saved:      {GREEN}{BOLD}{format_bytes(total_saved)} ({saved_pct:.1f}% reduction){RESET}")
    else:
        print(f"💾 Total Saved:      0 B (Assets are already optimal)")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    return 0 if error_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
