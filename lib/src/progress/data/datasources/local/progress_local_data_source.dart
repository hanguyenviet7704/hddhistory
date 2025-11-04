part of '../../../progress.dart';

/// Local data source for Progress
///
/// Handles caching of User Progress data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class ProgressLocalDataSource {
  Future<List<UserProgressModel>> getCachedUserProgresss();
  Future<void> cacheUserProgresss(List<UserProgressModel> models);
  
  Future<UserProgressModel?> getCachedUserProgressLesson(String lessonId);
  Future<void> cacheUserProgressLesson(String lessonId, UserProgressModel model);
  
  Future<UserProgressModel?> getCachedUserProgressKeypoint(String keypointId);
  Future<void> cacheUserProgressKeypoint(String keypointId, UserProgressModel model);
  
  Future<UserProgressModel?> getCachedUserProgressExercise(String exerciseId);
  Future<void> cacheUserProgressExercise(String exerciseId, UserProgressModel model);
  
  Future<List<UserProgressModel>> getCachedUserProgressMyCourses();
  Future<void> cacheUserProgressMyCourses(List<UserProgressModel> models);

  Future<void> clearCache();
}

@LazySingleton(as: ProgressLocalDataSource)
class ProgressLocalDataSourceImpl implements ProgressLocalDataSource {
  static const String _cacheListKey = 'progress_list_cache';
  static const String _cacheLessonKey = 'progress_lesson_cache';
  static const String _cacheKeypointKey = 'progress_keypoint_cache';
  static const String _cacheExerciseKey = 'progress_exercise_cache';
  static const String _cacheMyCoursesKey = 'progress_my_courses_cache';

  final ILocalStoreService _localStoreService;

  ProgressLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<UserProgressModel>> getCachedUserProgresss() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];
      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => UserProgressModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheUserProgresss(List<UserProgressModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(key: _cacheListKey, value: {'items': jsonList});
    } catch (e) {}
  }

  @override
  Future<UserProgressModel?> getCachedUserProgressLesson(String lessonId) async {
    try {
      final cacheKey = '${_cacheLessonKey}_$lessonId';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return UserProgressModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserProgressLesson(String lessonId, UserProgressModel model) async {
    try {
      final cacheKey = '${_cacheLessonKey}_$lessonId';
      await _localStoreService.setMap(key: cacheKey, value: model.toJson());
    } catch (e) {}
  }

  @override
  Future<UserProgressModel?> getCachedUserProgressKeypoint(String keypointId) async {
    try {
      final cacheKey = '${_cacheKeypointKey}_$keypointId';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return UserProgressModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserProgressKeypoint(String keypointId, UserProgressModel model) async {
    try {
      final cacheKey = '${_cacheKeypointKey}_$keypointId';
      await _localStoreService.setMap(key: cacheKey, value: model.toJson());
    } catch (e) {}
  }

  @override
  Future<UserProgressModel?> getCachedUserProgressExercise(String exerciseId) async {
    try {
      final cacheKey = '${_cacheExerciseKey}_$exerciseId';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return UserProgressModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserProgressExercise(String exerciseId, UserProgressModel model) async {
    try {
      final cacheKey = '${_cacheExerciseKey}_$exerciseId';
      await _localStoreService.setMap(key: cacheKey, value: model.toJson());
    } catch (e) {}
  }

  @override
  Future<List<UserProgressModel>> getCachedUserProgressMyCourses() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheMyCoursesKey);
      if (data.isEmpty) return [];
      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => UserProgressModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheUserProgressMyCourses(List<UserProgressModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(key: _cacheMyCoursesKey, value: {'items': jsonList});
    } catch (e) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
      await _localStoreService.remove(key: _cacheMyCoursesKey);
    } catch (e) {}
  }
}
