import 'package:flutter/material.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../domain/models/developer_info.dart';
import '../../../widgets/animations/interactive_scale_card.dart';

/// Interactive developer profile card with avatar, role, bio, and social action chips
class DeveloperCard extends StatelessWidget {
  final DeveloperProfile profile;

  const DeveloperCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = profile.accentColor;

    Widget avatarWidget;
    if (profile.imageAsset != null) {
      avatarWidget = Image.asset(
        profile.imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          profile.fallbackIcon ?? Icons.person_rounded,
          size: 40,
          color: accentColor,
        ),
      );
    } else {
      avatarWidget = Icon(
        profile.fallbackIcon ?? Icons.person_pin_rounded,
        size: 38,
        color: accentColor,
      );
    }

    return InteractiveScaleCard(
      scaleOnHover: 1.02,
      scaleOnPress: 0.98,
      glowColor: accentColor,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                        profile.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.role,
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
              profile.bio,
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
              children: profile.links.map((link) {
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
                  onPressed: () => UrlHelper.launchExternalUrl(link.url),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
