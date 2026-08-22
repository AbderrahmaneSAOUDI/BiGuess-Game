import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../assets_manifest.dart';
import '../utils/asset_loader.dart';
import 'categories_screen.dart';

enum CharacterAlgorithm {
  random,
  nonRepeating,
}

class GameScreen extends StatefulWidget {
  final String categoryName;

  const GameScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  bool _showPicture = false;
  bool _isCountingDown = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _hasStarted = false;
  late final AnimationController _buttonAnimationController;
  late final Animation<double> _buttonScaleAnimation;
  late final Animation<double> _buttonRotationAnimation;
  late final Animation<double> _shimmerAnimation;
  bool _isPressed = false;

  List<String> _imageAssets = [];
  String? _currentImageAsset;
  String? _correctAnswer;
  bool _isLoading = true;
  bool _noImagesFound = false;

  CharacterAlgorithm _algorithm = CharacterAlgorithm.nonRepeating;
  List<String> _workingImageAssets = [];

  @override
  void initState() {
    super.initState();
    _loadImagesFromCategory();

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
      end: 2 * pi,
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
    });

    final assets = categoryAssets[widget.categoryName] ?? [];
    if (assets.isNotEmpty) {
      setState(() {
        _imageAssets = assets;
        _workingImageAssets = List<String>.from(assets);
        _noImagesFound = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          for (final asset in assets.take(5)) {
            precacheImage(
              AssetImage(asset),
              context,
              onError: (e, s) {},
            );
          }
        }
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

  void _onAlgorithmChanged(CharacterAlgorithm value) {
    if (_algorithm != value) {
      setState(() {
        _algorithm = value;
        if (_algorithm == CharacterAlgorithm.nonRepeating) {
          _workingImageAssets = List<String>.from(_imageAssets);
        }
      });
    }
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
      if (!mounted) {
        timer.cancel();
        return;
      }
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
      if (_workingImageAssets.isEmpty) {
        if (_imageAssets.isNotEmpty) {
          _workingImageAssets = List<String>.from(_imageAssets);
        } else {
          setState(() {
            _noImagesFound = true;
            _showPicture = false;
          });
          return;
        }
      }

      if (_workingImageAssets.isNotEmpty) {
        final random = Random();
        final idx = random.nextInt(_workingImageAssets.length);
        final asset = _workingImageAssets[idx];
        final character = AssetLoader.extractCharacterName(asset);

        _workingImageAssets.removeAt(idx);
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
                final double maxImageHeight = max(
                  0.0,
                  constraints.maxHeight - 45.0 - 4.0,
                );

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxHeight: maxImageHeight),
                            child: Image.asset(
                              _currentImageAsset!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red, size: 50),
                                      SizedBox(height: 8),
                                      Text('Error loading image',
                                          textAlign: TextAlign.center),
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
                          _correctAnswer!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => GameSettingsDialog(
                  algorithm: _algorithm,
                  onAlgorithmChanged: _onAlgorithmChanged,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Rules & Info',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => const RulesContactDialog(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset('assets/logos/gdg_logo.webp', width: 36),
          ),
        ],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
            ),
          ),
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
                                scale: _isPressed
                                    ? 0.95
                                    : _buttonScaleAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _hasStarted
                                          ? [
                                              Colors.blue.shade400,
                                              Colors.blue.shade700
                                            ]
                                          : [
                                              Colors.green.shade400,
                                              Colors.green.shade700
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_hasStarted
                                                ? Colors.blue
                                                : Colors.green)
                                            .withValues(alpha: 0.3),
                                        spreadRadius: _isPressed ? 0 : 1,
                                        blurRadius: _isPressed ? 4 : 8,
                                        offset: Offset(0, _isPressed ? 2 : 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: Transform.translate(
                                            offset: Offset(
                                              _shimmerAnimation.value *
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                              0,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white
                                                        .withValues(alpha: 0.0),
                                                    Colors.white
                                                        .withValues(alpha: 0.3),
                                                    Colors.white
                                                        .withValues(alpha: 0.0),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTapDown: (_) =>
                                            setState(() => _isPressed = true),
                                        onTapUp: (_) =>
                                            setState(() => _isPressed = false),
                                        onTapCancel: () =>
                                            setState(() => _isPressed = false),
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isLoading || _isCountingDown
                                                  ? null
                                                  : _startCountdown,
                                          icon: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            transitionBuilder:
                                                (child, animation) {
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
                                                    angle:
                                                        _buttonRotationAnimation
                                                            .value,
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
                                            duration: const Duration(
                                                milliseconds: 300),
                                            transitionBuilder:
                                                (child, animation) {
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
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

  const GameSettingsDialog({
    super.key,
    required this.algorithm,
    required this.onAlgorithmChanged,
  });

  @override
  State<GameSettingsDialog> createState() => _GameSettingsDialogState();
}

class _GameSettingsDialogState extends State<GameSettingsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
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
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SizedBox(
        width: 512.0,
        height: 520.0,
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Countdown Duration',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Set how long players have to look at the image before starting to guess (currently fixed to 2s for fast-paced excitement).',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Character Selection Algorithm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RadioGroup<CharacterAlgorithm>(
                          groupValue: _selectedAlgorithm,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAlgorithm = val);
                              widget.onAlgorithmChanged(val);
                            }
                          },
                          child: const Column(
                            children: [
                              ListTile(
                                title: Text('Random (characters can repeat)'),
                                subtitle: Text('Picks randomly from all available images'),
                                leading: Radio<CharacterAlgorithm>(
                                  value: CharacterAlgorithm.random,
                                ),
                              ),
                              ListTile(
                                title: Text('Non-repeating (fair rotation)'),
                                subtitle: Text(
                                    'Draws without replacement until all characters have appeared'),
                                leading: Radio<CharacterAlgorithm>(
                                  value: CharacterAlgorithm.nonRepeating,
                                ),
                              ),
                            ],
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'How to Play',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              for (int i = 0; i < 5; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${i + 1}. ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          [
                                            'Both players tap "Start/Refresh" on their phones to get a mystery character.',
                                            'Show your screen to your opponent before the countdown ends.',
                                            'Start taking turns asking yes/no questions to guess your character.',
                                            'The first player to guess their character correctly wins the round.',
                                            'Keep playing and tracking scores!',
                                          ][i],
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: theme.colorScheme.onSurface,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
