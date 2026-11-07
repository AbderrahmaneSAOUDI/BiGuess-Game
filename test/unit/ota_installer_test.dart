import 'dart:io';

import 'package:biguess/domain/models/update_decision.dart';
import 'package:biguess/domain/models/update_state.dart';
import 'package:biguess/presentation/controllers/update_controller.dart';
import 'package:biguess/services/ota_installer_service.dart';
import 'package:biguess/services/shorebird_patch_service.dart';
import 'package:biguess/services/version_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('development updates stop before making network requests', () async {
    final controller = UpdateController(
      versionService: const VersionService(),
      otaInstaller: OtaInstallerService(),
      shorebirdPatch: ShorebirdPatchService(),
    );
    addTearDown(controller.dispose);
    await controller.checkForUpdates();
    expect(controller.state, isA<UpdateCompleted>());
    expect((controller.state as UpdateCompleted).message, contains('signing'));
    await controller.downloadAndInstallApk(
      const UpdateFullApk(
        mandatory: false,
        apkUrl: 'https://invalid.example/app.apk',
        releaseNotes: '',
        latestVersion: '2.0.0',
      ),
    );
    expect(controller.state, isA<UpdateError>());
    expect((controller.state as UpdateError).canRetry, isFalse);
  });

  group('APK storage', () {
    late Directory cache;
    late Directory external;
    late OtaInstallerService service;

    setUp(() async {
      cache = await Directory.systemTemp.createTemp('biguess-update-test');
      external = await cache.createTemp('external');
      service = OtaInstallerService(
        temporaryDirectory: () async => cache,
        externalCacheDirectories: () async => [external],
      );
    });
    tearDown(() async => cache.delete(recursive: true));

    test(
      'startup cleanup removes APKs and preserves other cached files',
      () async {
        for (final directory in [cache, external]) {
          await File('${directory.path}/update.apk').writeAsString('old APK');
          await File(
            '${directory.path}/update.apk.tmp',
          ).writeAsString('partial');
          await File('${directory.path}/image.webp').writeAsString('keep');
        }
        await service.cleanStaleApks();
        expect(await service.getDownloadedApk(), isNull);
        for (final directory in [cache, external]) {
          expect(
            File('${directory.path}/update.apk.tmp').existsSync(),
            isFalse,
          );
          expect(File('${directory.path}/image.webp').existsSync(), isTrue);
        }
      },
    );

    test(
      'completed APK remains available until the next startup cleanup',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        server.listen((request) {
          request.response.add([1, 2, 3]);
          request.response.close();
        });
        final file = await service.downloadApk(
          'http://127.0.0.1:${server.port}/app.apk',
        );
        expect(await file.readAsBytes(), [1, 2, 3]);
        expect((await service.getDownloadedApk())?.path, file.path);
        expect(File('${cache.path}/update.apk.tmp').existsSync(), isFalse);
      },
    );

    test('cancelled transfer removes partial APK', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            await File('${cache.path}/update.apk.tmp').writeAsString('partial');
            handler.reject(
              DioException.requestCancelled(
                requestOptions: options,
                reason: 'Cancelled transfer',
              ),
            );
          },
        ),
      );
      service = OtaInstallerService(
        dio: dio,
        temporaryDirectory: () async => cache,
        externalCacheDirectories: () async => [external],
      );
      await expectLater(
        service.downloadApk('https://invalid.example/app.apk'),
        throwsA(isA<DioException>()),
      );
      expect(File('${cache.path}/update.apk.tmp').existsSync(), isFalse);
      expect(await service.getDownloadedApk(), isNull);
    });
  });
}
