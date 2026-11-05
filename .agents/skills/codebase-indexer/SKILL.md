---
name: codebase-indexer
description: Rapid codebase navigation, symbol lookup, and repository mapping using the sidecar index cache. Use when you need to find where models, widgets, controllers, services, or assets are defined without expensive recursive directory scans.
---

# Codebase Indexer & Fast Symbol Search

Use this skill to inspect architecture, locate classes, and map Flutter components in milliseconds.

## 1. Primary Cache Location
The continuous background indexer maintains:
- **JSON Index**: [codebase_index.json](file:///.agents/cache/codebase_index.json)
  Contains file metadata: path, extension, line count, and exported symbols.
- **Markdown Architecture Summary**: [codebase_summary.md](file:///.agents/cache/codebase_summary.md)
  Contains architectural overview, module boundaries, lines of code, and key symbols per file.

## 2. Fast Lookup Procedure
1. **Check the cache first**:
   Instead of running `find` or searching the whole filesystem, check `.agents/cache/codebase_summary.md` or query `.agents/cache/codebase_index.json`.

2. **Instant Symbol Resolution**:
   To find where a class, model, or widget is defined:
   ```bash
   grep -B 2 -A 5 '"symbols":.*class:GameController' .agents/cache/codebase_index.json
   ```

3. **Manual Refresh**:
   If net-new files were just written and you need an immediate refresh:
   ```bash
   python3 .agents/sidecars/codebase-index-daemon/indexer_daemon.py --once
   ```
