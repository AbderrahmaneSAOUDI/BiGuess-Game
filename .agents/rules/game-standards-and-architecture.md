---
trigger: always_on
description: Preserve offline gameplay, current layer ownership, and the bundled content contract.
---

# Game architecture

- Keep round selection/reveal entirely local. `GameRoundNotifier` owns state/timers; `SelectCharacterUseCase` owns random/deck selection; widgets render and dispatch. Do not introduce HTTP, database writes, or per-card validation into that path.
- `gameRoundProvider` is an auto-disposed family keyed by topic/pack. Preserve timer cancellation, duplicate-tap handling, pool exhaustion/refill, hint reset, and empty packs when changing it.
- Bundled `topicPackAssets` feeds `TopicPackDataSource` and content providers. Filenames supply display names, so renames affect gameplay labels. Regenerate with `scripts/generate_manifest.py` and synchronize pubspec; do not hand-edit generated lists.
- Prefer optimized WebP for new character artwork and audit sizes; existing PNG flags and supported formats remain valid. Do not blindly convert or rename an existing pack.
- Keep platform/network adapters in services and UI orchestration in presentation controllers. Current domain selection imports a Flutter-dependent asset utility; do not assume all domain files are already pure Dart.
- CloudDatabaseService is an unused record client scaffold. The blueprint's downloadable packs, stable Cards, Studio, difficulty/session rules, and synchronization are target work, implemented only by an authorized ticket.

See [current architecture](../sidecars/architecture.md), [integrations](../sidecars/integrations.md), and `docs/migration/DECISIONS.md` before crossing a boundary.
