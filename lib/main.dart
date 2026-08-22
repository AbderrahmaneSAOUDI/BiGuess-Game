import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/categories_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BiGuessApp());
}

class BiGuessApp extends StatelessWidget {
  const BiGuessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(),
      child: const MainLayout(),
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  ThemeData get theme => _isDarkMode ? darkTheme : lightTheme;
  ThemeData getTheme() => theme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static ThemeData buildTheme(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'GoogleSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
    );
  }

  static final ThemeData lightTheme = buildTheme(Brightness.light);
  static final ThemeData darkTheme = buildTheme(Brightness.dark);
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'BiGuess Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeNotifier.lightTheme,
      darkTheme: ThemeNotifier.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const CategoriesScreen(),
    );
  }
}
