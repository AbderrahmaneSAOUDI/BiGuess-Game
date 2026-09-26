import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/update_decision.dart';
import '../../../domain/models/update_state.dart';
import '../../controllers/update_controller.dart';

/// Interactive dialog displaying update status, changelog, download progress,
/// and installation actions.
class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  /// Displays the [UpdateDialog] modally.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const UpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final updateState = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Icon & Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Updates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSubtitleText(updateState),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Dynamic Body based on UpdateState
              switch (updateState) {
                UpdateIdle() => _buildIdleState(context, controller, theme),
                UpdateChecking() => _buildCheckingState(theme),
                UpdateAvailable() =>
                  _buildAvailableState(context, ref, updateState, theme),
                UpdateDownloading() =>
                  _buildDownloadingState(context, controller, updateState, theme),
                UpdateInstalling() => _buildInstallingState(theme),
                UpdatePatching() => _buildPatchingState(theme),
                UpdateRestarting() => _buildRestartingState(theme),
                UpdateCompleted() =>
                  _buildCompletedState(context, controller, updateState, theme),
                UpdateSkipped() => _buildSkippedState(context, controller, theme),
                UpdateError() =>
                  _buildErrorState(context, controller, updateState, theme),
              },
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitleText(UpdateState state) {
    return switch (state) {
      UpdateIdle() => 'Check for the latest features & fixes',
      UpdateChecking() => 'Connecting to update servers...',
      UpdateAvailable(:final latestVersion) => 'Version v$latestVersion is ready',
      UpdateDownloading() => 'Downloading update package...',
      UpdateInstalling() => 'Launching package installer...',
      UpdatePatching() => 'Downloading over-the-air patch...',
      UpdateRestarting() => 'Applying changes...',
      UpdateCompleted() => 'Everything is up to date',
      UpdateSkipped() => 'Update deferred',
      UpdateError() => 'Update check encountered an issue',
    };
  }

  // ---------------------------------------------------------------------------
  // State Views
  // ---------------------------------------------------------------------------

  Widget _buildIdleState(
    BuildContext context,
    UpdateController controller,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          'BiGuess automatically delivers patches and updates to keep your game fast and stable.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => controller.checkForUpdates(silent: false),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Check for Updates Now'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckingState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Checking remote version manifest...',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableState(
    BuildContext context,
    WidgetRef ref,
    UpdateAvailable state,
    ThemeData theme,
  ) {
    final isPatch = state.decision is UpdateShorebirdPatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Version badge row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'v${state.currentVersion} → v${state.latestVersion}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPatch ? 'OTA Patch' : 'Split-ABI APK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Release notes box
        if (state.releaseNotes.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s New:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.releaseNotes,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Action Buttons
        FilledButton.icon(
          onPressed: () {
            final controller = ref.read(updateControllerProvider.notifier);
            if (isPatch) {
              controller.applyShorebirdPatch();
            } else if (state.decision is UpdateFullApk) {
              controller.downloadAndInstallApk(state.decision as UpdateFullApk);
            }
          },
          icon: Icon(
            isPatch ? Icons.bolt_rounded : Icons.download_rounded,
            size: 18,
          ),
          label: Text(isPatch ? 'Apply Instant Patch' : 'Download & Install APK'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadingState(
    BuildContext context,
    UpdateController controller,
    UpdateDownloading state,
    ThemeData theme,
  ) {
    final percent = (state.progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: state.progress > 0 ? state.progress : null,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (state.speedText.isNotEmpty)
              Text(
                state.speedText,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (state.etaText.isNotEmpty)
              Text(
                state.etaText,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => controller.skipUpdate(),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Cancel Download'),
        ),
      ],
    );
  }

  Widget _buildInstallingState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Launching Android Package Installer...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatchingState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Applying code patch in background...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestartingState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.restart_alt_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 14),
          const Text(
            'Patch applied! Restarting...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(
    BuildContext context,
    UpdateController controller,
    UpdateCompleted state,
    ThemeData theme,
  ) {
    final message = state.message.isNotEmpty
        ? state.message
        : 'You are on the latest version.';

    return Column(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 44,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSkippedState(
    BuildContext context,
    UpdateController controller,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          'Update was cancelled.',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    UpdateController controller,
    UpdateError state,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 40,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          state.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => controller.checkForUpdates(silent: false),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
