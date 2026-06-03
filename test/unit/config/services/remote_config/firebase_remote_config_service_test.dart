// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_remote_config_platform_interface/firebase_remote_config_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  final remoteConfigPlatform = _FakeFirebaseRemoteConfigPlatform();

  setUpAll(() async {
    FirebaseRemoteConfigPlatform.instance = remoteConfigPlatform;
    await Firebase.initializeApp();
  });

  setUp(() {
    remoteConfigPlatform.reset();
  });

  group('FirebaseRemoteConfigService startup fetch', () {
    test('configures Firebase fetch timeout as the only startup fetch timeout', () async {
      final service = FirebaseRemoteConfigService(_FakePackageInfoService());

      await service.initialize();

      expect(remoteConfigPlatform.settings.fetchTimeout, const Duration(seconds: 10));
      expect(remoteConfigPlatform.settings.minimumFetchInterval, Duration.zero);
    });

    test('waits for fetchAndActivate instead of timing out through an app-side startup timer', () async {
      final service = FirebaseRemoteConfigService(_FakePackageInfoService());
      var completed = false;

      final shouldForceUpdate = service.shouldForceUpdate().whenComplete(() {
        completed = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 3300));

      expect(completed, isFalse);
      remoteConfigPlatform.completeFetchAndActivate(false);
      await shouldForceUpdate;
      expect(completed, isTrue);
    });
  });
}

class _FakeFirebaseRemoteConfigPlatform extends FirebaseRemoteConfigPlatform with MockPlatformInterfaceMixin {
  _FakeFirebaseRemoteConfigPlatform() : super();

  Completer<bool> _fetchAndActivateCompleter = Completer<bool>();
  final Map<String, String> _strings = {
    RemoteConfigKey.appVersionConfig: jsonEncode({
      'forceUserUpdate': true,
      'latestAndroidVersion': '99.0.0',
      'latestIosVersion': '99.0.0',
    }),
  };

  RemoteConfigSettings _settings = RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 60),
    minimumFetchInterval: const Duration(hours: 12),
  );

  void reset() {
    _fetchAndActivateCompleter = Completer<bool>();
    _settings = RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 60),
      minimumFetchInterval: const Duration(hours: 12),
    );
  }

  void completeFetchAndActivate(bool value) {
    if (!_fetchAndActivateCompleter.isCompleted) {
      _fetchAndActivateCompleter.complete(value);
    }
  }

  @override
  FirebaseRemoteConfigPlatform delegateFor({FirebaseApp? app}) => this;

  @override
  FirebaseRemoteConfigPlatform setInitialValues({Map<dynamic, dynamic>? remoteConfigValues}) => this;

  @override
  Future<bool> fetchAndActivate() => _fetchAndActivateCompleter.future;

  @override
  String getString(String key) => _strings[key] ?? '';

  @override
  Future<void> setConfigSettings(RemoteConfigSettings remoteConfigSettings) async {
    _settings = remoteConfigSettings;
  }

  @override
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) async {}

  @override
  RemoteConfigSettings get settings => _settings;

  @override
  RemoteConfigFetchStatus get lastFetchStatus => RemoteConfigFetchStatus.success;

  @override
  DateTime get lastFetchTime => DateTime(2026);
}

class _FakePackageInfoService implements IPackageInfoService {
  @override
  String get appName => 'Meup';

  @override
  String get buildNumber => '1';

  @override
  String get fullVersion => '$version+$buildNumber';

  @override
  Future<void> initialize() async {}

  @override
  bool isVersionLowerThan(String targetVersion) => true;

  @override
  PackageInfo get packageInfo => PackageInfo(
    appName: appName,
    packageName: packageName,
    version: version,
    buildNumber: buildNumber,
  );

  @override
  String get packageName => 'com.eup.meup';

  @override
  Map<String, dynamic> toMap() => {
    'appName': appName,
    'packageName': packageName,
    'version': version,
    'buildNumber': buildNumber,
  };

  @override
  String get version => '1.0.0';
}
