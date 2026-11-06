---
trigger: always_on
description: Preserve offline gameplay, current layer ownership, and the bundled content contract.
---

# Game architecture

- Keep configured gameplay entirely local. `GameSessionNotifier` owns transitions and an immutable content/configuration snapshot; `CardSelectionEngine` owns cumulative-difficulty, non-repeating Card-ID draws. Widgets render and dispatch. Do not introduce HTTP, database writes, repository reads or eligibility revalidation into session/deck transitions after Start. Image loading may verify local bytes in the data/presentation layer.
- The legacy `gameRoundProvider` remains an auto-disposed family keyed by topic/pack. Preserve timer cancellation, duplicate-tap handling, pool exhaustion/refill, hint reset, and empty packs when changing `GameRoundNotifier` / `SelectCharacterUseCase`.
- `contentRepositoryProvider` supplies verified local SQLite content or the bundled legacy adapter. Use stable IDs for configured selection/navigation; display names may repeat. Bundled `topicPackAssets` feeds `TopicPackDataSource`; filenames still supply legacy names. Regenerate with `scripts/generate_manifest.py` and synchronize pubspec; do not hand-edit generated lists.
- Prefer optimized WebP for new artwork and audit sizes; preserve the generator's supported PNG/JPG/JPEG formats. Do not blindly convert or rename an existing pack. Keep installed image generations available until active snapshots finish.
- Keep platform/network adapters in services and UI orchestration in presentation controllers. Current domain selection imports a Flutter-dependent asset utility; do not assume all domain files are already pure Dart.
- CloudDatabaseService is an unused record client scaffold. Local Pack import, canonical Cards, difficulty and sessions exist; the public catalog, Studio and remote synchronization remain future tickets. Preserve the bundled rollback path until its retirement gate.

See [current architecture](../sidecars/architecture.md), [integrations](../sidecars/integrations.md), and `docs/migration/DECISIONS.md` before crossing a boundary.
