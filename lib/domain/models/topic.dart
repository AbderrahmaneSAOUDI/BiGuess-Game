import 'content_validation.dart';

/// Immutable content category. Operational state belongs to containers, never
/// to the game-domain Card. Unpublished content is distinct from deleted content.
final class Topic {
  final String id;
  final String name;
  final bool published;
  final bool deleted;
  final int revision;

  Topic({
    required String id,
    required String name,
    this.published = false,
    this.deleted = false,
    int revision = 1,
  })  : id = ContentValidation.id(id, 'id'),
        name = ContentValidation.text(name, 'name'),
        revision = ContentValidation.revision(revision);

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: ContentValidation.readString(json, 'id'),
        name: ContentValidation.readString(json, 'name'),
        published: ContentValidation.readBool(json, 'published'),
        deleted: ContentValidation.readBool(json, 'deleted'),
        revision: ContentValidation.readRevision(json),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'published': published,
        'deleted': deleted,
        'revision': revision,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topic &&
          id == other.id &&
          name == other.name &&
          published == other.published &&
          deleted == other.deleted &&
          revision == other.revision;

  @override
  int get hashCode => Object.hash(id, name, published, deleted, revision);
}
