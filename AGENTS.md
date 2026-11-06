# BiGuess agent guide

BiGuess is a Flutter/Dart face-to-face guessing game using Riverpod 2.x, Material 3, bundled character assets, and optional Android hybrid updates. Core gameplay must work entirely offline.

## Start here

1. Inspect `git status --short`; preserve existing staged and unstaged work. Multiple sessions may share this checkout.
2. Read [.agents/README.md](.agents/README.md) for skill routing and automation. Read the relevant linked rules before editing their area; these Markdown rules are project instructions even when the host does not discover them automatically.
3. Consult the [source map](.agents/sidecars/file-map.md), [architecture](.agents/sidecars/architecture.md), and [test map](.agents/sidecars/test-map.md). Follow the [navigation](.agents/rules/codebase-indexing.md) and [execution](.agents/rules/speed-and-efficiency.md) rules. Use `rg` for direct searches; the generated index is an optional navigation cache, never the source of truth.
4. For migration work read [approved decisions](docs/migration/DECISIONS.md) and the relevant [blueprint](BIGUESS_PRODUCT_BLUEPRINT.md) section. The blueprint and historical dossiers include future designs, not just implemented features.

## Current ownership

| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | Flutter initialization, ProviderScope, themes, TopicsScreen |
| `lib/data/`, `lib/assets_manifest.dart` | Local Pack files/private images, SQLite installed snapshots, legacy manifest adapter and bundled `topicPackAssets` |
| `lib/domain/` | Canonical content models, Card deck, game configuration/session snapshots, legacy round and update models |
| `lib/providers/` | GameSessionNotifier, Pack selection/entitlements, legacy GameRoundNotifier, settings/theme/content providers |
| `lib/presentation/` | Topic → Pack → setup → identity/completion navigation, local image loader, legacy reveal and info/update dialogs |
| `lib/services/` | Version/APK/Shorebird adapters; separate optional CloudDatabaseService |
| `lib/core/` | AppConstants, themes, asset labels, URL helpers |
| `assets/` | Bundled character and flag images, logos, fonts, profile images |
| `backend/biguess-api/` | Cloudflare Worker/D1 game-record scaffold, not the planned content API |
| `scripts/`, `test/`, `.github/` | Asset/release tools, Flutter verification, CI |
| `.agents/`, `.codex/hooks.json` | Shared guidance, tools, optional sidecars, Codex hook entrypoint |

Current content entities are `Topic`, `Pack`, `Card`, and `Difficulty`; gameplay uses `GameSessionNotifier` and `CardSelectionEngine`. The legacy `GameRoundNotifier` / `SelectCharacterUseCase` path remains for rollback. There is no `Character`, `TopicPack`, or `GameController` class. Check declarations before introducing target-design abstractions. Historical copies under `old-lib/`, `old-test/`, and `ChatGPT/` are not active application source.

## Required invariants

- Implement only the requested behavior/copy; do not implement blueprint backlog or incidental app improvements. See [scope](.agents/rules/strict-scope-and-additions.md).
- Keep selection, countdown, and reveal independent of network calls. See [architecture](.agents/rules/game-standards-and-architecture.md).
- Use const constructors where possible and dedicated widgets for complex subtrees. After an async gap, check the owning `mounted`/`context.mounted` before UI access. Dispose owned controllers, focus nodes, subscriptions, and timers. See [quality](.agents/rules/code-quality-and-safety.md).
- Regenerate the asset manifest from disk and preserve names/case/Unicode and bundle registration. See the `topic-pack-maintenance` skill.
- Keep `pubspec.yaml`, `version.json`, and `AppConstants.defaultVersion` synchronized. Preserve native-change and release metadata. See [versioning](.agents/rules/git-workflow-and-versioning.md) and [releases](.agents/rules/release-automation.md).

## Verification and completion

```bash
flutter test
flutter analyze
python3 .agents/scripts/validate_setup.py
python3 -m unittest discover -s .agents/tests -v
```

Choose additional checks from the test map. Record pre-existing failures separately from regressions; do not claim a passing gate when its exit code failed.

After substantive edits and successful required tests, run `.agents/hooks/version_increment.py` (minor = elapsed days since `2025-05-27` in Africa/Algiers), then the scoped Git helper:

```bash
python3 .agents/hooks/version_increment.py
python3 .agents/hooks/git_auto_commit_push.py "chore(agents): describe the change" --paths <task-paths>
```

The helper includes version fields automatically. Inspect its `--dry-run` plan first; select only task-owned paths. Existing authorization for this lifecycle applies without another confirmation. Do not use whole-workspace staging for unrelated work. Stop on test/Git errors, report the cause, and never force-push. This lifecycle does not request APK/OTA publishing or backend deployment.
