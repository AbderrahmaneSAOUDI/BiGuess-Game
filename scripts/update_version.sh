#!/bin/bash
# ============================================================================
# update_version.sh — Auto-generates version.json from pubspec.yaml
# ============================================================================
#
# Usage:
#   ./scripts/update_version.sh                     # reads pubspec, writes version.json
#   ./scripts/update_version.sh --native            # sets has_native_changes=true
#   ./scripts/update_version.sh --notes "Bug fixes" # sets custom release notes
#   ./scripts/update_version.sh --min "0.28.0"      # overrides min_required_version
#   ./scripts/update_version.sh --commit            # auto-commits the updated version.json
#
# The script reads the version from pubspec.yaml, extracts the build number,
# and writes a valid version.json for the OTA update system.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"
VERSION_JSON="$PROJECT_ROOT/version.json"

# ---- Defaults ----
HAS_NATIVE_CHANGES="auto"
RELEASE_NOTES=""
MIN_REQUIRED_VERSION=""
AUTO_COMMIT=false

# ---- GitHub config ----
GITHUB_USER="AbderrahmaneSAOUDI"
GITHUB_REPO="BiGuess-Game"

# ---- Parse args ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --native)
      HAS_NATIVE_CHANGES="true"
      shift
      ;;
    --no-native)
      HAS_NATIVE_CHANGES="false"
      shift
      ;;
    --notes)
      RELEASE_NOTES="$2"
      shift 2
      ;;
    --min)
      MIN_REQUIRED_VERSION="$2"
      shift 2
      ;;
    --commit)
      AUTO_COMMIT=true
      shift
      ;;
    -h|--help)
      head -18 "$0" | tail -14
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ---- Extract version from pubspec.yaml ----
FULL_VERSION=$(grep -E "^version:" "$PUBSPEC" | head -1 | sed 's/version:[[:space:]]*//')

if [[ -z "$FULL_VERSION" ]]; then
  echo "❌ Could not find 'version:' in $PUBSPEC"
  exit 1
fi

# Split version and build number (e.g., "1.2.3+15" → "1.2.3" and "15")
if [[ "$FULL_VERSION" == *"+"* ]]; then
  VERSION="${FULL_VERSION%%+*}"
  BUILD_NUMBER="${FULL_VERSION##*+}"
else
  VERSION="$FULL_VERSION"
  # Auto-increment build number from existing version.json if it exists
  if [[ -f "$VERSION_JSON" ]]; then
    PREV_BUILD=$(grep -o '"build_number":[[:space:]]*[0-9]*' "$VERSION_JSON" | grep -o '[0-9]*' || echo "0")
    BUILD_NUMBER=$((PREV_BUILD + 1))
  else
    BUILD_NUMBER=1
  fi
fi

# ---- Auto-detect native changes if not explicitly specified ----
if [[ "$HAS_NATIVE_CHANGES" == "auto" ]]; then
  LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  NATIVE_DIFF=""
  if [[ -n "$LATEST_TAG" ]]; then
    NATIVE_DIFF=$(git diff --name-only "$LATEST_TAG"..HEAD -- android/ ios/ macos/ windows/ linux/ web/ 2>/dev/null || echo "")
  fi
  UNCOMMITTED_NATIVE=$(git status --porcelain android/ ios/ macos/ windows/ linux/ web/ 2>/dev/null || echo "")
  if [[ -n "$NATIVE_DIFF" || -n "$UNCOMMITTED_NATIVE" ]]; then
    HAS_NATIVE_CHANGES="true"
    echo "🔍 Auto-detected native changes → has_native_changes: true"
  else
    HAS_NATIVE_CHANGES="false"
    echo "🔍 Auto-detected pure Dart/assets update → has_native_changes: false (Shorebird OTA eligible)"
  fi
fi

# ---- Determine min_required_version ----
if [[ -z "$MIN_REQUIRED_VERSION" ]]; then
  if [[ -f "$VERSION_JSON" ]]; then
    # Keep the existing min_required_version by default
    MIN_REQUIRED_VERSION=$(grep -o '"min_required_version":[[:space:]]*"[^"]*"' "$VERSION_JSON" | sed 's/.*"\([^"]*\)"/\1/' || echo "$VERSION")
  else
    MIN_REQUIRED_VERSION="$VERSION"
  fi
fi

# ---- Determine release notes ----
if [[ -z "$RELEASE_NOTES" ]]; then
  if [[ -f "$VERSION_JSON" ]]; then
    RELEASE_NOTES=$(grep -o '"release_notes":[[:space:]]*"[^"]*"' "$VERSION_JSON" | sed 's/.*"\([^"]*\)"/\1/' || echo "Bug fixes and improvements.")
  else
    RELEASE_NOTES="Bug fixes and improvements."
  fi
fi

# ---- APK download URLs (GitHub Releases) ----
APK_BASE="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/latest/download"
APK_URL="$APK_BASE/app-arm64-v8a-release.apk"

# ---- Write version.json ----
cat > "$VERSION_JSON" <<EOF
{
  "latest_version": "$VERSION",
  "build_number": $BUILD_NUMBER,
  "min_required_version": "$MIN_REQUIRED_VERSION",
  "has_native_changes": $HAS_NATIVE_CHANGES,
  "apk_urls": {
    "arm64-v8a": "$APK_BASE/app-arm64-v8a-release.apk",
    "armeabi-v7a": "$APK_BASE/app-armeabi-v7a-release.apk",
    "x86_64": "$APK_BASE/app-x86_64-release.apk",
    "universal": "$APK_BASE/app-release.apk"
  },
  "apk_url": "$APK_URL",
  "release_notes": "$RELEASE_NOTES"
}
EOF

echo "✅ version.json updated:"
echo "   Version:        $VERSION"
echo "   Build:          $BUILD_NUMBER"
echo "   Min required:   $MIN_REQUIRED_VERSION"
echo "   Native changes: $HAS_NATIVE_CHANGES"
echo "   Split-ABI URLs: arm64-v8a, armeabi-v7a, x86_64, universal"
echo "   Default APK:    $APK_URL"

# ---- Auto-commit if requested ----
if $AUTO_COMMIT; then
  cd "$PROJECT_ROOT"
  git add version.json
  git commit -m "chore: update version.json to v$VERSION+$BUILD_NUMBER"
  echo "📦 Committed version.json"
fi
