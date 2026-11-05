---
name: create-hook
description: Standardized guide to implementing, registering, and testing lifecycle hooks in .agents/hooks/.
---

# Create Hook Runbook

## 1. Directory & Registration
- Place the hook script in `.agents/hooks/<hook_name>.py` (or `.sh`).
- Register it in `.agents/hooks.json` under the appropriate lifecycle event:
  - `sessionStart`: Pre-invocation context initialization.
  - `preToolUse`: Security and invariant validation before tool calls.
  - `postToolUse`: State synchronization and version bumping after tool calls.
  - `stop`: Post-execution integrity verification.

## 2. Invariants
- All hooks must be non-blocking with explicit timeout limits.
- Must accept stdin JSON payloads and return valid JSON output to stdout.
