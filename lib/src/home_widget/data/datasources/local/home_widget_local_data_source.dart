part of '../../../home_widget.dart';

/// Local data source for Home Widget
///
/// Handles caching of Home Widget data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class HomeWidgetLocalDataSource {
  /// Get all cached home_widgets
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<HomeWidgetModel>> getCachedHomeWidgets();

  /// Cache multiple home_widgets
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheHomeWidgets(List<HomeWidgetModel> models);

  /// Get cached home_widget by id
  Future<HomeWidgetModel?> getCachedHomeWidget(String id);

  /// Cache single home_widget
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheHomeWidget(HomeWidgetModel model);

  /// Delete cached home_widget
  Future<void> deleteCachedHomeWidget(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: HomeWidgetLocalDataSource)
class HomeWidgetLocalDataSourceImpl implements HomeWidgetLocalDataSource {
  static const String _cacheKey = 'home_widget_cache';
  static const String _cacheListKey = 'home_widget_list_cache';

  final ILocalStoreService _localStoreService;

  HomeWidgetLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<HomeWidgetModel>> getCachedHomeWidgets() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => HomeWidgetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheHomeWidgets(List<HomeWidgetModel> models) async {
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
  Future<HomeWidgetModel?> getCachedHomeWidget(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return HomeWidgetModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheHomeWidget(HomeWidgetModel model) async {
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
  Future<void> deleteCachedHomeWidget(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedHomeWidgets();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheHomeWidgets(updatedList);
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

