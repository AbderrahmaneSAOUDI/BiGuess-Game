import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/data/local/local_pack_store.dart';
import 'package:biguess/domain/models/card.dart' as domain;
import 'package:biguess/domain/models/difficulty.dart';
import 'package:biguess/presentation/images/content_image_loader.dart';
import 'package:biguess/presentation/screens/game/widgets/identity_card.dart';
import 'package:biguess/providers/content_image_provider.dart';

const _asset = 'assets/logos/biguess-icon.webp';

class _DeferredImage extends ImageProvider<_DeferredImage> {
  final frame = Completer<ImageInfo>();

  @override
  Future<_DeferredImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _DeferredImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(frame.future);
}

class _DeferredLoader extends ContentImageLoader {
  final image = _DeferredImage();

  @override
  ImageProvider<Object> imageFor(String reference) => image;
}

Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

domain.Card _card({
  String name = 'Étoile — 星 — نجمة',
  String imageReference = _asset,
}) => domain.Card(
  id: 'identity-card',
  packId: 'identity-pack',
  name: name,
  imageReference: imageReference,
  difficulty: Difficulty.easy,
);

Future<ImageInfo> _decode(ImageProvider<Object> provider) {
  final completed = Completer<ImageInfo>();
  final stream = provider.resolve(const ImageConfiguration());
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

Future<void> _mount(
  WidgetTester tester,
  domain.Card card,
  ContentImageLoader loader, {
  bool reducedMotion = false,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [contentImageLoaderProvider.overrideWithValue(loader)],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: Scaffold(
        body: SafeArea(child: IdentityCard(card: card)),
      ),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  testWidgets(
    'canonical identity and accessible name survive image/name taps',
    (tester) async {
      await _withSemantics(tester, () async {
        final card = _card();
        final loader = ContentImageLoader(
          openStore: () =>
              throw StateError('Bundled identity must remain offline'),
        );
        (await tester.runAsync(
          () => _decode(loader.imageFor(_asset)),
        ))!.dispose();

        await _mount(tester, card, loader);
        await tester.pump();
        // Allow the next frame beyond the floating-point animation endpoint.
        await tester.pump(const Duration(milliseconds: 251));
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);
        expect(find.text(card.name), findsOneWidget);
        expect(find.bySemanticsLabel('Identity: ${card.name}'), findsOneWidget);
        expect(find.text('Show Name'), findsNothing);
        expect(
          tester.widget<Image>(find.byType(Image)).image,
          loader.imageFor(card.imageReference),
        );
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);

        await tester.tap(find.byKey(const ValueKey('identity_name')));
        await tester.tap(find.byType(Image));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(card.name), findsOneWidget);
        expect(find.bySemanticsLabel('Identity: ${card.name}'), findsOneWidget);
        expect(find.text('Show Name'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    },
  );

  testWidgets(
    'reduced motion displays the identity without scheduling motion',
    (tester) async {
      final card = _card();
      final loader = ContentImageLoader();
      (await tester.runAsync(
        () => _decode(loader.imageFor(_asset)),
      ))!.dispose();
      await _mount(tester, card, loader, reducedMotion: true);
      await tester.pump();
      expect(find.text(card.name), findsOneWidget);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'identity name and loading semantics remain until an image frame arrives',
    (tester) async {
      await _withSemantics(tester, () async {
        final decoded = (await tester.runAsync(
          () => _decode(ContentImageLoader().imageFor(_asset)),
        ))!;
        final loader = _DeferredLoader();
        addTearDown(() {
          if (!loader.image.frame.isCompleted) decoded.dispose();
        });
        final card = _card();
        await _mount(tester, card, loader);
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(card.name), findsOneWidget);
        expect(find.bySemanticsLabel('Loading image'), findsOneWidget);
        expect(find.bySemanticsLabel('Identity: ${card.name}'), findsOneWidget);
        expect(find.byType(RawImage), findsNothing);

        loader.image.frame.complete(decoded);
        await tester.pump();
        await tester.pump();
        expect(find.bySemanticsLabel('Loading image'), findsNothing);
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
        expect(find.text(card.name), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    },
  );

  testWidgets(
    'installed private identity renders locally after source removal',
    (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('biguess-identity-test-'),
      ))!;
      addTearDown(() async => temp.delete(recursive: true));
      final store = LocalPackStore(Directory('${temp.path}/private'));
      final installed = (await tester.runAsync(() async {
        final source = await File(
          'test/fixtures/local_pack/colors.biguesspack',
        ).copy('${temp.path}/input.biguesspack');
        final result = await store.install(source);
        await source.delete();
        return result;
      }))!;
      final card = installed.cards.first;
      var storeReads = 0;
      final loader = ContentImageLoader(
        openStore: () {
          storeReads++;
          return Future.value(LocalPackStore(store.root));
        },
      );

      // Complete native IO before mounting; the deterministic deferred-provider
      // test above covers the widget's asynchronous loading presentation.
      final decoded = (await tester.runAsync(
        () => _decode(loader.imageFor(card.imageReference)),
      ))!;
      expect(decoded.image.width, 8);
      expect(decoded.image.height, 8);
      final pixels = (await tester.runAsync(decoded.image.toByteData))!;
      expect([
        pixels.getUint8(0),
        pixels.getUint8(1),
        pixels.getUint8(2),
      ], card.name == 'Red' ? [255, 0, 0] : [0, 0, 255]);
      decoded.dispose();
      await _mount(tester, card, loader);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(find.text(card.name), findsOneWidget);
      expect(find.text('Error loading image'), findsNothing);
      expect(storeReads, 1, reason: 'dimensions and display share one decode');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('missing private image retains the outward-facing identity', (
    tester,
  ) async {
    final card = _card(imageReference: 'biguess-pack:missing');
    final loader = ContentImageLoader(
      openStore: () =>
          throw StateError('Invalid references need no storage IO'),
    );
    await _mount(tester, card, loader);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Error loading image'), findsOneWidget);
    expect(find.text(card.name), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('long Unicode name stays usable at 2x text in $size', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _withSemantics(tester, () async {
        final card = _card(
          name:
              'Étoile du Nord — 星の守護者 — حارس النجوم '
              'Étoile du Nord — 星の守護者 — حارس النجوم',
        );
        final loader = ContentImageLoader();
        (await tester.runAsync(
          () => _decode(loader.imageFor(_asset)),
        ))!.dispose();

        await _mount(tester, card, loader);
        await tester.pump(const Duration(seconds: 3));
        await tester.ensureVisible(find.byKey(const ValueKey('identity_name')));
        await tester.pump();
        expect(find.text(card.name), findsOneWidget);
        expect(find.bySemanticsLabel('Identity: ${card.name}'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    });
  }
}
