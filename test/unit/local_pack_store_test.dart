import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:gdg_guess_game/data/local/local_pack_file.dart';
import 'package:gdg_guess_game/data/local/local_pack_store.dart';
import 'package:gdg_guess_game/data/local/private_pack_images.dart';
import 'package:path/path.dart' as p;

class FailingStorage extends PackStorageIo {
  final int? failWrite;
  final bool failActivation;
  final bool corruptWrite;
  final int corruptAt;
  int writes = 0;
  Future<void> Function()? beforeActivation;

  FailingStorage({
    this.failWrite,
    this.failActivation = false,
    this.corruptWrite = false,
    this.corruptAt = 1,
  });

  @override
  Future<void> write(File file, List<int> bytes) async {
    writes++;
    if (writes == failWrite) {
      await super.write(file, bytes.take(bytes.length ~/ 2).toList());
      throw FileSystemException('No space left on device', file.path);
    }
    await super.write(file, corruptWrite && writes == corruptAt ? [0] : bytes);
  }

  @override
  Future<void> activate(File pending, File active) async {
    await beforeActivation?.call();
    if (failActivation) throw FileSystemException('Rename failed', active.path);
    await super.activate(pending, active);
  }
}

void main() {
  late Directory temp;
  late Directory root;
  late LocalPackStore store;
  late File source;
  late Map<String, dynamic> fixture;
  late Map<String, Uint8List> objects;

  Future<File> writePack(
    Map<String, dynamic> json, {
    Map<String, Uint8List>? payloads,
    String? rawManifest,
    String? link,
  }) async {
    final archive = Archive();
    final entries = <String, List<int>>{
      'manifest.json': utf8.encode(
        rawManifest ?? LocalPackManifest.canonicalJson(json),
      ),
      ...(payloads ?? objects),
    };
    for (final entry in entries.entries) {
      final file = ArchiveFile(entry.key, entry.value.length, entry.value)
        ..compression = CompressionType.none
        ..mode = entry.key == link ? 0xa1ff : 0x81a4;
      archive.add(file);
    }
    await source.writeAsBytes(ZipEncoder().encodeBytes(archive));
    return source;
  }

  Future<void> expectPreviousIntact(InstalledLocalPack previous) async {
    final reopened = await LocalPackStore(root).readInstalled('fixture-pack');
    expect(reopened!.manifest.digest, previous.manifest.digest);
    expect(reopened.directory.path, previous.directory.path);
    for (final card in reopened.cards) {
      final key = reopened.manifest.cards
          .singleWhere((value) => value.id == card.id)
          .imageReference;
      expect(
        await PrivatePackImages.read(
          root,
          PrivateImageReference.parse(card.imageReference),
        ),
        objects[key],
      );
    }
  }

  Map<String, dynamic> copy() =>
      jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
  Map<String, dynamic> pack(Map<String, dynamic> json) =>
      json['pack'] as Map<String, dynamic>;
  List<dynamic> cards(Map<String, dynamic> json) =>
      json['cards'] as List<dynamic>;
  List<dynamic> images(Map<String, dynamic> json) =>
      json['objects'] as List<dynamic>;
  final invalid = throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>()));

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('biguess-import-test-');
    root = Directory(p.join(temp.path, 'private-packs'));
    store = LocalPackStore(root);
    source = File(p.join(temp.path, 'input.biguesspack'));
    await File('test/fixtures/local_pack/colors.biguesspack').copy(source.path);
    final archive = ZipDecoder().decodeBytes(await source.readAsBytes());
    fixture =
        jsonDecode(utf8.decode(archive.find('manifest.json')!.content))
            as Map<String, dynamic>;
    objects = {
      for (final entry in archive.files.where(
        (file) => file.name != 'manifest.json',
      ))
        entry.name: Uint8List.fromList(entry.content),
    };
  });

  tearDown(() async => temp.delete(recursive: true));

  test(
    'T09 exported fixture installs and survives restart without source files',
    () async {
      final installed = await store.install(source);
      expect(installed.manifest.pack.revision, 1);
      expect(installed.cards.map((card) => card.name), ['Red', 'Blue']);
      expect(() => installed.cards.clear(), throwsUnsupportedError);
      await source.delete();
      await expectPreviousIntact(installed);
      expect(await LocalPackStore(root).readAllInstalled(), hasLength(1));
      expect(await store.readInstalled('unknown'), isNull);
    },
  );

  test('new installs package images without loose gallery files', () async {
    final installed = await store.install(source);
    final files = await installed.directory.list(recursive: true).toList();
    expect(files.map((file) => p.basename(file.path)).toSet(), {
      'manifest.json',
      PrivatePackImages.fileName,
    });
    expect(
      installed.cards.every(
        (card) => card.imageReference.startsWith('biguess-pack:'),
      ),
      isTrue,
    );
    // References survive relocation of the application support directory.
    final moved = await root.rename(p.join(temp.path, 'relocated-private'));
    final reopened = (await LocalPackStore(
      moved,
    ).readInstalled('fixture-pack'))!;
    expect(reopened.cards, installed.cards);
    for (final card in reopened.cards) {
      expect(
        await PrivatePackImages.read(
          moved,
          PrivateImageReference.parse(card.imageReference),
        ),
        isNotEmpty,
      );
    }
  });

  test(
    'pre-T11 loose generations reopen without rewriting their images',
    () async {
      final installed = await store.install(source);
      await Directory(p.join(installed.directory.path, 'objects')).create();
      for (final object in objects.entries) {
        await File(
          p.join(installed.directory.path, object.key),
        ).writeAsBytes(object.value);
      }
      await File(
        p.join(installed.directory.path, PrivatePackImages.fileName),
      ).delete();
      await expectPreviousIntact(installed);
    },
  );

  test('tampered private payload fails reopening and direct loading', () async {
    final installed = await store.install(source);
    final container = File(
      p.join(installed.directory.path, PrivatePackImages.fileName),
    );
    final bytes = await container.readAsBytes();
    bytes[PrivatePackImages.header.length] ^= 0xff;
    await container.writeAsBytes(bytes);
    await expectLater(
      store.readInstalled('fixture-pack'),
      throwsFormatException,
    );
    final first = PrivateImageReference.parse(
      installed.cards.first.imageReference,
    );
    await expectLater(
      PrivatePackImages.read(root, first),
      throwsFormatException,
    );
  });

  test(
    'private reader rejects traversal, URLs, bounds and symlink escapes',
    () async {
      final installed = await store.install(source);
      final value = installed.cards.first.imageReference;
      for (final invalid in [
        '/storage/DCIM/image.jpg',
        'https://example.com/image.jpg',
        value.replaceFirst('generation-', '../generation-'),
        value.replaceFirst(RegExp(r'offset=\d+'), 'offset=0'),
        value.replaceFirst(RegExp(r'size=\d+'), 'size=999999999'),
      ]) {
        expect(
          () => PrivateImageReference.parse(invalid),
          throwsFormatException,
        );
      }
      final container = File(
        p.join(installed.directory.path, PrivatePackImages.fileName),
      );
      final outside = await container.copy(p.join(temp.path, 'outside.bgpack'));
      await container.delete();
      await Link(container.path).create(outside.path);
      await expectLater(
        PrivatePackImages.read(root, PrivateImageReference.parse(value)),
        throwsFormatException,
      );
    },
  );

  test('valid retry reuses generation; tampered retry still fails', () async {
    final first = await store.install(source);
    expect((await store.install(source)).directory.path, first.directory.path);
    final bad = {...objects};
    bad[objects.keys.first] = Uint8List(objects.values.first.length);
    await expectLater(
      store.install(await writePack(copy(), payloads: bad)),
      throwsFormatException,
    );
    await expectPreviousIntact(first);
  });

  test(
    'update is invisible until activation and retains previous snapshot files',
    () async {
      final first = await store.install(source);
      final update = copy();
      pack(update)['revision'] = 2;
      cards(update)[0]['name'] = 'Renamed red';
      final io = FailingStorage()
        ..beforeActivation = () => expectPreviousIntact(first);
      final next = await LocalPackStore(
        root,
        io: io,
      ).install(await writePack(update));
      expect(next.manifest.pack.revision, 2);
      expect(next.cards.first.name, 'Renamed red');
      expect(next.directory.path, isNot(first.directory.path));
      expect(
        await PrivatePackImages.read(
          root,
          PrivateImageReference.parse(first.cards.first.imageReference),
        ),
        objects[first.manifest.cards.first.imageReference],
      );
      expect(
        (await LocalPackStore(
          root,
        ).readInstalled('fixture-pack'))!.manifest.digest,
        next.manifest.digest,
      );
    },
  );

  final malformedCases = <String, void Function(Map<String, dynamic>)>{
    'unsupported format': (json) => json['schemaVersion'] = 2,
    'wrong kind': (json) => json['kind'] = 'delta',
    'unknown fields': (json) => json['surprise'] = true,
    'missing revision': (json) => pack(json).remove('revision'),
    'wrong topic': (json) => pack(json)['topicId'] = 'missing',
    'wrong Pack': (json) => cards(json)[0]['packId'] = 'missing',
    'duplicate Card': (json) => cards(json)[1]['id'] = cards(json)[0]['id'],
    'unplayable Pack': (json) => cards(json).removeLast(),
    'invalid difficulty': (json) => cards(json)[0]['difficulty'] = 4,
    'missing object': (json) => images(json).removeLast(),
    'duplicate object': (json) => images(json).add(images(json).first),
    'unreferenced object': (json) =>
        cards(json)[1]['imageReference'] = cards(json)[0]['imageReference'],
    'wrong size': (json) => images(json)[0]['sizeBytes'] = 1,
    'wrong hash': (json) =>
        images(json)[0]['sha256'] = List.filled(64, '0').join(),
    'wrong media type': (json) => images(json)[0]['mediaType'] = 'image/jpeg',
    'path traversal': (json) => images(json)[0]['key'] = '../outside.png',
    'absolute path': (json) => images(json)[0]['key'] = '/outside.png',
    'Windows path': (json) => images(json)[0]['key'] = r'..\outside.png',
    'missing provenance': (json) => json.remove('provenance'),
    'false clearance': (json) =>
        (json['provenance']
                as Map<
                  String,
                  dynamic
                >)['packRights']['permission_to_publish'] =
            false,
    'control in name': (json) => cards(json)[0]['name'] = 'a\u0000b',
  };

  for (final entry in malformedCases.entries) {
    test('${entry.key} is rejected without changing installed Pack', () async {
      final first = await store.install(source);
      final bad = copy();
      entry.value(bad);
      await expectLater(store.install(await writePack(bad)), invalid);
      await expectPreviousIntact(first);
    });
  }

  test('missing, partial and extra image entries are rejected', () async {
    final first = await store.install(source);
    for (final payload in [
      {...objects}..remove(objects.keys.first),
      {...objects, objects.keys.first: Uint8List(1)},
      {...objects, '../outside.png': Uint8List(1)},
    ]) {
      await expectLater(
        store.install(await writePack(copy(), payloads: payload)),
        invalid,
      );
      await expectPreviousIntact(first);
    }
  });

  test('matching hash cannot authorize corrupt image bytes', () async {
    final first = await store.install(source);
    final corrupt = Uint8List.fromList([0, 1, 2, 3]);
    final digest = sha256.convert(corrupt).toString();
    final key = 'objects/$digest.png';
    final bad = copy();
    final old = images(bad)[0] as Map<String, dynamic>;
    final oldKey = old['key'] as String;
    old
      ..['key'] = key
      ..['sha256'] = digest
      ..['sizeBytes'] = corrupt.length;
    for (final card in cards(bad)) {
      if (card['imageReference'] == oldKey) card['imageReference'] = key;
    }
    await expectLater(
      store.install(
        await writePack(
          bad,
          payloads: {...objects}
            ..remove(oldKey)
            ..[key] = corrupt,
        ),
      ),
      invalid,
    );
    await expectPreviousIntact(first);
  });

  test('symlinks and duplicate JSON keys are rejected', () async {
    final first = await store.install(source);
    await expectLater(
      store.install(await writePack(copy(), link: objects.keys.first)),
      invalid,
    );
    final raw = LocalPackManifest.canonicalJson(
      copy(),
    ).replaceFirst('{', '{"schemaVersion":1,');
    await expectLater(
      store.install(await writePack(copy(), rawManifest: raw)),
      invalid,
    );
    await expectPreviousIntact(first);
  });

  test(
    'duplicate ZIP filenames are rejected before archive deduplication',
    () async {
      final first = await store.install(source);
      final data = await source.readAsBytes();
      final old = ascii.encode(objects.keys.last);
      final replacement = ascii.encode(objects.keys.first);
      for (var offset = 0; offset <= data.length - old.length; offset++) {
        if (List.generate(
          old.length,
          (index) => data[offset + index] == old[index],
        ).every((match) => match)) {
          data.setRange(offset, offset + old.length, replacement);
        }
      }
      await source.writeAsBytes(data);
      await expectLater(store.install(source), invalid);
      await expectPreviousIntact(first);
    },
  );

  test(
    'truncated ZIP and bounded input limits preserve previous Pack',
    () async {
      final first = await store.install(source);
      final bytes = await source.readAsBytes();
      await source.writeAsBytes(bytes.take(bytes.length - 5).toList());
      await expectLater(store.install(source), invalid);
      await source.writeAsBytes(bytes);
      await expectLater(
        LocalPackStore(
          root,
          limits: const PackImportLimits(fileBytes: 10),
        ).install(source),
        invalid,
      );
      await expectLater(
        LocalPackStore(
          root,
          limits: const PackImportLimits(imagePixels: 1),
        ).install(source),
        invalid,
      );
      await expectPreviousIntact(first);
    },
  );

  for (final ioFactory in <String, FailingStorage Function()>{
    'container write': () => FailingStorage(failWrite: 1),
    'metadata write': () => FailingStorage(failWrite: 2),
    'pointer write': () => FailingStorage(failWrite: 3),
    'atomic rename': () => FailingStorage(failActivation: true),
    'corrupt disk write': () => FailingStorage(corruptWrite: true),
    'corrupt pointer write': () =>
        FailingStorage(corruptWrite: true, corruptAt: 3),
  }.entries) {
    test('${ioFactory.key} failure rolls back and allows retry', () async {
      final first = await store.install(source);
      final update = copy();
      pack(update)['revision'] = 2;
      await writePack(update);
      await expectLater(
        LocalPackStore(root, io: ioFactory.value()).install(source),
        throwsA(anything),
      );
      await expectPreviousIntact(first);
      final directories = await first.directory.parent.list().toList();
      expect(directories.whereType<Directory>(), hasLength(1));
      await store.install(source);
      expect(
        (await store.readInstalled('fixture-pack'))!.manifest.pack.revision,
        2,
      );
    });
  }

  test(
    'failed initial install is never discoverable and can be retried',
    () async {
      await expectLater(
        LocalPackStore(root, io: FailingStorage(failWrite: 2)).install(source),
        throwsA(isA<FileSystemException>()),
      );
      expect(await store.readAllInstalled(), isEmpty);
      await store.install(source);
      expect(await store.readAllInstalled(), hasLength(1));
    },
  );

  test(
    'interrupted staging and pending pointer are ignored then recovered',
    () async {
      final first = await store.install(source);
      final parent = first.directory.parent;
      final leftover = await Directory(
        p.join(parent.path, 'staging-interrupted'),
      ).create();
      await File(p.join(leftover.path, 'partial.png')).writeAsBytes([1]);
      await File(
        p.join(parent.path, 'active.pending'),
      ).writeAsString('generation-incomplete');
      await expectPreviousIntact(first);
      final update = copy();
      pack(update)['revision'] = 2;
      await store.install(await writePack(update));
      expect(await leftover.exists(), isFalse);
    },
  );

  test(
    'same revision conflicts, downgrades and reparenting are rejected',
    () async {
      final first = await store.install(source);
      final conflict = copy();
      pack(conflict)['name'] = 'Conflicting';
      await expectLater(
        store.install(await writePack(conflict)),
        throwsFormatException,
      );
      final reparented = copy();
      (reparented['topic'] as Map<String, dynamic>)['id'] = 'other-topic';
      pack(reparented)
        ..['topicId'] = 'other-topic'
        ..['revision'] = 2;
      await expectLater(
        store.install(await writePack(reparented)),
        throwsFormatException,
      );
      await expectPreviousIntact(first);
      final update = copy();
      pack(update)['revision'] = 2;
      await store.install(await writePack(update));
      await expectLater(
        store.install(await writePack(fixture)),
        throwsFormatException,
      );
    },
  );

  test('different Pack cannot steal installed Card IDs', () async {
    final first = await store.install(source);
    final other = copy();
    pack(other)['id'] = 'other-pack';
    for (final card in cards(other)) {
      card['packId'] = 'other-pack';
    }
    await expectLater(
      store.install(await writePack(other)),
      throwsFormatException,
    );
    await expectPreviousIntact(first);
    expect(await store.readAllInstalled(), hasLength(1));
  });

  test('concurrent installers serialize and reuse one generation', () async {
    final installed = await Future.wait(
      List.generate(4, (_) => LocalPackStore(root).install(source)),
    );
    expect(installed.map((pack) => pack.directory.path).toSet(), hasLength(1));
    expect(await store.readAllInstalled(), hasLength(1));
  });

  test(
    'full update replaces Cards and supports a shared image object',
    () async {
      final first = await store.install(source);
      final update = copy();
      pack(update)['revision'] = 2;
      final key = cards(update)[0]['imageReference'] as String;
      cards(update)[0]['id'] = 'replacement-card';
      cards(update)[0]['name'] = 'Étoile 紙';
      cards(update)[1]['imageReference'] = key;
      images(update).removeWhere((dynamic row) => row['key'] != key);
      final rights =
          (update['provenance'] as Map<String, dynamic>)['cardRights']
              as List<dynamic>;
      rights[0]['id'] = 'replacement-card';
      final next = await store.install(
        await writePack(update, payloads: {key: objects[key]!}),
      );
      expect(next.cards.map((card) => card.id), [
        'replacement-card',
        'fixture-card-2',
      ]);
      expect(next.cards.first.name, 'Étoile 紙');
      expect(
        next.cards.map((card) => card.imageReference).toSet(),
        hasLength(1),
      );
      expect(first.cards.first.id, 'fixture-card-1');
      expect(
        (await LocalPackStore(root).readInstalled('fixture-pack'))!.cards,
        next.cards,
      );
    },
  );
  for (final extension in ['webp', 'jpg']) {
    test(
      'valid static $extension images install with shared object references',
      () async {
        final data = extension == 'webp'
            ? base64Decode(
                'UklGRjwAAABXRUJQVlA4IDAAAADQAQCdASoIAAgAAUAmJaACdLoB+AADsAD+8ut//NgVzXPv9//S4P0uD9Lg/9KQAAA=',
              )
            : image.encodeJpg(image.Image(width: 8, height: 8));
        final hash = sha256.convert(data).toString();
        final key = 'objects/$hash.$extension';
        final json = copy();
        for (final card in cards(json)) {
          card['imageReference'] = key;
        }
        json['objects'] = [
          {
            'key': key,
            'sha256': hash,
            'sizeBytes': data.length,
            'mediaType': extension == 'jpg' ? 'image/jpeg' : 'image/webp',
          },
        ];
        final installed = await store.install(
          await writePack(json, payloads: {key: data}),
        );
        expect(installed.cards, hasLength(2));
        expect(
          await PrivatePackImages.read(
            root,
            PrivateImageReference.parse(installed.cards.first.imageReference),
          ),
          data,
        );
      },
    );
  }
}
