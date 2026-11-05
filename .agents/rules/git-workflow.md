---
trigger: always_on
description: Git branching, commit conventions, and repository hygiene.
---

# Git Workflow & Commit Standards

## 1. Branching Convention
- Feature branches: `feat/<short-description>`
- Bugfix branches: `fix/<issue-description>`
- Maintenance branches: `chore/<task-name>`
- Release branches: `release/v<version>`

## 2. Commit Message Structure
Use the Conventional Commits specification:
```text
<type>(<scope>): <short imperative summary>

[optional body explaining WHY, not what]

[optional footer(s)]
```
- Allowed types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `style`, `ci`.
- Scope is optional but encouraged (e.g. `feat(auth):`, `fix(ui):`).
- Keep the subject line under 72 characters, lowercase, no trailing period.

## 3. Clean Workspace Hygiene
- Never stage temporary test files, logs, or unneeded OS/IDE files (`.DS_Store`, `Thumbs.db`, `.idea`, `.vscode`).
- Keep `.gitignore` updated with project-specific build artifacts.
