import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/domain/models/remote_version.dart';
import 'package:gdg_guess_game/domain/models/sem_ver.dart';
import 'package:gdg_guess_game/domain/models/update_decision.dart';
import 'package:gdg_guess_game/services/version_service.dart';

void main() {
  group('SemVer parsing and comparisons', () {
    test('parses version with build number', () {
      final v = SemVer.parse('0.32.0+7');
      expect(v.major, 0);
      expect(v.minor, 32);
      expect(v.patch, 0);
      expect(v.buildNumber, 7);
    });

    test('parses version without build number', () {
      final v = SemVer.parse('1.2.3');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
      expect(v.buildNumber, 0);
    });

    test('correctly detects newer major or minor', () {
      final local = SemVer.parse('0.31.0+7');
      final remoteMinor = SemVer.parse('0.32.0+1');
      final remoteMajor = SemVer.parse('1.0.0+1');
      final remotePatch = SemVer.parse('0.31.1+8');

      expect(remoteMinor.isNewerMajorOrMinorThan(local), isTrue);
      expect(remoteMajor.isNewerMajorOrMinorThan(local), isTrue);
      expect(remotePatch.isNewerMajorOrMinorThan(local), isFalse);
    });

    test('correctly compares SemVer instances', () {
      final v1 = SemVer.parse('0.31.0+7');
      final v2 = SemVer.parse('0.32.0+1');
      final v3 = SemVer.parse('0.32.0+2');

      expect(v1 < v2, isTrue);
      expect(v2 < v3, isTrue);
      expect(v3 > v1, isTrue);
      expect(v2 == SemVer.parse('0.32.0+1'), isTrue);
    });
  });

  group('RemoteVersion and ABI resolution', () {
    test('resolves targeted ABI APK correctly', () {
      const remote = RemoteVersion(
        latestVersion: '0.32.0',
        buildNumber: 8,
        minRequiredVersion: '0.30.0',
        hasNativeChanges: true,
        apkUrl: 'https://example.com/fallback.apk',
        apkUrls: {
          'arm64-v8a': 'https://example.com/arm64.apk',
          'armeabi-v7a': 'https://example.com/armv7.apk',
          'x86_64': 'https://example.com/x86_64.apk',
        },
        releaseNotes: 'New features',
      );

      expect(
        remote.resolveApkUrl(['arm64-v8a', 'armeabi-v7a']),
        'https://example.com/arm64.apk',
      );
      expect(
        remote.resolveApkUrl(['x86_64']),
        'https://example.com/x86_64.apk',
      );
      expect(
        remote.resolveApkUrl(['mips']),
        'https://example.com/fallback.apk',
      );
    });
  });

  group('VersionService evaluateUpdate decisions', () {
    const versionService = VersionService();

    test('returns UpdateNone when local is up to date', () {
      final local = SemVer.parse('0.32.0+8');
      const remote = RemoteVersion(
        latestVersion: '0.32.0',
        buildNumber: 8,
        minRequiredVersion: '0.30.0',
        hasNativeChanges: false,
        apkUrl: '',
        releaseNotes: '',
      );

      final decision = versionService.evaluateUpdate(local, remote);
      expect(decision, isA<UpdateNone>());
    });

    test('returns UpdateFullApk on major or minor bump', () {
      final local = SemVer.parse('0.31.0+7');
      const remote = RemoteVersion(
        latestVersion: '0.32.0',
        buildNumber: 1,
        minRequiredVersion: '0.30.0',
        hasNativeChanges: false,
        apkUrl: 'https://example.com/arm64.apk',
        releaseNotes: 'Minor release',
      );

      final decision = versionService.evaluateUpdate(local, remote);
      expect(decision, isA<UpdateFullApk>());
      final fullApk = decision as UpdateFullApk;
      expect(fullApk.mandatory, isFalse);
    });

    test('returns UpdateFullApk with mandatory=true when below minRequiredVersion', () {
      final local = SemVer.parse('0.29.0+1');
      const remote = RemoteVersion(
        latestVersion: '0.32.0',
        buildNumber: 1,
        minRequiredVersion: '0.30.0',
        hasNativeChanges: false,
        apkUrl: 'https://example.com/arm64.apk',
        releaseNotes: 'Breaking update',
      );

      final decision = versionService.evaluateUpdate(local, remote);
      expect(decision, isA<UpdateFullApk>());
      final fullApk = decision as UpdateFullApk;
      expect(fullApk.mandatory, isTrue);
    });

    test('returns UpdateShorebirdPatch when pure patch bump without native changes', () {
      final local = SemVer.parse('0.31.0+7');
      const remote = RemoteVersion(
        latestVersion: '0.31.1',
        buildNumber: 8,
        minRequiredVersion: '0.30.0',
        hasNativeChanges: false,
        apkUrl: '',
        releaseNotes: 'Bug fixes',
      );

      final decision = versionService.evaluateUpdate(local, remote);
      expect(decision, isA<UpdateShorebirdPatch>());
    });
  });
}
