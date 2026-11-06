---
name: git-commit-push
description: Complete BiGuess work with a validated version-triad bump and a scoped commit/push that preserves unrelated staged and unstaged changes. Use after substantive edits or when asked to commit and push.
---

# Commit and push task-owned changes

Run `flutter test` before substantive completion, per `AGENTS.md`. Inspect `git status --short` and distinguish the task's files from existing work. The helper requires a conventional summary and explicit scope:

```bash
python3 .agents/hooks/git_auto_commit_push.py "chore(agents): update guidance" --paths AGENTS.md .agents --dry-run
python3 .agents/hooks/git_auto_commit_push.py "chore(agents): update guidance" --paths AGENTS.md .agents
```

Substitute actual task-owned paths. `--dry-run` performs read-only validation and prints the plan. `--no-push` commits locally when that is the requested scope. `--all` explicitly selects the entire worktree; use it only when all changes belong to the authorized task. There is no implicit blanket staging.

The helper uses an isolated Git index. Selected paths and all three version files must have no pre-existing staged changes; it refuses before mutation if they do. Unrelated staged blobs and unstaged work remain intact. Implicit version-triad entries are based on HEAD with **only version fields** replaced, so unrelated dependency/metadata/constants edits remain in the worktree. Explicitly selecting a version file, a containing directory, or `--all` includes its full worktree content with the synchronized version fields. Select those paths only when their other edits belong to this task. If selected paths have no tracked or untracked changes, the helper does nothing and does not bump the version.

Version synchronization validates the complete triad before preparing writes. It uses the Africa/Algiers date, elapsed days since `2025-05-27`, and HEAD patch/build + 1. Repeated calls before a commit remain idempotent; an explicitly prepared higher pubspec version/build is preserved. `--date YYYY-MM-DD` is available for deterministic verification. The helper prefixes the message with the resulting version and pushes the current branch to `origin`; it does not force-push, deploy, or create a release.

If validation, Git, or push fails, stop and report the actual error. A failed push can leave a valid local commit; retry the push after addressing the cause without creating another version bump. To sync versions without committing, use `python3 .agents/hooks/version_increment.py`; it acts when substantive changes exist and emits hook JSON.

Automation checks run in temporary repositories:

```bash
python3 -m unittest discover -s .agents/tests -p 'test_version_git.py'
```
