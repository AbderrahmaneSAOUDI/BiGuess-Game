---
name: topic-pack-maintenance
description: Add, rename, remove, inspect, or optimize BiGuess topics, packs, and bundled character images while keeping the generated manifest and Flutter asset registration synchronized.
---

# Maintain topics and packs

Run commands from the repository root. Read `scripts/generate_manifest.py` when changing the asset schema; `lib/assets_manifest.dart` is generated output.

## Inspect before changing

```bash
python3 scripts/manage_topics.py list
python3 scripts/generate_manifest.py --check
```

- Disk layout is `assets/images/<Topic>/<Pack>/<Display Name>.webp`. Names, spaces, case, and accents become lookup keys and displayed character names; preserve them deliberately.
- `TopicPackDataSource` reads the static `topicPackAssets` map. `topicsProvider`, `packsProvider`, and `packAssetsProvider` expose it to the screens. A folder alone does not make content available in a built app.
- The generator scans files directly inside each pack, ignores hidden entries, accepts WebP/PNG/JPG/JPEG, and normalizes filename strings to NFC. Prefer the project's WebP format and ensure actual disk names match NFC strings.

## Apply the requested content change

For a requested new pack, substitute the actual names:

```bash
python3 scripts/manage_topics.py create-pack "Topic" "Pack"
```

`create-pack` creates its parent topic if absent. It immediately regenerates the manifest and pubspec assets. A topic with no pack is omitted by the generator. Add the requested image files, then regenerate again:

```bash
python3 scripts/generate_manifest.py --sync-pubspec
```

For renames/deletions, inspect `python3 scripts/manage_topics.py --help` and the corresponding subcommand help. A rename also changes game route/provider keys. Delete only the content explicitly requested.

For optimization, Pillow is required. Scope the target to the requested pack and preview conversions:

```bash
python3 scripts/convert_and_optimize.py "assets/images/Topic/Pack" --dry-run
```

Remove `--dry-run` only to apply the requested conversion. Originals remain unless `--delete-original` is supplied; leaving both formats creates separate cards. Avoid converting the whole catalog for a single-pack task. Regenerate after conversion or renaming.

## Verify

```bash
python3 scripts/generate_manifest.py --check
python3 scripts/audit_assets.py --max-size 50
flutter test test/unit/topic_pack_test.dart
```

Review the diff in `lib/assets_manifest.dart` and the `flutter.assets` section of `pubspec.yaml`. Check that font/logo/profile entries and `shorebird.yaml` survive. Run `flutter test` before completing substantive changes, per `AGENTS.md`.

The manifest check compares generated Dart only; `--check --sync-pubspec` does not validate pubspec. The auditor returns failure for missing/corrupt images, but oversized/orphan/naming findings still require reading the report. Without Pillow it skips image decoding. Preview empty packs and changed name labels in the app when relevant.

## Current script limitation

`normalize_filenames.py` previews renames by default and applies with `--apply`. Its `--sync-manifest` branch imports obsolete generator names. Until repaired, run normalization without that flag and regenerate separately with `generate_manifest.py --sync-pubspec`.
