import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/data/local/local_pack_file.dart';
import 'package:biguess/data/local/local_pack_store.dart';
import 'package:biguess/domain/models/entitlement.dart';

void main() {
  late Directory directory;
  late Directory root;
  late Archive fixture;

  Future<File> packFile(int index, {int revision = 1}) async {
    final manifest =
        jsonDecode(utf8.decode(fixture.find('manifest.json')!.content))
            as Map<String, dynamic>;
    final pack = manifest['pack'] as Map<String, dynamic>;
    pack['id'] = 'pack-$index';
    pack['revision'] = revision;
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
    final entries = {
      'manifest.json': utf8.encode(LocalPackManifest.canonicalJson(manifest)),
      for (final entry in fixture.files)
        if (entry.name != 'manifest.json') entry.name: entry.content,
    };
    for (final entry in entries.entries) {
      archive.add(
        ArchiveFile(entry.key, entry.value.length, entry.value)
          ..compression = CompressionType.none,
      );
    }
    return File('${directory.path}/pack-$index-v$revision.biguesspack')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('biguess-entitlement-');
    root = Directory('${directory.path}/private');
    fixture = ZipDecoder().decodeBytes(
      await File('test/fixtures/local_pack/colors.biguesspack').readAsBytes(),
    );
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'Free rejects sixth Pack; retries and revisions preserve five slots',
    () async {
      final store = LocalPackStore(root);
      for (var index = 0; index < 5; index++) {
        await store.install(await packFile(index));
      }
      final sixth = await packFile(5);
      await expectLater(store.install(sixth), throwsStateError);
      expect(await store.readInstalled('pack-5'), isNull);
      final first = await store.readInstalled('pack-0');
      final retry = await store.install(await packFile(0));
      expect(retry.directory.path, first!.directory.path);
      await store.install(await packFile(0, revision: 2));
      expect(await store.readAllInstalled(), hasLength(5));
      expect((await store.readInstalled('pack-0'))!.manifest.pack.revision, 2);

      final pro = LocalPackStore(
        root,
        entitlement: const Entitlement(isProTestEnabled: true),
      );
      await pro.install(sixth);
      await pro.install(await packFile(6));
      expect(await pro.readAllInstalled(), hasLength(7));
      // Returning to Free never evicts or hides already installed content.
      expect(await store.readAllInstalled(), hasLength(7));
      await expectLater(store.install(await packFile(7)), throwsStateError);
    },
  );

  test('concurrent imports cannot exceed the last Free storage slot', () async {
    final store = LocalPackStore(root);
    for (var index = 0; index < 4; index++) {
      await store.install(await packFile(index));
    }
    final candidates = [await packFile(4), await packFile(5)];
    final outcomes = await Future.wait([
      for (final file in candidates)
        LocalPackStore(root)
            .install(file)
            .then(
              (_) => true,
              onError: (Object error) {
                expect(error, isStateError);
                return false;
              },
            ),
    ]);
    expect(outcomes.where((success) => success), hasLength(1));
    expect(await store.readAllInstalled(), hasLength(5));
  });
}
