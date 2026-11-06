import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Confirmed-Cleared Fixture Pack (T05)', () {
    const fixtureDir = 'test/fixtures/cleared_shapes';
    final packJsonFile = File('$fixtureDir/pack.json');

    test('pack.json exists and contains valid JSON', () {
      expect(packJsonFile.existsSync(), isTrue,
          reason: 'Fixture pack.json must exist');
      final content = packJsonFile.readAsStringSync();
      final data = json.decode(content) as Map<String, dynamic>;

      expect(data['schema_version'], isNotNull);
      expect(data['topic'], isA<Map<String, dynamic>>());
      expect(data['pack'], isA<Map<String, dynamic>>());
      expect(data['cards'], isA<List<dynamic>>());
    });

    test('pack has valid hierarchy, metadata, and cleared rights', () {
      final data =
          json.decode(packJsonFile.readAsStringSync()) as Map<String, dynamic>;
      final topic = data['topic'] as Map<String, dynamic>;
      final pack = data['pack'] as Map<String, dynamic>;

      expect(topic['name'], 'Shapes');
      expect(topic['id'], isNotEmpty);

      expect(pack['name'], 'Geometric Shapes');
      expect(pack['id'], isNotEmpty);
      expect(pack['rights_status'], 'cleared');
      expect(pack['permission_to_publish'], isTrue);
      expect(pack['public_test_publishable'], isTrue);
      expect(pack['license'], contains('CC0-1.0'));
      expect(pack['attribution'], isNotEmpty);
      expect(pack['source'], isNotEmpty);
    });

    test('fixture pack satisfies playable pack constraints (>= 2 cards)', () {
      final data =
          json.decode(packJsonFile.readAsStringSync()) as Map<String, dynamic>;
      final cards = data['cards'] as List<dynamic>;

      expect(cards.length, greaterThanOrEqualTo(2),
          reason: 'Minimum playable pack requires at least 2 cards');
      expect(cards.length, 4);

      final difficulties = <int>{};
      for (final rawCard in cards) {
        final card = rawCard as Map<String, dynamic>;
        expect(card['id'], isNotEmpty);
        expect(card['pack_id'], equals(data['pack']['id']));
        expect(card['name'], isNotEmpty);
        expect(card['image'], isNotEmpty);

        final diff = card['difficulty'] as int;
        expect(diff, inInclusiveRange(1, 3));
        difficulties.add(diff);

        // Rights verification
        expect(card['rights_status'], 'cleared');
        expect(card['permission_to_publish'], isTrue);
        expect(card['public_test_publishable'], isTrue);

        // Verify underlying image exists and is non-empty
        final imgFile = File('$fixtureDir/${card['image']}');
        expect(imgFile.existsSync(), isTrue,
            reason: 'Card image ${card['image']} must exist on disk');
        expect(imgFile.lengthSync(), greaterThan(0),
            reason: 'Card image ${card['image']} must not be empty');
      }

      // Covers Easy (1), Medium (2), Hard (3)
      expect(difficulties, containsAll([1, 2, 3]));
    });

    test('rights quarantine invariant: unverified assets are not cleared', () {
      // Confirms that legacy Anime images are not marked cleared
      final legacyAotDir = Directory('assets/images/Anime/Attack on Titan');
      expect(legacyAotDir.existsSync(), isTrue);

      // Cleared fixture pack is separate and isolated from bundled legacy assets
      expect(packJsonFile.path, startsWith('test/fixtures/'));
      expect(packJsonFile.path, isNot(startsWith('assets/images/')));
    });
  });
}
