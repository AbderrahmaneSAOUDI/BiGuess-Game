import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/card.dart';
import '../../domain/models/entitlement.dart';
import 'local_pack_file.dart';
import 'private_pack_images.dart';

/// An immutable installed revision. Its directory remains available to readers
/// after an update, so existing snapshots can finish using their original files.
final class InstalledLocalPack {
  final LocalPackManifest manifest;
  final Directory directory;
  late final List<Card> cards;

  InstalledLocalPack._(this.manifest, this.directory) {
    final references = PrivatePackImages.references(manifest, directory);
    cards = List.unmodifiable(
      manifest.cards.map(
        (card) => Card(
          id: card.id,
          packId: card.packId,
          name: card.name,
          imageReference: references[card.imageReference]!,
          difficulty: card.difficulty,
        ),
      ),
    );
  }
}

/// The write boundary, also allowing deterministic storage-failure tests.
/// [activate] must either rename successfully or leave the old pointer intact.
class PackStorageIo {
  const PackStorageIo();

  Future<void> write(File file, List<int> bytes) async {
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> activate(File pending, File active) async {
    await pending.rename(active.path);
  }
}

/// Local file importer, independent of network, UI and the legacy catalog.
///
/// Metadata and images live in one immutable generation. The only commit point
/// is an atomic same-filesystem rename of a flushed pointer file. Never delete
/// the old pointer first. Filesystem errors propagate to the caller.
final class LocalPackStore {
  static final _queues = <String, Future<void>>{};
  final Directory root;
  final PackStorageIo _io;
  final PackImportLimits limits;
  final Entitlement entitlement;

  /// Supply app-private storage. Tests may supply an isolated temporary root.
  LocalPackStore(
    Directory root, {
    PackStorageIo io = const PackStorageIo(),
    this.limits = const PackImportLimits(),
    this.entitlement = const Entitlement.fromEnvironment(),
  }) : root = root.absolute,
       _io = io;

  static Future<LocalPackStore> openDefault({
    Entitlement entitlement = const Entitlement.fromEnvironment(),
  }) async => LocalPackStore(
    Directory(p.join((await getApplicationSupportDirectory()).path, 'packs')),
    entitlement: entitlement,
  );

  /// Import a self-contained .biguesspack ZIP before making it discoverable.
  /// All writers in this process must use the same owning isolate.
  Future<InstalledLocalPack> install(File source) => _exclusive(() async {
    final archive = LocalPackFile.decode(await _readBounded(source), limits);
    final manifest = archive.manifest;

    final previous = await readInstalled(manifest.pack.id);
    if (previous != null) {
      final old = previous.manifest;
      if (manifest.pack.topicId != old.pack.topicId ||
          manifest.pack.revision < old.pack.revision ||
          (manifest.pack.revision == old.pack.revision &&
              manifest.digest != old.digest)) {
        throw const FormatException('Conflicting or older Pack revision');
      }
      if (manifest.digest == old.digest) return previous;
    }
    final cardIds = manifest.cards.map((card) => card.id).toSet();
    final installedPacks = await readAllInstalled();
    // Counting and activation share the writer lock. Revisions and retries of
    // an existing Pack do not consume a new slot.
    if (previous == null && !entitlement.allowsNewPack(installedPacks.length)) {
      throw StateError('Free storage allows up to 5 downloaded Packs');
    }
    for (final installed in installedPacks) {
      if (installed.manifest.pack.id != manifest.pack.id &&
          installed.cards.any((card) => cardIds.contains(card.id))) {
        throw const FormatException('Card ID belongs to another Pack');
      }
    }

    final packDirectory = _packDirectory(manifest.pack.id);
    await packDirectory.create(recursive: true);
    // A killed writer never activated staging. Recover under the writer lock.
    await for (final entry in packDirectory.list(followLinks: false)) {
      if (entry is Directory && p.basename(entry.path).startsWith('staging-')) {
        await entry.delete(recursive: true);
      }
    }
    var staged = await packDirectory.createTemp('staging-');
    final pending = File(p.join(packDirectory.path, 'active.pending'));
    var activated = false;
    try {
      await _io.write(
        File(p.join(staged.path, PrivatePackImages.fileName)),
        PrivatePackImages.encode(manifest, archive.objects),
      );
      await PrivatePackImages.verify(manifest, staged);
      final metadata = File(p.join(staged.path, 'manifest.json'));
      await _io.write(metadata, manifest.metadataBytes);
      if (sha256.convert(await _readBounded(metadata)).toString() !=
          manifest.digest) {
        throw const FormatException('Staged metadata integrity check failed');
      }
      final name = p
          .basename(staged.path)
          .replaceFirst('staging-', 'generation-');
      staged = await staged.rename(p.join(packDirectory.path, name));
      final result = InstalledLocalPack._(manifest, staged);
      await _io.write(pending, utf8.encode(name));
      if (utf8.decode(await _readBounded(pending, limit: 128)) != name) {
        throw const FormatException('Staged pointer integrity check failed');
      }
      await _io.activate(pending, File(p.join(packDirectory.path, 'active')));
      activated = true;
      return result;
    } finally {
      if (!activated) {
        // Best effort rollback: cleanup must not mask the original failure.
        try {
          if (await staged.exists()) await staged.delete(recursive: true);
          if (await pending.exists()) await pending.delete();
        } on FileSystemException {
          // An interrupted cleanup is harmless: the active pointer is intact.
        }
      }
    }
  });

