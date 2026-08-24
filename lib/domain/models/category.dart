/// Represents a game category with anime assets and branding
class GameCategory {
  final String name;
  final String path;
  final String logoPath;

  const GameCategory({
    required this.name,
    required this.path,
    required this.logoPath,
  });

  /// Map representation for backward compatibility
  Map<String, String> toMap() {
    return {
      'name': name,
      'path': path,
      'logo_path': logoPath,
    };
  }

  factory GameCategory.fromMap(Map<String, String> map) {
    return GameCategory(
      name: map['name'] ?? '',
      path: map['path'] ?? '',
      logoPath: map['logo_path'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCategory &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          logoPath == other.logoPath;

  @override
  int get hashCode => name.hashCode ^ path.hashCode ^ logoPath.hashCode;
}
