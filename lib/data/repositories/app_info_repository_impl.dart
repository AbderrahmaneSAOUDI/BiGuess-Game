import '../../domain/repositories/i_app_info_repository.dart';
import '../datasources/package_info_data_source.dart';

/// Concrete repository providing application info & version
class AppInfoRepositoryImpl implements IAppInfoRepository {
  final IPackageInfoDataSource _dataSource;

  const AppInfoRepositoryImpl({
    IPackageInfoDataSource dataSource = const PackageInfoDataSource(),
  }) : _dataSource = dataSource;

  @override
  Future<String> getAppVersion() async {
    return _dataSource.getAppVersion();
  }
}
