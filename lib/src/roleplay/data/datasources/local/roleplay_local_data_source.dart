part of '../../../roleplay.dart';

/// Local data source for Roleplay
///
/// Handles caching of Section data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class RoleplayLocalDataSource {
  /// Get all cached sections
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<SectionModel>> getCachedSections();

  /// Cache multiple sections
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheSections(List<SectionModel> models);

  /// Get cached section by id
  Future<SectionModel?> getCachedSection(String id);

  /// Cache single section
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheSection(SectionModel model);

  /// Delete cached section
  Future<void> deleteCachedSection(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: RoleplayLocalDataSource)
class RoleplayLocalDataSourceImpl implements RoleplayLocalDataSource {
  static const String _cacheKey = 'roleplay_cache';
  static const String _cacheListKey = 'roleplay_list_cache';

  final ILocalStoreService _localStoreService;

  RoleplayLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<SectionModel>> getCachedSections() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => SectionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheSections(List<SectionModel> models) async {
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
  Future<SectionModel?> getCachedSection(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return SectionModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheSection(SectionModel model) async {
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
  Future<void> deleteCachedSection(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedSections();
      final updatedList = cachedList.where((item) => item.id.toString() != id).toList();
      await cacheSections(updatedList);
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
