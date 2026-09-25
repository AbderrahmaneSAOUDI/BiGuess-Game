import '../../assets_manifest.dart' as manifest;
import '../../core/utils/asset_loader.dart';

/// Data source interface for asset manifest interactions
abstract class IAssetManifestDataSource {
  Map<String, List<String>> getCategoryAssetsMap();
  List<String> getAssetsForCategory(String categoryName);
  String? extractCharacterName(String assetPath);
}

/// Implementation using static generated asset manifest
class AssetManifestDataSource implements IAssetManifestDataSource {
  const AssetManifestDataSource();

  @override
  Map<String, List<String>> getCategoryAssetsMap() {
    return manifest.categoryAssets;
  }

  @override
  List<String> getAssetsForCategory(String categoryName) {
    return manifest.categoryAssets[categoryName] ?? [];
  }

  @override
  String? extractCharacterName(String assetPath) {
    return AssetLoader.extractCharacterName(assetPath);
  }
}
