#!/usr/bin/env bash
# BiGuess Game - Developer Toolbox Launcher
# Usage: ./scripts/run.sh [task_name] [args...]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not found."
    exit 1
fi

cd "$REPO_ROOT"

if [ $# -eq 0 ]; then
    # Launch interactive menu
    python3 "$SCRIPT_DIR/menu.py"
else
    # Forward arguments to specific script
    case "$1" in
        convert|optimize|webp)
            shift
            python3 "$SCRIPT_DIR/convert_and_optimize.py" "$@"
            ;;
        manifest|sync)
            shift
            python3 "$SCRIPT_DIR/generate_manifest.py" "$@"
            ;;
        audit|check)
            shift
            python3 "$SCRIPT_DIR/audit_assets.py" "$@"
            ;;
        normalize|clean-names)
            shift
            python3 "$SCRIPT_DIR/normalize_filenames.py" "$@"
            ;;
        stats|analytics)
            shift
            python3 "$SCRIPT_DIR/character_stats.py" "$@"
            ;;
        build|release)
            shift
            python3 "$SCRIPT_DIR/build_app.py" "$@"
            ;;
        *)
            echo "Unknown command: $1"
            echo "Available shortcuts: convert, manifest, audit, normalize, stats, build"
            echo "Or run without arguments for interactive menu: ./scripts/run.sh"
            exit 1
            ;;
    esac
fi
