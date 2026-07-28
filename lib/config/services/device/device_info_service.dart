part of '../services.dart';

abstract interface class IDeviceInfoService {
  Future<String> get deviceToken;
  Future<String> get deviceName;
  Future<void> getAllDeviceInfo();
  Future<int?> getAndroidSdkVersion();
  Future<bool> isAndroid13OrHigher();
  Future<BaseDeviceInfo?> get deviceInfo;
}

@LazySingleton(as: IDeviceInfoService)
class DeviceInfoService implements IDeviceInfoService {
  /// The infamous duplicated ANDROID_ID shared by a batch of older devices —
  /// deriving an identity from it would collapse them all onto one guest.
  static const _knownBuggySsaid = '9774d56d682e549c';

  final ILocalStoreService _localStoreService;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final bool? _isAndroidOverride;
  final Future<String?> Function() _androidSsaidProvider;
  String? _cachedDeviceToken;
  Future<String>? _deviceTokenTask;

  DeviceInfoService(
    this._localStoreService, {
    @ignoreParam @visibleForTesting bool? isIOSOverride,
    @ignoreParam @visibleForTesting bool? isAndroidOverride,
    @ignoreParam @visibleForTesting bool enableStartupInitialization = true,
    @ignoreParam @visibleForTesting Future<String?> Function()? androidSsaidProvider,
  })  : _isAndroidOverride = isAndroidOverride,
        _androidSsaidProvider = androidSsaidProvider ?? (const AndroidId().getId) {
    if (enableStartupInitialization) {
      unawaited(initialize());
    }
  }

  DeviceInfoPlugin get deviceInfoPlugin => _deviceInfoPlugin;
  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  /// Initialize the device info service
  Future<void> initialize() async {
    LogDev.info('DeviceInfoService initialized');
    try {
      await getAllDeviceInfo();
    } catch (error) {
      LogDev.warning('Error initializing device info: $error');
    }
    // Warm the persisted device-token cache on BOTH platforms so the stable
    // per-install UUID is ready before the first auth/anonymous call.
    final deviceId = await _getOrCreateDeviceToken();
    LogDev.one('deviceId: $deviceId');
  }

  /// Returns the Android SDK version as an integer.
  /// For non-Android devices, it returns null.
  @override
  Future<int?> getAndroidSdkVersion() async {
    if (_isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return null;
  }

  /// Checks if the device is running Android 13 or higher
  @override
  Future<bool> isAndroid13OrHigher() async {
    final sdkVersion = await getAndroidSdkVersion();
    return sdkVersion != null && sdkVersion > 32;
  }

  @override
  Future<void> getAllDeviceInfo() async {
    final deviceInfo = await _deviceInfoPlugin.deviceInfo;
    LogDev.one('deviceInfo: ${deviceInfo.data}');
  }

  /// A STABLE, per-device-unique token used as the anonymous/guest identity
  /// key on the server, persisted in secure storage. When storage is empty:
  /// iOS mints a random UUID (the Keychain survives reinstalls, so this is
  /// effectively once per device); Android derives a v5 UUID from the SSAID
  /// (Settings.Secure.ANDROID_ID) because uninstall wipes secure storage there
  /// — the SSAID survives reinstalls, so the guest account does too. It is
  /// deliberately NOT Android's `Build.ID` (the firmware build string,
  /// identical across every device on the same OS build) nor a shared vendor
  /// id. Using `Build.ID` made every Android device collapse onto one
  /// pre-existing guest → new devices skipped onboarding and landed in
  /// someone else's guest account.
  @override
  Future<String> get deviceToken async {
    try {
      return await _getOrCreateDeviceToken();
    } catch (e) {
      LogDev.warning('Error getting device token: $e');
      // Store failure: fall back to an in-memory token, stable within this
      // process via the cache so auth still works for the session.
      final fallback = _cachedDeviceToken ?? const Uuid().v4();
      _cachedDeviceToken = fallback;
      return fallback;
    }
  }

  Future<String> _getOrCreateDeviceToken() {
    final cachedToken = _cachedDeviceToken;
    if (cachedToken != null && cachedToken.isNotEmpty) {
      return Future.value(cachedToken);
    }

    final activeTask = _deviceTokenTask;
    if (activeTask != null) return activeTask;

    late final Future<String> task;
    task = _loadOrCreateDeviceToken().whenComplete(() {
      if (identical(_deviceTokenTask, task)) {
        _deviceTokenTask = null;
      }
    });
    _deviceTokenTask = task;
    return task;
  }

  Future<String> _loadOrCreateDeviceToken() async {
    final storedDeviceId = await _localStoreService.getString(key: LocalStoreKey.deviceTokenUID);
    if (storedDeviceId.isNotEmpty) {
      _cachedDeviceToken = storedDeviceId;
      return storedDeviceId;
    }

    // Empty storage = first run OR Android reinstall (uninstall wipes
    // EncryptedSharedPreferences + Keystore, unlike the iOS Keychain which
    // survives). Derive the token from the SSAID there so a reinstall maps
    // back to the SAME guest account instead of minting a new one. v5 = a
    // deterministic namespaced hash: same SSAID → same token, and the raw
    // SSAID itself never leaves the device.
    final generatedDeviceId = (_isAndroid ? await _ssaidDerivedToken() : null) ?? const Uuid().v8();
    await _localStoreService.setString(key: LocalStoreKey.deviceTokenUID, value: generatedDeviceId);
    _cachedDeviceToken = generatedDeviceId;
    return generatedDeviceId;
  }

  Future<String?> _ssaidDerivedToken() async {
    try {
      // The guest bootstrap awaits this token, so a wedged platform channel must
      // degrade to a random id rather than stall that await indefinitely.
      final ssaid = await _androidSsaidProvider().timeout(const Duration(seconds: 3));
      if (ssaid == null || ssaid.trim().isEmpty || ssaid == _knownBuggySsaid) return null;
      return const Uuid().v5(Namespace.url.value, 'meup-android-device-$ssaid');
    } catch (e) {
      LogDev.warning('SSAID unavailable, falling back to random device token: $e');
      return null;
    }
  }

  @override
  Future<String> get deviceName async {
    final deviceInfo = await _deviceInfoPlugin.deviceInfo;
    return deviceInfo.data['model'] as String;
  }

  @override
  Future<BaseDeviceInfo?> get deviceInfo async {
    return await _deviceInfoPlugin.deviceInfo;
  }
}
