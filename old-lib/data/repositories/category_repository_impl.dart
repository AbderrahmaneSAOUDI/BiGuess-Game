import '../../core/constants/app_constants.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../datasources/asset_manifest_data_source.dart';

/// Concrete repository providing category and character asset data
class CategoryRepositoryImpl implements ICategoryRepository {
  final IAssetManifestDataSource _dataSource;

  const CategoryRepositoryImpl({
    IAssetManifestDataSource dataSource = const AssetManifestDataSource(),
  }) : _dataSource = dataSource;

  @override
  List<GameCategory> getCategories() {
    return AppConstants.categories;
  }

  @override
  List<String> getAssetsForCategory(String categoryName) {
    return _dataSource.getAssetsForCategory(categoryName);
  }

  @override
  String? extractCharacterName(String assetPath) {
    return _dataSource.extractCharacterName(assetPath);
  }
}
