part of '../../../course.dart';

/// Local data source for Course
///
/// Handles caching of Course data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class CourseLocalDataSource {
  /// Get all cached courses
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<CourseModel>> getCachedCourses();

  /// Cache multiple courses
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheCourses(List<CourseModel> models);

  /// Get cached course by id
  Future<CourseModel?> getCachedCourse(String id);

  /// Cache single course
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheCourse(CourseModel model);

  /// Delete cached course
  Future<void> deleteCachedCourse(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: CourseLocalDataSource)
class CourseLocalDataSourceImpl implements CourseLocalDataSource {
  static const String _cacheKey = 'course_cache';
  static const String _cacheListKey = 'course_list_cache';

  final ILocalStoreService _localStoreService;

  CourseLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<CourseModel>> getCachedCourses() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheCourses(List<CourseModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(
        key: _cacheListKey,
        value: {'items': jsonList},
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<CourseModel?> getCachedCourse(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return CourseModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheCourse(CourseModel model) async {
    try {
      final cacheKey = '${_cacheKey}_${model.id}';
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> deleteCachedCourse(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedCourses();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheCourses(updatedList);
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
      // Note: Individual item caches (_cacheKey_id) are kept for specific item lookups
      // To clear everything, you could track all keys or implement prefix-based deletion
    } catch (e) {
      // Handle error silently or log
    }
  }
}
