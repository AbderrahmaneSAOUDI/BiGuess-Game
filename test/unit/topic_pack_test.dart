import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/core/utils/asset_loader.dart';
import 'package:gdg_guess_game/data/datasources/topic_pack_data_source.dart';

void main() {
  group('TopicPackDataSource', () {
    const dataSource = TopicPackDataSource();

    test('returns only Anime and Geography topics', () {
      final topics = dataSource.getTopics();
      expect(topics, containsAll(['Anime', 'Geography']));
      expect(topics, isNot(contains('Movies')));
    });

    test('returns all anime packs', () {
      final packs = dataSource.getPacksForTopic('Anime');
      expect(
        packs,
        containsAll([
          'Attack on Titan',
          'Black Clover',
          'Demon Slayer',
          'Hunter X Hunter',
          'Naruto',
          'One Piece',
        ]),
      );
      expect(packs.length, 6);
    });

    test('returns flags pack under Geography', () {
      final packs = dataSource.getPacksForTopic('Geography');
      expect(packs, ['Flags']);
    });

    test('all packs contain assets', () {
      final topics = dataSource.getTopics();
      for (final topic in topics) {
        final packs = dataSource.getPacksForTopic(topic);
        expect(packs, isNotEmpty);
        for (final pack in packs) {
          final count = dataSource.getAssetCountForPack(topic, pack);
          expect(count, greaterThan(0), reason: '$topic -> $pack has 0 assets');
        }
      }
    });

    test('geography flags count is 252', () {
      final count = dataSource.getAssetCountForPack('Geography', 'Flags');
      expect(count, 252);
    });
  });

  group('AssetLoader.extractCharacterName', () {
    test('extracts flag names without file extension', () {
      expect(
        AssetLoader.extractCharacterName('assets/images/Geography/Flags/Algeria.png'),
        'Algeria',
      );
      expect(
        AssetLoader.extractCharacterName('assets/images/Geography/Flags/United States.png'),
        'United States',
      );
      expect(
        AssetLoader.extractCharacterName('assets/images/Geography/Flags/South Korea.png'),
        'South Korea',
      );
    });

    test('extracts anime character names properly', () {
      expect(
        AssetLoader.extractCharacterName('assets/images/Anime/Naruto/Itachi Utchiha.webp'),
        'Itachi Utchiha',
      );
      expect(
        AssetLoader.extractCharacterName('assets/images/Anime/Attack on Titan/Eren YAEGER.webp'),
        'Eren YAEGER',
      );
    });
  });
}
