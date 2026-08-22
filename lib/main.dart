import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'screens/categories_screen.dart';

export 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BiGuessApp(),
    ),
  );
}

class BiGuessApp extends ConsumerWidget {
  const BiGuessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'BiGuess Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeNotifier.lightTheme,
      darkTheme: ThemeNotifier.darkTheme,
      themeMode: themeMode,
      home: const CategoriesScreen(),
    );
  }
}
