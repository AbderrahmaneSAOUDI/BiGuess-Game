import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/asset_loader.dart';

class GameScreen extends StatefulWidget {
  final String categoryName;

  const GameScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum CharacterAlgorithm {
  random,
  nonRepeating,
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  bool _showPicture = false;
  bool _isCountingDown = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _hasStarted = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonRotationAnimation;
  late Animation<double> _shimmerAnimation;
  bool _isPressed = false;

  List<String> _imageAssets = [];
  String? _currentImageAsset;
  String? _correctAnswer;
  bool _isLoading = true;
  bool _noImagesFound = false;

  // New: Algorithm state and working list for non-repeating
  CharacterAlgorithm _algorithm = CharacterAlgorithm.random;
  List<String> _workingImageAssets = [];
  Set<String> _usedCharacters = {};

  @override
  void initState() {
    super.initState();
    _loadImagesFromCategory();
    
    // Initialize button animations
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _buttonRotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadImagesFromCategory() async {
    setState(() {
      _isLoading = true;
      _noImagesFound = false;
      _imageAssets = [];
      _currentImageAsset = null;
      _correctAnswer = null;
      _hasStarted = false;
      _workingImageAssets = [];
      _usedCharacters = {};
    });

    // Convert category name to path format
    final categoryPath = 'assets/images/${widget.categoryName.toLowerCase().replaceAll(' ', '_')}';
    
    // Load assets using AssetLoader
    final assets = await AssetLoader.loadCategoryAssets(categoryPath);
    
    if (assets.isNotEmpty) {
      setState(() {
        _imageAssets = assets;
        _workingImageAssets = List<String>.from(assets);
        _noImagesFound = false;
        _usedCharacters = {};
      });
    } else {
      setState(() {
        _noImagesFound = true;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _buttonAnimationController.dispose();
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
      _hasStarted = true;
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
    if (_algorithm == CharacterAlgorithm.random) {
      // Old logic: pick any image
      if (_imageAssets.isNotEmpty) {
        final random = Random();
        _currentImageAsset = _imageAssets[random.nextInt(_imageAssets.length)];
        _correctAnswer = AssetLoader.extractCharacterName(_currentImageAsset!);
        setState(() {
          _showPicture = true;
        });
      } else {
        setState(() {
          _noImagesFound = true;
          _showPicture = false;
        });
      }
    } else {
      // New logic: non-repeating per character
      if (_workingImageAssets.isEmpty) {
        // refill
        _workingImageAssets = List<String>.from(_imageAssets);
        _usedCharacters.clear();
      }
      if (_workingImageAssets.isNotEmpty) {
        final random = Random();
        final idx = random.nextInt(_workingImageAssets.length);
        final asset = _workingImageAssets[idx];
        final character = AssetLoader.extractCharacterName(asset);
        // Remove all images for this character
        _workingImageAssets.removeWhere((img) => AssetLoader.extractCharacterName(img) == character);
        _usedCharacters.add(character ?? '');
        _currentImageAsset = asset;
        _correctAnswer = character;
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
  }

  void _onAlgorithmChanged(CharacterAlgorithm value) {
    setState(() {
      _algorithm = value;
      // Reset working list if switching to non-repeating
      if (_algorithm == CharacterAlgorithm.nonRepeating) {
        _workingImageAssets = List<String>.from(_imageAssets);
        _usedCharacters.clear();
      }
    });
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
            child: Image.asset('assets/logos/gdg_logo.webp'),
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
                        child: ScaleAnimation(
                          scale: 0.9,
                          child: AnimatedBuilder(
                            animation: _buttonAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isPressed ? 0.95 : _buttonScaleAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _hasStarted 
                                        ? [Colors.blue.shade400, Colors.blue.shade700]
                                        : [Colors.green.shade400, Colors.green.shade700],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_hasStarted ? Colors.blue : Colors.green).withAlpha(77),
                                        spreadRadius: _isPressed ? 0 : 1,
                                        blurRadius: _isPressed ? 4 : 8,
                                        offset: Offset(0, _isPressed ? 2 : 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Shimmer effect
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: Transform.translate(
                                            offset: Offset(
                                              _shimmerAnimation.value * MediaQuery.of(context).size.width,
                                              0,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withAlpha(0),
                                                    Colors.white.withAlpha(77),
                                                    Colors.white.withAlpha(0),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Button content
                                      GestureDetector(
                                        onTapDown: (_) => setState(() => _isPressed = true),
                                        onTapUp: (_) => setState(() => _isPressed = false),
                                        onTapCancel: () => setState(() => _isPressed = false),
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoading || _isCountingDown ? null : _startCountdown,
                                          icon: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 300),
                                            transitionBuilder: (child, animation) {
                                              return ScaleTransition(
                                                scale: animation,
                                                child: FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: _hasStarted
                                              ? Transform.rotate(
                                                  angle: _buttonRotationAnimation.value,
                                                  child: const Icon(
                                                    Icons.refresh,
                                                    key: ValueKey('refresh'),
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.play_arrow,
                                                  key: ValueKey('play'),
                                                  color: Colors.white,
                                                ),
                                          ),
                                          label: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 300),
                                            transitionBuilder: (child, animation) {
                                              return ScaleTransition(
                                                scale: animation,
                                                child: FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: Text(
                                              _hasStarted ? 'Refresh' : 'Start',
                                              key: ValueKey(_hasStarted),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

class GameSettingsDialog extends StatefulWidget {
  final CharacterAlgorithm algorithm;
  final ValueChanged<CharacterAlgorithm> onAlgorithmChanged;
  const GameSettingsDialog({super.key, required this.algorithm, required this.onAlgorithmChanged});

  @override
  State<GameSettingsDialog> createState() => _GameSettingsDialogState();
}

class _GameSettingsDialogState extends State<GameSettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CharacterAlgorithm _selectedAlgorithm;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedAlgorithm = widget.algorithm;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(0.0),
        width: 512.0,
        height: 512.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Game Settings'),
                Tab(text: 'How to Play'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimationConfiguration.staggeredList(
                          position: 0,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Countdown Duration',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Set how long players have to look at the image before starting to guess.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimationConfiguration.staggeredList(
                          position: 1,
                          duration: const Duration(milliseconds: 600),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(77),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.help_outline,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Game Rules',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: 5,
                                      itemBuilder: (context, index) {
                                        final List<String> rules = [
                                          'Ask yes/no questions only',
                                          'One question per turn',
                                          'No peeking at your own screen',
                                          'Be honest when answering',
                                          'Try not to repeat previous questions',
                                        ];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '• ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  rules[index],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    height: 1.5,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Character Selection Algorithm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ListTile(
                          title: const Text('Random (characters can repeat)'),
                          leading: Radio<CharacterAlgorithm>(
                            value: CharacterAlgorithm.random,
                            groupValue: _selectedAlgorithm,
                            onChanged: (val) {
                              setState(() => _selectedAlgorithm = val!);
                              widget.onAlgorithmChanged(val!);
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('Non-repeating (all images for a character are removed until all characters have appeared)'),
                          leading: Radio<CharacterAlgorithm>(
                            value: CharacterAlgorithm.nonRepeating,
                            groupValue: _selectedAlgorithm,
                            onChanged: (val) {
                              setState(() => _selectedAlgorithm = val!);
                              widget.onAlgorithmChanged(val!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimationConfiguration.staggeredList(
                          position: 0,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'How to Play',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: 5,
                                      itemBuilder: (context, index) {
                                        final List<String> steps = [
                                          'Both players tap "Start/Refresh" on their phones to get a different mystery character.',
                                          'Show your screen to your opponent before the countdown ends.',
                                          'Start taking turns asking yes/no questions to guess your own character.',
                                          'The first player to guess their character correctly wins the round.',
                                          'Keep playing and tracking scores!',
                                        ];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${index + 1}. ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  steps[index],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    height: 1.5,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
