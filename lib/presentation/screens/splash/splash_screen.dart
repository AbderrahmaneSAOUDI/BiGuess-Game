import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/update_state.dart';
import '../../controllers/update_controller.dart';
import '../categories/categories_screen.dart';

/// Premium animated splash screen with particle field, 3D logo flip,
/// staggered text reveal, and integrated hybrid update pipeline.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _progressController;
  late final AnimationController _particleController;
  late final AnimationController _shimmerController;
  late final AnimationController _statusTextController;

  late final Animation<double> _logoFlip;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _shimmerSweep;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _progressValue;

  bool _navigated = false;

  /// Whether the update check has been kicked off.
  bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();

    // Logo entrance: 3D flip + scale + fade
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoFlip = Tween<double>(begin: pi / 2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_logoController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Shimmer sweep across the logo
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _shimmerSweep = Tween<double>(begin: -1.5, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Text staggered reveal
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Progress bar — now manually driven by update state
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    // Particle field
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Status text fade controller
    _statusTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Orchestrate the sequence
    _startSequence();
  }

  Future<void> _startSequence() async {
    // Start particles immediately
    // Logo flips in
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // Shimmer after logo lands
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _shimmerController.forward();

    // Text fades in
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _textController.forward();

    // Fade in the status text area
    _statusTextController.forward();

    // Kick off the update check — the progress bar is now driven by state
    if (!_updateCheckStarted) {
      _updateCheckStarted = true;
      // Small delay to let the text animation settle
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      ref.read(updateControllerProvider.notifier).runUpdateCheck();
    }
  }

  void _navigateToHome() {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CategoriesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.08, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _statusTextController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Update state helpers
  // ---------------------------------------------------------------------------

  /// Returns the target progress value (0.0–1.0) for the current update state.
  double _targetProgressForState(UpdateState updateState) {
    return switch (updateState) {
      UpdateIdle() => 0.0,
      UpdateChecking() => 0.15,
      UpdateDownloading(:final progress) => 0.15 + progress * 0.70,
      UpdatePatching() => 0.60,
      UpdateInstalling() => 0.95,
      UpdateRestarting() => 1.0,
      UpdateCompleted() => 1.0,
      UpdateSkipped() => 1.0,
      UpdateError() => _progressController.value, // freeze
    };
  }

  /// Returns the status text to display above the progress bar.
  String _statusTextForState(UpdateState updateState) {
    return switch (updateState) {
      UpdateIdle() => '',
      UpdateChecking() => 'Checking for updates...',
      UpdateDownloading(:final progress, :final speedText, :final etaText) =>
        'Downloading update: ${(progress * 100).toStringAsFixed(0)}%'
            '${speedText.isNotEmpty ? ' ($speedText)' : ''}'
            '${etaText.isNotEmpty ? ' • $etaText' : ''}',
      UpdatePatching() => 'Applying game patch...',
      UpdateInstalling() => 'Launching package installer...',
      UpdateRestarting() => 'Patch complete! Restarting...',
      UpdateCompleted() => 'Loading...',
      UpdateSkipped() => 'Loading...',
      UpdateError(:final message) => message,
    };
  }

  /// Whether back navigation should be blocked.
  bool _shouldBlockPop(UpdateState updateState) {
    return switch (updateState) {
      UpdateChecking() => true,
      UpdateDownloading() => true,
      UpdateInstalling() => true,
      UpdatePatching() => true,
      UpdateRestarting() => true,
      UpdateError(:final canSkip) => !canSkip,
      _ => false,
    };
  }

  /// Whether to show the "Skip for Now" button.
  bool _showSkipButton(UpdateState updateState) {
    return switch (updateState) {
      UpdateDownloading() => true,
      UpdateError(:final canSkip) => canSkip,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    final updateState = ref.watch(updateControllerProvider);

    // Animate progress bar to match state
    final targetProgress = _targetProgressForState(updateState);
    _progressController.animateTo(
      targetProgress.clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    // Auto-navigate on completion
    if ((updateState is UpdateCompleted || updateState is UpdateSkipped) &&
        !_navigated) {
      Future.microtask(() {
        if (mounted && !_navigated) {
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _navigateToHome();
          });
        }
      });
    }

    return PopScope(
      canPop: !_shouldBlockPop(updateState),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Animated gradient background
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.4,
                  colors: isDark
                      ? [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF0F0F1A),
                        ]
                      : [
                          const Color(0xFFF0F4FF),
                          const Color(0xFFE8ECF4),
                        ],
                ),
              ),
            ),

            // Subtle accent glow behind logo
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Container(
                    width: 200 * _logoScale.value,
                    height: 200 * _logoScale.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15 * _logoOpacity.value,
                          ),
                          blurRadius: 80,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Particle field
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticleFieldPainter(
                      progress: _particleController.value,
                      color: theme.colorScheme.primary,
                      screenSize: size,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with 3D flip
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(_logoFlip.value)
                            ..scaleByDouble(
                                _logoScale.value, _logoScale.value, 1.0, 1.0),
                          alignment: Alignment.center,
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Logo image
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              AppConstants.appIconPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Holographic shimmer sweep
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            if (_shimmerController.value <= 0.01 ||
                                _shimmerController.value >= 0.99) {
                              return const SizedBox.shrink();
                            }
                            return SizedBox(
                              width: 120,
                              height: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: IgnorePointer(
                                  child: Transform.translate(
                                    offset: Offset(
                                      _shimmerSweep.value * 120,
                                      0,
                                    ),
                                    child: Transform.rotate(
                                      angle: 0.35,
                                      child: Container(
                                        width: 60,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white
                                                  .withValues(alpha: 0.0),
                                              Colors.white
                                                  .withValues(alpha: 0.5),
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
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App title with staggered letter animation
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return _StaggeredText(
                        text: AppConstants.appName,
                        progress: _textController.value,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: theme.colorScheme.onSurface,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          AppConstants.appTagline,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar + status text at bottom
            Positioned(
              left: 48,
              right: 48,
              bottom: 60,
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [_progressController, _statusTextController]),
                builder: (context, child) {
                  final statusText = _statusTextForState(updateState);
                  final showSkip = _showSkipButton(updateState);
                  final isError = updateState is UpdateError;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status text
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _statusTextController,
                          curve: Curves.easeOut,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: statusText.isNotEmpty
                              ? Text(
                                  statusText,
                                  key: ValueKey(
                                    // Use a simplified key for download states
                                    // to avoid rebuilding on every progress tick
                                    updateState is UpdateDownloading
                                        ? 'downloading'
                                        : statusText,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isError
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Progress bar
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progressValue.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: isError
                                      ? [
                                          theme.colorScheme.error,
                                          theme.colorScheme.error
                                              .withValues(alpha: 0.7),
                                        ]
                                      : [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.tertiary,
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isError
                                            ? theme.colorScheme.error
                                            : theme.colorScheme.primary)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Error action buttons
                      if (isError) ...[
                        _buildErrorActions(
                            updateState, theme, isDark),
                        const SizedBox(height: 8),
                      ],

                      // Skip button (for non-mandatory APK updates)
                      if (showSkip && !isError)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(updateControllerProvider.notifier)
                                .skipUpdate();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          ),
                          child: Text(
                            'Skip for Now',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                      // Version badge (shown when not in error state)
                      if (!isError)
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Text(
                            'v${AppConstants.defaultVersion}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Mandatory update modal overlay
            if (updateState is UpdateError &&
                !(updateState).canSkip)
              _buildMandatoryUpdateModal(
                  updateState, theme, isDark),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error action buttons
  // ---------------------------------------------------------------------------

  Widget _buildErrorActions(
      UpdateError errorState, ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (errorState.canRetry)
          TextButton.icon(
            onPressed: () {
              ref.read(updateControllerProvider.notifier).retryUpdate();
            },
            icon: Icon(
              Icons.refresh_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Retry',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (errorState.canSkip) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              ref.read(updateControllerProvider.notifier).skipUpdate();
            },
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mandatory update modal
  // ---------------------------------------------------------------------------

  Widget _buildMandatoryUpdateModal(
      UpdateError errorState, ThemeData theme, bool isDark) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E2E).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.error.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    color: theme.colorScheme.error,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Update Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'This version is no longer supported.\nPlease connect to the internet and update.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(updateControllerProvider.notifier)
                          .retryUpdate();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Check internet connection button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _openWifiSettings();
                    },
                    icon: const Icon(Icons.wifi_rounded, size: 18),
                    label: const Text('Check Internet Connection'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.2),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the device WiFi settings page.
  Future<void> _openWifiSettings() async {
    // Android WiFi settings URI
    final uri = Uri.parse('android.settings.WIFI_SETTINGS');
    try {
      await launchUrl(uri);
    } catch (_) {
      // Fallback — try the generic settings page
      try {
        await launchUrl(Uri.parse('android.settings.SETTINGS'));
      } catch (_) {
        // Silently fail — no settings page available
      }
    }
  }
}

// ---------- Staggered text widget ----------

class _StaggeredText extends StatelessWidget {
  final String text;
  final double progress;
  final TextStyle style;

  const _StaggeredText({
    required this.text,
    required this.progress,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final chars = text.characters.toList();
    final total = chars.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        // Each character fades in with a stagger offset
        final charStart = (i / total) * 0.6; // stagger across 60% of timeline
        final charEnd = charStart + 0.4;
        final charProgress =
            ((progress - charStart) / (charEnd - charStart)).clamp(0.0, 1.0);

        final opacity = charProgress;
        final yOffset =
            12.0 * (1.0 - Curves.easeOutCubic.transform(charProgress));

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Opacity(
            opacity: opacity,
            child: Text(
              chars[i],
              style: style,
            ),
          ),
        );
      }),
    );
  }
}

// ---------- Particle field painter ----------

class _ParticleFieldPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Size screenSize;
  final bool isDark;

  static final List<_Particle> _particles = _generateParticles(20);

  _ParticleFieldPainter({
    required this.progress,
    required this.color,
    required this.screenSize,
    required this.isDark,
  });

  static List<_Particle> _generateParticles(int count) {
    final rng = Random(42); // deterministic seed for consistent layout
    return List.generate(count, (i) {
      return _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 2.0 + rng.nextDouble() * 3.0,
        speed: 0.3 + rng.nextDouble() * 0.7,
        phase: rng.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final x = p.x * size.width;
      final baseY = p.y * size.height;
      final floatY = baseY + sin(t * 2 * pi) * 20.0;
      final alpha = (sin(t * 2 * pi) + 1.0) / 2.0;

      final paint = Paint()
        ..color = color.withValues(
          alpha: (isDark ? 0.25 : 0.15) * alpha,
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
          Offset(x, floatY), p.size * (0.5 + alpha * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}
