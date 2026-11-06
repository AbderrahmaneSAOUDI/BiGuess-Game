---
name: create-hook
description: Add or change a repository-local BiGuess lifecycle hook and verify its JSON contract and side effects.
---

# Maintain a BiGuess hook

Read `.agents/README.md` and the existing event handler before editing. Keep scripts in `.agents/hooks/`, register in `.agents/hooks.json`, and preserve `.codex/hooks.json` as its relative symlink. Use the current native Codex event/group schema (`SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`); check official host documentation when adding a new event instead of copying a different host's schema.

Reuse `hook_common` for root resolution, bounded Git queries, stdin handling, and context output. Modern inputs use `tool_name` and `tool_input`; preserve supported legacy shapes only where needed. Return event-supported JSON only, send diagnostics to stderr, and use explicit short timeouts. Do not emit an allow permission that overrides the host's normal approval logic.

Session/edit/stop handlers are read-only and bounded. Keep tests, versions, Git synchronization, publishing, and persistent daemons in explicit workflows. A stop hook should report evidence without trapping the agent in a dirty-tree loop. A shell guard is a narrow heuristic, not a complete parser or sandbox.

Add fixture tests under `.agents/tests/` for the actual event shape, safe and denied cases, malformed input, exit status, and filesystem side effects. Run setup validation and the automation suite from `.agents/README.md`. Make executable entrypoints executable. In a host with hook UI/logs, verify the event actually fires; otherwise report that activation remains unverified.
