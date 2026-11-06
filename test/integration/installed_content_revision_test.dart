import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/data/repositories/sqlite_content_repository.dart';
import 'package:gdg_guess_game/domain/models/card.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory directory;
  late String databasePath;

  setUp(() {
    directory = Directory.systemTemp.createTempSync(
      'biguess-installed-revision-',
    );
    databasePath = '${directory.path}/content.sqlite';
  });
  tearDown(() => directory.deleteSync(recursive: true));

  InstalledPackState installed(int revision) => InstalledPackState(
    packId: 'pack',
    revision: revision,
    installedAt: DateTime.utc(2026, 11, 6),
  );

  Card card(String id, String image, {Difficulty level = Difficulty.easy}) =>
      Card(
        id: id,
        packId: 'pack',
        name: id,
        imageReference: image,
        difficulty: level,
      );

  List<Card> eligible(
    SqliteContentRepository repository, {
    Difficulty level = Difficulty.hard,
  }) => repository.getEligibleCards(
    topicId: 'topic',
    packIds: ['pack'],
    maximumDifficulty: level,
    includeUnpublished: true,
  );

  void seed(SqliteContentRepository repository) {
    repository.putContent(
      topics: [Topic(id: 'topic', name: 'Topic')],
      packs: [Pack(id: 'pack', topicId: 'topic', name: 'Pack')],
      cards: [
        card('one', 'installed-one.webp'),
        card('two', 'installed-two.webp'),
      ],
    );
    repository.setInstalledPack(installed(1));
  }

  void cacheUpdate(SqliteContentRepository repository) {
    repository.putContent(
      packs: [Pack(id: 'pack', topicId: 'topic', name: 'Pack', revision: 2)],
      cards: [
        card('one', 'uninstalled-one-v2.webp', level: Difficulty.hard),
        card('new', 'uninstalled-new-v2.webp'),
      ],
    );
  }

  test(
    'cached revisions cannot replace installed Cards, even after restart',
    () {
      var repository = SqliteContentRepository.open(databasePath);
      seed(repository);
      final original = eligible(repository);
      cacheUpdate(repository);
      expect(repository.getCardsForPack('pack'), hasLength(3));
      expect(eligible(repository), original);
      expect(eligible(repository, level: Difficulty.easy), original);
      repository.close();

      repository = SqliteContentRepository.open(databasePath);
      addTearDown(repository.close);
      expect(eligible(repository), original);
      // Retrying the old installation must not copy newer cached Cards.
      repository.setInstalledPack(installed(1));
      expect(eligible(repository), original);
      repository.setInstalledPack(installed(2));
      expect(repository.getInstalledPack('pack')!.revision, 2);
      expect(eligible(repository), repository.getCardsForPack('pack'));
      expect(eligible(repository, level: Difficulty.easy).map((c) => c.id), [
        'two',
        'new',
      ]);
      expect(original.first.imageReference, 'installed-one.webp');
    },
  );

  test(
    'snapshot and installed revision roll back together on storage failure',
    () {
      final repository = SqliteContentRepository.open(databasePath);
      addTearDown(repository.close);
      seed(repository);
      final original = eligible(repository);
      cacheUpdate(repository);
      final database = sqlite3.open(databasePath);
      database.execute(
        '''CREATE TRIGGER fail_installed_card BEFORE INSERT ON installed_cards
      WHEN NEW.id = 'new'
      BEGIN SELECT RAISE(ABORT, 'Simulated snapshot write failure'); END''',
      );
      database.close();
      expect(
        () => repository.setInstalledPack(installed(2)),
        throwsA(isA<SqliteException>()),
      );
      expect(repository.getInstalledPack('pack')!.revision, 1);
      expect(eligible(repository), original);
    },
  );

  test(
    'new installation requires Cards from the requested cached revision',
    () {
      final repository = SqliteContentRepository.open(databasePath);
      addTearDown(repository.close);
      repository.putContent(
        topics: [Topic(id: 'topic', name: 'Topic')],
        packs: [Pack(id: 'pack', topicId: 'topic', name: 'Pack', revision: 2)],
        cards: [card('one', 'v2.webp')],
      );
      expect(() => repository.setInstalledPack(installed(1)), throwsStateError);
      expect(repository.getInstalledPack('pack'), isNull);
      expect(eligible(repository), isEmpty);
    },
  );

  test(
    'v2 upgrades backfill installed Cards before accepting cached updates',
    () {
      var repository = SqliteContentRepository.open(databasePath);
      seed(repository);
      final original = eligible(repository);
      repository.close();
      // The v2 schema differs only by lacking the installed Card snapshot table.
      final old = sqlite3.open(databasePath);
      old.execute('DROP TABLE installed_cards');
      old.userVersion = 2;
      old.close();

      repository = SqliteContentRepository.open(databasePath);
      addTearDown(repository.close);
      expect(eligible(repository), original);
      cacheUpdate(repository);
      expect(eligible(repository), original);
    },
  );

  test(
    'ambiguous v2 installations fail upgrade without rewriting stored data',
    () {
      final repository = SqliteContentRepository.open(databasePath);
      seed(repository);
      cacheUpdate(repository);
      repository.close();
      final old = sqlite3.open(databasePath);
      old.execute('DROP TABLE installed_cards');
      old.userVersion = 2;
      old.close();

      expect(
        () => SqliteContentRepository.open(databasePath),
        throwsStateError,
      );
      final unchanged = sqlite3.open(databasePath);
      addTearDown(unchanged.close);
      expect(unchanged.userVersion, 2);
      expect(
        unchanged
            .select('SELECT revision FROM installed_packs')
            .single['revision'],
        1,
      );
      expect(
        unchanged.select('SELECT revision FROM packs').single['revision'],
        2,
      );
      expect(unchanged.select('SELECT * FROM cards'), hasLength(3));
      expect(
        unchanged.select(
          "SELECT name FROM sqlite_master WHERE name = 'installed_cards'",
        ),
        isEmpty,
      );
    },
  );
}
