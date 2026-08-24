/// Immutable snapshot of the current game round state
class GameRoundState {
  final bool isLoading;
  final bool isCountingDown;
  final int countdown;
  final bool showPicture;
  final String? currentImageAsset;
  final String? correctAnswer;
  final bool hasStarted;
  final bool noImagesFound;
  final List<String> allImages;
  final List<String> remainingImages;

  const GameRoundState({
    this.isLoading = true,
    this.isCountingDown = false,
    this.countdown = 0,
    this.showPicture = false,
    this.currentImageAsset,
    this.correctAnswer,
    this.hasStarted = false,
    this.noImagesFound = false,
    this.allImages = const [],
    this.remainingImages = const [],
  });

  GameRoundState copyWith({
    bool? isLoading,
    bool? isCountingDown,
    int? countdown,
    bool? showPicture,
    String? currentImageAsset,
    String? correctAnswer,
    bool? hasStarted,
    bool? noImagesFound,
    List<String>? allImages,
    List<String>? remainingImages,
    bool clearCurrentAsset = false,
    bool clearCorrectAnswer = false,
  }) {
    return GameRoundState(
      isLoading: isLoading ?? this.isLoading,
      isCountingDown: isCountingDown ?? this.isCountingDown,
      countdown: countdown ?? this.countdown,
      showPicture: showPicture ?? this.showPicture,
      currentImageAsset:
          clearCurrentAsset ? null : (currentImageAsset ?? this.currentImageAsset),
      correctAnswer:
          clearCorrectAnswer ? null : (correctAnswer ?? this.correctAnswer),
      hasStarted: hasStarted ?? this.hasStarted,
      noImagesFound: noImagesFound ?? this.noImagesFound,
      allImages: allImages ?? this.allImages,
      remainingImages: remainingImages ?? this.remainingImages,
    );
  }
}
