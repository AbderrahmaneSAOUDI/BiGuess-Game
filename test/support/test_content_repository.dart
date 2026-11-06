import 'package:gdg_guess_game/domain/models/card.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:gdg_guess_game/domain/repositories/content_repository.dart';

/// Independent repository with IDs unrelated to labels or bundled folder keys.
class TestContentRepository implements ContentRepository {
  final List<Topic> _topics = List.unmodifiable([
    Topic(id: 't-41', name: 'Shapes'),
  ]);
  final List<Pack> _packs = List.unmodifiable([
    Pack(id: 'p-72', topicId: 't-41', name: 'Paper Shapes'),
    Pack(id: 'p-73', topicId: 't-41', name: 'Empty Draft'),
  ]);
  final List<Card> _cards = List.unmodifiable([
    Card(
      id: 'c-85',
      packId: 'p-72',
      name: 'Original icon',
      imageReference: 'assets/logos/biguess-icon.webp',
      difficulty: Difficulty.medium,
    ),
    Card(
      id: 'c-86',
      packId: 'p-72',
      name: 'Original logo',
      imageReference: 'assets/logos/biguess_logo.webp',
      difficulty: Difficulty.hard,
    ),
  ]);

  @override
  List<Topic> getTopics() => _topics;

  @override
  List<Pack> getPacksForTopic(String topicId) =>
      List.unmodifiable(_packs.where((pack) => pack.topicId == topicId));

  @override
  List<Card> getCardsForPack(String packId) =>
      List.unmodifiable(_cards.where((card) => card.packId == packId));

  @override
  List<Card>? getInstalledCardsForPack(String packId) =>
      _packs.any((pack) => pack.id == packId) ? getCardsForPack(packId) : null;
}
