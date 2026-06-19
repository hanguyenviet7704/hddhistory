import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('MonetizationLocalDataSource impression count', () {
    late _MemoryLocalStoreService store;
    late MonetizationLocalDataSource dataSource;

    setUp(() {
      store = _MemoryLocalStoreService();
      dataSource = MonetizationLocalDataSourceImpl(store);
    });

    test('defaults to zero and persists explicit values', () async {
      expect(await dataSource.getNewUserPaywallImpressionCount(), 0);

      await dataSource.setNewUserPaywallImpressionCount(3);

      expect(await dataSource.getNewUserPaywallImpressionCount(), 3);
    });

    test('malformed or negative stored values return zero', () async {
      await store.setString(key: 'monetization_new_user_paywall_impressions', value: 'bad');
      expect(await dataSource.getNewUserPaywallImpressionCount(), 0);

      await dataSource.setNewUserPaywallImpressionCount(-2);
      expect(await dataSource.getNewUserPaywallImpressionCount(), 0);
    });
  });
}

class _MemoryLocalStoreService implements ILocalStoreService {
  final Map<String, dynamic> storage = {};

  @override
  Future<void> clear() async => storage.clear();

  @override
  Future<bool> getBool({required String key}) async => storage[key] as bool? ?? false;

  @override
  Future<double> getDouble({required String key}) async => storage[key] as double? ?? 0;

  @override
  Future<int> getInt({required String key}) async => int.tryParse(storage[key]?.toString() ?? '0') ?? 0;

  @override
  Future<List<T>> getList<T>({required String key}) async => (storage[key] as List<T>?) ?? <T>[];

  @override
  Future<Map<String, dynamic>> getMap({required String key}) async => (storage[key] as Map<String, dynamic>?) ?? <String, dynamic>{};

  @override
  Future<String> getString({required String key}) async => storage[key]?.toString() ?? '';

  @override
  Future<void> remove({required String key}) async => storage.remove(key);

  @override
  Future<void> setBool({required String key, required bool value}) async => storage[key] = value;

  @override
  Future<void> setDouble({required String key, required double value}) async => storage[key] = value;

  @override
  Future<void> setInt({required String key, required int value}) async => storage[key] = value;

  @override
  Future<void> setList<T>({required String key, required List<T> value}) async => storage[key] = value;

  @override
  Future<void> setMap({required String key, required Map<String, dynamic> value}) async => storage[key] = value;

  @override
  Future<void> setString({required String key, required String value}) async => storage[key] = value;
}
