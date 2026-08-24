import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../controllers/category_controller.dart';
import '../game/game_screen.dart';
import 'widgets/animated_category_card.dart';
import 'widgets/categories_app_bar.dart';

/// Categories selection dashboard screen
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    final topPadding =
        MediaQuery.paddingOf(context).top + kToolbarHeight + 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CategoriesAppBar(),
      body: AnimationLimiter(
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 800),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 50.0,
                curve: Curves.easeOutCubic,
                child: FadeInAnimation(
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedCategoryCard(
                    category: category,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder<void>(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              GameScreen(
                            categoryName: category.name,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.95,
                                  end: 1.0,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
