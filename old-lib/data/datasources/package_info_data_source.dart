import 'package:package_info_plus/package_info_plus.dart';

/// Data source interface for fetching device package info
abstract class IPackageInfoDataSource {
  Future<String> getAppVersion();
}

/// Concrete implementation wrapping PackageInfo platform plugin
class PackageInfoDataSource implements IPackageInfoDataSource {
  const PackageInfoDataSource();

  @override
  Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.28.0';
    }
  }
}
