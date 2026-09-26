import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/models/developer_info.dart';
import '../widgets/developer_card.dart';

/// Developers Tab view presenting developer and contributor profiles
class DevelopersTab extends StatelessWidget {
  const DevelopersTab({super.key});

  static const List<DeveloperProfile> developers = [
    DeveloperProfile(
      name: 'Abderrahmane SAOUDI',
      role: 'Lead Developer & UI/UX Designer',
      bio:
          'Frontend & Mobile Developer, Graphic Designer, and Technical Trainer with experience in teaching, building, and leading tech communities.',
      accentColor: Color(0xFF2979FF),
      imageAsset: AppConstants.defaultProfilePath,
      links: [
        DeveloperLink(
          label: 'Website',
          icon: Icons.language_rounded,
          url: 'https://saoudi.online',
        ),
        DeveloperLink(
          label: 'GitHub',
          icon: Icons.code_rounded,
          url: 'https://github.com/AbderrahmaneSAOUDI',
        ),
        DeveloperLink(
          label: 'Email',
          icon: Icons.email_rounded,
          url: 'mailto:saoudi.dev@gmail.com',
        ),
      ],
    ),
    DeveloperProfile(
      name: 'Anas Oussama DJRIBIE',
      role: 'Data Collector & QA Tester',
      bio:
          'Curated anime character datasets, managed image processing and naming conventions across all 18 categories, and performed gameplay balancing and testing.',
      accentColor: Color(0xFF00E676),
      fallbackIcon: Icons.person_pin_rounded,
      links: [
        DeveloperLink(
          label: 'Email',
          icon: Icons.email_rounded,
          url: 'mailto:anas.djribie@gmail.com',
        ),
        DeveloperLink(
          label: 'GitHub',
          icon: Icons.code_rounded,
          url: 'https://github.com/',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: developers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final dev = developers[index];
          // Use theme primary/secondary to match color scheme dynamically if desired
          final effectiveDev = DeveloperProfile(
            name: dev.name,
            role: dev.role,
            bio: dev.bio,
            accentColor: index == 0
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            imageAsset: dev.imageAsset,
            fallbackIcon: dev.fallbackIcon,
            links: dev.links,
          );

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 20.0,
              child: FadeInAnimation(
                child: DeveloperCard(profile: effectiveDev),
              ),
            ),
          );
        },
      ),
    );
  }
}
