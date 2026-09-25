import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/app_info_repository_impl.dart';
import '../../domain/repositories/i_app_info_repository.dart';

final appInfoRepositoryProvider = Provider<IAppInfoRepository>((ref) {
  return const AppInfoRepositoryImpl();
});

final appVersionProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(appInfoRepositoryProvider);
  return repository.getAppVersion();
});
