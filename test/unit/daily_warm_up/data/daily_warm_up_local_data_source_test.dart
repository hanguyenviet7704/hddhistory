import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

class _MemoryLocalStoreService implements ILocalStoreService {
  final Map<String, Object> values = {};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<bool> getBool({required String key}) async => values[key] as bool? ?? false;

  @override
  Future<double> getDouble({required String key}) async => values[key] as double? ?? 0;

  @override
  Future<int> getInt({required String key}) async => values[key] as int? ?? 0;

  @override
  Future<List<T>> getList<T>({required String key}) async => (values[key] as List<T>?) ?? [];

  @override
  Future<Map<String, dynamic>> getMap({required String key}) async => (values[key] as Map<String, dynamic>?) ?? {};

  @override
  Future<String> getString({required String key}) async => values[key] as String? ?? '';

  @override
  Future<void> remove({required String key}) async => values.remove(key);

  @override
  Future<void> setBool({required String key, required bool value}) async => values[key] = value;

  @override
  Future<void> setDouble({required String key, required double value}) async => values[key] = value;

  @override
  Future<void> setInt({required String key, required int value}) async => values[key] = value;

  @override
  Future<void> setList<T>({required String key, required List<T> value}) async => values[key] = value;

  @override
  Future<void> setMap({required String key, required Map<String, dynamic> value}) async => values[key] = value;

  @override
  Future<void> setString({required String key, required String value}) async => values[key] = value;
}

void main() {
  group('DailyWarmUpLocalDataSource', () {
    test('Given two users, When shown dates are marked, Then dates are scoped by user', () async {
      final dataSource = DailyWarmUpLocalDataSourceImpl(_MemoryLocalStoreService());

      await dataSource.markShownDate('user-a', '2026-05-22');
      await dataSource.markShownDate('user-b', '2026-05-23');

      expect(await dataSource.getShownDate('user-a'), '2026-05-22');
      expect(await dataSource.getShownDate('user-b'), '2026-05-23');
    });

    test('Given two users, When onboarding completed date is marked, Then date is scoped by user and not overwritten', () async {
      final dataSource = DailyWarmUpLocalDataSourceImpl(_MemoryLocalStoreService());

      await dataSource.markOnboardingCompletedDateIfAbsent('user-a', '2026-05-22');
      await dataSource.markOnboardingCompletedDateIfAbsent('user-a', '2026-05-23');

      expect(await dataSource.getOnboardingCompletedDate('user-a'), '2026-05-22');
      expect(await dataSource.getOnboardingCompletedDate('user-b'), isEmpty);
    });
  });
}
