import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_controller.dart';
import 'providers/topic_pack_providers.dart';
import 'data/local/local_content_runtime.dart';
import 'presentation/screens/topics/topics_screen.dart';
import 'presentation/images/content_image_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ContentImageLoader.configureCache();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  const importPath = String.fromEnvironment('biguessLocalPackPath');
  final content = await LocalContentRuntime.open(
    importFile: importPath.isEmpty ? null : File(importPath),
    useLegacy: const bool.fromEnvironment('biguessUseLegacyContent'),
  );
  if (content.failure != null) {
    debugPrint(
      'Local Packs unavailable; using bundled content: ${content.failure}',
    );
  }
  runApp(
    ProviderScope(
      overrides: [
        localContentRuntimeProvider.overrideWith((ref) {
          ref.onDispose(content.close);
          return content;
        }),
      ],
      child: const BiGuessApp(),
    ),
  );
}

class BiGuessApp extends ConsumerWidget {
  const BiGuessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const TopicsScreen(),
    );
  }
}
