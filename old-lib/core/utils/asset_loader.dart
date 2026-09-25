import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset loading and parsing utility functions
class AssetLoader {
  AssetLoader._();

  static Future<List<String>> loadCategoryAssets(String categoryPath) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest
          .listAssets()
          .where((String key) {
            return key.startsWith(categoryPath) &&
                (key.endsWith('.webp') ||
                    key.endsWith('.png') ||
                    key.endsWith('.jpg'));
          })
          .toList();

      return assets;
    } catch (e) {
      debugPrint('Error loading assets: $e');
      return [];
    }
  }

  static String? extractCharacterName(String assetPath) {
    try {
      final parts = assetPath.split('/');
      final filename = parts.isNotEmpty ? parts.last : '';
      final dotIndex = filename.lastIndexOf('.');
      if (dotIndex != -1) {
        return filename.substring(0, dotIndex);
      }
      return filename.isEmpty ? null : filename;
    } catch (e) {
      debugPrint('Error extracting character name: $e');
      return null;
    }
  }
}
