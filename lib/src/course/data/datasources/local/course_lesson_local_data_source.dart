part of '../../../course.dart';

abstract class CourseLessonLocalDataSource {
  Future<List<LessonModel>> getCachedLessons();
  Future<void> cacheLessons(List<LessonModel> models);
  Future<LessonModel?> getCachedLesson(String id);
  Future<void> cacheLesson(LessonModel model);
  Future<void> deleteCachedLesson(String id);
  Future<void> clearCache();
}

@LazySingleton(as: CourseLessonLocalDataSource)
class CourseLessonLocalDataSourceImpl implements CourseLessonLocalDataSource {
  static const String _cacheKey = 'course_lesson_cache';
  static const String _cacheListKey = 'course_lesson_list_cache';

  final ILocalStoreService _localStoreService;

  CourseLessonLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<LessonModel>> getCachedLessons() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => LessonModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheLessons(List<LessonModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(
        key: _cacheListKey,
        value: {'items': jsonList},
      );
    } catch (e) {}
  }

  @override
  Future<LessonModel?> getCachedLesson(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return LessonModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheLesson(LessonModel model) async {
    try {
      final cacheKey = '${_cacheKey}_${model.id}';
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {}
  }

  @override
  Future<void> deleteCachedLesson(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      final cachedList = await getCachedLessons();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheLessons(updatedList);
    } catch (e) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
    } catch (e) {}
  }
}
