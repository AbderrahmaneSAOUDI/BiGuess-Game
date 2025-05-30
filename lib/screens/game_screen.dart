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
      _countdown = 2;
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
    } else if (_showPicture && _currentImageAsset != null) {
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
                  //TODO: height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      _currentImageAsset!,
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
        elevation: 20.0,
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
