// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_remote_config_platform_interface/firebase_remote_config_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';
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
      // Cached config is served instantly and only refetched after this window,
      // instead of a live fetch on every launch. Note the trade-off: a Remote
      // Config change can take up to this long to reach an already-installed app.
      expect(remoteConfigPlatform.settings.minimumFetchInterval, const Duration(minutes: 30));
    });

    test('waits for fetchAndActivate instead of timing out through an app-side startup timer', () async {
      final service = FirebaseRemoteConfigService(_FakePackageInfoService());
      var completed = false;

      final updateAvailable = service.optionalUpdateAvailable().whenComplete(() {
        completed = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 3300));

      expect(completed, isFalse);
      remoteConfigPlatform.completeFetchAndActivate(false);
      await updateAvailable;
      expect(completed, isTrue);
    });
  });

  group('shouldShowUpdateBanner', () {
    bool older(String _) => true;
    bool upToDate(String _) => false;

    test('shows the banner when the installed version is older than the platform latest', () {
      const config = AppVersionConfigEntity(latestIosVersion: '2.0.0', latestAndroidVersion: '2.0.0');

      expect(shouldShowUpdateBanner(config, isIOS: true, isInstalledOlderThan: older), isTrue);
    });

    test('hides the banner when forceUserUpdate is set', () {
      // The forced case belongs to the blocking splash dialog; showing both
      // would stack two update surfaces on the same launch.
      const config = AppVersionConfigEntity(
        forceUserUpdate: true,
        latestIosVersion: '2.0.0',
        latestAndroidVersion: '2.0.0',
      );

      expect(shouldShowUpdateBanner(config, isIOS: true, isInstalledOlderThan: older), isFalse);
    });

    test('reads the version for the running platform', () {
      const config = AppVersionConfigEntity(latestIosVersion: '2.0.0', latestAndroidVersion: '');

      // Android has no latest version configured → nothing to offer there.
      expect(shouldShowUpdateBanner(config, isIOS: false, isInstalledOlderThan: older), isFalse);
      expect(shouldShowUpdateBanner(config, isIOS: true, isInstalledOlderThan: older), isTrue);
    });

    test('hides the banner when the installed version is already up to date', () {
      const config = AppVersionConfigEntity(latestIosVersion: '2.0.0', latestAndroidVersion: '2.0.0');

      expect(shouldShowUpdateBanner(config, isIOS: true, isInstalledOlderThan: upToDate), isFalse);
    });

    test('never compares versions when the platform latest is blank', () {
      const config = AppVersionConfigEntity(latestIosVersion: '   ', latestAndroidVersion: '   ');
      var compared = false;

      final result = shouldShowUpdateBanner(
        config,
        isIOS: true,
        isInstalledOlderThan: (_) {
          compared = true;
          return true;
        },
      );

      expect(result, isFalse);
      expect(compared, isFalse);
    });
  });

  group('shouldBlockForForcedUpdate', () {
    bool older(String _) => true;
    bool upToDate(String _) => false;

    test('blocks when forceUserUpdate is set and the build is older than the platform latest', () {
      const config = AppVersionConfigEntity(
        forceUserUpdate: true,
        latestIosVersion: '2.0.0',
        latestAndroidVersion: '2.0.0',
      );

      expect(shouldBlockForForcedUpdate(config, isIOS: true, isInstalledOlderThan: older), isTrue);
    });

    test('never blocks while forceUserUpdate is off, however old the build is', () {
      // This is the kill switch: clearing the flag in Remote Config must free
      // every user on the next fetch without touching the version fields.
      const config = AppVersionConfigEntity(
        latestIosVersion: '2.0.0',
        latestAndroidVersion: '2.0.0',
      );

      expect(shouldBlockForForcedUpdate(config, isIOS: true, isInstalledOlderThan: older), isFalse);
    });

    test('does not block a build that already meets the latest version', () {
      const config = AppVersionConfigEntity(
        forceUserUpdate: true,
        latestIosVersion: '2.0.0',
        latestAndroidVersion: '2.0.0',
      );

      expect(shouldBlockForForcedUpdate(config, isIOS: true, isInstalledOlderThan: upToDate), isFalse);
    });

    test('reads the version for the running platform', () {
      const config = AppVersionConfigEntity(
        forceUserUpdate: true,
        latestIosVersion: '2.0.0',
        latestAndroidVersion: '',
      );

      expect(shouldBlockForForcedUpdate(config, isIOS: false, isInstalledOlderThan: older), isFalse);
      expect(shouldBlockForForcedUpdate(config, isIOS: true, isInstalledOlderThan: older), isTrue);
    });

    test('never blocks on a blank platform version, even with the flag set', () {
      // A missing ceiling must never read as "everyone is out of date" — that
      // would lock the whole user base out of the app.
      const config = AppVersionConfigEntity(
        forceUserUpdate: true,
        latestIosVersion: '   ',
        latestAndroidVersion: '   ',
      );
      var compared = false;

      final result = shouldBlockForForcedUpdate(
        config,
        isIOS: true,
        isInstalledOlderThan: (_) {
          compared = true;
          return true;
        },
      );

      expect(result, isFalse);
      expect(compared, isFalse);
    });

    test('is mutually exclusive with the optional banner', () {
      const forced = AppVersionConfigEntity(
        forceUserUpdate: true,
        latestIosVersion: '2.0.0',
        latestAndroidVersion: '2.0.0',
      );
      const optional = AppVersionConfigEntity(
        latestIosVersion: '2.0.0',
        latestAndroidVersion: '2.0.0',
      );

      expect(shouldBlockForForcedUpdate(forced, isIOS: true, isInstalledOlderThan: older), isTrue);
      expect(shouldShowUpdateBanner(forced, isIOS: true, isInstalledOlderThan: older), isFalse);

      expect(shouldBlockForForcedUpdate(optional, isIOS: true, isInstalledOlderThan: older), isFalse);
      expect(shouldShowUpdateBanner(optional, isIOS: true, isInstalledOlderThan: older), isTrue);
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
  String get appName => 'HDDhistory';

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
  String get packageName => 'com.hddhistory.app';

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
