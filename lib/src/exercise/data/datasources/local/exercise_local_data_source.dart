part of '../../../exercise.dart';

/// Local data source for Exercise
///
/// Handles caching of Exercise data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class ExerciseLocalDataSource {
  /// Get all cached exercises
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<ExerciseModel>> getCachedExercises();

  /// Cache multiple exercises
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheExercises(List<ExerciseModel> models);

  /// Get cached exercise by id
  Future<ExerciseModel?> getCachedExercise(String id);

  /// Cache single exercise
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheExercise(ExerciseModel model);

  /// Delete cached exercise
  Future<void> deleteCachedExercise(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: ExerciseLocalDataSource)
class ExerciseLocalDataSourceImpl implements ExerciseLocalDataSource {
  static const String _cacheKey = 'exercise_cache';
  static const String _cacheListKey = 'exercise_list_cache';

  final ILocalStoreService _localStoreService;

  ExerciseLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<ExerciseModel>> getCachedExercises() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => ExerciseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheExercises(List<ExerciseModel> models) async {
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
  Future<ExerciseModel?> getCachedExercise(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return ExerciseModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheExercise(ExerciseModel model) async {
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
  Future<void> deleteCachedExercise(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedExercises();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheExercises(updatedList);
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
