import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

class _FakeLocalStoreService implements ILocalStoreService {
  final Map<String, String> _storage = <String, String>{};

  bool containsKey(String key) => _storage.containsKey(key);

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<bool> getBool({required String key}) async {
    return bool.tryParse(_storage[key] ?? '') ?? false;
  }

  @override
  Future<double> getDouble({required String key}) async {
    return double.tryParse(_storage[key] ?? '') ?? 0.0;
  }

  @override
  Future<int> getInt({required String key}) async {
    return int.tryParse(_storage[key] ?? '') ?? 0;
  }

  @override
  Future<List<T>> getList<T>({required String key}) async {
    final raw = _storage[key];
    if (raw == null || raw.isEmpty) return <T>[];
    return raw.split(',').map((e) => e as T).toList();
  }

  @override
  Future<Map<String, dynamic>> getMap({required String key}) async {
    final raw = _storage[key];
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<String> getString({required String key}) async {
    return _storage[key] ?? '';
  }

  @override
  Future<void> remove({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> setBool({required String key, required bool value}) async {
    _storage[key] = value.toString();
  }

  @override
  Future<void> setDouble({required String key, required double value}) async {
    _storage[key] = value.toString();
  }

  @override
  Future<void> setInt({required String key, required int value}) async {
    _storage[key] = value.toString();
  }

  @override
  Future<void> setList<T>({required String key, required List<T> value}) async {
    _storage[key] = value.join(',');
  }

  @override
  Future<void> setMap({required String key, required Map<String, dynamic> value}) async {
    _storage[key] = jsonEncode(value);
  }

  @override
  Future<void> setString({required String key, required String value}) async {
    _storage[key] = value;
  }
}

void main() {
  group('LearningStreakLocalDataSource', () {
    late _FakeLocalStoreService store;
    late LearningStreakLocalDataSourceImpl dataSource;

    setUp(() {
      store = _FakeLocalStoreService();
      dataSource = LearningStreakLocalDataSourceImpl(store);
    });

    test('stores and reads per-user cache keys without leaking between users', () async {
      await dataSource.cacheUserLearningStreak(
        'user-a',
        const UserLearningStreakModel(currentStreak: 1),
      );
      await dataSource.cacheUserLearningStreak(
        'user-b',
        const UserLearningStreakModel(currentStreak: 7),
      );

      final userA = await dataSource.getCachedUserLearningStreak('user-a');
      final userB = await dataSource.getCachedUserLearningStreak('user-b');

      expect(userA?.currentStreak, 1);
      expect(userB?.currentStreak, 7);
    });

    test('does not migrate legacy cache and purges unsafe legacy key', () async {
      await store.setMap(
        key: 'learning_streak_cache',
        value: const UserLearningStreakModel(currentStreak: 3).toJson(),
      );

      final cached = await dataSource.getCachedUserLearningStreak('user-a');

      expect(cached, isNull);
      expect(store.containsKey('learning_streak_cache'), isFalse);
      expect(store.containsKey('learning_streak_cache_user-a'), isFalse);
    });

    test('clearCache(userId) only clears target user key', () async {
      await dataSource.cacheUserLearningStreak('user-a', const UserLearningStreakModel(currentStreak: 2));
      await dataSource.cacheUserLearningStreak('user-b', const UserLearningStreakModel(currentStreak: 5));

      await dataSource.clearCache(userId: 'user-a');

      final userA = await dataSource.getCachedUserLearningStreak('user-a');
      final userB = await dataSource.getCachedUserLearningStreak('user-b');

      expect(userA, isNull);
      expect(userB?.currentStreak, 5);
    });

    test('skips cache read and write when user id is empty', () async {
      await dataSource.cacheUserLearningStreak('', const UserLearningStreakModel(currentStreak: 9));
      final cached = await dataSource.getCachedUserLearningStreak('');

      expect(cached, isNull);
      expect(store.containsKey('learning_streak_cache_'), isFalse);
    });

    test('clearCache with empty user id does not wipe all user caches', () async {
      await dataSource.cacheUserLearningStreak('user-a', const UserLearningStreakModel(currentStreak: 2));
      await dataSource.cacheUserLearningStreak('user-b', const UserLearningStreakModel(currentStreak: 5));

      await dataSource.clearCache(userId: '');

      final userA = await dataSource.getCachedUserLearningStreak('user-a');
      final userB = await dataSource.getCachedUserLearningStreak('user-b');
      expect(userA?.currentStreak, 2);
      expect(userB?.currentStreak, 5);
    });
  });
}
