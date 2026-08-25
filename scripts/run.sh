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
    # Forward to interactive task runner or specific script
    TASK="$1"
    shift

    if [ $# -eq 0 ]; then
        # Interactive mode via menu.py
        case "$TASK" in
            convert|optimize|webp|\
            manifest|sync|\
            audit|check|\
            normalize|clean-names|\
            stats|analytics|\
            build|\
            clean|\
            release|publish|\
            version|ver|bump)
                python3 "$SCRIPT_DIR/menu.py" "$TASK"
                ;;
            -h|--help|help)
                python3 "$SCRIPT_DIR/menu.py" --help
                ;;
            *)
                echo "Unknown command: $TASK"
                echo "Available shortcuts:"
                echo "  release, version, build, convert, manifest, audit, normalize, stats, clean"
                echo "Or run without arguments for interactive menu: ./scripts/run.sh"
                exit 1
                ;;
        esac
    else
        # Direct CLI mode with flags passed
        case "$TASK" in
            convert|optimize|webp)
                python3 "$SCRIPT_DIR/convert_and_optimize.py" "$@"
                ;;
            manifest|sync)
                python3 "$SCRIPT_DIR/generate_manifest.py" "$@"
                ;;
            audit|check)
                python3 "$SCRIPT_DIR/audit_assets.py" "$@"
                ;;
            normalize|clean-names)
                python3 "$SCRIPT_DIR/normalize_filenames.py" "$@"
                ;;
            stats|analytics)
                python3 "$SCRIPT_DIR/character_stats.py" "$@"
                ;;
            build)
                python3 "$SCRIPT_DIR/build_app.py" "$@"
                ;;
            release|publish)
                python3 "$SCRIPT_DIR/release.py" "$@"
                ;;
            version|ver|bump)
                python3 "$SCRIPT_DIR/release.py" --version-only "$@"
                ;;
            *)
                echo "Unknown command: $TASK"
                exit 1
                ;;
        esac
    fi
fi
