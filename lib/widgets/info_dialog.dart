import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/game_providers.dart';
import '../providers/theme_provider.dart';

enum GameInfoTab {
  settings,
  howToPlay,
  aboutGame,
  developers,
}

class GameInfoDialog extends ConsumerStatefulWidget {
  final GameInfoTab initialTab;
  final CharacterAlgorithm? algorithm;
  final ValueChanged<CharacterAlgorithm>? onAlgorithmChanged;

  const GameInfoDialog({
    super.key,
    this.initialTab = GameInfoTab.settings,
    this.algorithm,
    this.onAlgorithmChanged,
  });

  static Future<void> show(
    BuildContext context, {
    GameInfoTab initialTab = GameInfoTab.settings,
    CharacterAlgorithm? algorithm,
    ValueChanged<CharacterAlgorithm>? onAlgorithmChanged,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => GameInfoDialog(
        initialTab: initialTab,
        algorithm: algorithm,
        onAlgorithmChanged: onAlgorithmChanged,
      ),
    );
  }

  @override
  ConsumerState<GameInfoDialog> createState() => _GameInfoDialogState();
}

class _GameInfoDialogState extends ConsumerState<GameInfoDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'Settings',
      icon: Icons.tune_rounded,
      tab: GameInfoTab.settings,
    ),
    _TabItem(
      label: 'How to Play',
      icon: Icons.sports_esports_rounded,
      tab: GameInfoTab.howToPlay,
    ),
    _TabItem(
      label: 'About Game',
      icon: Icons.auto_awesome_rounded,
      tab: GameInfoTab.aboutGame,
    ),
    _TabItem(
      label: 'Developers',
      icon: Icons.people_alt_rounded,
      tab: GameInfoTab.developers,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = _tabs.indexWhere((t) => t.tab == widget.initialTab);
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 500;

    final dialogWidth = mediaQuery.size.width > 680 ? 640.0 : mediaQuery.size.width * 0.92;
    final dialogHeight = mediaQuery.size.height > 720 ? 620.0 : mediaQuery.size.height * 0.88;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Top Bar with gradient accent & title
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/logos/biguess-icon.webp',
                      width: 22,
                      height: 22,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.videogame_asset_rounded,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BiGuess Game',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Game Center & Rules',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isCompact,
                tabAlignment: isCompact ? TabAlignment.start : TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                tabs: _tabs.map((tab) {
                  return Tab(
                    icon: Icon(tab.icon, size: 20),
                    text: tab.label,
                    iconMargin: const EdgeInsets.only(bottom: 4),
                  );
                }).toList(),
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SettingsView(
                    algorithm: widget.algorithm,
                    onAlgorithmChanged: widget.onAlgorithmChanged,
                  ),
                  const _HowToPlayView(),
                  const _AboutGameView(),
                  const _AboutDevelopersView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final GameInfoTab tab;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.tab,
  });
}

// -----------------------------------------------------------------------------
// 1. SETTINGS VIEW
// -----------------------------------------------------------------------------

class _SettingsView extends ConsumerWidget {
  final CharacterAlgorithm? algorithm;
  final ValueChanged<CharacterAlgorithm>? onAlgorithmChanged;

