import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/data/local/local_pack_store.dart';
import 'package:biguess/data/local/private_pack_images.dart';
import 'package:biguess/presentation/images/content_image_loader.dart';
import 'package:biguess/presentation/widgets/animations/animated_character_card.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

Future<ImageInfo> resolveImage(ImageProvider<Object> provider) async {
  final stream = provider.resolve(const ImageConfiguration());
  final completed = Completer<ImageInfo>();
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      completed.complete(info);
    },
    onError: (Object error, StackTrace? stack) {
      stream.removeListener(listener);
      completed.completeError(error, stack);
    },
  );
  stream.addListener(listener);
  return completed.future.timeout(const Duration(seconds: 15));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late LocalPackStore store;
  late ContentImageLoader loader;
  final cache = PaintingBinding.instance.imageCache;
  late int oldBytes;
  late int oldEntries;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('biguess-image-test-');
    store = LocalPackStore(Directory(p.join(temp.path, 'private')));
    loader = ContentImageLoader(openStore: () async => store);
    oldBytes = cache.maximumSizeBytes;
    oldEntries = cache.maximumSize;
    ContentImageLoader.configureCache();
    cache.clear();
    cache.clearLiveImages();
  });

  tearDown(() async {
    cache.clear();
    cache.clearLiveImages();
    cache.maximumSizeBytes = oldBytes;
    cache.maximumSize = oldEntries;
    await temp.delete(recursive: true);
  });

  test(
    'installed private images decode offline after source deletion and restart',
    () async {
      final source = await File(
        'test/fixtures/local_pack/colors.biguesspack',
      ).copy(p.join(temp.path, 'input.biguesspack'));
      final installed = await store.install(source);
      await source.delete();
      final reopened = (await LocalPackStore(
        store.root,
      ).readInstalled(installed.manifest.pack.id))!;
      var reads = 0;
      loader = ContentImageLoader(
        openStore: () async {
          reads++;
          return LocalPackStore(store.root);
        },
      );
      for (final card in reopened.cards) {
        final info = await resolveImage(loader.imageFor(card.imageReference));
        expect(info.image.width, 8);
        expect(info.image.height, 8);
        // Fixture uses two solid original colors; decode must return their pixels.
        final pixels = (await info.image.toByteData())!;
        expect([
          pixels.getUint8(0),
          pixels.getUint8(1),
          pixels.getUint8(2),
        ], card.name == 'Red' ? [255, 0, 0] : [0, 0, 255]);
        info.dispose();
        (await resolveImage(loader.imageFor(card.imageReference))).dispose();
      }
      expect(reads, 2, reason: 'cache hits must not reopen or rehash images');
    },
  );

  test(
    'bundled asset migration path needs no private storage plugin',
    () async {
      final assets = ContentImageLoader(
        openStore: () => throw StateError('private IO'),
      );
      final info = await resolveImage(
        assets.imageFor('assets/logos/biguess-icon.webp'),
      );
      expect(info.image.width, greaterThan(0));
      expect(
        info.image.width,
        lessThanOrEqualTo(ContentImageLoader.maxDecodeDimension),
      );
      info.dispose();
    },
  );

  test('failed loads are evicted and the same reference can retry', () async {
    final installed = await store.install(
      File('test/fixtures/local_pack/colors.biguesspack'),
    );
    final file = File(
      p.join(installed.directory.path, PrivatePackImages.fileName),
    );
    final bytes = await file.readAsBytes();
    await file.writeAsBytes([0]);
    final provider = loader.imageFor(installed.cards.first.imageReference);
    await expectLater(resolveImage(provider), throwsFormatException);
    await Future<void>.delayed(Duration.zero);
    expect(cache.pendingImageCount, 0);
    await file.writeAsBytes(bytes);
    (await resolveImage(provider)).dispose();
  });

  test(
    '48 large images preserve aspect ratio and stay within the cache budget',
    () async {
      // Synthetic single-Pack workload, with independently addressed JPEG objects.
      // Trailing bytes produce distinct hashes without repeated Dart JPEG encoding.
      final jpeg = img.encodeJpg(img.Image(width: 2048, height: 1024));
      final pack = sha256.convert(utf8.encode('large-pack')).toString();
      final directory = await Directory(
        p.join(store.root.path, pack, 'generation-Benchmark'),
      ).create(recursive: true);
      final builder = BytesBuilder(copy: false)..add(PrivatePackImages.header);
      var offset = PrivatePackImages.header.length;
      final references = <String>[];
      for (var i = 0; i < 48; i++) {
        final bytes = Uint8List.fromList([...jpeg, i]);
        final hash = sha256.convert(bytes).toString();
        references.add(
          'biguess-pack:$pack/generation-Benchmark/objects/$hash.jpg'
          '?offset=$offset&size=${bytes.length}',
        );
        builder.add(bytes);
        offset += bytes.length;
      }
      await File(
        p.join(directory.path, PrivatePackImages.fileName),
      ).writeAsBytes(builder.takeBytes());
      final timings = <int>[];
      for (final reference in references) {
        final watch = Stopwatch()..start();
        final info = await resolveImage(loader.imageFor(reference));
        timings.add(watch.elapsedMicroseconds);
        expect(info.image.width, 1024);
        expect(info.image.height, 512);
        info.dispose();
        expect(
          cache.currentSizeBytes,
          lessThanOrEqualTo(ContentImageLoader.cacheBytes),
        );
        expect(
          cache.currentSize,
          lessThanOrEqualTo(ContentImageLoader.cacheEntries),
        );
      }
      expect(cache.currentSize, lessThan(references.length));
      expect(cache.pendingImageCount, 0);
      expect(cache.liveImageCount, 0);
      final hit = Stopwatch()..start();
      (await resolveImage(loader.imageFor(references.last))).dispose();
      timings.sort();
      // Timing is evidence, not a machine-dependent pass/fail threshold.
      debugPrint(
        'Private images (host debug): cold median '
        '${timings[timings.length ~/ 2] / 1000} ms, '
        'p95 ${timings[(timings.length * .95).floor()] / 1000} ms; '
        'warm ${hit.elapsedMicroseconds / 1000} ms; '
        'retained ${cache.currentSizeBytes} bytes / ${cache.currentSize} images',
      );
    },
  );

  testWidgets('reveal renders a private image and handles a missing image', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => store.install(File('test/fixtures/local_pack/colors.biguesspack')),
    ))!;
    final reference = installed.cards.first.imageReference;
    // Complete native IO/decoding outside the widget test's fake clock.
    (await tester.runAsync(
      () => resolveImage(loader.imageFor(reference)),
    ))!.dispose();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCharacterCard(
              imageAsset: reference,
              imageLoader: loader,
              characterName: 'Red',
              maxWidth: 240,
              maxHeight: 300,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, loader.imageFor(reference));
    expect(find.text('Error loading image'), findsNothing);
    expect(tester.takeException(), isNull);
    // The same public widget supplies the existing presentation-safe fallback.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCharacterCard(
              imageAsset: 'biguess-pack:missing',
              imageLoader: loader,
              maxWidth: 240,
              maxHeight: 300,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Error loading image'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      cache.liveImageCount,
      0,
      reason: 'dimension listener must be disposed',
    );
  });
}
