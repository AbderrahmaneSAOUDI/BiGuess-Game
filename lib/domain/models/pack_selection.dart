import 'content_validation.dart';

enum PackSelectionMode { single, multiple, random }

/// Retained selection uses canonical IDs only; labels are resolved for display.
/// An empty manual selection is valid while configuring, but cannot start play.
final class PackSelection {
  final String topicId;
  final PackSelectionMode mode;
  final List<String> packIds;
  final int randomCount;

  PackSelection({
    required String topicId,
    this.mode = PackSelectionMode.single,
    Iterable<String> packIds = const [],
    this.randomCount = 1,
  }) : topicId = ContentValidation.id(topicId, 'topicId'),
       packIds = List.unmodifiable(
         packIds.map((id) => ContentValidation.id(id, 'packId')),
       ) {
    if (this.packIds.toSet().length != this.packIds.length ||
        (mode == PackSelectionMode.single && this.packIds.length > 1) ||
        (mode == PackSelectionMode.random && this.packIds.isNotEmpty) ||
        randomCount < 1) {
      throw ArgumentError('Invalid Pack selection');
    }
  }

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'mode': mode.name,
    'packIds': packIds,
    'randomCount': randomCount,
  };

  factory PackSelection.fromJson(Map<String, dynamic> json) {
    final mode = PackSelectionMode.values.where(
      (mode) => mode.name == json['mode'],
    );
    final ids = json['packIds'];
    final count = json['randomCount'];
    if (mode.isEmpty ||
        ids is! List ||
        count is! int ||
        ids.any((id) => id is! String)) {
      throw ArgumentError('Invalid Pack selection');
    }
    return PackSelection(
      topicId: ContentValidation.readString(json, 'topicId'),
      mode: mode.single,
      packIds: ids.cast<String>(),
      randomCount: count,
    );
  }
}
