part of '../services.dart';

abstract interface class ILocalStoreService {
  Future<void> setString({required String key, required String value});
  Future<String> getString({required String key});
  Future<void> remove({required String key});
  Future<void> clear();
  Future<void> setBool({required String key, required bool value});
  Future<bool> getBool({required String key});
  Future<void> setInt({required String key, required int value});
  Future<int> getInt({required String key});
  Future<void> setDouble({required String key, required double value});
  Future<double> getDouble({required String key});
  Future<void> setList<T>({required String key, required List<T> value});
  Future<List<T>> getList<T>({required String key});
  Future<void> setMap({required String key, required Map<String, dynamic> value});
  Future<Map<String, dynamic>> getMap({required String key});
}

@LazySingleton(as: ILocalStoreService)
class LocalStoreService implements ILocalStoreService {
  FlutterSecureStorage? _storage;
  LocalStoreService() {
    initialize();
  }

  void initialize() async {
    AndroidOptions androidOptions = AndroidOptions(
      resetOnError: true,
    );
    IOSOptions iosOptions = const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    );
    _storage = FlutterSecureStorage(aOptions: androidOptions, iOptions: iosOptions);
  }

  @override
  Future<void> setString({required String key, required String value}) async {
    await _storage?.write(key: key, value: value);
  }

  @override
  Future<String> getString({required String key}) async {
    return await _storage?.read(key: key) ?? '';
  }

  @override
  Future<void> remove({required String key}) async {
    await _storage?.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _storage?.deleteAll();
  }

  @override
  Future<void> setBool({required String key, required bool value}) async {
    await _storage?.write(key: key, value: value.toString());
  }

  @override
  Future<bool> getBool({required String key}) async {
    String? value = await _storage?.read(key: key);
    return bool.tryParse(value ?? 'false') ?? false;
  }

  @override
  Future<void> setInt({required String key, required int value}) async {
    await _storage?.write(key: key, value: value.toString());
  }

  @override
  Future<int> getInt({required String key}) async {
    String? value = await _storage?.read(key: key);
    return int.tryParse(value ?? '0') ?? 0;
  }

  @override
  Future<void> setDouble({required String key, required double value}) async {
    await _storage?.write(key: key, value: value.toString());
  }

  @override
  Future<double> getDouble({required String key}) async {
    String? value = await _storage?.read(key: key);
    return double.tryParse(value ?? '0.0') ?? 0.0;
  }

  @override
  Future<void> setList<T>({required String key, required List<T> value}) async {
    await _storage?.write(key: key, value: value.join(','));
  }

  @override
  Future<List<T>> getList<T>({required String key}) async {
    String? value = await _storage?.read(key: key);
    return value?.split(',').map((e) => e as T).toList() ?? [];
  }

  @override
  Future<void> setMap({required String key, required Map<String, dynamic> value}) async {
    await _storage?.write(key: key, value: jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>> getMap({required String key}) async {
    String? value = await _storage?.read(key: key);
    return jsonDecode(value ?? '{}');
  }
}
