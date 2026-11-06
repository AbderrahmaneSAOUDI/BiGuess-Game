---
trigger: always_on
description: Navigate live source efficiently and treat generated indexes as disposable hints.
---

# Source navigation

Use a named path or `rg` first for direct lookups. For broad orientation consult [file map](../sidecars/file-map.md) or the optional `.agents/cache/codebase_summary.md`. An index can be stale and uses regex symbol extraction; verify declarations before editing.

Refresh after structural changes with `python3 .agents/sidecars/codebase-index-daemon/indexer_daemon.py --once`. The index excludes archives, binary assets, dependency trees, and its own cache. Keep generated caches/logs/locks untracked. An explicit `--watch` process is optional; manage its lifetime in the foreground.
