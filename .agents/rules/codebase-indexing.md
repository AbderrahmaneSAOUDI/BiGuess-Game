---
trigger: always_on
description: Fast codebase navigation using the background sidecar index cache.
---

# Codebase Indexing & Cache Utilization

## 1. Primary Cache Location
The continuous background indexer maintains:
- **JSON Index**: [codebase_index.json](file:///.agents/cache/codebase_index.json)
  Contains file metadata: path, extension, line count, byte size, and exported classes/symbols.
- **Markdown Architecture Summary**: [codebase_summary.md](file:///.agents/cache/codebase_summary.md)
  Contains architectural overview, module boundaries, lines of code, and key symbols per file.

## 2. Fast Lookup Workflow
1. **Check Cache First**: Consult `.agents/cache/codebase_index.json` or `.agents/cache/codebase_summary.md` before executing expensive recursive directory scans.
2. **Instant Symbol Resolution**: Search for classes, models, widgets, or providers directly in the JSON index.
3. **Manual Index Refresh**: If net-new files were just added and an immediate refresh is required:
   ```bash
   python3 .agents/sidecars/codebase-index-daemon/indexer_daemon.py --once
   ```
