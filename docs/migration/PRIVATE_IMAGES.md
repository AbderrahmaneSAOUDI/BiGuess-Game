# T11 — Private images and presentation loading

`ContentImageLoader.imageFor(card.imageReference)` resolves both bundled
`assets/...` references and installed `biguess-pack:...` references. Pass its
provider to Flutter's `Image` or `precacheImage`; errors flow to the existing
image fallback. `contentImageLoaderProvider` supplies the loader to the current
game screen. `AnimatedCharacterCard` also accepts an explicit loader for tests.
The default catalog remains bundled during migration.

```dart
final store = await LocalPackStore.openDefault();
final installed = await store.install(selectedPackFile);
final provider = ContentImageLoader.shared.imageFor(
  installed.cards.first.imageReference,
);
// Image(image: provider, errorBuilder: ...)
```

## Storage and protection

The default root is `getApplicationSupportDirectory()/packs`, persistent native
application storage. The injected constructor root is for tests or another
caller-controlled **private** directory. Never pass a public gallery, Downloads,
or external-storage directory. No gallery API, media registration, network call,
or external-storage permission is needed by this implementation.

New generations contain `manifest.json` and one `images.bgpack` container:
eight bytes `BGIMG01\n`, followed by the original encoded images in manifest
object order. The manifest's object sizes determine offsets; existing SHA-256
hashes verify bytes. The installer verifies the entire staged container before
its existing atomic activation. The transport `.biguesspack` format is unchanged.
The caller still owns the selected source file; installation does not delete it.

Installed Card references contain only a private root-relative generation,
object hash/extension, offset and encoded length. They survive relocation of
application support storage. They are opaque references, **not filesystem paths**;
use the loader rather than `FileImage` or `Image.asset` directly. Readers reject
URLs, arbitrary absolute paths, traversal, out-of-bounds ranges and symlink
escapes. Reopening verifies all hashes once; a cold image load verifies only its
requested object. Reads seek to that range and never unpack a Pack or write a
plaintext temporary image. A cache hit performs no file read or hash operation.

App-private access plus packaging discourages ordinary browsing and gallery
discovery. The container is **not encrypted**. Hashes detect corruption, not an
attacker who can rewrite application data. Rooted devices, backups, debugging,
screenshots and deliberate reverse engineering can expose content. This is
practical casual-extraction protection, not perfect DRM.

Pre-T11 generations with loose private `objects/...` files remain readable when
reopened through `LocalPackStore`; reopening supplies the new opaque references
without rewriting the generation. Bundled asset strings remain unchanged. Old
generations remain available to existing snapshots after Pack updates. Retention
and reclamation follow the T10 contract; automatic repack/deletion is separate.

## Memory and timing

- Encoded images are limited to 16 MiB each. Existing import limits still bound
  the transport file and intrinsic pixel count. A load allocates only its encoded
  image, not the entire container. Import/reopen validation stays outside draws.
- Both sources use `ResizeImagePolicy.fit`, at most 1024×1024 decoded pixels,
  preserving aspect ratio without upscaling. Typical RGBA decoded storage is at
  most 4 MiB per image. Sizing and rendering use the same provider/cache key.
- Application startup sets Flutter's retained image cache to at most 32 MiB and
  32 entries. It includes all Flutter image providers. No additional byte cache
  is kept. Game-screen warmup loads at most two images, sequentially, and stops
  if the screen is disposed. It never precaches an entire Pack.
- Flutter's live images, pending loads, codec/native workspace and GPU copies
  are separate allocations. This is a retained-cache bound, not a claim of a
  32 MiB total-process ceiling. Keep active image widgets bounded; disposing the
  reveal removes its dimension listener and releases its live-image hold.

The repeatable host-debug workload loads 48 separately addressed 2048×1024 JPEGs
from a single container. It asserts 1024×512 output, eviction, cache byte/entry
bounds, zero pending/live holds after listeners detach, and cache-hit reuse.
One Linux host run measured cold median **17.8 ms**, p95 **26.0 ms**, and warm
**3.0 ms**; retention plateaued at **33,554,432 bytes / 16 images**. Timings are
reported rather than asserted because hardware and load vary. These are not
Android release-mode, frame-time, total-RSS or low-memory-device measurements.

```bash
flutter test test/unit/local_pack_store_test.dart test/widget/content_image_loader_test.dart --reporter expanded
```

Tests also decode the authored fixture to its expected pixels after restart and
source deletion, load bundled assets without a storage plugin, render the reveal
and its error fallback, retry after corruption is repaired, and verify private
packaging, relocation, old loose generations, and path containment. Gallery
isolation is established by private-root routing and the absence of image-file
exports; a physical Android gallery scan was not performed.
