import '../core/constants/app_constants.dart';
import '../presentation/screens/categories/categories_screen.dart';
import '../presentation/screens/categories/widgets/animated_category_card.dart';

export '../presentation/dialogs/info/game_info_dialog.dart'
    show
        GameInfoDialog,
        GameInfoTab,
        GameSettingsDialog,
        RulesContactDialog;
export '../presentation/screens/categories/categories_screen.dart';
export '../presentation/screens/categories/widgets/animated_category_card.dart';

/// Legacy alias for AnimatedCard
typedef AnimatedCard = AnimatedCategoryCard;

/// Extension to maintain static `CategoriesScreen.categories` for backwards compatibility
extension LegacyCategoriesScreenExtension on CategoriesScreen {
  static List<Map<String, String>> get categories =>
      AppConstants.categories.map((c) => c.toMap()).toList();
}
