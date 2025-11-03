part of '../../../roadmap.dart';

/// Local data source for Roadmap
///
/// Handles caching of Roadmap data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class RoadmapLocalDataSource {
  /// Get all cached roadmaps
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<RoadmapModel>> getCachedRoadmaps();

  /// Cache multiple roadmaps
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheRoadmaps(List<RoadmapModel> models);

  /// Get cached roadmap by id
  Future<RoadmapModel?> getCachedRoadmap(String id);

  /// Cache single roadmap
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheRoadmap(RoadmapModel model);

  /// Delete cached roadmap
  Future<void> deleteCachedRoadmap(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: RoadmapLocalDataSource)
class RoadmapLocalDataSourceImpl implements RoadmapLocalDataSource {
  static const String _cacheKey = 'roadmap_cache';
  static const String _cacheListKey = 'roadmap_list_cache';

  final ILocalStoreService _localStoreService;

  RoadmapLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<RoadmapModel>> getCachedRoadmaps() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => RoadmapModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheRoadmaps(List<RoadmapModel> models) async {
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
  Future<RoadmapModel?> getCachedRoadmap(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return RoadmapModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheRoadmap(RoadmapModel model) async {
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
  Future<void> deleteCachedRoadmap(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedRoadmaps();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheRoadmaps(updatedList);
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
