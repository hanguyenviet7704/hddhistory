import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

class _MemoryLocalStoreService implements ILocalStoreService {
  final Map<String, String> strings = {};
  bool throwOnGetString = false;

  @override
  Future<void> setString({required String key, required String value}) async {
    strings[key] = value;
  }

  @override
  Future<String> getString({required String key}) async {
    if (throwOnGetString) throw StateError('storage unavailable');
    return strings[key] ?? '';
  }

  @override
  Future<void> remove({required String key}) async {
    strings.remove(key);
  }

  @override
  Future<void> clear() async {
    strings.clear();
  }

  @override
  Future<void> setBool({required String key, required bool value}) async {}

  @override
  Future<bool> getBool({required String key}) async => false;

  @override
  Future<void> setInt({required String key, required int value}) async {}

  @override
  Future<int> getInt({required String key}) async => 0;

  @override
  Future<void> setDouble({required String key, required double value}) async {}

  @override
  Future<double> getDouble({required String key}) async => 0;

  @override
  Future<void> setList<T>({required String key, required List<T> value}) async {}

  @override
  Future<List<T>> getList<T>({required String key}) async => [];

  @override
  Future<void> setMap({required String key, required Map<String, dynamic> value}) async {}

  @override
  Future<Map<String, dynamic>> getMap({required String key}) async => {};
}

void main() {
  group('DeviceInfoService iOS device token', () {
    test('returns existing spoofed device id from local storage', () async {
      final localStore = _MemoryLocalStoreService();
      await localStore.setString(key: LocalStoreKey.deviceTokenUID, value: 'spoofed-ios-device');
      final service = DeviceInfoService(
        localStore,
        isIOSOverride: true,
        isAndroidOverride: false,
        enableStartupInitialization: false,
      );

      final deviceToken = await service.deviceToken;

      expect(deviceToken, 'spoofed-ios-device');
    });

    test('creates, persists, and reuses one generated iOS device id', () async {
      final localStore = _MemoryLocalStoreService();
      final service = DeviceInfoService(
        localStore,
        isIOSOverride: true,
        isAndroidOverride: false,
        enableStartupInitialization: false,
      );

      final firstToken = await service.deviceToken;
      final secondToken = await service.deviceToken;

      expect(firstToken, isNotEmpty);
      expect(secondToken, firstToken);
      expect(localStore.strings[LocalStoreKey.deviceTokenUID], firstToken);
    });

    test('coalesces concurrent first iOS device id reads', () async {
      final localStore = _MemoryLocalStoreService();
      final service = DeviceInfoService(
        localStore,
        isIOSOverride: true,
        isAndroidOverride: false,
        enableStartupInitialization: false,
      );

      final tokens = await Future.wait([service.deviceToken, service.deviceToken]);

      expect(tokens.first, isNotEmpty);
      expect(tokens.toSet(), hasLength(1));
      expect(localStore.strings[LocalStoreKey.deviceTokenUID], tokens.first);
    });

    test('keeps one in-memory fallback iOS device id when storage read fails', () async {
      final localStore = _MemoryLocalStoreService()..throwOnGetString = true;
      final service = DeviceInfoService(
        localStore,
        isIOSOverride: true,
        isAndroidOverride: false,
        enableStartupInitialization: false,
      );

      final firstToken = await service.deviceToken;
      final secondToken = await service.deviceToken;

      expect(firstToken, isNotEmpty);
      expect(secondToken, firstToken);
      expect(localStore.strings[LocalStoreKey.deviceTokenUID], isNull);
    });
  });
}
