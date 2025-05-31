import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../assets_manifest.dart';

class GameScreen extends StatefulWidget {
  final String categoryName;

  const GameScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showPicture = false;
  bool _isCountingDown = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  List<String> _imageAssets = [];
  String? _currentImageAsset;
  String? _correctAnswer;
  bool _isLoading = true;
  bool _noImagesFound = false;

  @override
  void initState() {
    super.initState();
    _loadImagesFromCategory();
  }

  void _loadImagesFromCategory() {
    setState(() {
      _isLoading = true;
      _noImagesFound = false;
      _imageAssets = [];
      _currentImageAsset = null;
      _correctAnswer = null;
    });

    // Use the category name to get the asset list
    final assets = categoryAssets[widget.categoryName];
    if (assets != null && assets.isNotEmpty) {
      _imageAssets = assets;
      _noImagesFound = false;
    } else {
      _noImagesFound = true;
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

    if (_noImagesFound || _imageAssets.isEmpty) {
      setState(() {
        _showPicture = false;
      });
      return;
    }

    setState(() {
      _isCountingDown = true;
      _showPicture = false;
      _currentImageAsset = null;
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
    if (_imageAssets.isNotEmpty) {
      final random = Random();
      _currentImageAsset = _imageAssets[random.nextInt(_imageAssets.length)];
      // Extract the parent directory as the answer
      final pathParts = _currentImageAsset!.split('/');
      // e.g. assets/images/naruto/Orochimaru/image_1.jpg
      // parentDirName = pathParts[pathParts.length - 2];
      String parentDirName = pathParts.length > 3 ? pathParts[pathParts.length - 2] : '';
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              key: ValueKey(_countdown),
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
      );
    } else if (_showPicture && _currentImageAsset != null) {
      return AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate available vertical space for the image container.
                // Subtract estimated height for the answer text (including top padding and some buffer) and the image container's vertical border.
                // Answer text has fontSize 20 and top padding 16.0. Estimate ~45.0 needed for safety for the text part.
                // Image container has a border of 2 on top and bottom (4 total).
                final double maxImageHeight = max(0.0, constraints.maxHeight - 45.0 - 4.0); // Max height for the image itself

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        width: double.infinity,
                        // Remove explicit height here. Let the image and ConstrainedBox determine height.
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: maxImageHeight),
                            child: Image.asset(
                              _currentImageAsset!,
                              fit: BoxFit.contain, // Use BoxFit.contain to respect constraints and aspect ratio
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
                );
              },
            ),
          ),
        ),
      );
    } else {
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
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
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
        color: theme.scaffoldBackgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logos/gdg_logo.png'),
          ),
        ],
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
              if (!_noImagesFound)
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
