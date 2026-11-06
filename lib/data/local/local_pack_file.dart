import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;

import '../../domain/models/card.dart';
import '../../domain/models/content_validator.dart';
import '../../domain/models/pack.dart';
import '../../domain/models/topic.dart';

/// Resource ceilings for untrusted inputs, configurable by the storage caller.
/// These are defensive allocation limits, not entitlement or Pack product rules.
final class PackImportLimits {
  final int fileBytes;
  final int imagePixels;
  const PackImportLimits({
    this.fileBytes = 256 * 1024 * 1024,
    this.imagePixels = 16 * 1024 * 1024,
  });
}

/// The T09 full-Pack v1 contract, with provenance outside gameplay models.
final class LocalPackManifest {
  final Topic topic;
  final Pack pack;
  final List<Card> cards;
  final List<LocalPackImage> images;
  final String _canonical;

  const LocalPackManifest._(
    this.topic,
    this.pack,
    this.cards,
    this.images,
    this._canonical,
  );

  factory LocalPackManifest.fromJson(Map<String, dynamic> json) {
    record(json, {
      'schemaVersion',
      'kind',
      'topic',
      'pack',
      'cards',
      'objects',
      'provenance',
    });
    if (json['schemaVersion'] != 1 ||
        json['schemaVersion'] is! int ||
        json['kind'] != 'full') {
      throw const FormatException('Unsupported full-Pack schema');
    }
    final topicJson = record(json['topic'], {'id', 'name'});
    final packJson = record(json['pack'], {
      'id',
      'topicId',
      'name',
      'revision',
    });
    final topic = Topic.fromJson(topicJson);
    final pack = Pack.fromJson(packJson);
    text(topic.id);
    text(pack.id);
    text(pack.topicId);
    text(topic.name);
    text(pack.name);
    final rawCards = json['cards'];
    final rawImages = json['objects'];
    if (rawCards is! List || rawImages is! List) {
      throw const FormatException('Invalid Card/object lists');
    }
    final cards = rawCards.map((value) {
      final card = Card.fromJson(
        record(value, {'id', 'packId', 'name', 'imageReference', 'difficulty'}),
      );
      text(card.name);
      text(card.id);
      text(card.packId);
      return card;
    }).toList();
    final images = rawImages
        .map((value) => LocalPackImage.fromJson(object(value)))
        .toList();
    ContentValidator.validateRelations(
      topics: [topic],
      packs: [pack],
      cards: cards,
    );
    ContentValidator.validatePlayablePack(pack: pack, cards: cards);
    final paths = <String>{};
    for (final object in images) {
      if (!paths.add(object.path)) {
        throw const FormatException('Duplicate image object');
      }
    }
    final references = cards.map((card) => card.imageReference).toSet();
    if (references.length != paths.length || !references.containsAll(paths)) {
      throw const FormatException('Card/object references do not match');
    }
    _provenance(json['provenance'], cards.map((card) => card.id).toSet());
    return LocalPackManifest._(
      topic,
      pack,
      List.unmodifiable(cards),
      List.unmodifiable(images),
      canonicalJson(json),
    );
  }

  Map<String, dynamic> toJson() => object(jsonDecode(_canonical));
  String get digest => sha256.convert(utf8.encode(_canonical)).toString();
  List<int> get metadataBytes => utf8.encode(_canonical);

  static String canonicalJson(Object? value) {
    Object? sorted(Object? value) {
      if (value is Map<String, dynamic>) {
        return {
          for (final key in value.keys.toList()..sort())
            key: sorted(value[key]),
        };
      }
      if (value is List) return value.map(sorted).toList();
      return value;
    }

    return '${jsonEncode(sorted(value))}\n';
  }

  static Map<String, dynamic> object(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return value;
  }

  static Map<String, dynamic> record(Object? value, Set<String> keys) {
    final json = object(value);
    if (json.length != keys.length || !keys.containsAll(json.keys)) {
      throw const FormatException('Missing or unexpected manifest fields');
    }
    return json;
  }