  /// Reopens and verifies the committed generation, including its images.
  /// Unreferenced directories and pending pointers are never considered installed.
  Future<InstalledLocalPack?> readInstalled(String packId) async {
    final installed = await _readDirectory(_packDirectory(packId));
    if (installed != null && installed.manifest.pack.id != packId) {
      throw const FormatException('Installed Pack ID does not match directory');
    }
    return installed;
  }

  Future<List<InstalledLocalPack>> readAllInstalled() async {
    if (!await root.exists()) return const [];
    final installed = <InstalledLocalPack>[];
    await for (final entry in root.list(followLinks: false)) {
      if (entry is Directory &&
          RegExp(r'^[a-f0-9]{64}$').hasMatch(p.basename(entry.path))) {
        final pack = await _readDirectory(entry);
        if (pack != null) {
          if (p.basename(_packDirectory(pack.manifest.pack.id).path) !=
              p.basename(entry.path)) {
            throw const FormatException(
              'Installed Pack ID does not match directory',
            );
          }
          installed.add(pack);
        }
      }
    }
    installed.sort((a, b) => a.manifest.pack.id.compareTo(b.manifest.pack.id));
    return List.unmodifiable(installed);
  }

  Future<InstalledLocalPack?> _readDirectory(Directory packDirectory) async {
    final active = File(p.join(packDirectory.path, 'active'));
    if (!await active.exists()) return null;
    final name = utf8.decode(await _readBounded(active, limit: 128));
    if (!RegExp(r'^generation-[A-Za-z0-9]+$').hasMatch(name)) {
      throw const FormatException('Invalid installed generation pointer');
    }
    final directory = Directory(p.join(packDirectory.path, name));
    final metadata = File(p.join(directory.path, 'manifest.json'));
    final bytes = await _readBounded(metadata);
    final manifest = LocalPackManifest.fromJson(
      LocalPackManifest.object(jsonDecode(utf8.decode(bytes))),
    );
    if (sha256.convert(bytes).toString() != manifest.digest) {
      throw const FormatException('Installed metadata integrity check failed');
    }
    await PrivatePackImages.verify(manifest, directory);
    return InstalledLocalPack._(manifest, directory);
  }

  Directory _packDirectory(String packId) => Directory(
    p.join(root.path, sha256.convert(utf8.encode(packId)).toString()),
  );

  Future<Uint8List> _readBounded(File file, {int? limit}) async {
    limit ??= limits.fileBytes;
    if (await file.length() > limit) {
      throw const FormatException('Pack file exceeds size limit');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, limit + 1)) {
      bytes.add(chunk);
      if (bytes.length > limit) {
        throw const FormatException('Pack file exceeds size limit');
      }
    }
    return bytes.takeBytes();
  }

  Future<T> _exclusive<T>(Future<T> Function() operation) async {
    await root.create(recursive: true);
    final key = await root.resolveSymbolicLinks();
    final previous = _queues[key] ?? Future<void>.value();
    final done = Completer<void>();
    _queues[key] = done.future;
    await previous;
    RandomAccessFile? lock;
    try {
      lock = await File(
        p.join(key, '.install.lock'),
      ).open(mode: FileMode.append);
      await lock.lock(FileLock.blockingExclusive);
      return await operation();
    } finally {
      try {
        await lock?.close();
      } finally {
        done.complete();
        if (identical(_queues[key], done.future)) _queues.remove(key);
      }
    }
  }
}
