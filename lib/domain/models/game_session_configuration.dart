import 'content_validation.dart';
import 'difficulty.dart';

/// Frozen session settings, including selected content and local access rules.
/// The configuration screen's editable draft can be converted to this value at
/// the session boundary. Production callers default to Free.
final class GameSessionConfiguration {
  static const freeRoundLimit = 10;

  final String topicId;
  final List<String> packIds;
  final Difficulty maximumDifficulty;
  final int rounds;
  final bool isPro;

  GameSessionConfiguration({
    required String topicId,
    required Iterable<String> packIds,
    required this.rounds,
    this.maximumDifficulty = Difficulty.easy,
    this.isPro = false,
  }) : topicId = ContentValidation.id(topicId, 'topicId'),
       packIds = List.unmodifiable(
         packIds.map((id) => ContentValidation.id(id, 'packId')),
       ) {
    if (this.packIds.isEmpty ||
        this.packIds.toSet().length != this.packIds.length) {
      throw ArgumentError('Select one or more distinct Packs');
    }
    if (rounds < 1 || (!isPro && rounds > freeRoundLimit)) {
      throw RangeError.range(
        rounds,
        1,
        isPro ? null : freeRoundLimit,
        'rounds',
      );
    }
  }
}
