import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/core/constants/app_constants.dart';
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

  group('AppConstants Dynamic Theme & Icons', () {
    test('known topics return configured colors', () {
      expect(AppConstants.getTopicColor('Anime'), AppConstants.topicColors['Anime']);
      expect(AppConstants.getTopicColor('Geography'), AppConstants.topicColors['Geography']);
      expect(AppConstants.getTopicColor('Movies'), AppConstants.topicColors['Movies']);
    });

    test('future custom topics dynamically receive valid colors', () {
      final gamingColor = AppConstants.getTopicColor('Gaming');
      final scienceColor = AppConstants.getTopicColor('Science');
      expect(gamingColor, isNotNull);
      expect(scienceColor, isNotNull);
    });

    test('future custom topics dynamically receive contextual icons', () {
      expect(AppConstants.getTopicIcon('Anime'), Icons.auto_awesome_rounded);
      expect(AppConstants.getTopicIcon('Flags of the World'), Icons.public_rounded);
      expect(AppConstants.getTopicIcon('Classic Cinema'), Icons.movie_creation_rounded);
      expect(AppConstants.getTopicIcon('Video Games'), Icons.sports_esports_rounded);
      expect(AppConstants.getTopicIcon('Pop Music'), Icons.music_note_rounded);
      expect(AppConstants.getTopicIcon('Football Legends'), Icons.sports_soccer_rounded);
      expect(AppConstants.getTopicIcon('Unknown Topic 123'), Icons.category_rounded);
    });
  });
}
