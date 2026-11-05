---
trigger: always_on
description: Universal high-speed agent execution, parallel tool use, zero polling, and low-latency workflows.
---

# Agent Speed & Execution Efficiency

## 1. Parallel Tool Calling & Batching
- **Simultaneous Lookups**: When multiple files, directories, or symbols need inspection, emit all `read_file` or search calls concurrently in the SAME turn. Never inspect files sequentially across multiple turns.
- **Strict Prohibition on Re-Reading**: Once a file has been read in the conversation trajectory, NEVER call `read_file` on it again. Its content is already in context.
- **No Self-Verification Re-Reads**: Do NOT call `read_file` immediately after editing a file to "verify" the edit. Trust your editor tool output unless a compiler error explicitly indicates the file failed to update.

## 2. Single-Pass Batch Editing
- Plan all necessary file changes upfront across the codebase and apply them in a single batch turn using `write_file` or `edit_file`.
- Avoid making tiny 2-line edits followed by immediate re-reads and questions.

## 3. Zero-Polling Policy
- NEVER poll background task status in a loop (e.g. repeatedly calling `manage_task(Action='status')`).
- Background commands notify you automatically upon completion. Set `WaitMsBeforeAsync` appropriately (10000ms+) so fast commands finish synchronously.

## 4. Diagnostic Loop Breaker
- If the IDE or analyzer reports diagnostics/lints after an edit, fix all legitimate issues in ONE single batch pass.
- Do NOT enter multi-turn ping-pong loops over minor cosmetic or stylistic lints when the core implementation works.

## 5. Instant Index Utilization
- Always consult `.agents/cache/codebase_index.json` or `.agents/cache/codebase_summary.md` before searching across directories.
