import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'local_pack_file.dart';

/// Portable reference to one image in an immutable private generation.
/// No absolute paths, network URLs or caller-selected container names.
final class PrivateImageReference {
  static final _pattern = RegExp(
    r'^biguess-pack:([a-f0-9]{64})/(generation-[A-Za-z0-9]+)/objects/([a-f0-9]{64})\.(png|jpg|webp)\?offset=([0-9]+)&size=([0-9]+)$',
  );
  final String packDirectory;
  final String generation;
  final String hash;
  final String extension;
  final int offset;
  final int size;

  const PrivateImageReference._(
    this.packDirectory,
    this.generation,
    this.hash,
    this.extension,
    this.offset,
    this.size,
  );

  factory PrivateImageReference.parse(String value) {
    final match = _pattern.firstMatch(value);
    final offset = int.tryParse(match?.group(5) ?? '');
    final size = int.tryParse(match?.group(6) ?? '');
    if (match == null ||
        offset == null ||
        size == null ||
        offset < PrivatePackImages.header.length ||
        offset > const PackImportLimits().fileBytes ||
        size < 1 ||
        size > PrivatePackImages.maxImageBytes) {
      throw const FormatException('Invalid private image reference');
    }
    return PrivateImageReference._(
      match[1]!,
      match[2]!,
      match[3]!,
      match[4]!,
      offset,
      size,
    );
  }

  String get objectPath => 'objects/$hash.$extension';

  @override
  String toString() =>
      'biguess-pack:$packDirectory/$generation/$objectPath'
      '?offset=$offset&size=$size';
}

/// Private packaging, not encryption or DRM. Images stay in one non-gallery
/// container; reads seek to a single encoded image and never unpack to disk.
abstract final class PrivatePackImages {
  static const fileName = 'images.bgpack';
  static const header = <int>[66, 71, 73, 77, 71, 48, 49, 10]; // BGIMG01\n
  static const maxImageBytes = 16 * 1024 * 1024;

  static Uint8List encode(
    LocalPackManifest manifest,
    Map<String, Uint8List> objects,
  ) {
    final builder = BytesBuilder(copy: false)..add(header);
    for (final image in manifest.images) {
      if (image.size > maxImageBytes) {
        throw const FormatException('Encoded image exceeds storage limit');
      }
      builder.add(objects[image.path]!);
    }
    return builder.takeBytes();
  }

  static Map<String, String> references(
    LocalPackManifest manifest,
    Directory directory,
  ) {
    var offset = header.length;
    final references = <String, String>{};
    for (final image in manifest.images) {
      references[image.path] =
          'biguess-pack:${p.basename(directory.parent.path)}/'
          '${p.basename(directory.path)}/${image.path}'
          '?offset=$offset&size=${image.size}';
      offset += image.size;
    }
    return references;
  }

  /// Used once at staging/reopen. Legacy T10 loose generations remain readable.
  static Future<void> verify(
    LocalPackManifest manifest,
    Directory directory,
  ) async {
    final container = File(p.join(directory.path, fileName));
    final packed = await container.exists();
    if (packed &&
        await container.length() !=
            header.length +
                manifest.images.fold<int>(0, (n, image) => n + image.size)) {
      throw const FormatException('Invalid private image container length');
    }
    var offset = header.length;
    for (final image in manifest.images) {
      image.verify(
        await _readObject(directory, image.path, offset, image.size),
      );
      offset += image.size;
    }
  }

  static Future<Uint8List> read(
    Directory root,
    PrivateImageReference reference,
  ) async {
    final directory = Directory(
      p.join(root.path, reference.packDirectory, reference.generation),
    );
    // Refuse symlink escapes even for syntactically valid references.
    final privateRoot = await root.resolveSymbolicLinks();
    final resolved = await directory.resolveSymbolicLinks();
    if (!p.isWithin(privateRoot, resolved)) {
      throw const FormatException('Image is outside private storage');
    }
    final bytes = await _readObject(
      directory,
      reference.objectPath,
      reference.offset,
      reference.size,
    );
    if (sha256.convert(bytes).toString() != reference.hash) {
      throw const FormatException('Private image integrity check failed');
    }
    return bytes;
  }

  static Future<Uint8List> _readObject(
    Directory directory,
    String objectPath,
    int offset,
    int size,
  ) async {
    if (size < 1 || size > maxImageBytes) {
      throw const FormatException('Encoded image exceeds storage limit');
    }
    final container = File(p.join(directory.path, fileName));
    final packed = await container.exists();
    final file = packed ? container : File(p.join(directory.path, objectPath));
    final resolved = await file.resolveSymbolicLinks();
    if (!p.isWithin(await directory.resolveSymbolicLinks(), resolved)) {
      throw const FormatException('Image file escapes its generation');
    }
    final handle = await file.open();
    try {
      final length = await handle.length();
      if (packed) {
        final magic = await handle.read(header.length);
        if (magic.length != header.length ||
            Iterable<int>.generate(
              header.length,
            ).any((index) => magic[index] != header[index]) ||
            offset < header.length ||
            offset + size > length) {
          throw const FormatException('Invalid private image container');
        }
        await handle.setPosition(offset);
      } else if (length != size) {
        throw const FormatException('Invalid legacy image length');
      }
      final bytes = await handle.read(size);
      if (bytes.length != size) {
        throw const FormatException('Truncated private image');
      }
      return bytes;
    } finally {
      await handle.close();
    }
  }
}
