import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../controllers/game_settings_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../widgets/settings_section_card.dart';

/// Settings Tab view for configuring algorithm, countdown duration, theme, and hint options
class SettingsTab extends ConsumerWidget {
  final CharacterAlgorithm? algorithm;
  final ValueChanged<CharacterAlgorithm>? onAlgorithmChanged;

  const SettingsTab({
    super.key,
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
            // 1. Character Algorithm Card
            SettingsSectionCard(
              title: 'Character Algorithm',
              icon: Icons.shuffle_rounded,
              child: RadioGroup<CharacterAlgorithm>(
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
            ),
            const SizedBox(height: 16),

            // 2. Countdown Duration Card
            SettingsSectionCard(
              title: 'Countdown Duration',
              icon: Icons.timer_outlined,
              trailing: Container(
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.supportedCountdownDurations.map((sec) {
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
              ),
            ),
            const SizedBox(height: 16),

            // 3. Appearance Card
            SettingsSectionCard(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

            // Reset Defaults Button
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
                ref
                    .read(countdownDurationProvider.notifier)
                    .setDuration(AppConstants.defaultCountdownSeconds);
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
