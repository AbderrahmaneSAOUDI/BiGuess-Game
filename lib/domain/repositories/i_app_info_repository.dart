/// Contract for fetching application metadata and version
abstract class IAppInfoRepository {
  Future<String> getAppVersion();
}
