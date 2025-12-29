part of '../../../progress.dart';

abstract class AchievenmentProgressLocalDataSource {
  Future<List<AchievenmentResponseModel>> getCachedAchievenmentResponses();
  Future<void> cacheAchievenmentResponses(List<AchievenmentResponseModel> models);

  Future<List<CourseLevelProgressModel>> getCachedCourseLevelProgress(String courseId);
  Future<void> cacheCourseLevelProgress(String courseId, List<CourseLevelProgressModel> models);

  Future<void> clearCache();
}

@LazySingleton(as: AchievenmentProgressLocalDataSource)
class AchievenmentProgressLocalDataSourceImpl implements AchievenmentProgressLocalDataSource {
  static const String _cacheAchievenmentResponsesKey = 'achievenment_progress_responses_cache';
  static const String _cacheCourseLevelProgressKey = 'achievenment_progress_course_level_cache';

  final ILocalStoreService _localStoreService;

  AchievenmentProgressLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<AchievenmentResponseModel>> getCachedAchievenmentResponses() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheAchievenmentResponsesKey);
      if (data.isEmpty) return [];
      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => AchievenmentResponseModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheAchievenmentResponses(List<AchievenmentResponseModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(key: _cacheAchievenmentResponsesKey, value: {'items': jsonList});
    } catch (e) {
      //
    }
  }

  @override
  Future<List<CourseLevelProgressModel>> getCachedCourseLevelProgress(String courseId) async {
    try {
      final cacheKey = '${_cacheCourseLevelProgressKey}_$courseId';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return [];
      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => CourseLevelProgressModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheCourseLevelProgress(String courseId, List<CourseLevelProgressModel> models) async {
    try {
      final cacheKey = '${_cacheCourseLevelProgressKey}_$courseId';
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(key: cacheKey, value: {'items': jsonList});
    } catch (e) {
      //
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheAchievenmentResponsesKey);
    } catch (e) {
      //
    }
  }
}
