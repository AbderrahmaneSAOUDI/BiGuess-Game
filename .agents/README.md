# BiGuess development tooling

[AGENTS.md](../AGENTS.md) is the entrypoint. The files here capture current source ownership and reusable development workflows; they do not implement the future product blueprint. Keep guidance in the repository so a fresh session can discover it.

## Choose the relevant skill

| Task | Skill |
| --- | --- |
| Implement requested Flutter behavior | [feature-development](skills/feature-development/SKILL.md) |
| Reproduce and fix a bug | [debugging](skills/debugging/SKILL.md) |
| Add or maintain bundled content | [topic-pack-maintenance](skills/topic-pack-maintenance/SKILL.md) |
| Work on the Worker/D1 record API | [backend-development](skills/backend-development/SKILL.md) |
| Update delivery or a requested release | [biguess-ota-release](skills/biguess-ota-release/SKILL.md) |
| Complete the required scoped Git sync | [git-commit-push](skills/git-commit-push/SKILL.md) |
| Find code with the optional index | [codebase-indexer](skills/codebase-indexer/SKILL.md) |
| Maintain this setup | [agent-maintenance](skills/agent-maintenance/SKILL.md) |
| Author a specific instruction or hook | [create-skill](skills/create-skill/SKILL.md), [create-rule](skills/create-rule/SKILL.md), [create-hook](skills/create-hook/SKILL.md) |

Read only the needed skill and supporting map. Skills use `SKILL.md` frontmatter; rules are explicitly linked from AGENTS.md so behavior does not depend on proprietary rule discovery.

## Maps and source authority

- [File map](sidecars/file-map.md): active modules and developer commands.
- [Architecture](sidecars/architecture.md): startup, state, offline selection, and update boundaries.
- [Test map](sidecars/test-map.md): existing coverage and its practical limits.
- [Integrations](sidecars/integrations.md): asset generation, record API, and hybrid releases.
- [Known issues](sidecars/known-issues.md): source-backed limitations; reverify before fixing.
- [Roadmap navigation](sidecars/roadmap-status.md): approved migration documents and implemented/target distinction.

These Markdown sidecars are maintained knowledge. The JSON/Markdown index under `.agents/cache/` is generated and disposable. Verify mutable claims in source; avoid baking current versions, inventory totals, test counts, or deployment health into rules.

## Lifecycle hooks

[hooks.json](hooks.json) is the single configuration source. [The native Codex entrypoint](../.codex/hooks.json) is a relative symlink to it. The setup follows the [official OpenAI hooks schema](https://learn.chatgpt.com/docs/hooks); project hook execution depends on the host loading and trusting the project layer. Hook trust and live event dispatch must be checked in that host; local script tests alone cannot prove activation. No user-level configuration is modified.

| Event | Script | Behavior |
| --- | --- | --- |
| SessionStart | `hooks/session_start.py` | Brief branch/dirty-tree snapshot, source routing, version drift |
| PreToolUse (shell) | `hooks/dangerous_command_guard.py` | Deny obvious destructive directory/manifest deletion, hard reset, primary-branch force push, disk overwrite |
| PostToolUse (file edits) | `hooks/project_check.py` | Read-only version-triad diagnostics |
| Stop | `hooks/stop_guard.py` | Advisory drift/dirty-tree context; no continuation loop |

Scripts read JSON on stdin and emit JSON on stdout, use bounded subprocesses, and resolve paths from their own location. A safe shell operation returns no permission override. The guard is a best-effort check, not a shell parser or security sandbox. It cannot prove arbitrary shell scripts safe.

Hooks never run Flutter tests, bump versions, commit/push, deploy, or spawn watchers. After validation, completion explicitly runs `version_increment.py` and the scoped Git helper as required by AGENTS.md. This keeps parallel file edits from racing to bump shared version files. Compatibility shell launchers remain available for hosts that call the scripts directly.

## Optional process sidecars

Both `sidecar.json` manifests are disabled by default and describe local launch commands; Codex does not automatically discover a `.agents/sidecars/` process manager. Start only the process needed for the task. Run from the repository root:

```bash
# Generate a current source/symbol cache and exit.
python3 .agents/sidecars/codebase-index-daemon/indexer_daemon.py --once

# Optional foreground indexing; Ctrl-C stops it.
bash .agents/sidecars/codebase-index-daemon/run_daemon.sh --watch

# Run tests once, or watch only the relevant test target.
bash .agents/sidecars/test-daemon/run_daemon.sh --once test/unit/topic_pack_test.dart
bash .agents/sidecars/test-daemon/run_daemon.sh --watch test/unit/topic_pack_test.dart
```

Watchers hold per-checkout locks, avoid overlapping their own runs, and handle termination. The index includes active application/tooling/platform trees, CI configuration, and migration documents. The test watcher runs serially with a timeout; coordinate with other sessions before starting additional Flutter jobs. Runtime cache, logs, bytecode, and locks stay untracked. Process locking uses POSIX `fcntl`, matching the Linux development environment; Windows needs WSL or a port of that lock implementation.

## Validate changes to this system

```bash
python3 .agents/scripts/validate_setup.py
python3 -m unittest discover -s .agents/tests -v
python3 .agents/hooks/project_check.py --check
```

The validator checks configuration, references, and Python syntax without editing files or invoking lifecycle hooks. Automation tests use temporary fixture trees and Git repositories. They do not contact production services. Run the Flutter gates required by AGENTS.md for completion; source-map edits also need reference checks. For manual hook smoke tests pass JSON via stdin, for example `printf '{}' | python3 .agents/hooks/session_start.py`.

Keep app fixes, release publishing, remote schema application, and global agent settings out of a tooling-only change unless the user requests them.
