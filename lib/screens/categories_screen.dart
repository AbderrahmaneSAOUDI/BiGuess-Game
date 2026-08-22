import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'game_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static const List<Map<String, String>> categories = [
    {
      'name': 'Attack on Titan',
      'path': 'assets/images/attack_on_titan',
      'logo_path': 'assets/logos/Attack on Titan.webp',
    },
    {
      'name': 'Black Clover',
      'path': 'assets/images/black_clover',
      'logo_path': 'assets/logos/Black-Clover.webp',
    },
    {
      'name': 'Demon Slayer',
      'path': 'assets/images/demon_slayer',
      'logo_path': 'assets/logos/Demon Slayer.webp',
    },
    {
      'name': 'Hunter X Hunter',
      'path': 'assets/images/hunter_x_hunter',
      'logo_path': 'assets/logos/Hunter X Hunter.webp',
    },
    {
      'name': 'Naruto',
      'path': 'assets/images/naruto',
      'logo_path': 'assets/logos/Naruto Uzumaki.webp',
    },
    {
      'name': 'One Piece',
      'path': 'assets/images/one_piece',
      'logo_path': 'assets/logos/One Piece.webp',
    },
    {
      'name': 'Bleach',
      'path': 'assets/images/bleach',
      'logo_path': 'assets/logos/Bleach.webp',
    },
    {
      'name': 'Code Geass',
      'path': 'assets/images/code_geass',
      'logo_path': 'assets/logos/Code Geass.webp',
    },
    {
      'name': 'Death Note',
      'path': 'assets/images/death_note',
      'logo_path': 'assets/logos/Death Note.webp',
    },
    {
      'name': 'Detective Conan',
      'path': 'assets/images/detective_conan',
      'logo_path': 'assets/logos/Detective Conan.webp',
    },
    {
      'name': 'Dr. Stone',
      'path': 'assets/images/dr_stone',
      'logo_path': 'assets/logos/Dr. Stone.webp',
    },
    {
      'name': 'Dragon Ball Z',
      'path': 'assets/images/dragon_ball_z',
      'logo_path': 'assets/logos/Dragon Ball Z.webp',
    },
    {
      'name': 'FMAB',
      'path': 'assets/images/fmab',
      'logo_path': 'assets/logos/FMAB.webp',
    },
    {
      'name': 'Jujutsu Kaisen',
      'path': 'assets/images/jujutsu_kaisen',
      'logo_path': 'assets/logos/Jujutsu Kaisen.webp',
    },
    {
      'name': 'My Hero Academia',
      'path': 'assets/images/my_hero_academia',
      'logo_path': 'assets/logos/My Hero Academia.webp',
    },
    {
      'name': 'Solo Leveling',
      'path': 'assets/images/solo_leveling',
      'logo_path': 'assets/logos/Solo Leveling.webp',
    },
    {
      'name': 'Tokyo Revengers',
      'path': 'assets/images/tokyo_revengers',
      'logo_path': 'assets/logos/Tokyo Revengers.webp',
    },
    {
      'name': 'Vinland Saga',
      'path': 'assets/images/vinland_saga',
      'logo_path': 'assets/logos/Winland Saga.webp',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GDG Ghardaia'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Image.asset('assets/logos/gdg_logo.webp'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => const GameSettingsDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Rules & About',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => const RulesContactDialog(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 500),
              turns: isDark ? 0.5 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: isDark ? 1.2 : 1.0,
                child: IconButton(
                  tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                  ),
                  onPressed: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 1200),
              columnCount: 2,
              child: SlideAnimation(
                horizontalOffset: 300.0,
                child: FadeInAnimation(
                  duration: const Duration(milliseconds: 1200),
                  child: AnimatedCard(
                    category: category,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => GameScreen(
                            categoryName: category['name']!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Map<String, String> category;
  final VoidCallback onTap;

  const AnimatedCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotateAnimation;
  bool _isLongPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() => _isLongPressed = true);
    _controller.forward();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _isLongPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = widget.category['name'] ?? '';
    final logoPath = widget.category['logo_path'] ?? '';

    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: _isLongPressed ? 6 : 4,
                offset: Offset(0, _isLongPressed ? 3 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Hero(
                          tag: 'category_$categoryName',
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutBack,
                            builder: (context, double value, child) {
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateX((1 - value) * 0.5)
                                  ..rotateY((1 - value) * 0.5)
                                  ..scaleByDouble(
                                    value,
                                    value,
                                    1.0,
                                    1.0,
                                  ),
                                alignment: Alignment.center,
                                child: Image.asset(
                                  logoPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 40),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 1,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          curve: Curves.easeOutBack,
                          builder: (context, double value, child) {
                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..translateByDouble(
                                  0.0,
                                  30.0 * (1 - value),
                                  0.0,
                                  1.0,
                                )
                                ..scaleByDouble(
                                  value,
                                  value,
                                  1.0,
                                  1.0,
                                ),
                              alignment: Alignment.center,
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateZ(_rotateAnimation.value)
              ..scaleByDouble(
                _scaleAnimation.value,
                _scaleAnimation.value,
                1.0,
                1.0,
              ),
            alignment: Alignment.center,
            child: child,
          );
        },
      ),
    );
  }
}

class RulesContactDialog extends StatefulWidget {
  const RulesContactDialog({super.key});

  @override
  State<RulesContactDialog> createState() => _RulesContactDialogState();
}

class _RulesContactDialogState extends State<RulesContactDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static Future<void> _launch(BuildContext context, String url) async {
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SizedBox(
        width: 512.0,
        height: 540.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'About the game'),
                Tab(text: 'About the developers'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: About the game
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          context: context,
                          position: 0,
                          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          accentColor: theme.colorScheme.primary,
                          emoji: '🎮',
                          title: 'What is BiGuess Game?',
                          child: Text(
                            'BiGuess Game is a fast-paced, two-player challenge where each player tries to guess their own mystery character by asking clever yes/no questions. The first to guess correctly wins the round and scores a point!',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context: context,
                          position: 1,
                          backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                          shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          accentColor: theme.colorScheme.secondary,
                          emoji: '🕹️',
                          title: 'How to Play',
                          child: _buildNumberedList(
                            context: context,
                            accentColor: theme.colorScheme.secondary,
                            items: const [
                              'Both players tap "Start/Refresh" on their phones to get a different mystery character.',
                              'Show your screen to your opponent before the countdown ends.',
                              'Start taking turns asking yes/no questions to guess your own character.',
                              'The first player to guess their character correctly wins the round.',
                              'Keep playing and tracking scores!',
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context: context,
                          position: 2,
                          backgroundColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                          shadowColor: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                          accentColor: theme.colorScheme.tertiary,
                          emoji: '⚔️',
                          title: 'Game Rules',
                          child: _buildBulletList(
                            context: context,
                            accentColor: theme.colorScheme.tertiary,
                            items: const [
                              'Ask yes/no questions only',
                              'One question per turn',
                              'No peeking at your own screen',
                              'Be honest when answering',
                              'Try not to repeat previous questions',
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context: context,
                          position: 3,
                          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          accentColor: theme.colorScheme.primary,
                          emoji: '🤩',
                          title: "Why You'll Love It",
                          child: _buildBulletList(
                            context: context,
                            accentColor: theme.colorScheme.primary,
                            items: const [
                              'A game of speed, memory, and smart questioning',
                              'Great for clubs, friends, or events',
                              'Brings people together through fun competition',
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context: context,
                          position: 4,
                          backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                          shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          accentColor: theme.colorScheme.secondary,
                          emoji: '🎉',
                          title: 'Make It More Fun',
                          child: _buildBulletList(
                            context: context,
                            accentColor: theme.colorScheme.secondary,
                            items: const [
                              'Add a time limit per question (e.g., 20 seconds) for more pressure and laughs',
                              'Keep a scoreboard and play multiple rounds for bragging rights',
                              'Encourage funny or tricky questions to stump your opponent',
                              'Invite a group to watch and cheer, turning it into a mini-tournament!',
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: About the developers
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'Meet Our Developers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDeveloperCard(
                          context: context,
                          name: 'Abderrahmane SAOUDI',
                          role: 'Lead Developer & Designer',
                          bio:
                              'Graphic Designer & Flutter Mobile Developer with expertise in Adobe Illustrator and Android Studio. GDG Ghardaia Club President and DevFest organizer.',
                          avatarWidget: Image.asset(
                            'assets/profile/profile.webp',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: 40,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          accentColor: theme.colorScheme.primary,
                          actions: [
                            IconButton(
                              tooltip: 'Email',
                              onPressed: () => _launch(context, 'mailto:saoudi.dev@gmail.com'),
                              icon: Icon(Icons.email, size: 20, color: theme.colorScheme.primary),
                            ),
                            IconButton(
                              tooltip: 'Website',
                              onPressed: () => _launch(context, 'https://saoudi.online'),
                              icon: Icon(Icons.link, size: 20, color: theme.colorScheme.primary),
                            ),
                            IconButton(
                              tooltip: 'GitHub',
                              onPressed: () => _launch(context, 'https://github.com/AbderrahmaneSAOUDI'),
                              icon: Icon(Icons.code, size: 20, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDeveloperCard(
                          context: context,
                          name: 'Anas Oussama DJRIBIE',
                          role: 'Data Collector & Tester',
                          bio:
                              'Data Collector & Game Tester for BiGuess Game. Contributed to character database curation, testing, and quality assurance.',
                          avatarWidget: Icon(
                            Icons.person,
                            size: 40,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          accentColor: theme.colorScheme.secondary,
                          actions: [
                            IconButton(
                              tooltip: 'Email',
                              onPressed: () => _launch(context, 'mailto:anas.djribie@gmail.com'),
                              icon: Icon(Icons.email, size: 20, color: theme.colorScheme.secondary),
                            ),
                            IconButton(
                              tooltip: 'Portfolio',
                              onPressed: () => _launch(context, 'https://github.com/'),
                              icon: Icon(Icons.code, size: 20, color: theme.colorScheme.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildInfoCard({
    required BuildContext context,
    required int position,
    required Color backgroundColor,
    required Color shadowColor,
    required Color accentColor,
    required String emoji,
    required String title,
    required Widget child,
  }) {
    return AnimationConfiguration.staggeredList(
      position: position,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 40.0,
        child: FadeInAnimation(
          child: ScaleAnimation(
            scale: 0.95,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedList({
    required BuildContext context,
    required Color accentColor,
    required List<String> items,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}. ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBulletList({
    required BuildContext context,
    required Color accentColor,
    required List<String> items,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDeveloperCard({
    required BuildContext context,
    required String name,
    required String role,
    required String bio,
    required Widget avatarWidget,
    required Color accentColor,
    required List<Widget> actions,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: ClipOval(child: avatarWidget),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
