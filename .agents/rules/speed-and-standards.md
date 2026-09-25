---
trigger: always_on
---

# Antigravity Rule: High Speed & Quality Guidelines for BiGuess-Game

Applies to all interactions and coding tasks within `BiGuess-Game`.

---

## 1. High Speed Execution
- **Parallel Tool Batching**: When reading or searching multiple files, emit tool calls concurrently in the same turn rather than executing one at a time.
- **Read Files in Full**: Use `view_file` to read relevant files in one shot. Never arbitrarily fragment file reads into tiny line slices.
- **Surgical Edits**: Use `replace_file_content` with precise context windows for clean, direct edits.
- **Selective Verification**: Run `flutter analyze lib/path/to/file.dart` or specific test files (`flutter test test/specific_test.dart`) instead of running full project rebuilds for simple changes.

## 2. Project Architecture
- State & game logic: encapsulated in controllers/providers or dedicated state managers.
- UI components: modular widgets located under `lib/` components/widgets.
- Version triad: follow `release-automation.md` for version updates.
