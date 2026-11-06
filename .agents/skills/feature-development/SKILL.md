---
name: feature-development
description: Implement a requested BiGuess feature or migration ticket using the existing Flutter/Riverpod layers, approved contracts, and focused verification. Use for new gameplay, content, settings, service, or screen behavior.
---

# BiGuess feature workflow

1. Read root `AGENTS.md`, then `git status --short`. Preserve existing user changes. For a numbered ticket, read its acceptance criteria in `TODO.md`, relevant `docs/migration/DECISIONS.md` contracts, and needed blueprint sections. Implement the requested ticket; do not automatically begin the next one or bypass human gates.
2. Consult `.agents/sidecars/file-map.md`, `architecture.md`, and `test-map.md`; confirm symbols in source. Current code uses `GameRoundNotifier`, image-path pools, and generated `topicPackAssets`. Canonical Card/session/storage APIs are targets until implemented.
3. Define the smallest acceptance condition and its owner: selection/value behavior in `lib/domain/`, round/settings state in `lib/providers/`, content access in `lib/data/`, IO in `lib/services/`, update orchestration in `lib/presentation/controllers/`, widgets/screens in `lib/presentation/`. Reuse existing widgets/providers and snake_case filenames; do not invent naming prefixes or scaffolding layers.
4. Implement required layers only. Keep gameplay local and offline; preserve a playable flow during migration. Use const widgets where possible, dispose owned resources, guard async UI access, and cancel timers/subscriptions. Do not add settings, copy, calls, or dependencies without a requirement.
5. For assets, inspect `scripts/generate_manifest.py` before its write mode. Generate rather than hand-edit `lib/assets_manifest.dart`; include required `pubspec.yaml` registrations. Validate filename-derived names and retain sources unless deletion is authorized.
6. Verify using `.agents/sidecars/test-map.md`. Prefer seeded Random, provider overrides, and bounded animation pumping. Add tests for meaningful new behavior, then run `flutter test` and `flutter analyze` for Flutter work. Report actual results.
7. Review the scoped diff; follow root lifecycle/version guidance and git/release playbooks. Preserve unrelated work when staging. Report behavior, checks, and limitations. A feature request does not authorize cloud publication, deployment, or an unrelated roadmap migration.