  const _SettingsView({
    this.algorithm,
    this.onAlgorithmChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedAlgorithm =
        algorithm ?? ref.watch(characterAlgorithmProvider);
    final countdown = ref.watch(countdownDurationProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final showHint = ref.watch(showCharacterNameHintProvider);

    void setAlgo(CharacterAlgorithm val) {
      if (onAlgorithmChanged != null) {
        onAlgorithmChanged!(val);
      } else {
        ref.read(characterAlgorithmProvider.notifier).setAlgorithm(val);
      }
    }

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 400),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 20.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // 1. Character Algorithm Card (with Radio Buttons in one card)
            Material(
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shuffle_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Character Algorithm',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 12),
                  RadioGroup<CharacterAlgorithm>(
                    groupValue: selectedAlgorithm,
                    onChanged: (val) {
                      if (val != null) setAlgo(val);
                    },
                    child: const Column(
                      children: [
                        RadioListTile<CharacterAlgorithm>(
                          title: Text(
                            'Non-Repeating (Fair Rotation)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          value: CharacterAlgorithm.nonRepeating,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        RadioListTile<CharacterAlgorithm>(
                          title: Text(
                            'Random (Can Repeat)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          value: CharacterAlgorithm.random,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Countdown Duration Card
            Material(
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Countdown Duration',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${countdown}s',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [2, 3, 5, 10].map((sec) {
                        final isCurrent = countdown == sec;
                        return ChoiceChip(
                          label: Text('$sec seconds'),
                          selected: isCurrent,
                          showCheckmark: true,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(countdownDurationProvider.notifier)
                                  .setDuration(sec);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Appearance Card
            Material(
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light Mode'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark Mode'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {
                        themeMode == ThemeMode.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                      },
                      onSelectionChanged: (newSelection) {
                        final currentMode = ref.read(themeNotifierProvider);
                        final desired = newSelection.first;
                        if (currentMode != desired) {
                          ref.read(themeNotifierProvider.notifier).toggleTheme();
                        }
                      },
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Show Character Name On Reveal',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      value: showHint,
                      onChanged: (val) {
                        ref.read(showCharacterNameHintProvider.notifier).set(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Reset defaults button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('Reset All Settings to Default'),
              onPressed: () {
                ref
                    .read(characterAlgorithmProvider.notifier)
                    .setAlgorithm(CharacterAlgorithm.nonRepeating);
                ref.read(countdownDurationProvider.notifier).setDuration(2);
                ref.read(showCharacterNameHintProvider.notifier).set(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings restored to defaults'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. HOW TO PLAY VIEW
// -----------------------------------------------------------------------------

class _HowToPlayView extends StatelessWidget {
  const _HowToPlayView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 400),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 20.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Hero Intro Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2-Player Guessing Game',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ask clever Yes/No questions to deduce your mystery character before your rival does!',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Step-by-Step Guide
            Text(
              'Step-by-Step Gameplay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            _buildStepCard(
              context: context,
              stepNumber: 1,
              title: 'Pick a Category & Tap Start',
              icon: Icons.touch_app_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),

            _buildStepCard(
              context: context,
              stepNumber: 2,
              title: 'Show Screen & Hide From Yourself',
              icon: Icons.screen_rotation_rounded,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 8),

            _buildStepCard(
              context: context,
              stepNumber: 3,
              title: 'Take Turns Asking Yes/No Questions',
              icon: Icons.question_answer_rounded,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 8),

            _buildStepCard(
              context: context,
              stepNumber: 4,
              title: 'Eliminate & Deduce',
              icon: Icons.psychology_rounded,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 8),

            _buildStepCard(
              context: context,
              stepNumber: 5,
              title: 'Guess Correctly & Win the Round!',
              icon: Icons.emoji_events_rounded,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 32),

            // Example Duel Simulation Mockup
            Text(
              'Example Question Exchange',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  _buildChatBubble(
                    context,
                    speaker: 'Player 1',
                    question: 'Does my character possess Titan shifting powers?',
                    response: '✅ YES',
                    isUser: true,
                  ),
                  const SizedBox(height: 10),
                  _buildChatBubble(
                    context,
                    speaker: 'Player 2',
                    question: 'Is my character part of the Scout Regiment?  ',
                    response: '❌ NO',
                    isUser: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required int stepNumber,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    BuildContext context, {
    required String speaker,
    required String question,
    required String response,
    required bool isUser,
  }) {
    final theme = Theme.of(context);
    final accentColor = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: accentColor,
            child: Text(
              isUser ? 'P1' : 'P2',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  question,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              response,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. ABOUT THE GAME VIEW
// -----------------------------------------------------------------------------

class _AboutGameView extends StatelessWidget {
  const _AboutGameView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 400),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 20.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // App Branding Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/logos/biguess-icon.webp',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.videogame_asset_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BiGuess Game',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The Ultimate 2-Player Anime Mystery Challenge',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Version 0.21.0',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '100% Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Highlights
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge(
                    context,
                    number: '18+',
                    label: 'Categories',
                    icon: Icons.category_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatBadge(
                    context,
                    number: '300+',
                    label: 'Characters',
                    icon: Icons.people_outline_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatBadge(
                    context,
                    number: '2P',
                    label: 'Local Duel',
                    icon: Icons.sports_esports_outlined,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // What is BiGuess?
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About the Game',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BiGuess Game is a fast-paced, face-to-face guessing game built for anime enthusiasts, party gaming, and tech community gatherings. Players test their franchise knowledge, memory, and deductive questioning in real time.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildFeatureBullet(
                    context,
                    icon: Icons.bolt_rounded,
                    title: 'Instant Setup:',
                    desc: 'Grab two devices anywhere, select your favorite anime franchise, and start a duel within 3 seconds.',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureBullet(
                    context,
                    icon: Icons.wifi_off_rounded,
                    title: 'Fully Offline:',
                    desc: 'Zero mobile data or Wi-Fi required. All high-res character assets are bundled locally.',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureBullet(
                    context,
                    icon: Icons.groups_rounded,
                    title: 'Community Driven:',
                    desc: 'Born from Google Developer Groups (GDG) Ghardaia community meetups and DevFest celebration events.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required String number,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            number,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 4. ABOUT THE DEVELOPERS VIEW
// -----------------------------------------------------------------------------

class _AboutDevelopersView extends StatelessWidget {
  const _AboutDevelopersView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 400),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 20.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Lead Developer Card
            _buildDevCard(
              context: context,
              name: 'Abderrahmane SAOUDI',
              role: 'Lead Developer & UI/UX Designer',
              bio:
                  'Frontend & Mobile Developer, Graphic Designer, and Technical Trainer with experience in teaching, building, and leading tech communities.',
              accentColor: theme.colorScheme.primary,
              avatarWidget: Image.asset(
                'assets/profile/profile.webp',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              links: [
                const _DevLink(
                  label: 'Website',
                  icon: Icons.language_rounded,
                  url: 'https://saoudi.online',
                ),
                const _DevLink(
                  label: 'GitHub',
                  icon: Icons.code_rounded,
                  url: 'https://github.com/AbderrahmaneSAOUDI',
                ),
                const _DevLink(
                  label: 'Email',
                  icon: Icons.email_rounded,
                  url: 'mailto:saoudi.dev@gmail.com',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contributor Card
            _buildDevCard(
              context: context,
              name: 'Anas Oussama DJRIBIE',
              role: 'Data Collector & QA Tester',
              bio:
                  'Curated anime character datasets, managed image processing and naming conventions across all 18 categories, and performed gameplay balancing and testing.',
              accentColor: theme.colorScheme.secondary,
              avatarWidget: Icon(
                Icons.person_pin_rounded,
                size: 38,
                color: theme.colorScheme.secondary,
              ),
              links: [
                const _DevLink(
                  label: 'Email',
                  icon: Icons.email_rounded,
                  url: 'mailto:anas.djribie@gmail.com',
                ),
                const _DevLink(
                  label: 'GitHub',
                  icon: Icons.code_rounded,
                  url: 'https://github.com/',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevCard({
    required BuildContext context,
    required String name,
    required String role,
    required String bio,
    required Color accentColor,
    required Widget avatarWidget,
    required List<_DevLink> links,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: ClipOval(child: avatarWidget),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: links.map((link) {
              return ActionChip(
                avatar: Icon(link.icon, size: 14, color: accentColor),
                label: Text(link.label),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: accentColor.withValues(alpha: 0.3),
                ),
                onPressed: () => _GameInfoDialogState._launchUrl(link.url),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DevLink {
  final String label;
  final IconData icon;
  final String url;

  const _DevLink({
    required this.label,
    required this.icon,
    required this.url,
  });
}

// -----------------------------------------------------------------------------
// Backward Compatibility Wrappers for Legacy Code
// -----------------------------------------------------------------------------

class GameSettingsDialog extends StatelessWidget {
  final CharacterAlgorithm? algorithm;
  final ValueChanged<CharacterAlgorithm>? onAlgorithmChanged;

  const GameSettingsDialog({
    super.key,
    this.algorithm,
    this.onAlgorithmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GameInfoDialog(
      initialTab: GameInfoTab.settings,
      algorithm: algorithm,
      onAlgorithmChanged: onAlgorithmChanged,
    );
  }
}

class RulesContactDialog extends StatelessWidget {
  final GameInfoTab initialTab;

  const RulesContactDialog({
    super.key,
    this.initialTab = GameInfoTab.howToPlay,
  });

  @override
  Widget build(BuildContext context) {
    return GameInfoDialog(
      initialTab: initialTab,
    );
  }
}
