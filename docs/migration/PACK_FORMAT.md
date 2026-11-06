# Full-Pack format v1 and offline exporter (T09)

This is the initial local interchange contract for a single complete Pack. It
follows [canonical content decisions](DECISIONS.md#2-decision-1--canonical-mvp-card-model)
and the blueprint's [canonical hierarchy](../../BIGUESS_PRODUCT_BLUEPRINT.md#4-phase-1--establish-the-canonical-content-model).
The exporter runs entirely offline. App installation, database activation,
downloads, deltas, signatures, and gameplay integration belong to later tickets.

## Container

A `.biguesspack` file is a ZIP containing exactly `manifest.json` and the image
objects listed in that manifest. It has no absolute paths, parent traversal,
directories, symlinks, external URLs, or additional entries. Objects are raw,
unmodified WebP, PNG, or JPEG files; they are not transcoded or encrypted.

Every Card resolves its `imageReference` to an included object. All names,
difficulties, relationships, and image bytes needed to construct a local playable
Pack are included; neither original source folders nor a server is needed after
export. This does not make the current Flutter app an importer (T10/T11).

## Manifest

The top-level object has exactly these required fields:

| Field | Contract |
| --- | --- |
| `schemaVersion` | Integer `1`; reject unknown versions and booleans. |
| `kind` | Literal `"full"`; no patch/delta semantics. |
| `topic` | Object with `id`, `name`. |
| `pack` | Object with `id`, `topicId`, `name`, `revision`. `topicId` must equal the included Topic ID; `revision` is an explicit positive integer. |
| `cards` | At least two distinct Card records, sorted by `id`. |
| `objects` | Distinct image object records, sorted by `key`. |
| `provenance` | Export mode and rights declarations, separate from gameplay metadata. |

IDs are opaque, case-sensitive, nonempty UTF-8 strings without whitespace or
control characters. Names are nonempty, trimmed UTF-8 strings without control
characters. Preserve case and Unicode exactly; do not normalize IDs or names.
Topic/Pack identity is supplied by the source, never inferred from array order.
The exporter requires strict field sets and rejects duplicate JSON object keys.

Each Card has exactly the canonical model's technical ID and four product fields:

| Field | Contract |
| --- | --- |
| `id` | Unique Card ID within this Pack. |
| `packId` | Exactly the included Pack ID. |
| `name` | Display name. |
| `imageReference` | Exact object key, such as `objects/<sha256>.webp`. |
| `difficulty` | Integer `1`, `2`, or `3`; booleans/floats are invalid. |

Each image object has exactly these fields:

| Field | Contract |
| --- | --- |
| `key` | `objects/<sha256>.<extension>`; extension is `webp`, `png`, or `jpg`, determined from actual decoded encoding. |
| `sha256` | Lowercase 64-character hex SHA-256 of the original image bytes. |
| `sizeBytes` | Positive integer length of those bytes. |
| `mediaType` | `image/webp`, `image/png`, or `image/jpeg`, matching encoding. |

The set of Card image references, object keys, and archived image entries must
be identical. Identical bytes may be shared by several distinct Cards; duplicate
Card IDs and duplicate object rows fail validation. Duplicate display names are
allowed because they are not identity. Hashes, sizes, and actual image decoding
must validate; empty, missing, corrupt, animated, and mislabeled images fail.
No arbitrary image/Pack size cap is introduced: the blueprint's normal size
targets remain engineering targets rather than new product rules.

## Provenance and source inputs

`provenance` contains exactly `mode`, `packRights`, and `cardRights`.

For `mode: "cleared-test"`, `packRights` contains exactly `rights_status:
"cleared"`, `permission_to_publish: true`, `public_test_publishable: true`,
and nonempty `source`, `license`, `attribution` strings. `cardRights` is an array
sorted by Card `id`; every included Card has exactly one record with `id` and
the same six rights fields. Its declarations may differ from the Pack's and are
preserved verbatim. Missing clearance on either the Pack or any Card fails the
entire export. These declarations record source evidence; hashing and decoding
alone do not establish permission to publish.

The `fixture` command consumes a fixture `pack.json` with:

- `schema_version: "1.0.0"`.
- `topic: {id, name}`.
- `pack: {id, name, ...six rights fields}`; an optional input `description` is
  accepted for existing fixtures but is not exported as gameplay metadata.
- `cards: [{id, pack_id, name, image, difficulty, ...six rights fields}]`.

Image paths are relative to `pack.json`'s directory. Parent traversal, absolute
paths, backslashes, and symlinks escaping that directory are rejected. Only
referenced images are included. The existing internally authored Shapes fixture
uses this input layout; the exporter does not depend on the inventory script.

For `mode: "legacy-development"`, `packRights` is exactly
`{"rights_status":"unverified","permission_to_publish":false,"public_test_publishable":false}`
and `cardRights` is empty. The command requires `--development-only`; this output
must be excluded from public test publishing. The flag does not bypass validation
and cannot upgrade rights.

Legacy input scans only the selected `assets/images/<Topic>/<Pack>/` folder's
direct nonhidden WebP/PNG/JPG/JPEG entries. Names come from filename stems and
difficulty defaults to `1`, matching the current adapter. IDs encode source keys
with Dart `Uri.encodeComponent` escaping:

```text
topic: legacy:topic:<encoded topic>
pack:  legacy:pack:<encoded topic>:<encoded pack>
card:  legacy:card:<encoded topic>:<encoded pack>:<encoded asset path>
```

These are temporary migration IDs: renaming/moving source assets requires an
explicit identity mapping. They are not the inventory's proposed UUIDs and do
not assign production identities or alter source assets. A source Pack is not
silently skipped if it has missing, invalid, or insufficient image records.

## Determinism and integrity

The canonical manifest encoding is UTF-8 JSON with sorted object keys, no ASCII
escaping, no spaces between tokens, and one final LF. Arrays use the ordering
above. Non-JSON constants (`NaN`, infinities) are invalid. There are no timestamps,
local absolute paths, randomly generated IDs, or embedded self-hashes.

ZIP entries are sorted lexicographically by name, use `ZIP_STORED` (no compressor
version variability), timestamp `1980-01-01 00:00:00`, Unix regular-file mode
`0644`, creator system `3`, and no extra fields or comments. The archive has no
directory entries. Source mtime, directory traversal order, input JSON key order,
Card array order, and output location do not affect the output bytes.

The CLI prints `manifestSha256` over canonical `manifest.json`, `archiveSha256`
over the complete archive, and archive `sizeBytes`. These hashes stay external to
avoid a circular digest. Equivalent source metadata, revision, and image bytes
produce identical manifest/archive hashes. A changed revision, Card field, rights
declaration, or image changes the applicable digest. Checksums detect corruption;
they do not authenticate a publisher.

## Commands and verification

Use Python 3.11+ and Pillow (CI pins `Pillow==12.3.0`). Image validation fails
closed if Pillow is unavailable; there are no network calls or optional decode
shortcuts. Choose a fresh output path; existing outputs are never overwritten.
Input validation finishes before any output is created.

```bash
python3 scripts/export_pack.py fixture test/fixtures/cleared_shapes/pack.json \
  --revision 1 --output build/packs/shapes.biguesspack

python3 scripts/export_pack.py legacy Anime "One Piece" --development-only \
  --revision 1 --output build/packs/legacy-one-piece.biguesspack

python3 -m unittest discover -s .agents/tests -p test_pack_export.py -v
```

The tests author temporary PNG fixtures themselves and do not need legacy assets
or uncommitted inventory outputs. They check byte-identical archives across input
ordering, mtimes and source locations; offline completeness; revisions and
metadata/image changes; shared-image deduplication; malformed/duplicate/missing
records; broken relations; rights gates; corrupt and tampered images; path
escapes; explicit legacy opt-in; reported hashes and source/output preservation.
They also run in the existing CI tooling test discovery.
