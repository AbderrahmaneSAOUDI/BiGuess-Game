import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/use_cases/select_character_use_case.dart';

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return const CategoryRepositoryImpl();
});

final categoriesProvider = Provider<List<GameCategory>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories();
});

final selectCharacterUseCaseProvider = Provider<SelectCharacterUseCase>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return SelectCharacterUseCase(repository: repo);
});
