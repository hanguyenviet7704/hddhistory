part of '../../../auth.dart';

/// Local data source for Auth2
///
/// Handles caching of Auth data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class AuthLocalDataSource {
  /// Get all cached auths
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<AuthModel>> getCachedAuths();

  /// Cache multiple auths
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheAuths(List<AuthModel> models);

  /// Get cached auth by id
  Future<AuthModel?> getCachedAuth(String id);

  /// Cache single auth
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheAuth(AuthModel model);

  /// Delete cached auth
  Future<void> deleteCachedAuth(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: AuthLocalDataSource)
class Auth2LocalDataSourceImpl implements AuthLocalDataSource {
  static const String _cacheKey = 'auth2_cache';
  static const String _cacheListKey = 'auth2_list_cache';

  final ILocalStoreService _localStoreService;

  Auth2LocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<AuthModel>> getCachedAuths() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => AuthModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheAuths(List<AuthModel> models) async {
    try {
      // final jsonList = models.map((model) => model.toEntity().toJson()).toList();
      // await _localStoreService.setMap(
      //   key: _cacheListKey,
      //   value: {'items': jsonList},
      // );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<AuthModel?> getCachedAuth(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return AuthModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheAuth(AuthModel model) async {
    try {
      // final cacheKey = '${_cacheKey}_${model.id}';
      // await _localStoreService.setMap(
      //   key: cacheKey,
      //   value: model.toJson(),
      // );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> deleteCachedAuth(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // // Also remove from cached list if exists
      // final cachedList = await getCachedAuths();
      // final updatedList = cachedList.where((item) => item.id != id).toList();
      // await cacheAuths(updatedList);
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
