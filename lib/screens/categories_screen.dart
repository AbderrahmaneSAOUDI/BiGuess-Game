import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart'; // Import provider
import '../main.dart'; // Import main.dart to access ThemeNotifier
import 'game_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<Map<String, String>> categories = const [
    {'name': 'Attack on Titans', 'path': 'assets/images/attack_on_titans'},
    {'name': 'Black Clover', 'path': 'assets/images/black_clover'},
    {'name': 'Bleach', 'path': 'assets/images/bleach'},
    {'name': 'Code Geass', 'path': 'assets/images/code_geass'},
    {'name': 'Death Note', 'path': 'assets/images/death_note'},
    {'name': 'Demon Slayer', 'path': 'assets/images/demon_slayer'},
    {'name': 'Detective Conan', 'path': 'assets/images/detective_conan'},
    {'name': 'Dr. Stone', 'path': 'assets/images/dr_stone'},
    {'name': 'Dragon Ball Z', 'path': 'assets/images/dragon_ball_z'},
    {'name': 'FMAB', 'path': 'assets/images/fmab'},
    {'name': 'Hunter X Hunter', 'path': 'assets/images/hunter_x_hunter'},
    {'name': 'Jujutsu Kaisen', 'path': 'assets/images/jujutsu_kaisen'},
    {'name': 'My Hero Academia', 'path': 'assets/images/my_hero_academia'},
    {'name': 'Naruto', 'path': 'assets/images/naruto'},
    {'name': 'One Piece', 'path': 'assets/images/one_piece'},
    {'name': 'Solo Leveling', 'path': 'assets/images/solo_leveling'},
    {'name': 'Tokyo Revengers', 'path': 'assets/images/tokyo_revengers'},
    {'name': 'Vinland Saga', 'path': 'assets/images/vinland_saga'},
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess Image Game'),
        centerTitle: true,
      ),
      body: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 750),
              columnCount: 2, // Should match crossAxisCount
              child: SlideAnimation(
                verticalOffset: 20.0,
                child: FadeInAnimation(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            categoryName: categories[index]['name']!,
                            categoryPath: categories[index]['path']!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category, size: 40), // Placeholder icon for category
                        const SizedBox(height: 8),
                        Text(
                          categories[index]['name']!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          themeNotifier.toggleTheme();
        },
        child: Icon(
          themeNotifier.getTheme().brightness == Brightness.dark
              ? Icons.light_mode
              : Icons.dark_mode,
        ),
      ),
    );
  }
}
