import 'dart:math';
import '../models/character_algorithm.dart';
import '../repositories/i_category_repository.dart';

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
  final ICategoryRepository _repository;
  final Random _random;

  SelectCharacterUseCase({
    required ICategoryRepository repository,
    Random? random,
  })  : _repository = repository,
        _random = random ?? Random();

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
      final name = _repository.extractCharacterName(asset);
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
      final name = _repository.extractCharacterName(asset);

      return CharacterSelectionResult(
        assetPath: asset,
        characterName: name,
        updatedRemainingImages: currentPool,
        hasImages: true,
      );
    }
  }
}
