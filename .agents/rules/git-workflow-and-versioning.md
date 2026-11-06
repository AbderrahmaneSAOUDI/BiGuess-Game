---
trigger: always_on
description: Date-based synchronized versions, scoped commits, and required Git completion.
---

# Version and Git lifecycle

- Snapshot status/index at task start and recheck before committing: this checkout can change concurrently. Preserve unrelated edits and pre-staged files rather than clearing or committing them.
- After substantive edits, required Flutter tests must pass. Run `python3 .agents/hooks/version_increment.py` once at completion; it computes the date minor from `2025-05-27` in Africa/Algiers and a patch/build beyond HEAD. Repeated calls before a commit are idempotent; all three files are repaired even if pubspec already has the target version.
- The triad is pubspec `version: major.minor.patch+build`, manifest `latest_version` and `build_number`, and `AppConstants.defaultVersion` without build. Preserve other manifest metadata. Invalid input must fail before any writes.
- Use the `git-commit-push` skill and helper with explicit `--paths` for task-owned paths; inspect `--dry-run` first. Implicit version-triad entries include only version fields; explicitly selecting a version file or its parent directory includes its other edits too. Whole-workspace `--all` is for explicitly owned complete work only.
- Commit subject: `<version> - <type>(<scope>): <imperative summary>`; allowed types: feat, fix, refactor, perf, test, docs, chore, style, ci.
- Complete the authorized commit and ordinary push to the current branch. Do not retry a rejected push by force, reset, rebase, or sweeping in someone else's changes. Report the actual outcome.
- Hooks observe edits and report drift; they do not bump on arbitrary tools, commit, publish, or launch daemons. Completion performs the mandatory version/Git lifecycle explicitly to avoid races between parallel edits.
