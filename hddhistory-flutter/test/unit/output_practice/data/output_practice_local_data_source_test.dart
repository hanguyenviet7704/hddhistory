import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

class _FakeLocalStoreService implements ILocalStoreService {
  final Map<String, dynamic> _storage = <String, dynamic>{};

  @override
  Future<void> clear() async => _storage.clear();

  @override
  Future<bool> getBool({required String key}) async => _storage[key] as bool? ?? false;

  @override
  Future<double> getDouble({required String key}) async => _storage[key] as double? ?? 0;

  @override
  Future<int> getInt({required String key}) async => _storage[key] as int? ?? 0;

  @override
  Future<List<T>> getList<T>({required String key}) async => (_storage[key] as List<T>?) ?? <T>[];

  @override
  Future<Map<String, dynamic>> getMap({required String key}) async =>
      (_storage[key] as Map<String, dynamic>?) ?? <String, dynamic>{};

  @override
  Future<String> getString({required String key}) async => _storage[key] as String? ?? '';

  @override
  Future<void> remove({required String key}) async => _storage.remove(key);

  @override
  Future<void> setBool({required String key, required bool value}) async => _storage[key] = value;

  @override
  Future<void> setDouble({required String key, required double value}) async => _storage[key] = value;

  @override
  Future<void> setInt({required String key, required int value}) async => _storage[key] = value;

  @override
  Future<void> setList<T>({required String key, required List<T> value}) async => _storage[key] = value;

  @override
  Future<void> setMap({required String key, required Map<String, dynamic> value}) async => _storage[key] = value;

  @override
  Future<void> setString({required String key, required String value}) async => _storage[key] = value;
}

void main() {
  group('OutputPracticeLocalDataSource', () {
    late OutputPracticeLocalDataSource localDataSource;

    setUp(() {
      localDataSource = OutputPracticeLocalDataSourceImpl(_FakeLocalStoreService());
    });

    test('stores messages separately per conversation id', () async {
      const firstMessage = OutputPracticeMessageModel(
        conversationId: 'conversation-1',
        seq: 1,
        content: 'first',
      );
      const secondMessage = OutputPracticeMessageModel(
        conversationId: 'conversation-2',
        seq: 1,
        content: 'second',
      );

      await localDataSource.cacheMessages('conversation-1', [firstMessage]);
      await localDataSource.cacheMessages('conversation-2', [secondMessage]);

      expect((await localDataSource.getCachedMessages('conversation-1')).single.content, 'first');
      expect((await localDataSource.getCachedMessages('conversation-2')).single.content, 'second');
    });

    test('stores conversations separately per section id', () async {
      const firstConversation = OutputPracticeConversationModel(
        id: 'conversation-1',
        sectionId: 'section-1',
      );
      const secondConversation = OutputPracticeConversationModel(
        id: 'conversation-2',
        sectionId: 'section-2',
      );

      await localDataSource.cacheConversation('section-1', firstConversation);
      await localDataSource.cacheConversation('section-2', secondConversation);

      expect((await localDataSource.getCachedConversation('section-1'))?.id, 'conversation-1');
      expect((await localDataSource.getCachedConversation('section-2'))?.id, 'conversation-2');
    });
  });
}
