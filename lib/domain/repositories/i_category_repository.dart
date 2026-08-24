import '../models/category.dart';

/// Contract for category data access
abstract class ICategoryRepository {
  List<GameCategory> getCategories();

  List<String> getAssetsForCategory(String categoryName);

  String? extractCharacterName(String assetPath);
}
