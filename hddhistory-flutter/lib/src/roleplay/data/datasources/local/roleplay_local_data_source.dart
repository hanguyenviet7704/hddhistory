part of '../../../roleplay.dart';

/// Local data source for Roleplay
///
/// Handles caching of individual Learning Item data for offline support.
abstract class RoleplayLocalDataSource {
  /// Get cached learning_item by id
  Future<LearningItemModel?> getCachedLearningItem(String id);

  /// Cache single learning_item
  ///
  /// Used for caching individual items from GET responses.
  Future<void> cacheLearningItem(LearningItemModel model);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: RoleplayLocalDataSource)
class RoleplayLocalDataSourceImpl implements RoleplayLocalDataSource {
  static const String _cacheKey = 'roleplay_learning_item_cache';

  final ILocalStoreService _localStoreService;

  RoleplayLocalDataSourceImpl(this._localStoreService);

  @override
  Future<LearningItemModel?> getCachedLearningItem(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return LearningItemModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheLearningItem(LearningItemModel model) async {
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
  Future<void> clearCache() async {
    try {
      // Note: Individual item caches (_cacheKey_id) would need prefix-based deletion
      // For now, this is a placeholder that could be implemented if needed
    } catch (e) {
      // Handle error silently or log
    }
  }
}
