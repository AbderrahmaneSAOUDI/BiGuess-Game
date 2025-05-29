import 'dart:async';
import 'dart:io'; // Added for File and Directory
import 'dart:math'; // Added for Random

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class GameScreen extends StatefulWidget {
  final String categoryName;
  final String categoryPath;

  const GameScreen({
    super.key,
    required this.categoryName,
    required this.categoryPath,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showPicture = false;
  bool _isCountingDown = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  List<File> _imageFiles = [];
  File? _currentImage;
  String? _correctAnswer;
  bool _isLoading = true;
  bool _noImagesFound = false;

  @override
  void initState() {
    super.initState();
    _loadImagesFromCategory();
  }

  Future<void> _loadImagesFromCategory() async {
    setState(() {
      _isLoading = true;
      _noImagesFound = false;
      _imageFiles = [];
      _currentImage = null;
      _correctAnswer = null;
    });

    try {
      final dir = Directory(widget.categoryPath);
      if (await dir.exists()) {
        // Get all files recursively from the directory and its subdirectories
        final List<FileSystemEntity> allFiles = [];
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            allFiles.add(entity);
          }
        }

        _imageFiles = allFiles
            .whereType<File>()
            .where((file) =>
                ['.png', '.jpg', '.jpeg'].any((ext) => file.path.toLowerCase().endsWith(ext)))
            .toList();

        if (_imageFiles.isEmpty) {
          _noImagesFound = true;
        }
      } else {
        _noImagesFound = true; // Directory doesn't exist
      }
    } catch (e) {
      // Handle potential errors during file listing
      _noImagesFound = true;
      print('Error loading images: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (_isCountingDown) return;

    if (_noImagesFound || _imageFiles.isEmpty) {
      // If no images, just show the state, don't start countdown
      setState(() {
        _showPicture = false; // Ensure picture is not shown if folder is empty
      });
      return;
    }

    setState(() {
      _isCountingDown = true;
      _showPicture = false;
      _currentImage = null;
      _correctAnswer = null;
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _isCountingDown = false;
          timer.cancel();
          _showRandomImage();
        }
      });
    });
  }

  void _showRandomImage() {
    if (_imageFiles.isNotEmpty) {
      final random = Random();
      _currentImage = _imageFiles[random.nextInt(_imageFiles.length)];
      
      // Extract answer from the parent directory name
      final pathParts = _currentImage!.path.split(Platform.pathSeparator);
      // Get the parent directory name (character name)
      final parentDirName = pathParts[pathParts.length - 2];
      _correctAnswer = parentDirName;

      setState(() {
        _showPicture = true;
      });
    } else {
      setState(() {
        _noImagesFound = true;
        _showPicture = false;
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_noImagesFound) {
      return const Center(
        child: Text(
          'Coming soon...\nNo images in this category yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    if (_isCountingDown) {
      return AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(begin: Colors.red, end: Colors.blue),
                  duration: const Duration(milliseconds: 375),
                  builder: (context, color, child) {
                    return Text(
                      _countdown.toString(),
                      style: TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Get ready...',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_showPicture && _currentImage != null) {
      return AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10), // slightly less than container to avoid overflow
                    child: Image.file(
                      _currentImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 50),
                              SizedBox(height: 8),
                              Text('Error loading image', textAlign: TextAlign.center),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_correctAnswer != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      '$_correctAnswer',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Initial state or after an image has been shown and reset
      return AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 100,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Click Random to reveal',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAnimatedBackground() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Use theme's scaffold background color
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _buildContent(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || _isCountingDown ? null : _startCountdown,
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Random'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
