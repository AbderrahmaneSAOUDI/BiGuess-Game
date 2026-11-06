---
name: agent-maintenance
description: Maintain BiGuess agent instructions, skills, rules, lifecycle hooks, setup validation, architecture maps, and opt-in sidecars. Use when changing the development automation or refreshing project guidance after architectural changes.
---

# Agent maintenance workflow

1. Read root `AGENTS.md` and `.agents/README.md`; inspect `git status --short` and preserve other sessions' work. Consult the relevant `create-skill`, `create-rule`, or `create-hook` playbook before editing its artifact.
2. Confirm claims in current source and manifests. Use `.agents/sidecars/file-map.md` for entry points; distinguish implemented behavior from approved target contracts and dated baseline evidence. Update the smallest affected map rather than copying a second backlog, fixed inventory counts, or old command results.
3. Keep root guidance short, persistent rules focused on invariants, and skills procedural with clear activation descriptions. Use relative links that resolve from the document. Keep generated indexes under ignored `.agents/cache/`; never treat the cache as authoritative.
4. Preserve canonical `.agents/hooks.json` and its `.codex/hooks.json` symlink. Validate hook event names, stdin/output contracts, timeouts, read-only automatic checks, and tests. Automatic hooks must not stage changes, publish, build, bump versions, or start background processes. Explicit lifecycle scripts remain separate. Read current host documentation if changing its integration format.
5. Keep sidecars opt-in and stoppable. Exercise bounded `--once` paths and verify launcher/manifest arguments; do not leave daemons running after verification. Retain serial test execution and ignored runtime cache/log/PID artifacts.
6. Run from the repository root:

   ```bash
   python3 .agents/scripts/validate_setup.py
   python3 -m unittest discover -s .agents/tests -v
   ```

   The validator only reads files and compiles Python in memory; it never executes project hooks, Git, versioning, Flutter, or daemons. Unit tests exercise temporary repositories/fixtures. For shell changes run `bash -n` on affected launchers. When available, the system skill creator's `scripts/quick_validate.py` is an additional skill-format check; it is not required by the stdlib validator.
7. Review tests, links, and the scoped diff. Run the root-required Flutter gate and explicit version/Git lifecycle before completion. Report checks and remaining limitations; do not claim host hook activation until a fresh trusted session actually loads it.
