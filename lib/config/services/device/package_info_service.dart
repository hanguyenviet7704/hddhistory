part of '../services.dart';

@lazySingleton
class PackageInfoService {
  PackageInfo? _packageInfo;
  PackageInfoService();

  /// Initialize the package info service
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      LogDev.info('PackageInfoService initialized: ${packageInfo.appName} v${packageInfo.version}');
    } catch (e) {
      LogDev.error('Error initializing PackageInfoService: $e');
      // Initialize with default values to prevent null errors
      _packageInfo = PackageInfo(
        appName: 'Unknown',
        packageName: 'Unknown',
        version: '0.0.0',
        buildNumber: '0',
      );
    }
  }

  /// Get package info data
  PackageInfo get packageInfo => _packageInfo ?? PackageInfo(
        appName: 'Unknown',
        packageName: 'Unknown',
        version: '0.0.0',
        buildNumber: '0',
      );

  /// App name (display name)
  String get appName => packageInfo.appName;

  /// Package name (bundle identifier)
  String get packageName => _packageInfo?.packageName ?? 'Unknown';

  /// App version
  String get version => _packageInfo?.version ?? '0.0.0';

  /// Build number
  String get buildNumber => _packageInfo?.buildNumber ?? '0';

  /// Get full version string (version+buildNumber)
  String get fullVersion => '$version+$buildNumber';

  /// Check if app version is lower than specified version
  bool isVersionLowerThan(String targetVersion) {
    final List<int> current = version.split('.').map(int.parse).toList();
    final List<int> target = targetVersion.split('.').map(int.parse).toList();

    // Compare major, minor, patch versions
    for (int i = 0; i < 3; i++) {
      final int currentValue = i < current.length ? current[i] : 0;
      final int targetValue = i < target.length ? target[i] : 0;

      if (currentValue < targetValue) return true;
      if (currentValue > targetValue) return false;
    }

    return false; // Equal versions
  }

  /// Get app info as a map
  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'version': version,
      'buildNumber': buildNumber,
    };
  }
}
