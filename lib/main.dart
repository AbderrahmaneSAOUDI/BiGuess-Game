import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/categories_screen.dart';

void main() => runApp(ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MainLayout(),
    ));

class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier() : _themeData = _lightTheme;

  ThemeData getTheme() => _themeData;

  static final ThemeData _lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    fontFamily: 'GoogleSans',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      titleSmall: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(fontFamily: 'GoogleSans'),
      bodyMedium: TextStyle(fontFamily: 'GoogleSans'),
      bodySmall: TextStyle(fontFamily: 'GoogleSans'),
      labelLarge: TextStyle(fontFamily: 'GoogleSans'),
      labelMedium: TextStyle(fontFamily: 'GoogleSans'),
      labelSmall: TextStyle(fontFamily: 'GoogleSans'),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    fontFamily: 'GoogleSans',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      titleSmall: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(fontFamily: 'GoogleSans'),
      bodyMedium: TextStyle(fontFamily: 'GoogleSans'),
      bodySmall: TextStyle(fontFamily: 'GoogleSans'),
      labelLarge: TextStyle(fontFamily: 'GoogleSans'),
      labelMedium: TextStyle(fontFamily: 'GoogleSans'),
      labelSmall: TextStyle(fontFamily: 'GoogleSans'),
    ),
  );

  void toggleTheme() {
    _themeData = _themeData == _lightTheme ? _darkTheme : _lightTheme;
    notifyListeners();
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.getTheme(),
      home: const CategoriesScreen(),
    );
  }
}