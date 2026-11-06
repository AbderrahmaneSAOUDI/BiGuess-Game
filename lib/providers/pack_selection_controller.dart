import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/pack_selection.dart';
import '../domain/use_cases/select_packs_use_case.dart';
import 'topic_pack_providers.dart';

final selectPacksUseCaseProvider = Provider<SelectPacksUseCase>((ref) {
  return SelectPacksUseCase(ref.watch(contentRepositoryProvider));
});

final packOptionsProvider = Provider.family<List<PackOption>, String>((
  ref,
  id,
) {
  return ref.watch(selectPacksUseCaseProvider).options(id);
});

/// Retain each Topic's configuration while navigating; never store display names.
class PackSelectionNotifier extends FamilyNotifier<PackSelection, String> {
  @override
  PackSelection build(String arg) {
    ref.listen(packOptionsProvider(arg), (_, options) {
      if (state.mode == PackSelectionMode.random) return;
      final available = {
        for (final option in options)
          if (option.availability == PackAvailability.playable) option.pack.id,
      };
      final ids = state.packIds.where(available.contains).toList();
      if (ids.length == state.packIds.length) return;
      state = PackSelection(
        topicId: arg,
        mode: state.mode,
        packIds: ids,
        randomCount: state.randomCount,
      );
    });
    return PackSelection(topicId: arg);
  }

  void setMode(PackSelectionMode mode) {
    state = PackSelection(
      topicId: arg,
      mode: mode,
      packIds: mode == PackSelectionMode.random
          ? const []
          : mode == PackSelectionMode.single
          ? state.packIds.take(1)
          : state.packIds,
      randomCount: state.randomCount,
    );
  }

  void selectPack(String packId) {
    final available = ref
        .read(packOptionsProvider(arg))
        .any(
          (option) =>
              option.pack.id == packId &&
              option.availability == PackAvailability.playable,
        );
    if (!available || state.mode == PackSelectionMode.random) {
      throw const PackSelectionException('Pack is not selectable.');
    }
    final ids = state.packIds.toList();
    if (state.mode == PackSelectionMode.single) {
      ids
        ..clear()
        ..add(packId);
    } else if (!ids.remove(packId)) {
      ids.add(packId);
    }
    state = PackSelection(
      topicId: arg,
      mode: state.mode,
      packIds: ids,
      randomCount: state.randomCount,
    );
  }

  void setRandomCount(int count) {
    state = PackSelection(
      topicId: arg,
      mode: state.mode,
      packIds: state.packIds,
      randomCount: count,
    );
  }
}

final packSelectionProvider =
    NotifierProvider.family<PackSelectionNotifier, PackSelection, String>(
      PackSelectionNotifier.new,
    );
