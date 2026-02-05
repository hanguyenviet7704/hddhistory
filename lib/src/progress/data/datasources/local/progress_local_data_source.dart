part of '../../../progress.dart';

/// Local data source for Progress
///
/// Handles caching of User Progress data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class ProgressLocalDataSource {
  Future<List<UserProgressModel>> getCachedUserProgresss();
  Future<void> cacheUserProgresss(List<UserProgressModel> models);

  Future<LessonResultModel?> getCachedLessonResult();
  Future<void> cacheLessonResult(LessonResultModel model);

  Future<KeypointResultModel?> getCachedKeypointResult();
  Future<void> cacheKeypointResult(KeypointResultModel model);

  Future<ExerciseResultModel?> getCachedExerciseResult();
  Future<void> cacheExerciseResult(ExerciseResultModel model);

  Future<UserProgressModel?> getCachedUserProgressLesson(String lessonId);
  Future<void> cacheUserProgressLesson(String lessonId, UserProgressModel model);

  Future<UserProgressModel?> getCachedUserProgressKeypoint();
  Future<void> cacheUserProgressKeypoint(UserProgressModel model);

  Future<UserProgressModel?> getCachedUserProgressExercise();
  Future<void> cacheUserProgressExercise(UserProgressModel model);

  Future<List<CourseModel>> getCachedUserProgressMyCourses();
  Future<void> cacheUserProgressMyCourses(List<CourseModel> models);

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
    } catch (e) {
      //
    }
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
    } catch (e) {
      //
    }
  }

  @override
  Future<UserProgressModel?> getCachedUserProgressKeypoint() async {
    try {
      final cacheKey = _cacheKeypointKey;
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return UserProgressModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserProgressKeypoint(UserProgressModel model) async {
    try {
      final cacheKey = _cacheKeypointKey;
      await _localStoreService.setMap(key: cacheKey, value: model.toJson());
    } catch (e) {
      //
    }
  }

  @override
  Future<UserProgressModel?> getCachedUserProgressExercise() async {
    try {
      final cacheKey = _cacheExerciseKey;
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return UserProgressModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserProgressExercise(UserProgressModel model) async {
    try {
      final cacheKey = _cacheExerciseKey;
      await _localStoreService.setMap(key: cacheKey, value: model.toJson());
    } catch (e) {
      //
    }
  }

  @override
  Future<List<CourseModel>> getCachedUserProgressMyCourses() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheMyCoursesKey);
      if (data.isEmpty) return [];
      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => CourseModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheUserProgressMyCourses(List<CourseModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(key: _cacheMyCoursesKey, value: {'items': jsonList});
    } catch (e) {
      //
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
      await _localStoreService.remove(key: _cacheMyCoursesKey);
    } catch (e) {
      //
    }
  }

  @override
  Future<LessonResultModel?> getCachedLessonResult() async {
    try {
      final data = await _localStoreService.getMap(key: 'progress_lesson_result_cache');
      if (data.isEmpty) return null;
      return LessonResultModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheLessonResult(LessonResultModel model) async {
    try {
      await _localStoreService.setMap(key: 'progress_lesson_result_cache', value: model.toJson());
    } catch (e) {
      //
    }
  }

  @override
  Future<KeypointResultModel?> getCachedKeypointResult() async {
    try {
      final data = await _localStoreService.getMap(key: 'progress_keypoint_result_cache');
      if (data.isEmpty) return null;
      return KeypointResultModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheKeypointResult(KeypointResultModel model) async {
    try {
      await _localStoreService.setMap(key: 'progress_keypoint_result_cache', value: model.toJson());
    } catch (e) {
      //
    }
  }

  @override
  Future<ExerciseResultModel?> getCachedExerciseResult() async {
    try {
      final data = await _localStoreService.getMap(key: 'progress_exercise_result_cache');
      if (data.isEmpty) return null;
      return ExerciseResultModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheExerciseResult(ExerciseResultModel model) async {
    try {
      await _localStoreService.setMap(key: 'progress_exercise_result_cache', value: model.toJson());
    } catch (e) {
      //
    }
  }
}
