import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('PackageInfoService version comparison', () {
    Future<PackageInfoService> buildService({required String version, String buildNumber = '1'}) async {
      PackageInfo.setMockInitialValues(
        appName: 'HDDhistory',
        packageName: 'com.hddhistory.app',
        version: version,
        buildNumber: buildNumber,
        buildSignature: '',
      );

      final service = PackageInfoService();
      await service.initialize();
      return service;
    }

    test('Given current version is lower, When comparing with target version, Then returns true', () async {
      final service = await buildService(version: '1.1.6');

      final result = service.isVersionLowerThan('1.1.7');

      expect(result, isTrue);
    });

    test('Given current version equals target, When comparing, Then returns false', () async {
      final service = await buildService(version: '1.1.6');

      final result = service.isVersionLowerThan('1.1.6');

      expect(result, isFalse);
    });

    test('Given current version is higher, When comparing with target version, Then returns false', () async {
      final service = await buildService(version: '1.2.0');

      final result = service.isVersionLowerThan('1.1.9');

      expect(result, isFalse);
    });

    test('Given target omits patch version, When comparing, Then missing parts are treated as zero', () async {
      final service = await buildService(version: '1.1.6');

      final result = service.isVersionLowerThan('1.2');

      expect(result, isTrue);
    });

    test('Given invalid target version, When comparing, Then returns false', () async {
      final service = await buildService(version: '1.1.6');

      final result = service.isVersionLowerThan('latest');

      expect(result, isFalse);
    });

    test('Given build suffix differs only, When comparing, Then semantic version equality is not forced lower', () async {
      final service = await buildService(version: '1.1.6+6', buildNumber: '6');

      final result = service.isVersionLowerThan('1.1.6+26');

      expect(result, isFalse);
    });
  });
}
