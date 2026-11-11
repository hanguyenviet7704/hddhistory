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
  Future<Map<String, dynamic>> getMap({required String key}) async => (_storage[key] as Map<String, dynamic>?) ?? <String, dynamic>{};

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
  group('VideoLessonLocalDataSource', () {
    late VideoLessonLocalDataSource localDataSource;

    const firstFilter = VideoLessonNoteFilterEntity(
      courseId: 'course-1',
      nodeId: 'node-1',
      lessonId: 'lesson-1',
    );
    const secondFilter = VideoLessonNoteFilterEntity(
      courseId: 'course-1',
      nodeId: 'node-2',
      lessonId: 'lesson-1',
    );

    setUp(() {
      localDataSource = VideoLessonLocalDataSourceImpl(_FakeLocalStoreService());
    });

    test('stores note lists separately per course, node, and lesson scope', () async {
      const firstScopeNotes = [
        UserVideoLessonNoteModel(
          id: 'note-1',
          courseId: 'course-1',
          nodeId: 'node-1',
          lessonId: 'lesson-1',
          content: 'first scope',
        ),
      ];
      const secondScopeNotes = [
        UserVideoLessonNoteModel(
          id: 'note-2',
          courseId: 'course-1',
          nodeId: 'node-2',
          lessonId: 'lesson-1',
          content: 'second scope',
        ),
      ];

      await localDataSource.cacheUserVideoLessonNotes(firstFilter, firstScopeNotes);
      await localDataSource.cacheUserVideoLessonNotes(secondFilter, secondScopeNotes);

      expect((await localDataSource.getCachedUserVideoLessonNotes(firstFilter)).single.content, 'first scope');
      expect((await localDataSource.getCachedUserVideoLessonNotes(secondFilter)).single.content, 'second scope');
    });

    test('deletes only the targeted note inside the same scope', () async {
      const targetNote = UserVideoLessonNoteModel(
        id: 'note-1',
        courseId: 'course-1',
        nodeId: 'node-1',
        lessonId: 'lesson-1',
        content: 'delete me',
      );
      const siblingNote = UserVideoLessonNoteModel(
        id: 'note-2',
        courseId: 'course-1',
        nodeId: 'node-1',
        lessonId: 'lesson-1',
        content: 'keep me',
      );
      const otherScopeNote = UserVideoLessonNoteModel(
        id: 'note-3',
        courseId: 'course-1',
        nodeId: 'node-2',
        lessonId: 'lesson-1',
        content: 'other scope',
      );

      await localDataSource.cacheUserVideoLessonNotes(firstFilter, [targetNote, siblingNote]);
      await localDataSource.cacheUserVideoLessonNote(targetNote);
      await localDataSource.cacheUserVideoLessonNote(siblingNote);
      await localDataSource.cacheUserVideoLessonNotes(secondFilter, [otherScopeNote]);
      await localDataSource.cacheUserVideoLessonNote(otherScopeNote);

      await localDataSource.deleteCachedUserVideoLessonNote(targetNote);

      expect(await localDataSource.getCachedUserVideoLessonNote(firstFilter, 'note-1'), isNull);
      expect(await localDataSource.getCachedUserVideoLessonNote(firstFilter, 'note-2'), isNotNull);
      expect(await localDataSource.getCachedUserVideoLessonNote(secondFilter, 'note-3'), isNotNull);
      expect(
        (await localDataSource.getCachedUserVideoLessonNotes(firstFilter)).map((note) => note.id),
        ['note-2'],
      );
    });
  });
}
