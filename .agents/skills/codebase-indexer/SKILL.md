---
name: codebase-indexer
description: Locate BiGuess classes, Riverpod providers and active source using the optional local index. Use for broad navigation; search a known file directly.
---

# Navigate active source

1. Check `.agents/cache/codebase_summary.md` if present. Cache is disposable and may
   be stale; source files determine behavior. Refresh after switching branches,
   creating files or deleting files:

   ```bash
   python3 .agents/sidecars/codebase-index-daemon/indexer_daemon.py --once
   ```

2. Query metadata without reading the entire JSON index:

   ```bash
   python3 - <<'PY'
   import json
   from pathlib import Path
   index = json.loads(Path('.agents/cache/codebase_index.json').read_text())
   for item in index['files']:
       if any('GameRoundNotifier' in symbol for symbol in item['symbols']):
           print(item['path'], ', '.join(item['symbols']))
   PY
   rg -n 'gameRoundProvider|class GameRoundNotifier' lib/providers/game_controller.dart
   ```

3. Use `.agents/sidecars/file-map.md` and `architecture.md` for ownership and flow,
   and `rg --files lib test backend scripts` when cache is unavailable.

The index includes active app, tests, scripts, backend, platform and `.agents`
source; excludes archive copies, binary assets, generated dependency/build trees
and cache; skips files over 2 MiB. It records file sizes, line counts, Dart class,
enum, mixin and provider names. Symbols are regex hints, not a full Dart parser.
Use `scripts/audit_assets.py` and `lib/assets_manifest.dart` for asset inventory.

For a long editing session, opt in to a foreground watcher:

```bash
bash .agents/sidecars/codebase-index-daemon/run_daemon.sh --watch --interval 5
bash .agents/sidecars/test-daemon/run_daemon.sh --watch test/unit/topic_pack_test.dart
```

Both sidecars default to one invocation without `--watch`, resolve the repository
from their own location, and support `--root /path/to/checkout`. Watchers are
explicitly opt-in in the descriptive `sidecar.json` manifests; a host must run
them from the repository root. They do not auto-start at session start. Stop with
Ctrl-C or SIGTERM. POSIX locks in ignored `.agents/cache/` prevent duplicate
instances of each sidecar; process exit releases the lock. Indexer cache files
are replaced atomically. Tests run serially after `lib/`, `test/`, pubspec or
analyzer configuration changes, with a five-minute timeout per run plus up to
five seconds for shutdown; `--timeout` adjusts it. A later edit during testing
schedules one further run. No tests are launched merely by indexing.
