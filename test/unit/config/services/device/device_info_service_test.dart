import 'dart:async';

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

  group('DeviceInfoService Android device token (SSAID reinstall stability)', () {
    DeviceInfoService buildService(
      _MemoryLocalStoreService localStore, {
      Future<String?> Function()? ssaid,
    }) {
      return DeviceInfoService(
        localStore,
        isIOSOverride: false,
        isAndroidOverride: true,
        enableStartupInitialization: false,
        androidSsaidProvider: ssaid,
      );
    }

    test('derives the SAME device id from the same SSAID across fresh installs', () async {
      final firstInstall = buildService(_MemoryLocalStoreService(), ssaid: () async => 'a1b2c3d4e5f60718');
      final reinstall = buildService(_MemoryLocalStoreService(), ssaid: () async => 'a1b2c3d4e5f60718');

      final firstToken = await firstInstall.deviceToken;
      final reinstallToken = await reinstall.deviceToken;

      expect(firstToken, isNotEmpty);
      expect(reinstallToken, firstToken);
    });

    test('persists the SSAID-derived id so later reads reuse it', () async {
      final localStore = _MemoryLocalStoreService();
      final service = buildService(localStore, ssaid: () async => 'a1b2c3d4e5f60718');

      final token = await service.deviceToken;

      expect(localStore.strings[LocalStoreKey.deviceTokenUID], token);
    });

    test('prefers an already-stored device id over the SSAID', () async {
      final localStore = _MemoryLocalStoreService();
      await localStore.setString(key: LocalStoreKey.deviceTokenUID, value: 'pre-existing-guest');
      final service = buildService(localStore, ssaid: () async => 'a1b2c3d4e5f60718');

      final token = await service.deviceToken;

      expect(token, 'pre-existing-guest');
    });

    test('different SSAIDs derive different device ids', () async {
      final deviceA = buildService(_MemoryLocalStoreService(), ssaid: () async => 'a1b2c3d4e5f60718');
      final deviceB = buildService(_MemoryLocalStoreService(), ssaid: () async => 'ffffffff00000000');

      expect(await deviceA.deviceToken, isNot(await deviceB.deviceToken));
    });

    test('falls back to a random persisted id when SSAID is unavailable', () async {
      final localStore = _MemoryLocalStoreService();
      final service = buildService(localStore, ssaid: () async => null);

      final token = await service.deviceToken;

      expect(token, isNotEmpty);
      expect(localStore.strings[LocalStoreKey.deviceTokenUID], token);
    });

    test('treats the known-buggy shared SSAID as unavailable', () async {
      // 9774d56d682e549c is the infamous duplicated ANDROID_ID on some devices —
      // deriving from it would collapse those devices onto one guest account.
      final deviceA = buildService(_MemoryLocalStoreService(), ssaid: () async => '9774d56d682e549c');
      final deviceB = buildService(_MemoryLocalStoreService(), ssaid: () async => '9774d56d682e549c');

      expect(await deviceA.deviceToken, isNot(await deviceB.deviceToken));
    });

    test('falls back to a random id when the SSAID provider throws', () async {
      final service = buildService(_MemoryLocalStoreService(), ssaid: () async => throw StateError('no platform'));

      expect(await service.deviceToken, isNotEmpty);
    });

    test('falls back instead of hanging when the SSAID provider never completes', () async {
      // A never-resolving platform call must not stall the caller: the guest
      // bootstrap awaits this token, and a stuck await there is what froze the
      // welcome screen.
      final service = buildService(_MemoryLocalStoreService(), ssaid: () => Completer<String?>().future);

      final token = await service.deviceToken.timeout(const Duration(seconds: 10));

      expect(token, isNotEmpty);
    });
  });
}
