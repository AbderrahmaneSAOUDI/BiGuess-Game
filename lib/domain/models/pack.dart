import 'content_validation.dart';

/// Immutable metadata for a content/download unit. Cards are related by packId
/// rather than held in a mutable list. Revision is a positive content version.
final class Pack {
  final String id;
  final String topicId;
  final String name;
  final bool published;
  final bool deleted;
  final int revision;

  Pack({
    required String id,
    required String topicId,
    required String name,
    this.published = false,
    this.deleted = false,
    int revision = 1,
  }) : id = ContentValidation.id(id, 'id'),
       topicId = ContentValidation.id(topicId, 'topicId'),
       name = ContentValidation.text(name, 'name'),
       revision = ContentValidation.revision(revision);

  factory Pack.fromJson(Map<String, dynamic> json) => Pack(
    id: ContentValidation.readString(json, 'id'),
    topicId: ContentValidation.readString(json, 'topicId'),
    name: ContentValidation.readString(json, 'name'),
    published: ContentValidation.readBool(json, 'published'),
    deleted: ContentValidation.readBool(json, 'deleted'),
    revision: ContentValidation.readRevision(json),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'topicId': topicId,
    'name': name,
    'published': published,
    'deleted': deleted,
    'revision': revision,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pack &&
          id == other.id &&
          topicId == other.topicId &&
          name == other.name &&
          published == other.published &&
          deleted == other.deleted &&
          revision == other.revision;

  @override
  int get hashCode =>
      Object.hash(id, topicId, name, published, deleted, revision);
}
