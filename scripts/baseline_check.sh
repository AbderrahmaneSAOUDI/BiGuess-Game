#!/usr/bin/env bash
# ==============================================================================
# BiGuess Game — Baseline Verification Script (T01)
# ==============================================================================
set -euo pipefail

echo "=================================================="
echo "  BiGuess Baseline Health Check"
echo "  Commit: $(git rev-parse HEAD)"
echo "  Date:   $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "=================================================="

echo ""
echo "--- 1. Static Analysis (flutter analyze) ---"
flutter analyze

echo ""
echo "--- 2. Automated Test Suite (flutter test) ---"
flutter test

echo ""
echo "--- 3. Asset Integrity Audit (scripts/audit_assets.py) ---"
python3 scripts/audit_assets.py

echo ""
echo "--- 4. Character Analytics (scripts/character_stats.py) ---"
python3 scripts/character_stats.py

echo ""
echo "--- 5. Platform Diagnostics (flutter doctor -v) ---"
flutter doctor -v

echo ""
echo "=================================================="
echo "  Baseline verification completed."
echo "=================================================="
