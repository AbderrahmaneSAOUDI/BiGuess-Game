import 'dart:convert';
import 'package:flutter/services.dart';

class AssetLoader {
  static Future<List<String>> loadCategoryAssets(String categoryPath) async {
    try {
      // Get the asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        const JsonDecoder().convert(manifestContent),
      );

      // Filter assets that match the category path and are images
      final List<String> assets = manifestMap.keys.where((String key) {
        return key.startsWith(categoryPath) && 
               (key.endsWith('.webp') || key.endsWith('.png') || key.endsWith('.jpg'));
      }).toList();

      return assets;
    } catch (e) {
      print('Error loading assets: $e');
      return [];
    }
  }

  static String? extractCharacterName(String assetPath) {
    try {
      // Split the path and get the second-to-last part (character name)
      final parts = assetPath.split('/');
      if (parts.length >= 3) {
        return parts[parts.length - 2];
      }
      return null;
    } catch (e) {
      print('Error extracting character name: $e');
      return null;
    }
  }
} 