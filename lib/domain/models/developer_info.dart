import 'package:flutter/widgets.dart';

/// Interactive link for developer profiles
class DeveloperLink {
  final String label;
  final IconData icon;
  final String url;

  const DeveloperLink({
    required this.label,
    required this.icon,
    required this.url,
  });
}

/// Developer profile model
class DeveloperProfile {
  final String name;
  final String role;
  final String bio;
  final Color accentColor;
  final String? imageAsset;
  final IconData? fallbackIcon;
  final List<DeveloperLink> links;

  const DeveloperProfile({
    required this.name,
    required this.role,
    required this.bio,
    required this.accentColor,
    this.imageAsset,
    this.fallbackIcon,
    required this.links,
  });
}
