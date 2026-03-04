part of '../../../learning_streak.dart';

/// Local data source for Learning Streak
///
/// Handles caching of User Learning Streak data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class LearningStreakLocalDataSource {
  /// Get all cached user_learning_streaks
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<UserLearningStreakModel>> getCachedUserLearningStreaks();

  /// Cache multiple user_learning_streaks
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheUserLearningStreaks(List<UserLearningStreakModel> models);

  /// Get cached user_learning_streak by id
  Future<UserLearningStreakModel?> getCachedUserLearningStreak(String id);

  /// Cache single user_learning_streak
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheUserLearningStreak(UserLearningStreakModel model);

  /// Delete cached user_learning_streak
  Future<void> deleteCachedUserLearningStreak(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: LearningStreakLocalDataSource)
class LearningStreakLocalDataSourceImpl implements LearningStreakLocalDataSource {
  static const String _cacheKey = 'learning_streak_cache';
  static const String _cacheListKey = 'learning_streak_list_cache';

  final ILocalStoreService _localStoreService;

  LearningStreakLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<UserLearningStreakModel>> getCachedUserLearningStreaks() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => UserLearningStreakModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheUserLearningStreaks(List<UserLearningStreakModel> models) async {
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
  Future<UserLearningStreakModel?> getCachedUserLearningStreak(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return UserLearningStreakModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserLearningStreak(UserLearningStreakModel model) async {
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
  Future<void> deleteCachedUserLearningStreak(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedUserLearningStreaks();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheUserLearningStreaks(updatedList);
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

