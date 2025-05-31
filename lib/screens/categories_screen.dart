import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
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
            padding: const EdgeInsets.only(left:12.0),
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
            child: IconButton(
              icon: Icon(themeNotifier.getTheme().brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                themeNotifier.toggleTheme();
              },
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
              duration: const Duration(milliseconds: 1000),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 20.0,
                child: FadeInAnimation(
                  child: ScaleAnimation(
                    scale: 0.8,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              categoryName: categories[index]['name']!,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding (
                            padding: const EdgeInsets.all (16.0),
                            child: Image.asset(
                            categories[index]['logo_path']!,
                            width: double.infinity,
                          ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            categories[index]['name']!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                            maxLines: 1,
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
                Tab(text: 'Contact'),
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
                                              'What is GDG Character Guessing Game?',
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
                                        'GDG Character Guessing Game is a fast-paced, two-player challenge where each player tries to guess their own mystery character by asking clever yes/no questions. The first to guess correctly wins the round and scores a point!',
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
                  const Center(child: SingleChildScrollView(child: Text('Contact information goes here...'),),), // Placeholder contact
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
