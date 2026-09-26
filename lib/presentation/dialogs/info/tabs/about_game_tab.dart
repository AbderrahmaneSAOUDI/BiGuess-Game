import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/models/update_state.dart';
import '../../../controllers/app_version_controller.dart';
import '../../../controllers/update_controller.dart';
import '../../update/update_dialog.dart';
import '../widgets/feature_bullet.dart';
import '../widgets/stat_badge.dart';

/// About Game Tab view presenting branding, version, offline stats, and community background
class AboutGameTab extends ConsumerWidget {
  const AboutGameTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final versionAsync = ref.watch(appVersionProvider);
    final versionText = versionAsync.when(
      data: (version) => 'Version $version',
      loading: () => 'Version ...',
      error: (_, __) => 'Version ${AppConstants.defaultVersion}',
    );

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
                      AppConstants.appIconPath,
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
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.appTagline,
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
                          versionText,
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
                  child: StatBadge(
                    number: '18+',
                    label: 'Categories',
                    icon: Icons.category_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatBadge(
                    number: '300+',
                    label: 'Characters',
                    icon: Icons.people_outline_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatBadge(
                    number: '2P',
                    label: 'Local Duel',
                    icon: Icons.sports_esports_outlined,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // App Updates & Status Card
            const _AppUpdateCard(),
            const SizedBox(height: 16),

            // About Game Overview
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
                  const FeatureBullet(
                    icon: Icons.bolt_rounded,
                    title: 'Instant Setup:',
                    desc: 'Grab two devices anywhere, select your favorite anime franchise, and start a duel within 3 seconds.',
                  ),
                  const SizedBox(height: 8),
                  const FeatureBullet(
                    icon: Icons.wifi_off_rounded,
                    title: 'Fully Offline:',
                    desc: 'Zero mobile data or Wi-Fi required. All high-res character assets are bundled locally.',
                  ),
                  const SizedBox(height: 8),
                  const FeatureBullet(
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
}

/// Compact widget presenting current update status and check action.
class _AppUpdateCard extends ConsumerWidget {
  const _AppUpdateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final updateState = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);

    return Container(
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
          Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Auto-Updates & Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatusContent(context, ref, controller, updateState, theme),
        ],
      ),
    );
  }

  Widget _buildStatusContent(
    BuildContext context,
    WidgetRef ref,
    UpdateController controller,
    UpdateState state,
    ThemeData theme,
  ) {
    return switch (state) {
      UpdateIdle() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Instant OTA patches enabled',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => controller.checkForUpdates(silent: false),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Check', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      UpdateChecking() => Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Checking for new version...',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      UpdateAvailable(:final latestVersion) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '🎉 Version v$latestVersion available!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => UpdateDialog.show(context),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Update', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      UpdateDownloading(:final progress, :final speedText) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress > 0 ? progress : null),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% downloaded',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                ),
                Text(
                  speedText,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      UpdateCompleted(:final message) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message.isNotEmpty ? message : 'App is up to date',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              tooltip: 'Check again',
              onPressed: () => controller.checkForUpdates(silent: false),
            ),
          ],
        ),
      _ => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Check for latest updates',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => UpdateDialog.show(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Manage', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
    };
  }
}

