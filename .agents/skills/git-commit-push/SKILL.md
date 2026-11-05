---
name: git-commit-push
description: Mandatory automated git workflow for BiGuess: increment patch version, stage modified files, commit with semantic version message, and push to remote. Use at the completion of substantive edits or when asked to commit and push changes.
---

# Git Commit & Push Workflow

Follow this procedure to guarantee that all work is tracked with semantic patch versioning, descriptive conventional commit messages, and synchronized to the remote git branch.

## 1. Automated Execution (Recommended)
Run the project git assistant directly:
```bash
python3 .agents/hooks/git_auto_commit_push.py "feat: your descriptive message"
```
Or with auto-detected category:
```bash
python3 .agents/hooks/git_auto_commit_push.py
```

This single command:
1. Detects substantive changes via `git status --porcelain`.
2. Calculates elapsed days since project inception (**2025-05-27**).
3. Increments the patch and build number in `pubspec.yaml`, `version.json`, and `app_constants.dart`.
4. Formats the commit message as `<version> - <type>: <description>`.
5. Executes `git add .`.
6. Executes `git commit -m "<version> - <type>: <description>"`.
7. Executes `git push origin <branch>`.

## 2. Invariants
- Never push with `--force` to `main` or `master`.
- Never commit broken code or failing tests.
- Always include the version prefix in the commit message.
