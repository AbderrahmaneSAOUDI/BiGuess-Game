import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/data/repositories/sqlite_content_repository.dart';
import 'package:gdg_guess_game/domain/models/card.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/pack_selection.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:gdg_guess_game/domain/use_cases/select_packs_use_case.dart';

void main() {
  test(
    'selection uses installed SQLite Cards, excluding cached-only Packs and revisions',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'biguess-selection-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final repository = SqliteContentRepository.open(
        '${directory.path}/content.sqlite',
      );
      addTearDown(repository.close);
      Card card(String packId, String id) => Card(
        id: id,
        packId: packId,
        name: id,
        imageReference: 'private/$id.webp',
        difficulty: Difficulty.easy,
      );
      repository.putContent(
        topics: [Topic(id: 'topic', name: 'Topic', published: true)],
        packs: [
          Pack(
            id: 'installed',
            topicId: 'topic',
            name: 'Installed',
            published: true,
          ),
          Pack(id: 'remote', topicId: 'topic', name: 'Remote', published: true),
        ],
        cards: [
          card('installed', 'old-one'),
          card('installed', 'old-two'),
          card('remote', 'remote-one'),
          card('remote', 'remote-two'),
        ],
      );
      repository.setInstalledPack(
        InstalledPackState(
          packId: 'installed',
          revision: 1,
          installedAt: DateTime.utc(2026, 11, 6),
        ),
      );
      repository.putContent(
        packs: [
          Pack(
            id: 'installed',
            topicId: 'topic',
            name: 'Renamed',
            published: true,
            revision: 2,
          ),
        ],
        cards: [card('installed', 'new-one'), card('installed', 'new-two')],
      );

      final select = SelectPacksUseCase(repository);
      final options = {
        for (final option in select.options('topic')) option.pack.id: option,
      };
      expect(
        options['remote']!.availability,
        PackAvailability.downloadRequired,
      );
      expect(options['installed']!.availability, PackAvailability.playable);
      final pool = select(
        PackSelection(
          topicId: 'topic',
          mode: PackSelectionMode.random,
          randomCount: 99,
        ),
      );
      expect(pool.packs.map((pack) => pack.id), ['installed']);
      expect(pool.cards.map((card) => card.id), ['old-one', 'old-two']);
      expect(pool.packs.single.name, 'Renamed');
      expect(repository.getCardsForPack('remote'), hasLength(2));
      expect(
        () => select(PackSelection(topicId: 'topic', packIds: ['remote'])),
        throwsA(isA<PackSelectionException>()),
      );
    },
  );
}
