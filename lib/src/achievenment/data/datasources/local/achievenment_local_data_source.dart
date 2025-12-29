part of '../../../achievenment.dart';

/// Local data source for Achievenment
///
/// Handles caching of Achievenment Response data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class AchievenmentLocalDataSource {
  /// Get all cached achievenment_responses
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<AchievenmentResponseModel>> getCachedAchievenmentResponses();

  /// Cache multiple achievenment_responses
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheAchievenmentResponses(List<AchievenmentResponseModel> models);

  /// Get cached achievenment_response by id
  Future<AchievenmentResponseModel?> getCachedAchievenmentResponse(String id);

  /// Cache single achievenment_response
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheAchievenmentResponse(AchievenmentResponseModel model);

  /// Delete cached achievenment_response
  Future<void> deleteCachedAchievenmentResponse(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: AchievenmentLocalDataSource)
class AchievenmentLocalDataSourceImpl implements AchievenmentLocalDataSource {
  static const String _cacheKey = 'achievenment_cache';
  static const String _cacheListKey = 'achievenment_list_cache';

  final ILocalStoreService _localStoreService;

  AchievenmentLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<AchievenmentResponseModel>> getCachedAchievenmentResponses() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => AchievenmentResponseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheAchievenmentResponses(List<AchievenmentResponseModel> models) async {
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
  Future<AchievenmentResponseModel?> getCachedAchievenmentResponse(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return AchievenmentResponseModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheAchievenmentResponse(AchievenmentResponseModel model) async {
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
  Future<void> deleteCachedAchievenmentResponse(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedAchievenmentResponses();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheAchievenmentResponses(updatedList);
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

