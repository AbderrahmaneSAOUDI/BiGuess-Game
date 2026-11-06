import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/core/utils/asset_loader.dart';
import 'package:gdg_guess_game/data/datasources/topic_pack_data_source.dart';
import 'package:gdg_guess_game/data/repositories/legacy_manifest_content_repository.dart';
import 'package:gdg_guess_game/domain/models/content_validator.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/providers/game_controller.dart';
import 'package:gdg_guess_game/providers/topic_pack_providers.dart';

import '../support/test_content_repository.dart';

class _MapDataSource extends TopicPackDataSource {
  final Map<String, Map<String, List<String>>> content;

  _MapDataSource(this.content);

  @override
  List<String> getTopics() => content.keys.toList();

  @override
  List<String> getPacksForTopic(String topicName) =>
      content[topicName]?.keys.toList() ?? [];

  @override
  List<String> getAssetsForPack(String topicName, String packName) =>
      content[topicName]?[packName] ?? [];
}

void main() {
  group('Legacy manifest adapter', () {
    test(
      'preserves both topics, all seven packs, order, labels and images',
      () {
        const source = TopicPackDataSource();
        final repository = LegacyManifestContentRepository();
        final topics = repository.getTopics();
        expect(topics.map((topic) => topic.name), ['Anime', 'Geography']);
        final packs = topics
            .expand((topic) => repository.getPacksForTopic(topic.id))
            .toList();
        expect(packs.map((pack) => pack.name), [
          'Attack on Titan',
          'Black Clover',
          'Demon Slayer',
          'Hunter X Hunter',
          'Naruto',
          'One Piece',
          'Flags',
        ]);
        final cards = packs
            .expand((pack) => repository.getCardsForPack(pack.id))
            .toList();
        ContentValidator.validateRelations(
          topics: topics,
          packs: packs,
          cards: cards,
        );
        for (final topic in topics) {
          expect(topic.published, isFalse);
          for (final pack in repository.getPacksForTopic(topic.id)) {
            final packCards = repository.getCardsForPack(pack.id);
            final paths = source.getAssetsForPack(topic.name, pack.name);
            expect(packCards.map((card) => card.imageReference), paths);
            expect(
              packCards.map((card) => card.name),
              paths.map(AssetLoader.extractCharacterName),
            );
            expect(
              packCards.every((card) => card.difficulty == Difficulty.easy),
              isTrue,
            );
            expect(pack.published, isFalse);
            ContentValidator.validatePlayablePack(pack: pack, cards: packCards);
          }
        }
      },
    );

    test('unknown IDs return empty lists and all results are immutable', () {
      final repository = LegacyManifestContentRepository();
      final topics = repository.getTopics();
      final packs = repository.getPacksForTopic(topics.first.id);
      final cards = repository.getCardsForPack(packs.first.id);
      expect(repository.getPacksForTopic('unknown'), isEmpty);
      expect(repository.getCardsForPack('unknown'), isEmpty);
      expect(() => topics.clear(), throwsUnsupportedError);
      expect(() => packs.clear(), throwsUnsupportedError);
      expect(() => cards.clear(), throwsUnsupportedError);
    });

    test('IDs are deterministic, scoped, and independent of source order', () {
      final source = _MapDataSource({
        'Original: Shapes': {
          'Paper: A': ['images/Étoile 紙.webp', 'images/Circle.webp'],
          'Paper': ['images/Étoile 紙.webp'],
        },
        'Original': {
          'Shapes: Paper: A': ['images/Étoile 紙.webp'],
        },
      });
      final first = LegacyManifestContentRepository(dataSource: source);
      final reordered = LegacyManifestContentRepository(
        dataSource: _MapDataSource({
          for (final topic in source.content.entries.toList().reversed)
            topic.key: {
              for (final pack in topic.value.entries.toList().reversed)
                pack.key: pack.value.reversed.toList(),
            },
        }),
      );
      final topicIds = <String>{};
      final packIds = <String>{};
      final cardIds = <String>{};
      for (final topic in first.getTopics()) {
        expect(reordered.getTopics(), contains(topic));
        expect(topicIds.add(topic.id), isTrue);
        for (final pack in first.getPacksForTopic(topic.id)) {
          expect(reordered.getPacksForTopic(topic.id), contains(pack));
          expect(packIds.add(pack.id), isTrue);
          for (final card in first.getCardsForPack(pack.id)) {
            expect(reordered.getCardsForPack(pack.id), contains(card));
            expect(cardIds.add(card.id), isTrue);
          }
        }
      }
      source.content.clear();
      expect(first.getTopics(), hasLength(2));
      expect(first.getPacksForTopic(first.getTopics().first.id), hasLength(2));
    });

    test('empty legacy packs remain representable', () {
      final repository = LegacyManifestContentRepository(
        dataSource: _MapDataSource({
          'Shapes': {'Empty': []},
        }),
      );
      final pack = repository
          .getPacksForTopic(repository.getTopics().single.id)
          .single;
      expect(pack.name, 'Empty');
      expect(repository.getCardsForPack(pack.id), isEmpty);
    });
  });

  group('Repository-backed compatibility providers', () {
    test(
      'default providers match all existing manifest lookups and counts',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        const source = TopicPackDataSource();
        expect(container.read(topicsProvider), source.getTopics());
        for (final topic in source.getTopics()) {
          expect(
            container.read(packsProvider(topic)),
            source.getPacksForTopic(topic),
          );
          expect(
            container.read(topicAssetCountProvider(topic)),
            source.getTotalAssetsForTopic(topic),
          );
          for (final pack in source.getPacksForTopic(topic)) {
            final key = (topic: topic, pack: pack);
            expect(
              container.read(packAssetsProvider(key)),
              source.getAssetsForPack(topic, pack),
            );
            expect(
              container.read(packAssetCountProvider(key)),
              source.getAssetCountForPack(topic, pack),
            );
          }
        }
      },
    );

    test(
      'one repository override replaces labels, counts, Cards and round pool',
      () {
        final repository = TestContentRepository();
        final container = ProviderContainer(
          overrides: [
            contentRepositoryProvider.overrideWithValue(repository),
            topicPackDataSourceProvider.overrideWith(
              (ref) => throw StateError(
                'A repository override must not access the manifest source',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        const key = (topic: 'Shapes', pack: 'Paper Shapes');
        final images = repository
            .getCardsForPack('p-72')
            .map((card) => card.imageReference)
            .toList();
        expect(container.read(topicsProvider), ['Shapes']);
        expect(container.read(packsProvider(key.topic)), [
          'Paper Shapes',
          'Empty Draft',
        ]);
        expect(container.read(topicAssetCountProvider(key.topic)), 2);
        expect(container.read(packAssetCountProvider(key)), 2);
        expect(
          container.read(packCardsProvider(key)),
          repository.getCardsForPack('p-72'),
        );
        expect(container.read(packAssetsProvider(key)), images);
        final subscription = container.listen(
          gameRoundProvider(key),
          (previous, next) {},
        );
        addTearDown(subscription.close);
        final state = subscription.read();
        expect(state.allImages, images);
        expect(state.remainingImages, images);
        expect(state.noImagesFound, isFalse);
      },
    );

    test(
      'unknown topics/packs and empty drafts preserve empty/zero behavior',
      () {
        final container = ProviderContainer(
          overrides: [
            contentRepositoryProvider.overrideWithValue(
              TestContentRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);
        expect(container.read(packsProvider('Missing')), isEmpty);
        expect(container.read(topicAssetCountProvider('Missing')), 0);
        for (final key in [
          (topic: 'Missing', pack: 'Paper Shapes'),
          (topic: 'Shapes', pack: 'Missing'),
          (topic: 'Shapes', pack: 'Empty Draft'),
        ]) {
          expect(container.read(packAssetsProvider(key)), isEmpty);
          expect(container.read(packAssetCountProvider(key)), 0);
          expect(container.read(gameRoundProvider(key)).noImagesFound, isTrue);
        }
      },
    );
  });
}
