import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper utility for opening external URLs securely
class UrlHelper {
  UrlHelper._();

  static Future<bool> launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error launching URL $url: $e');
      return false;
    }
  }
}
