import 'dart:math';
import '../../core/utils/asset_loader.dart';
import '../models/character_algorithm.dart';

/// Result wrapper for character selection
class CharacterSelectionResult {
  final String? assetPath;
  final String? characterName;
  final List<String> updatedRemainingImages;
  final bool hasImages;

  const CharacterSelectionResult({
    this.assetPath,
    this.characterName,
    required this.updatedRemainingImages,
    required this.hasImages,
  });

  factory CharacterSelectionResult.empty() {
    return const CharacterSelectionResult(
      assetPath: null,
      characterName: null,
      updatedRemainingImages: [],
      hasImages: false,
    );
  }
}

/// Use case that selects the next character given an algorithm
class SelectCharacterUseCase {
  final Random _random;

  SelectCharacterUseCase({Random? random}) : _random = random ?? Random();

  CharacterSelectionResult call({
    required List<String> allImages,
    required List<String> remainingImages,
    required CharacterAlgorithm algorithm,
  }) {
    if (allImages.isEmpty) {
      return CharacterSelectionResult.empty();
    }

    if (algorithm == CharacterAlgorithm.random) {
      final idx = _random.nextInt(allImages.length);
      final asset = allImages[idx];
      final name = AssetLoader.extractCharacterName(asset);
      return CharacterSelectionResult(
        assetPath: asset,
        characterName: name,
        updatedRemainingImages: remainingImages,
        hasImages: true,
      );
    } else {
      // Non-repeating rotation algorithm
      List<String> currentPool = List<String>.from(remainingImages);
      if (currentPool.isEmpty) {
        currentPool = List<String>.from(allImages);
      }

      if (currentPool.isEmpty) {
        return CharacterSelectionResult.empty();
      }

      final idx = _random.nextInt(currentPool.length);
      final asset = currentPool.removeAt(idx);
      final name = AssetLoader.extractCharacterName(asset);

      return CharacterSelectionResult(
        assetPath: asset,
        characterName: name,
        updatedRemainingImages: currentPool,
        hasImages: true,
      );
    }
  }
}
