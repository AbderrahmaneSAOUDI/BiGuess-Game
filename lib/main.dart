import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
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
    primarySwatch: Colors.red,
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: 'GoogleSans',
  );

  static final ThemeData _darkTheme = ThemeData(
    primarySwatch: Colors.red,
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'GoogleSans',
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