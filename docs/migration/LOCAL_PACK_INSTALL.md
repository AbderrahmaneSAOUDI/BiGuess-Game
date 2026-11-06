# T10 — Atomic local file installation

`LocalPackStore` imports the ZIP_STORED `.biguesspack` container defined by
[T09](PACK_FORMAT.md). It never accesses a network or mutates the bundled catalog.

```dart
final store = await LocalPackStore.openDefault();
final installed = await store.install(File(selectedPackPath));
// After restart, reopen the same private root:
final reopened = await store.readInstalled(installed.manifest.pack.id);
```

`openDefault()` uses application-support storage. Tests can supply a temporary
`Directory` to the constructor. The caller owns file selection and handles
validation errors (`FormatException`/`ArgumentError`) and `FileSystemException`
for storage failures. This ticket adds the import API; file-picker UI, image
widgets and the gameplay switch remain with later tickets.

## Validation and activation

1. Bound source reads and parse the complete ZIP directory. Require regular,
   unencrypted, uncompressed entries, consistent local/central headers, valid
   CRCs, unique safe object keys and exactly one manifest. Reject extra entries,
   traversal, symlinks, unsupported versions and duplicate JSON keys. Require the
   canonical JSON encoding specified by T09.
2. Validate strict record fields, canonical models, unique Card IDs, parent
   relations, the two-Card minimum, provenance and exact Card/object coverage.
   Verify every original image size and SHA-256, encoding/media type, successful
   decoding and single-frame status. No source directory is needed afterward.
3. Write images and metadata to a fresh temporary generation on the destination
   filesystem. Flush writes and verify their persisted bytes. Rename the completed
   directory, write/flush/read back a pending pointer, then atomically rename that
   pointer over `active`. This last rename publishes metadata and images together.
   No operation deletes or overwrites the previous active generation.
4. Reopen reads only the active pointer, validates metadata and hashes, and
   returns immutable Cards with opaque private image references. Selection can
   use this snapshot in memory; storage reads and integrity checks do not belong
   in the per-draw gameplay path.

T11 packages newly installed images in one private `images.bgpack` container;
older loose generations are still supported. Use `ContentImageLoader` to render
installed references rather than treating them as absolute file paths. See
[private storage, decode/cache bounds and benchmarks](PRIVATE_IMAGES.md).

The active generation's `manifest.json` is the installation metadata authority.
There is no dual commit between a filesystem pointer and the separate T08 catalog
SQLite database. A future catalog projection must derive from these committed
snapshots rather than mark a Pack installed independently before activation.

Identical metadata/image retries return the existing generation, after validating
all incoming bytes. Conflicting same-revision data, older revisions, Pack
reparenting and Card IDs owned by another installed Pack are rejected. Higher
revisions replace the full metadata/Card snapshot, including removed Cards.

Writers serialize across store instances and processes using an in-process queue
and an OS file lock. All writers within one process must use one owning Dart
isolate; POSIX advisory locks do not coordinate sibling isolates. Readers need no writer lock: they see an entire old or new
generation. Ordinary failures clean up staged files and preserve the active
pointer. Abandoned staging directories from a killed writer are ignored and
removed by the next staged install. Previously activated generations remain on
disk so existing game snapshots retain their image files. Generation reclamation
and broader download interruption management belong to T41/T43.

Atomicity relies on same-filesystem rename in native app-private storage. Tests
exercise Linux filesystem semantics and simulated write/rename failures. Flushed
files and atomic rename address app-process interruption; sudden device-power
loss and physical filesystem corruption are not a tested durability guarantee.

## Resource bounds and fixture evidence

`PackImportLimits` defaults to 256 MiB per input file and 16 megapixels per decoded
image. These configurable allocation safeguards are separate from product limits
and Free/Pro entitlement rules. ZIP_STORED means compressed archive expansion
cannot bypass the input bound. Images are decoded individually during validation.

`test/fixtures/local_pack/colors.biguesspack` contains two original 8x8 solid-color
PNGs authored for this ticket, with CC0 declarations separate from Card metadata.
It was produced by the T09 exporter. Its archive SHA-256 is
`218519edbaf7ca69e184c3c7082564d2e2a595a02acaf1f5622def00d3dac1e2`.
No legacy artwork is included.

```bash
flutter test test/unit/local_pack_store_test.dart
```

Tests cover exported-fixture compatibility, reopening without the source,
pre-activation visibility, retained previous images, same-revision retries,
malformed/truncated/tampered files, relations/provenance, corrupt image bytes
with a matching declared hash, unsafe/duplicate archive entries, input bounds,
partial storage writes, activation failures, retry after failure and concurrent
installers. These tests do not install an Android application or perform a
physical-device power-loss experiment.
