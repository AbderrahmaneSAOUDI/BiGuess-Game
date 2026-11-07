import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/data/local/local_content_runtime.dart';
import 'package:biguess/data/local/local_pack_file.dart';
import 'package:biguess/data/local/local_pack_store.dart';

void main() {
  test(
    'installed IDs remain distinct when Topic and Pack names repeat',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'biguess-labels-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final fixture = ZipDecoder().decodeBytes(
        await File('test/fixtures/local_pack/colors.biguesspack').readAsBytes(),
      );
      final store = LocalPackStore(Directory('${directory.path}/packs'));
      for (var index = 0; index < 3; index++) {
        final manifest =
            jsonDecode(utf8.decode(fixture.find('manifest.json')!.content))
                as Map<String, dynamic>;
        final topicId = index < 2 ? 'topic-a' : 'topic-b';
        (manifest['topic'] as Map<String, dynamic>)
          ..['id'] = topicId
          ..['name'] = 'Shared topic';
        (manifest['pack'] as Map<String, dynamic>)
          ..['id'] = 'pack-$index'
          ..['topicId'] = topicId
          ..['name'] = 'Shared pack';
        final cards = manifest['cards'] as List<dynamic>;
        final rights =
            (manifest['provenance'] as Map<String, dynamic>)['cardRights']
                as List<dynamic>;
        for (var cardIndex = 0; cardIndex < cards.length; cardIndex++) {
          cards[cardIndex]['id'] = 'card-$index-$cardIndex';
          cards[cardIndex]['packId'] = 'pack-$index';
          rights[cardIndex]['id'] = cards[cardIndex]['id'];
        }
        final archive = Archive();
        for (final entry in fixture.files) {
          final bytes = entry.name == 'manifest.json'
              ? utf8.encode(LocalPackManifest.canonicalJson(manifest))
              : entry.content;
          archive.add(
            ArchiveFile(entry.name, bytes.length, bytes)
              ..compression = CompressionType.none,
          );
        }
        final source = File('${directory.path}/$index.biguesspack');
        await source.writeAsBytes(ZipEncoder().encodeBytes(archive));
        await store.install(source);
      }

      for (var restart = 0; restart < 2; restart++) {
        final runtime = await LocalContentRuntime.open(
          supportDirectory: directory,
        );
        try {
          expect(runtime.failure, isNull);
          expect(runtime.usesSqlite, isTrue);
          final repository = runtime.repository;
          expect(
            repository.getTopics().map((topic) => topic.id),
            unorderedEquals(['topic-a', 'topic-b']),
          );
          expect(
            repository.getPacksForTopic('topic-a').map((pack) => pack.id),
            unorderedEquals(['pack-0', 'pack-1']),
          );
          expect(repository.getPacksForTopic('topic-b').single.id, 'pack-2');
          for (var index = 0; index < 3; index++) {
            expect(
              repository
                  .getInstalledCardsForPack('pack-$index')!
                  .every((card) => card.packId == 'pack-$index'),
              isTrue,
            );
          }
        } finally {
          runtime.close();
        }
      }
    },
  );
}
