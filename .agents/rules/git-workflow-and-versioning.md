---
trigger: always_on
description: Mandatory semantic patch versioning, commit message structure, and automated remote git push for BiGuess.
---

# Git Workflow & Versioning

## 1. Mandatory Date-Based Semantic Versioning
- BiGuess project inception date: **2025-05-27** (`BASE_DATE`).
- Every substantive change to code, components, styles, or configuration MUST bump the version according to:
  - **Major**: `1` (stable release track)
  - **Minor**: elapsed days since project inception: `floor((Current Date - 2025-05-27) in days)`.
  - **Patch**: incremental patch / commit number (incremented with every commit).
  - **Build Number**: auto-incrementing integer appended to pubspec (`+<build>`).

## 2. Version File Triad
Three files must always stay in sync:
1. **`pubspec.yaml`** — `version: 1.<minor>.<patch>+<build>` (single source of truth).
2. **`version.json`** — remote OTA update manifest served to in-app updater.
3. **`lib/core/constants/app_constants.dart`** — `defaultVersion = '1.<minor>.<patch>';`.

Handled automatically via `.agents/hooks/version_increment.py` on `postToolUse`, or directly via `python3 .agents/hooks/git_auto_commit_push.py`.

## 3. Commit Message Structure
- Every commit MUST follow the semantic versioned format:
  ```text
  <version> - <type>(<scope>): <short imperative summary>
  ```
  or for general changes:
  ```text
  <version> - <type>: <short imperative summary>
  ```
- Allowed types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `style`, `ci`.
- Examples:
  - `1.527.59 - feat(rules): add project operational rules, hooks, sidecars, and skills`
  - `1.527.60 - fix(game): resolve character selection overflow on compact mobile devices`
  - `1.527.61 - perf(assets): compress anime card images to high-efficiency webp`

## 4. Mandatory End-of-Turn Git Push
- Before completing any prompt turn with substantive changes:
  1. Verify tests with `flutter test`.
  2. Run the automated git assistant:
     ```bash
     python3 .agents/hooks/git_auto_commit_push.py "feat: description here"
     ```
  3. Ensure the remote repository is always synchronized with the latest working tree.
