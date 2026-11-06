#!/usr/bin/env bash
set -euo pipefail
sidecar_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$sidecar_dir/indexer_daemon.py" "$@"
