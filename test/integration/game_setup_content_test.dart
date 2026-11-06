import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/data/repositories/sqlite_content_repository.dart';
import 'package:gdg_guess_game/domain/models/card.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:gdg_guess_game/providers/topic_pack_providers.dart';

void main() {
  test(
    'setup rejects cached-only Packs and reads installed revision snapshots',
    () {
      final directory = Directory.systemTemp.createTempSync('biguess-setup-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final repository = SqliteContentRepository.open(
        '${directory.path}/content.sqlite',
      );
      addTearDown(repository.close);
      Card card(String name) => Card(
        id: 'card',
        packId: 'pack',
        name: name,
        imageReference: 'assets/logos/biguess-icon.webp',
        difficulty: Difficulty.easy,
      );
      repository.putContent(
        topics: [Topic(id: 'topic', name: 'Topic')],
        packs: [Pack(id: 'pack', topicId: 'topic', name: 'Pack')],
        cards: [card('Installed')],
      );
      expect(repository.getInstalledCardsForPack('pack'), isNull);
      expect(repository.getInstalledCardsForPack('missing'), isNull);
      repository.setInstalledPack(
        InstalledPackState(
          packId: 'pack',
          revision: 1,
          installedAt: DateTime.utc(2026, 11, 6),
        ),
      );
      repository.putContent(
        packs: [Pack(id: 'pack', topicId: 'topic', name: 'Pack', revision: 2)],
        cards: [card('Cached revision')],
      );
      final container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final content = container.read(
        gameSetupContentProvider((topic: 'Topic', pack: 'Pack')),
      )!;
      expect(content.installedCards!.single.name, 'Installed');
      expect(repository.getCardsForPack('pack').single.name, 'Cached revision');
      expect(() => content.installedCards!.clear(), throwsUnsupportedError);
      repository.putContent(
        packs: [
          Pack(
            id: 'pack',
            topicId: 'topic',
            name: 'Pack',
            revision: 3,
            deleted: true,
          ),
        ],
      );
      expect(repository.getInstalledCardsForPack('pack'), isNull);
    },
  );
}
