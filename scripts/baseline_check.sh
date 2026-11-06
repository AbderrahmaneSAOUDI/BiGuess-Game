#!/usr/bin/env bash
# ==============================================================================
# BiGuess Game — Verification & Health Check Script
# Mirrors the CI quality gates defined in .github/workflows/ci.yml
# ==============================================================================
set -euo pipefail

echo "=================================================="
echo "  BiGuess Fast Verification & Quality Gates"
echo "  Commit: $(git rev-parse --short HEAD)"
echo "  Date:   $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "=================================================="

echo ""
echo "--- 1. Dependency Resolution (flutter pub get) ---"
flutter pub get

echo ""
echo "--- 2. Code Formatting (dart format) ---"
dart format --output=none --set-exit-if-changed lib test

echo ""
echo "--- 3. Static Analysis (flutter analyze --fatal-infos) ---"
flutter analyze --fatal-infos

echo ""
echo "--- 4. Automated Test Suite (flutter test) ---"
flutter test

echo ""
echo "--- 5. Topic/Pack Manifest Sync (scripts/generate_manifest.py --check) ---"
python3 scripts/generate_manifest.py --check

echo ""
echo "--- 6. Asset Integrity Audit (scripts/audit_assets.py) ---"
python3 scripts/audit_assets.py

echo ""
echo "--- 7. Version Triad Check (scripts/release.py --version-only) ---"
python3 scripts/release.py --version-only

echo ""
echo "--- 8. Character Analytics (scripts/character_stats.py) ---"
python3 scripts/character_stats.py

echo ""
echo "--- 9. Platform Diagnostics (flutter doctor -v) ---"
flutter doctor -v

echo ""
echo "=================================================="
echo "  ✅ All verification checks completed successfully!"
echo "=================================================="