  static void text(Object? value) {
    if (value is! String ||
        value.isEmpty ||
        value.trim() != value ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
      throw const FormatException(
        'Expected nonempty trimmed text without controls',
      );
    }
    // The canonical UTF-8 round trip also rejects unpaired UTF-16 surrogates.
    if (utf8.decode(utf8.encode(value)) != value) {
      throw const FormatException('Invalid UTF-8 text');
    }
  }

  static const _rights = {
    'rights_status',
    'permission_to_publish',
    'public_test_publishable',
    'source',
    'license',
    'attribution',
  };

  static void _cleared(Map<String, dynamic> rights) {
    if (rights['rights_status'] != 'cleared' ||
        rights['permission_to_publish'] != true ||
        rights['public_test_publishable'] != true) {
      throw const FormatException('Invalid test clearance');
    }
    for (final field in ['source', 'license', 'attribution']) {
      text(rights[field]);
    }
  }

  static void _provenance(Object? value, Set<String> cards) {
    final json = record(value, {'mode', 'packRights', 'cardRights'});
    final rows = json['cardRights'];
    if (rows is! List) throw const FormatException('Invalid Card provenance');
    if (json['mode'] == 'cleared-test') {
      _cleared(record(json['packRights'], _rights));
      final ids = <String>{};
      for (final row in rows) {
        final rights = record(row, {..._rights, 'id'});
        if (rights['id'] is! String || !ids.add(rights['id'] as String)) {
          throw const FormatException('Duplicate/invalid Card provenance');
        }
        _cleared(rights);
      }
      if (ids.length != cards.length || !ids.containsAll(cards)) {
        throw const FormatException('Missing Card provenance');
      }
    } else {
      final rights = record(json['packRights'], {
        'rights_status',
        'permission_to_publish',
        'public_test_publishable',
      });
      if (json['mode'] != 'legacy-development' ||
          rows.isNotEmpty ||
          rights['rights_status'] != 'unverified' ||
          rights['permission_to_publish'] != false ||
          rights['public_test_publishable'] != false) {
        throw const FormatException('Invalid development provenance');
      }
    }
  }
}

final class LocalPackImage {
  final String path;
  final int size;
  final String hash;
  final String mediaType;
  const LocalPackImage._(this.path, this.size, this.hash, this.mediaType);

  factory LocalPackImage.fromJson(Map<String, dynamic> json) {
    LocalPackManifest.record(json, {'key', 'sizeBytes', 'sha256', 'mediaType'});
    final path = json['key'];
    final size = json['sizeBytes'];
    final hash = json['sha256'];
    final media = json['mediaType'];
    if (path is! String ||
        size is! int ||
        size < 1 ||
        hash is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        !{
          'image/webp': 'webp',
          'image/png': 'png',
          'image/jpeg': 'jpg',
        }.entries.any(
              (entry) =>
                  media == entry.key && path == 'objects/$hash.${entry.value}',
            )) {
      throw const FormatException(
        'Invalid object key, size, hash or media type',
      );
    }
    return LocalPackImage._(path, size, hash, media as String);
  }

  void verify(List<int> bytes) {
    if (bytes.length != size || sha256.convert(bytes).toString() != hash) {
      throw FormatException('Image integrity check failed: $path');
    }
  }

  void verifyEncoding(Uint8List bytes, PackImportLimits limits) {
    final decoder = switch (mediaType) {
      'image/png' => image.PngDecoder(),
      'image/webp' => image.WebPDecoder(),
      _ => image.JpegDecoder(),
    };
    final info = decoder.startDecode(bytes);
    if (info == null ||
        info.width < 1 ||
        info.height < 1 ||
        (info is image.WebPInfo ? info.hasAnimation : info.numFrames != 1) ||
        (info is image.PngInfo && info.isAnimated) ||
        info.width * info.height > limits.imagePixels ||
        decoder.decodeFrame(0) == null) {
      throw FormatException('Invalid, animated or oversized image: $path');
    }
  }
}

/// Strict ZIP_STORED reader for the T09 container. No extraction utility receives
/// archive paths. Check local and central headers, duplicate names, CRCs and exact
/// entry coverage before considering the manifest or allocating image decoders.
final class LocalPackFile {
  final LocalPackManifest manifest;
  final Map<String, Uint8List> objects;
  const LocalPackFile._(this.manifest, this.objects);

