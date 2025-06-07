import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'game_screen.dart';
import 'dart:math';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<Map<String, String>> categories = const [
    {'name': 'Naruto', 'path': 'assets/images/naruto', 'logo_path': 'assets/logos/Naruto Uzumaki.webp'},
    {'name': 'Attack on Titan', 'path': 'assets/images/attack_on_titan', 'logo_path': 'assets/logos/Attack on Titan.webp'},
    {'name': 'Black Clover', 'path': 'assets/images/black_clover', 'logo_path': 'assets/logos/Black-Clover.webp'},
    {'name': 'Bleach', 'path': 'assets/images/bleach', 'logo_path': 'assets/logos/Bleach.webp'},
    {'name': 'Code Geass', 'path': 'assets/images/code_geass', 'logo_path': 'assets/logos/Code Geass.webp'},
    {'name': 'Death Note', 'path': 'assets/images/death_note', 'logo_path': 'assets/logos/Death Note.webp'},
    {'name': 'Demon Slayer', 'path': 'assets/images/demon_slayer', 'logo_path': 'assets/logos/Demon Slayer.png'},
    {'name': 'Detective Conan', 'path': 'assets/images/detective_conan', 'logo_path': 'assets/logos/Detective Conan.webp'},
    {'name': 'Dr. Stone', 'path': 'assets/images/dr_stone', 'logo_path': 'assets/logos/Dr. Stone.webp'},
    {'name': 'Dragon Ball Z', 'path': 'assets/images/dragon_ball_z', 'logo_path': 'assets/logos/Dragon Ball Z.webp'},
    {'name': 'FMAB', 'path': 'assets/images/fmab', 'logo_path': 'assets/logos/FMAB.webp'},
    {'name': 'Hunter X Hunter', 'path': 'assets/images/hunter_x_hunter', 'logo_path': 'assets/logos/Hunter X Hunter.webp'},
    {'name': 'Jujutsu Kaisen', 'path': 'assets/images/jujutsu_kaisen', 'logo_path': 'assets/logos/Jujutsu Kaisen.webp'},
    {'name': 'My Hero Academia', 'path': 'assets/images/my_hero_academia', 'logo_path': 'assets/logos/My Hero Academia.webp'},
    {'name': 'One Piece', 'path': 'assets/images/one_piece', 'logo_path': 'assets/logos/One Piece.webp'},
    {'name': 'Solo Leveling', 'path': 'assets/images/solo_leveling', 'logo_path': 'assets/logos/Solo Leveling.webp'},
    {'name': 'Tokyo Revengers', 'path': 'assets/images/tokyo_revengers', 'logo_path': 'assets/logos/Tokyo Revengers.webp'},
    {'name': 'Vinland Saga', 'path': 'assets/images/vinland_saga', 'logo_path': 'assets/logos/Winland Saga.webp'},
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final List<IconData> iconList = [
      Icons.star,
      Icons.favorite,
      Icons.flash_on,
      Icons.cake,
      Icons.emoji_events,
      Icons.sports_esports,
      Icons.movie,
      Icons.music_note,
      Icons.public,
      Icons.pets,
      Icons.science,
      Icons.rocket_launch,
      Icons.palette,
      Icons.book,
      Icons.directions_car,
      Icons.fastfood,
      Icons.nature,
      Icons.spa,
      Icons.sports_soccer,
      Icons.access_alarm,
      Icons.account_balance,
      Icons.account_circle,
      Icons.add,
      Icons.airplanemode_active,
      Icons.attach_money,
      Icons.audiotrack,
      Icons.backup,
      Icons.battery_charging_full,
      Icons.bluetooth,
      Icons.brush,
      Icons.bug_report,
      Icons.build,
      Icons.camera_alt,
      Icons.chat,
      Icons.cloud_download,
      Icons.code,
      Icons.collections,
      Icons.computer,
      Icons.credit_card,
      Icons.dashboard,
      Icons.delete,
      Icons.description,
      Icons.dialpad,
      Icons.directions_bike,
      Icons.directions_bus,
      Icons.directions_railway,
      Icons.directions_run,
      Icons.directions_subway,
      Icons.directions_walk,
      Icons.dns,
      Icons.drive_eta,
      Icons.edit,
      Icons.email,
      Icons.event,
      Icons.exit_to_app,
      Icons.explore,
      Icons.extension,
      Icons.face,
      Icons.filter_drama,
      Icons.fingerprint,
      Icons.fitness_center,
      Icons.folder,
      Icons.format_quote,
      Icons.gamepad,
      Icons.gps_fixed,
      Icons.group,
      Icons.headset_mic,
      Icons.help,
      Icons.highlight,
      Icons.home,
      Icons.hotel,
      Icons.image,
      Icons.inbox,
      Icons.info,
      Icons.keyboard,
      Icons.language,
      Icons.layers,
      Icons.lightbulb_outline,
      Icons.link,
      Icons.local_cafe,
      Icons.local_gas_station,
      Icons.local_hospital,
      Icons.local_pharmacy,
      Icons.local_pizza,
      Icons.local_taxi,
      Icons.lock,
      Icons.map,
      Icons.memory,
      Icons.menu,
      Icons.message,
      Icons.mic,
      Icons.mood,
      Icons.navigation,
      Icons.notifications,
      Icons.palette,
      Icons.people,
      Icons.phone,
      Icons.photo_camera,
      Icons.place,
      Icons.play_arrow,
      Icons.print,
      Icons.public,
      Icons.redeem,
      Icons.refresh,
      Icons.restaurant,
      Icons.school,
      Icons.send,
      Icons.settings,
      Icons.share,
      Icons.shopping_bag,
      Icons.shuffle,
      Icons.sms,
      Icons.speaker_phone,
      Icons.speed,
      Icons.star_half,
      Icons.store,
      Icons.streetview,
      Icons.subway,
      Icons.terrain,
      Icons.textsms,
      Icons.thumb_up,
      Icons.timer,
      Icons.toll,
      Icons.traffic,
      Icons.train,
      Icons.translate,
      Icons.trending_up,
      Icons.tune,
      Icons.umbrella,
      Icons.usb,
      Icons.verified_user,
      Icons.videocam,
      Icons.visibility,
      Icons.voicemail,
      Icons.volume_up,
      Icons.wallet_giftcard,
      Icons.warning,
      Icons.watch,
      Icons.wifi,
      Icons.work,
      Icons.zoom_in,
    ];
    final random = Random();
    return Scaffold(
      appBar: AppBar(
        title: const Text('GDG Ghardaia'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Image.asset('assets/logos/gdg_logo.png'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return RulesContactDialog();
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 500),
              turns: themeNotifier.getTheme().brightness == Brightness.dark ? 0.5 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: themeNotifier.getTheme().brightness == Brightness.dark ? 1.2 : 1.0,
                child: IconButton(
                  icon: Icon(
                    themeNotifier.getTheme().brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 1200),
              columnCount: 2,
              child: SlideAnimation(
                horizontalOffset: 300.0,
                child: FadeInAnimation(
                  duration: const Duration(milliseconds: 1200),
                  child: AnimatedCard(
                    category: categories[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            categoryName: categories[index]['name']!,
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

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(_isLongPressed ? 0.4 : 0.2),
                    blurRadius: _isLongPressed ? 12 : 8,
                    offset: Offset(0, _isLongPressed ? 6 : 4),
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
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'category_${widget.category['name']}',
                          child: TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutBack,
                            builder: (context, double value, child) {
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateX((1 - value) * 0.5)
                                  ..rotateY((1 - value) * 0.5)
                                  ..scale(value),
                                alignment: Alignment.center,
                                child: Container(
                                  height: 120,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Image.asset(
                                    widget.category['logo_path']!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          curve: Curves.easeOutBack,
                          builder: (context, double value, child) {
                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..translate(0.0, 30.0 * (1 - value))
                                ..scale(value),
                              alignment: Alignment.center,
                              child: Text(
                                widget.category['name']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
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
          );
        },
      ),
    );
  }
}

// Create a new StatefulWidget for the Rules and Contact dialog
class RulesContactDialog extends StatefulWidget {
  const RulesContactDialog({super.key});

  @override
  State<RulesContactDialog> createState() => _RulesContactDialogState();
}

class _RulesContactDialogState extends State<RulesContactDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                Tab(text: 'About the game'),
                Tab(text: 'About the developer'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimationConfiguration.staggeredList(
                          position: 0,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: ScaleAnimation(
                                scale: 0.9,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🎮',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
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
                                      const SizedBox(height: 12),
                                      Text(
                                        'BiGuess Game is a fast-paced, two-player challenge where each player tries to guess their own mystery character by asking clever yes/no questions. The first to guess correctly wins the round and scores a point!',
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.5,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimationConfiguration.staggeredList(
                          position: 1,
                          duration: const Duration(milliseconds: 600),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: ScaleAnimation(
                                scale: 0.9,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🕹️',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
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
                                      const SizedBox(height: 12),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: 5,
                                        itemBuilder: (context, index) {
                                          final List<String> steps = [
                                            'Both players tap "Start/Refresh" on their phones to get a different mystery character.',
                                            'Show your screen to your opponent before the countdown ends.',
                                            'start taking turns asking yes/no questions to guess your own character.',
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
                        const SizedBox(height: 12),
                        AnimationConfiguration.staggeredList(
                          position: 2,
                          duration: const Duration(milliseconds: 700),
                          child: SlideAnimation(
                            verticalOffset: -50.0,
                            child: FadeInAnimation(
                              child: ScaleAnimation(
                                scale: 0.9,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '⚔️',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
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
                                      const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        AnimationConfiguration.staggeredList(
                          position: 3,
                          duration: const Duration(milliseconds: 800),
                          child: SlideAnimation(
                            horizontalOffset: -50.0,
                            child: FadeInAnimation(
                              child: ScaleAnimation(
                                scale: 0.9,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🤩',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
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
                                      const SizedBox(height: 12),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: 3,
                                        itemBuilder: (context, index) {
                                          final List<String> reasons = [
                                            'A game of speed, memory, and smart questioning',
                                            'Great for clubs, friends, or events',
                                            'Brings people together through fun competition',
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
                        const SizedBox(height: 12),
                        AnimationConfiguration.staggeredList(
                          position: 4,
                          duration: const Duration(milliseconds: 900),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: ScaleAnimation(
                                scale: 0.9,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🎉',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
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
                                      const SizedBox(height: 12),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: 4,
                                        itemBuilder: (context, index) {
                                          final List<String> ideas = [
                                            'Add a time limit per question (e.g., 20 seconds) for more pressure and laughs',
                                            'Keep a scoreboard and play multiple rounds for bragging rights',
                                            'Encourage funny or tricky questions to stump your opponent',
                                            'Invite a group to watch and cheer, turning it into a mini-tournament!',
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
                    child: AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    Text(
                                      'Developed by',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/profile/profile.jpg', // **Double-check this path is correct**
                                          width: 100, // Should be radius * 2 (50 * 2)
                                          height: 100, // Should be radius * 2 (50 * 2)
                                          fit: BoxFit.cover, // Ensures the image covers the circular area
                                          errorBuilder: (context, error, stackTrace) {
                                            // This will show the person icon if profile.jpg can't be loaded
                                            return Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.white,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Abderrahmane SAOUDI',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            duration: const Duration(milliseconds: 600),
                            child: SlideAnimation(
                              horizontalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.work,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Professional Title',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Graphic Designer & Flutter Mobile Developer',
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimationConfiguration.staggeredList(
                            position: 2,
                            duration: const Duration(milliseconds: 700),
                            child: SlideAnimation(
                              verticalOffset: -50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Skills & Achievements',
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
                                        '• Skilled in Adobe Illustrator, Android Studio, and Problem Solving\n• 3rd Place in StartUp City Hackathon\n• Led DevFest 2023 & 2024\n• GDG Ghardaia Club President since Aug 2022',
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
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
                            position: 3,
                            duration: const Duration(milliseconds: 800),
                            child: SlideAnimation(
                              horizontalOffset: -50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.contact_mail,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Contact Information',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'saoudi26@proton.me',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '+213 561 37 77 61',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () async {
                                          final Uri url = Uri.parse('https://www.linktr.ee/AbdouSAOUDI');
                                          try {
                                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Could not open the website'),
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: ${e.toString()}'),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.link,
                                              size: 20,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'www.linktr.ee/AbdouSAOUDI',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
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
