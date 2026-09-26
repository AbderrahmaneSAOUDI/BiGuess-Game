import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_constants.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isNotEmpty) {
      return info.version;
    }
  } catch (_) {
    // Fall back to constants
  }
  return AppConstants.defaultVersion;
});
