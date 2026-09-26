---
trigger: always_on
---

# Antigravity Rule: High Speed & Quality Guidelines for BiGuess-Game

Applies to all interactions and coding tasks within `BiGuess-Game`.

---

## 1. High Speed Execution
- **Parallel Tool Batching**: When reading or searching multiple files, emit tool calls concurrently in the same turn rather than executing one at a time.
- **Strict Prohibition on Re-Reading**: Once a file has been read in the conversation, DO NOT call `view_file` on it again. You already have it in context. Never re-read a file right after editing to "verify" it.
- **Atomic Batch Edits**: Group all edits across files into a single turn. Do not make micro 2-line edits followed by sequential checks.
- **Zero Polling**: Never poll `manage_task(Action='status')` in loops. The system wakes you up automatically upon task completion. Use sufficient `WaitMsBeforeAsync` (10000-15000ms) for tests and analyzers to complete synchronously.
- **Lint Loop Breaker**: Do not get trapped in multi-turn lint-fixing cycles. Fix all reported issues in ONE single batch pass.
- **Selective Verification**: Run `flutter analyze lib/path/to/file.dart` or specific test files (`flutter test test/specific_test.dart`) instead of running full project rebuilds for simple changes.
- **Subagent Delegation for Deep Audits**: When asked to audit, search all errors, or review features, delegate to a `research` subagent to preserve the main context speed.

## 2. Project Architecture
- State & game logic: encapsulated in controllers/providers or dedicated state managers.
- UI components: modular widgets located under `lib/` components/widgets.
- Version triad: follow `release-automation.md` for version updates.

