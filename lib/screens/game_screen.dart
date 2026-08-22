import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../assets_manifest.dart';
import '../providers/game_providers.dart';
import '../utils/asset_loader.dart';
import '../widgets/animations/animated_character_card.dart';
import '../widgets/animations/animated_countdown.dart';
import '../widgets/animations/animated_mystery_box.dart';
import '../widgets/info_dialog.dart';

export '../providers/game_providers.dart'
    show
        CharacterAlgorithm,
        characterAlgorithmProvider,
        countdownDurationProvider,
        showCharacterNameHintProvider;

class GameScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const GameScreen({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  bool _showPicture = false;
  bool _isCountingDown = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _hasStarted = false;

  late final AnimationController _buttonAnimationController;
  late final AnimationController _tapClickController;
  late final Animation<double> _buttonScaleAnimation;
  late final Animation<double> _buttonRotationAnimation;
  late final Animation<double> _shimmerAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _tapScalePunchAnimation;
  late final Animation<double> _tapSpinAnimation;
  late final Animation<double> _tapFlashAnimation;
  bool _isPressed = false;

  List<String> _imageAssets = [];
  String? _currentImageAsset;
  String? _correctAnswer;
  bool _isLoading = true;
  bool _noImagesFound = false;

  List<String> _workingImageAssets = [];

  @override
  void initState() {
    super.initState();
    _loadImagesFromCategory();

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _tapClickController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
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
      begin: -1.2,
      end: 2.2,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _tapScalePunchAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_tapClickController);

    _tapSpinAnimation = Tween<double>(begin: 0.0, end: 4 * pi).animate(
      CurvedAnimation(
        parent: _tapClickController,
        curve: Curves.easeOutCubic,
      ),
    );

    _tapFlashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tapClickController,
        curve: Curves.easeOutQuad,
      ),
    );
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _buttonAnimationController.dispose();
    _tapClickController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_isCountingDown) return;

    _tapClickController.forward(from: 0.0);

    if (_noImagesFound || _imageAssets.isEmpty) {
      setState(() {
        _showPicture = false;
      });
      return;
    }

    final countdownDuration = ref.read(countdownDurationProvider);
    setState(() {
      _isCountingDown = true;
      _showPicture = false;
      _currentImageAsset = null;
      _correctAnswer = null;
      _countdown = countdownDuration;
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
    final algorithm = ref.read(characterAlgorithmProvider);

    if (algorithm == CharacterAlgorithm.random) {
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
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + 0.2 * value,
              child: child,
            ),
          );
        },
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Coming soon...\nNo images in this category yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_isCountingDown) {
      return AnimatedCountdown(
        key: ValueKey(_countdown),
        countdown: _countdown,
      );
    } else if (_showPicture && _currentImageAsset != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double maxImageHeight = max(
            0.0,
            constraints.maxHeight - 55.0,
          );

          return AnimatedCharacterCard(
            key: ValueKey(_currentImageAsset),
            imageAsset: _currentImageAsset!,
            characterName: _correctAnswer,
            showNameHint: ref.watch(showCharacterNameHintProvider),
            maxHeight: maxImageHeight,
          );
        },
      );
    } else {
      return AnimatedMysteryBox(
        onTap: _isLoading || _isCountingDown ? null : _startCountdown,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              GameInfoDialog.show(
                context,
                initialTab: GameInfoTab.settings,
              );
            },
          ),
          IconButton(
            tooltip: 'Rules & Info',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              GameInfoDialog.show(
                context,
                initialTab: GameInfoTab.howToPlay,
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
          // Background with subtle animated ambient gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: isDark
                    ? [
                        theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        theme.scaffoldBackgroundColor,
                      ]
                    : [
                        theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.25),
                        theme.scaffoldBackgroundColor,
                      ],
              ),
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
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _buttonAnimationController,
                      _tapClickController,
                    ]),
                    builder: (context, child) {
                      final activeColor1 = _hasStarted
                          ? const Color(0xFF2979FF) // Electric Blue
                          : const Color(0xFF00E676); // Spring Green
                      final activeColor2 = _hasStarted
                          ? const Color(0xFF1565C0) // Deep Blue
                          : const Color(0xFF00C853); // Emerald Green

                      final scale = _isPressed
                          ? 0.93
                          : (_buttonScaleAnimation.value *
                              (_tapClickController.isAnimating
                                  ? _tapScalePunchAnimation.value
                                  : 1.0));

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [activeColor1, activeColor2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor1.withValues(
                                  alpha: _isPressed
                                      ? 0.3
                                      : _glowAnimation.value * 0.45,
                                ),
                                spreadRadius: _isPressed ? 0 : 2,
                                blurRadius: _isPressed ? 6 : 18,
                                offset: Offset(0, _isPressed ? 2 : 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Button Shimmer Light Sweep
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Transform.translate(
                                    offset: Offset(
                                      _shimmerAnimation.value *
                                          (MediaQuery.of(context).size.width *
                                              0.6),
                                      0,
                                    ),
                                    child: Transform.rotate(
                                      angle: 0.3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white
                                                  .withValues(alpha: 0.0),
                                              Colors.white
                                                  .withValues(alpha: 0.35),
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
                              ),

                              // Tap Energy Flash Wave
                              if (_tapClickController.isAnimating)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: CustomPaint(
                                      painter: _ButtonFlashPainter(
                                        progress: _tapFlashAnimation.value,
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
                                  onPressed: _isLoading || _isCountingDown
                                      ? null
                                      : _startCountdown,
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
                                            angle: _buttonRotationAnimation.value +
                                                _tapSpinAnimation.value,
                                            child: const Icon(
                                              Icons.refresh_rounded,
                                              key: ValueKey('refresh'),
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.play_arrow_rounded,
                                            key: ValueKey('play'),
                                            color: Colors.white,
                                            size: 28,
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 42,
                                      vertical: 18,
                                    ),
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
            ],
          ),
        ],
      ),
    );
  }
}

class _ButtonFlashPainter extends CustomPainter {
  final double progress;

  _ButtonFlashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final currentRadius = progress * maxRadius;
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.5;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _ButtonFlashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
