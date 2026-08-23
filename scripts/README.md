# 🛠️ BiGuess Game - Developer Toolbox

A suite of cross-platform Python and Bash automation scripts for maintaining game assets, synchronizing manifests, analyzing character data, and building release binaries.

---

## ⚡ Quick Start

Run the interactive dashboard to access all tools via a clean terminal interface:

```bash
./scripts/run.sh
# or
python3 scripts/menu.py
```

You can also run any tool directly using CLI flags or shortcuts:

```bash
./scripts/run.sh convert assets/images/one_piece/ -q 80
./scripts/run.sh manifest --sync-pubspec
./scripts/run.sh audit
./scripts/run.sh stats --check-duplicates
./scripts/run.sh build apk
```

---

## 📚 Tools Overview

### 1. `convert_and_optimize.py` - Image Converter & Compressor
Converts images (PNG, JPG, JPEG, BMP, GIF, TIFF) to WebP, recompresses existing WebP files, strips unnecessary EXIF metadata, and scales down oversized assets.

```bash
# Convert & compress all images in assets/images/ with quality 80
python3 scripts/convert_and_optimize.py assets/images/ -q 80

# Convert a single category and delete original non-webp files
python3 scripts/convert_and_optimize.py assets/images/naruto/ -q 85 -d

# Resize oversized images so max dimension is 500px (saves mobile RAM)
python3 scripts/convert_and_optimize.py assets/images/ -m 500

# Dry-run to preview potential savings without modifying files
python3 scripts/convert_and_optimize.py --dry-run
```

**Options:**
- `-q, --quality <int>`: WebP compression quality (0-100, default: `82`).
- `-m, --max-dim <int>`: Downscale images larger than this width/height in pixels.
- `-l, --lossless`: Encode WebP without quality loss.
- `-d, --delete-original`: Delete source files after converting to `.webp`.
- `--no-recompress`: Skip recompressing files that are already WebP.
- `--dry-run`: Preview actions without changing any files.

---

### 2. `generate_manifest.py` - Asset Manifest & Config Sync
Scans all anime subfolders in `assets/images/` and regenerates `lib/assets_manifest.dart` with deterministic sorting and Unicode NFC normalization (preventing broken characters like `Bell-mère` or `Charlotte Brûlée`).

```bash
# Regenerate lib/assets_manifest.dart
python3 scripts/generate_manifest.py

# Sync both assets_manifest.dart and pubspec.yaml asset folder declarations
python3 scripts/generate_manifest.py --sync-pubspec

# Check if manifest is in sync (useful for CI/pre-commit hooks)
python3 scripts/generate_manifest.py --check
```

**Options:**
- `-i, --images-dir <path>`: Source folder (default: `assets/images`).
- `-o, --output <path>`: Output Dart file (default: `lib/assets_manifest.dart`).
- `--sync-pubspec`: Auto-registers any new category folders in `pubspec.yaml`.
- `--check`: Returns exit code `1` if out of sync, `0` if up-to-date.

---

### 3. `audit_assets.py` - Health & Integrity Auditor
Scans the entire repository to detect broken links, missing files referenced in Dart, orphaned assets on disk, corrupted images, and suspicious filenames.

```bash
# Run audit and show colored summary in terminal
python3 scripts/audit_assets.py

# Export audit findings to a Markdown report
python3 scripts/audit_assets.py -r audit_report.md

# Flag images larger than 100 KB
python3 scripts/audit_assets.py --max-size 100
```

**Checks performed:**
- ❌ **Missing Assets**: Listed in `assets_manifest.dart` but missing on disk.
- ⚠️ **Typo / Casing Mismatches**: Casing or accent differences between code and disk.
- 💥 **Corrupt Files**: Unreadable or truncated image files.
- 📦 **Orphan Assets**: Files on disk not registered in the game's manifest.
- 🐘 **Oversized Assets**: Files larger than threshold.
- ✏️ **Naming Irregularities**: Double spaces, URL encodings (`%20`), trailing spaces.

---

### 4. `normalize_filenames.py` - Character Filename Cleaner
Cleans up character image filenames by removing common web download artifacts (`_1`, `(1)`, `[HQ]`, `%20`, double spaces) and applying Unicode NFC normalization.

```bash
# Preview proposed renames (Dry Run)
python3 scripts/normalize_filenames.py

# Apply renames and automatically sync lib/assets_manifest.dart
python3 scripts/normalize_filenames.py --apply --sync-manifest
```

---

### 5. `character_stats.py` - Analytics, Typos & Exporter
Analyzes character distributions across anime categories, detects near-duplicate names or typos using Levenshtein distance, searches character names, and exports data.

```bash
# View character count and stats table
python3 scripts/character_stats.py

# Detect typos or near-duplicate names across categories
python3 scripts/character_stats.py --check-duplicates

# Search for a character
python3 scripts/character_stats.py -s "Luffy"

# Export all characters to JSON and CSV
python3 scripts/character_stats.py --export-json characters.json --export-csv characters.csv
```

---

### 6. `build_app.py` - Flutter Build & Release Automation
Automates pre-flight checks (`flutter pub get`, `flutter analyze`, `flutter test`), builds the requested target, and reports output file size and SHA-256 checksums.

```bash
# Build Android APK (Release)
python3 scripts/build_app.py apk

# Build smaller split APKs per architecture (arm64, v7a, x86_64)
python3 scripts/build_app.py apk --split-per-abi

# Build Android App Bundle (.aab) for Google Play Store
python3 scripts/build_app.py appbundle

# Build Web version
python3 scripts/build_app.py web

# Clean before building
python3 scripts/build_app.py apk --clean
```

---

## 📦 Requirements

- **Python**: Python 3.8+
- **Pillow**: `pip install pillow` (for image processing & verification)
- **Flutter**: Flutter SDK on `PATH` (for build automation)
