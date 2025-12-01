part of '../../../monetization.dart';

/// Local data source for Monetization
///
/// Handles caching of Iap Product data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class MonetizationLocalDataSource {
  /// Get all cached iap_products
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<IapProductModel>> getCachedIapProducts();

  /// Cache multiple iap_products
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheIapProducts(List<IapProductModel> models);

  /// Get cached iap_product by id
  Future<IapProductModel?> getCachedIapProduct(String id);

  /// Cache single iap_product
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheIapProduct(IapProductModel model);

  /// Delete cached iap_product
  Future<void> deleteCachedIapProduct(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: MonetizationLocalDataSource)
class MonetizationLocalDataSourceImpl implements MonetizationLocalDataSource {
  static const String _cacheKey = 'monetization_cache';
  static const String _cacheListKey = 'monetization_list_cache';

  final ILocalStoreService _localStoreService;

  MonetizationLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<IapProductModel>> getCachedIapProducts() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => IapProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheIapProducts(List<IapProductModel> models) async {
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
  Future<IapProductModel?> getCachedIapProduct(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return IapProductModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheIapProduct(IapProductModel model) async {
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
  Future<void> deleteCachedIapProduct(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedIapProducts();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheIapProducts(updatedList);
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

