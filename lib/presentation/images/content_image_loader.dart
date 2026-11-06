import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../data/local/local_pack_store.dart';
import '../../data/local/private_pack_images.dart';

/// One presentation boundary for bundled assets and installed private images.
/// Providers have stable keys, so dimensions, precaching and display share a
/// single decode. Encoded bytes are released after the codec consumes them.
class ContentImageLoader {
  static final shared = ContentImageLoader();
  static const maxDecodeDimension = 1024;
  static const cacheBytes = 32 * 1024 * 1024;
  static const cacheEntries = 32;
  static const precacheCount = 2;
  final Future<LocalPackStore> Function() _openStore;

  ContentImageLoader({Future<LocalPackStore> Function()? openStore})
    : _openStore = openStore ?? LocalPackStore.openDefault;

  /// App-wide retained decoded-image budget. Live images and pending decodes
  /// are separate Flutter allocations; callers must also bound active widgets.
  static void configureCache() {
    PaintingBinding.instance.imageCache
      ..maximumSizeBytes = cacheBytes
      ..maximumSize = cacheEntries;
  }

  ImageProvider<Object> imageFor(String reference) {
    final ImageProvider<Object> source;
    if (reference.startsWith('assets/')) {
      source = AssetImage(reference);
    } else {
      // Parse inside the asynchronous load so Image.errorBuilder handles errors.
      source = _PrivateImage(this, reference);
    }
    return ResizeImage(
      source,
      width: maxDecodeDimension,
      height: maxDecodeDimension,
      policy: ResizeImagePolicy.fit,
    );
  }
}

@immutable
final class _PrivateImage extends ImageProvider<_PrivateImage> {
  final ContentImageLoader loader;
  final String reference;
  const _PrivateImage(this.loader, this.reference);

  @override
  Future<_PrivateImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PrivateImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    // ResizeImage evicts its outer cache key on errors, allowing a later retry.
    final image = PrivateImageReference.parse(reference);
    final store = await loader._openStore();
    final bytes = await PrivatePackImages.read(store.root, image);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is _PrivateImage &&
      identical(loader, other.loader) &&
      reference == other.reference;

  @override
  int get hashCode => Object.hash(loader, reference);
}
