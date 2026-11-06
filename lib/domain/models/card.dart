import 'content_validation.dart';
import 'difficulty.dart';

/// One topic-agnostic playable identity: a technical ID and exactly the four
/// MVP product fields. Publishing/revision/deletion state is not gameplay data.
final class Card {
  final String id;
  final String packId;
  final String name;

  /// Opaque image reference, resolved by the content/image layer. This model
  /// does not access files or the network and allows bundled paths with spaces.
  final String imageReference;
  final Difficulty difficulty;

  Card({
    required String id,
    required String packId,
    required String name,
    required String imageReference,
    required this.difficulty,
  }) : id = ContentValidation.id(id, 'id'),
       packId = ContentValidation.id(packId, 'packId'),
       name = ContentValidation.text(name, 'name'),
       imageReference = ContentValidation.text(
         imageReference,
         'imageReference',
       );

  factory Card.fromJson(Map<String, dynamic> json) => Card(
    id: ContentValidation.readString(json, 'id'),
    packId: ContentValidation.readString(json, 'packId'),
    name: ContentValidation.readString(json, 'name'),
    imageReference: ContentValidation.readString(json, 'imageReference'),
    difficulty: Difficulty.fromJson(json['difficulty']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'packId': packId,
    'name': name,
    'imageReference': imageReference,
    'difficulty': difficulty.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          id == other.id &&
          packId == other.packId &&
          name == other.name &&
          imageReference == other.imageReference &&
          difficulty == other.difficulty;

  @override
  int get hashCode => Object.hash(id, packId, name, imageReference, difficulty);
}
