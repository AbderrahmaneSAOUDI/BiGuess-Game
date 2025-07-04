import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'game_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<Map<String, String>> categories =
      const [
    {
      'name': 'Attack on Titan',
      'path': 'assets/images/attack_on_titan',
      'logo_path':
          'assets/logos/Attack on Titan.webp'
    },
    {
      'name': 'Black Clover',
      'path': 'assets/images/black_clover',
      'logo_path':
          'assets/logos/Black-Clover.webp'
    },
    {
      'name': 'Demon Slayer',
      'path': 'assets/images/demon_slayer',
      'logo_path':
          'assets/logos/Demon Slayer.png'
    },
    {
      'name': 'Hunter X Hunter',
      'path': 'assets/images/hunter_x_hunter',
      'logo_path':
          'assets/logos/Hunter X Hunter.webp'
    },
    {
      'name': 'Naruto',
      'path': 'assets/images/naruto',
      'logo_path':
          'assets/logos/Naruto Uzumaki.webp'
    },
    {
      'name': 'One Piece',
      'path': 'assets/images/one_piece',
      'logo_path': 'assets/logos/One Piece.webp'
    },
    {
      'name': 'Bleach',
      'path': 'assets/images/bleach',
      'logo_path': 'assets/logos/Bleach.webp'
    },
    {
      'name': 'Code Geass',
      'path': 'assets/images/code_geass',
      'logo_path':
          'assets/logos/Code Geass.webp'
    },
    {
      'name': 'Death Note',
      'path': 'assets/images/death_note',
      'logo_path':
          'assets/logos/Death Note.webp'
    },
    {
      'name': 'Detective Conan',
      'path': 'assets/images/detective_conan',
      'logo_path':
          'assets/logos/Detective Conan.webp'
    },
    {
      'name': 'Dr. Stone',
      'path': 'assets/images/dr_stone',
      'logo_path': 'assets/logos/Dr. Stone.webp'
    },
    {
      'name': 'Dragon Ball Z',
      'path': 'assets/images/dragon_ball_z',
      'logo_path':
          'assets/logos/Dragon Ball Z.webp'
    },
    {
      'name': 'FMAB',
      'path': 'assets/images/fmab',
      'logo_path': 'assets/logos/FMAB.webp'
    },
    {
      'name': 'Jujutsu Kaisen',
      'path': 'assets/images/jujutsu_kaisen',
      'logo_path':
          'assets/logos/Jujutsu Kaisen.webp'
    },
    {
      'name': 'My Hero Academia',
      'path': 'assets/images/my_hero_academia',
      'logo_path':
          'assets/logos/My Hero Academia.webp'
    },
    {
      'name': 'Solo Leveling',
      'path': 'assets/images/solo_leveling',
      'logo_path':
          'assets/logos/Solo Leveling.webp'
    },
    {
      'name': 'Tokyo Revengers',
      'path': 'assets/images/tokyo_revengers',
      'logo_path':
          'assets/logos/Tokyo Revengers.webp'
    },
    {
      'name': 'Vinland Saga',
      'path': 'assets/images/vinland_saga',
      'logo_path':
          'assets/logos/Winland Saga.webp'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier =
        Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('GDG Ghardaia'),
        leading: Padding(
          padding:
              const EdgeInsets.only(left: 12.0),
          child: Image.asset(
              'assets/logos/gdg_logo.webp'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) =>
                      GameSettingsDialog(
                    algorithm: CharacterAlgorithm
                        .random, // fallback for now
                    onAlgorithmChanged:
                        (_) {}, // fallback for now
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon:
                const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (BuildContext context) {
                  return RulesContactDialog();
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(
                right: 8.0),
            child: AnimatedRotation(
              duration: const Duration(
                  milliseconds: 500),
              turns: themeNotifier
                          .getTheme()
                          .brightness ==
                      Brightness.dark
                  ? 0.5
                  : 0,
              child: AnimatedScale(
                duration: const Duration(
                    milliseconds: 300),
                scale: themeNotifier
                            .getTheme()
                            .brightness ==
                        Brightness.dark
                    ? 1.2
                    : 1.0,
                child: IconButton(
                  icon: Icon(
                    themeNotifier
                                .getTheme()
                                .brightness ==
                            Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () {
                    themeNotifier.toggleTheme();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration
                .staggeredGrid(
              position: index,
              duration: const Duration(
                  milliseconds: 1200),
              columnCount: 2,
              child: SlideAnimation(
                horizontalOffset: 300.0,
                child: FadeInAnimation(
                  duration: const Duration(
                      milliseconds: 1200),
                  child: AnimatedCard(
                    category: categories[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GameScreen(
                            categoryName:
                                categories[
                                        index]
                                    ['name']!,
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
  State<AnimatedCard> createState() =>
      _AnimatedCardState();
}

class _AnimatedCardState
    extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isLongPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration:
          const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95)
            .animate(
      CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut),
    );

    _rotateAnimation =
        Tween<double>(begin: 0.0, end: 0.05)
            .animate(
      CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPressStart(
      LongPressStartDetails details) {
    setState(() => _isLongPressed = true);
    _controller.forward();
  }

  void _handleLongPressEnd(
      LongPressEndDetails details) {
    setState(() => _isLongPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateZ(_rotateAnimation.value)
              ..scale(_scaleAnimation.value),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.1),
                    blurRadius:
                        _isLongPressed ? 6 : 4,
                    offset: Offset(0,
                        _isLongPressed ? 3 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                              16),
                      gradient: LinearGradient(
                        begin:
                            Alignment.topLeft,
                        end: Alignment
                            .bottomRight,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .surface,
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withAlpha(77),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                              16.0),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Hero(
                              tag:
                                  'category_${widget.category['name']}',
                              child:
                                  TweenAnimationBuilder(
                                duration:
                                    const Duration(
                                        milliseconds:
                                            800),
                                tween: Tween<
                                        double>(
                                    begin: 0.0,
                                    end: 1.0),
                                curve: Curves
                                    .easeOutBack,
                                builder: (context,
                                    double
                                        value,
                                    child) {
                                  return Transform(
                                    transform: Matrix4
                                        .identity()
                                      ..setEntry(
                                          3,
                                          2,
                                          0.001)
                                      ..rotateX(
                                          (1 - value) *
                                              0.5)
                                      ..rotateY(
                                          (1 - value) *
                                              0.5)
                                      ..scale(
                                          value),
                                    alignment:
                                        Alignment
                                            .center,
                                    child: Image
                                        .asset(
                                      widget.category[
                                          'logo_path']!,
                                      fit: BoxFit
                                          .contain,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: 8),
                          Expanded(
                            flex: 1,
                            child:
                                TweenAnimationBuilder(
                              duration:
                                  const Duration(
                                      milliseconds:
                                          800),
                              tween:
                                  Tween<double>(
                                      begin:
                                          0.0,
                                      end: 1.0),
                              curve: Curves
                                  .easeOutBack,
                              builder: (context,
                                  double value,
                                  child) {
                                return Transform(
                                  transform: Matrix4
                                      .identity()
                                    ..setEntry(
                                        3,
                                        2,
                                        0.001)
                                    ..translate(
                                        0.0,
                                        30.0 *
                                            (1 -
                                                value))
                                    ..scale(
                                        value),
                                  alignment:
                                      Alignment
                                          .center,
                                  child: Text(
                                    widget.category[
                                        'name']!,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: Theme.of(
                                              context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    textAlign:
                                        TextAlign
                                            .center,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
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
          );
        },
      ),
    );
  }
}

// Create a new StatefulWidget for the Rules and Contact dialog
class RulesContactDialog
    extends StatefulWidget {
  const RulesContactDialog({super.key});

  @override
  State<RulesContactDialog> createState() =>
      _RulesContactDialogState();
}

class _RulesContactDialogState
    extends State<RulesContactDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this);
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
        borderRadius:
            BorderRadius.circular(16.0),
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
                Tab(text: 'About the game'),
                Tab(
                    text:
                        'About the developers'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(
                            12.0),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .center,
                      children: [
                        AnimationConfiguration
                            .staggeredList(
                          position: 0,
                          duration:
                              const Duration(
                                  milliseconds:
                                      500),
                          child: SlideAnimation(
                            verticalOffset:
                                50.0,
                            child:
                                FadeInAnimation(
                              child:
                                  ScaleAnimation(
                                scale: 0.9,
                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                          16),
                                  decoration:
                                      BoxDecoration(
                                    color: Theme.of(
                                            context)
                                        .colorScheme
                                        .primaryContainer
                                        .withAlpha(
                                            77),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(26),
                                        offset: const Offset(
                                            0,
                                            2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🎮',
                                            style:
                                                TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(
                                              width: 8),
                                          Expanded(
                                            child:
                                                Text(
                                              'What is BiGuess Game?',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height:
                                              12),
                                      Text(
                                        'BiGuess Game is a fast-paced, two-player challenge where each player tries to guess their own mystery character by asking clever yes/no questions. The first to guess correctly wins the round and scores a point!',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              15,
                                          height:
                                              1.5,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: 12),
                        AnimationConfiguration
                            .staggeredList(
                          position: 1,
                          duration:
                              const Duration(
                                  milliseconds:
                                      600),
                          child: SlideAnimation(
                            horizontalOffset:
                                50.0,
                            child:
                                FadeInAnimation(
                              child:
                                  ScaleAnimation(
                                scale: 0.9,
                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                          16),
                                  decoration:
                                      BoxDecoration(
                                    color: Theme.of(
                                            context)
                                        .colorScheme
                                        .secondaryContainer
                                        .withAlpha(
                                            77),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withAlpha(26),
                                        offset: const Offset(
                                            0,
                                            2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🕹️',
                                            style:
                                                TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(
                                              width: 8),
                                          Expanded(
                                            child:
                                                Text(
                                              'How to Play',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height:
                                              12),
                                      ListView
                                          .builder(
                                        shrinkWrap:
                                            true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            5,
                                        itemBuilder:
                                            (context,
                                                index) {
                                          final List<String>
                                              steps =
                                              [
                                            'Both players tap "Start/Refresh" on their phones to get a different mystery character.',
                                            'Show your screen to your opponent before the countdown ends.',
                                            'start taking turns asking yes/no questions to guess your own character.',
                                            'The first player to guess their character correctly wins the round.',
                                            'Keep playing and tracking scores!',
                                          ];
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 8.0),
                                            child:
                                                Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${index + 1}. ',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.secondary,
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
                        ),
                        const SizedBox(
                            height: 12),
                        AnimationConfiguration
                            .staggeredList(
                          position: 2,
                          duration:
                              const Duration(
                                  milliseconds:
                                      700),
                          child: SlideAnimation(
                            verticalOffset:
                                -50.0,
                            child:
                                FadeInAnimation(
                              child:
                                  ScaleAnimation(
                                scale: 0.9,
                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                          16),
                                  decoration:
                                      BoxDecoration(
                                    color: Theme.of(
                                            context)
                                        .colorScheme
                                        .tertiaryContainer
                                        .withAlpha(
                                            77),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary
                                            .withAlpha(26),
                                        offset: const Offset(
                                            0,
                                            2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '⚔️',
                                            style:
                                                TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(
                                              width: 8),
                                          Expanded(
                                            child:
                                                Text(
                                              'Game Rules',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.tertiary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height:
                                              12),
                                      ListView
                                          .builder(
                                        shrinkWrap:
                                            true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            5,
                                        itemBuilder:
                                            (context,
                                                index) {
                                          final List<String>
                                              rules =
                                              [
                                            'Ask yes/no questions only',
                                            'One question per turn',
                                            'No peeking at your own screen',
                                            'Be honest when answering',
                                            'Try not to repeat previous questions',
                                          ];
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 8.0),
                                            child:
                                                Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '• ',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.tertiary,
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
                        ),
                        const SizedBox(
                            height: 12),
                        AnimationConfiguration
                            .staggeredList(
                          position: 3,
                          duration:
                              const Duration(
                                  milliseconds:
                                      800),
                          child: SlideAnimation(
                            horizontalOffset:
                                -50.0,
                            child:
                                FadeInAnimation(
                              child:
                                  ScaleAnimation(
                                scale: 0.9,
                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                          16),
                                  decoration:
                                      BoxDecoration(
                                    color: Theme.of(
                                            context)
                                        .colorScheme
                                        .primaryContainer
                                        .withAlpha(
                                            77),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(26),
                                        offset: const Offset(
                                            0,
                                            2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🤩',
                                            style:
                                                TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(
                                              width: 8),
                                          Expanded(
                                            child:
                                                Text(
                                              'Why You\'ll Love It',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height:
                                              12),
                                      ListView
                                          .builder(
                                        shrinkWrap:
                                            true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            3,
                                        itemBuilder:
                                            (context,
                                                index) {
                                          final List<String>
                                              reasons =
                                              [
                                            'A game of speed, memory, and smart questioning',
                                            'Great for clubs, friends, or events',
                                            'Brings people together through fun competition',
                                          ];
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 8.0),
                                            child:
                                                Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '• ',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    reasons[index],
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
                        ),
                        const SizedBox(
                            height: 12),
                        AnimationConfiguration
                            .staggeredList(
                          position: 4,
                          duration:
                              const Duration(
                                  milliseconds:
                                      900),
                          child: SlideAnimation(
                            verticalOffset:
                                50.0,
                            child:
                                FadeInAnimation(
                              child:
                                  ScaleAnimation(
                                scale: 0.9,
                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                          16),
                                  decoration:
                                      BoxDecoration(
                                    color: Theme.of(
                                            context)
                                        .colorScheme
                                        .secondaryContainer
                                        .withAlpha(
                                            77),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withAlpha(26),
                                        offset: const Offset(
                                            0,
                                            2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🎉',
                                            style:
                                                TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(
                                              width: 8),
                                          Expanded(
                                            child:
                                                Text(
                                              'Make It More Fun',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height:
                                              12),
                                      ListView
                                          .builder(
                                        shrinkWrap:
                                            true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            4,
                                        itemBuilder:
                                            (context,
                                                index) {
                                          final List<String>
                                              ideas =
                                              [
                                            'Add a time limit per question (e.g., 20 seconds) for more pressure and laughs',
                                            'Keep a scoreboard and play multiple rounds for bragging rights',
                                            'Encourage funny or tricky questions to stump your opponent',
                                            'Invite a group to watch and cheer, turning it into a mini-tournament!',
                                          ];
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 8.0),
                                            child:
                                                Row(
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
                                                    ideas[index],
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
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Meet Our Developers',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // First Developer Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Picture
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/profile/profile.webp',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Developer Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      'Abderrahmane SAOUDI',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Position
                                    Text(
                                      'Lead Developer & Designer',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Bio
                                    Text(
                                      'Graphic Designer & Flutter Mobile Developer with expertise in Adobe Illustrator and Android Studio. GDG Ghardaia Club President and DevFest organizer.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Social Media Icons
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.email,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.link,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.phone,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Second Developer Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Picture
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Developer Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      'Anas Oussama DJRIBIE',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Position
                                    Text(
                                      'Data Collector & Tester',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Bio
                                    Text(
                                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 204),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Social Media Icons
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.email,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.code,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.work,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
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