  factory LocalPackFile.decode(Uint8List bytes, PackImportLimits limits) {
    if (bytes.length > limits.fileBytes) {
      throw const FormatException('Pack file exceeds size limit');
    }
    final directory = ZipDirectory()..read(InputMemoryStream(bytes));
    if (directory.filePosition < 0 ||
        directory.filePosition + 22 != bytes.length ||
        directory.numberOfThisDisk != 0 ||
        directory.diskWithTheStartOfTheCentralDirectory != 0 ||
        directory.totalCentralDirectoryEntries !=
            directory.fileHeaders.length ||
        directory.totalCentralDirectoryEntriesOnThisDisk !=
            directory.fileHeaders.length ||
        directory.centralDirectoryOffset + directory.centralDirectorySize !=
            directory.filePosition) {
      throw const FormatException('Invalid or incomplete ZIP directory');
    }
    final entries = <String, Uint8List>{};
    var offset = 0;
    final headers = directory.fileHeaders.toList()
      ..sort((a, b) => a.localHeaderOffset.compareTo(b.localHeaderOffset));
    final view = ByteData.sublistView(bytes);
    for (final header in headers) {
      final file = header.file;
      final mode = header.externalFileAttributes >> 16;
      if (file == null ||
          header.localHeaderOffset != offset ||
          file.filename != header.filename ||
          header.compressionMethod != 0 ||
          header.generalPurposeBitFlag & ~0x800 != 0 ||
          header.compressedSize != header.uncompressedSize ||
          header.diskNumberStart != 0 ||
          header.externalFileAttributes & 0x10 != 0 ||
          (mode & 0xf000 != 0 && mode & 0xf000 != 0x8000) ||
          header.filename != 'manifest.json' &&
              !RegExp(
                r'^objects/[a-f0-9]{64}\.(webp|png|jpg)$',
              ).hasMatch(header.filename) ||
          entries.containsKey(header.filename) ||
          offset + 30 > directory.centralDirectoryOffset) {
        throw const FormatException(
          'Unsafe, duplicate or unsupported ZIP entry',
        );
      }
      int u16(int delta) => view.getUint16(offset + delta, Endian.little);
      int u32(int delta) => view.getUint32(offset + delta, Endian.little);
      final dataOffset = offset + 30 + u16(26) + u16(28);
      final end = dataOffset + header.uncompressedSize;
      if (u32(0) != 0x04034b50 ||
          u16(6) != header.generalPurposeBitFlag ||
          u16(8) != 0 ||
          u32(14) != header.crc32 ||
          u32(18) != header.compressedSize ||
          u32(22) != header.uncompressedSize ||
          end > directory.centralDirectoryOffset ||
          header.uncompressedSize > limits.fileBytes) {
        throw const FormatException('Inconsistent ZIP headers or sizes');
      }
      final data = Uint8List.sublistView(bytes, dataOffset, end);
      if (getCrc32(data) != header.crc32) {
        throw const FormatException('ZIP CRC mismatch');
      }
      entries[header.filename] = data;
      offset = end;
    }
    if (offset != directory.centralDirectoryOffset ||
        !entries.containsKey('manifest.json')) {
      throw const FormatException('Missing manifest or unlisted ZIP entries');
    }
    final raw = utf8.decode(entries.remove('manifest.json')!);
    final manifest = LocalPackManifest.fromJson(
      LocalPackManifest.object(jsonDecode(raw)),
    );
    // T09 requires canonical JSON. This also rejects duplicate JSON keys, which
    // dart:convert would otherwise silently overwrite during parsing.
    if (raw != LocalPackManifest.canonicalJson(manifest.toJson())) {
      throw const FormatException(
        'Manifest must use canonical JSON without duplicate keys',
      );
    }
    if (entries.length != manifest.images.length) {
      throw const FormatException('Unexpected or missing image entries');
    }
    for (final object in manifest.images) {
      final data = entries[object.path];
      if (data == null) throw const FormatException('Missing image object');
      object.verify(data);
      object.verifyEncoding(data, limits);
    }
    return LocalPackFile._(manifest, Map.unmodifiable(entries));
  }
}
