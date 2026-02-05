{{#has_local_cache}}part of '../../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

/// Local data source for {{#titleCase}}{{feature_name}}{{/titleCase}}
///
/// Handles caching of {{#titleCase}}{{entity_name}}{{/titleCase}} data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class {{#pascalCase}}{{feature_name}}{{/pascalCase}}LocalDataSource {
  /// Get all cached {{#snakeCase}}{{entity_name}}{{/snakeCase}}s
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model>> getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}s();

  /// Cache multiple {{#snakeCase}}{{entity_name}}{{/snakeCase}}s
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(List<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model> models);

  /// Get cached {{#snakeCase}}{{entity_name}}{{/snakeCase}} by id
  Future<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model?> getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id);

  /// Cache single {{#snakeCase}}{{entity_name}}{{/snakeCase}}
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Model model);

  /// Delete cached {{#snakeCase}}{{entity_name}}{{/snakeCase}}
  Future<void> deleteCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: {{#pascalCase}}{{feature_name}}{{/pascalCase}}LocalDataSource)
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}LocalDataSourceImpl implements {{#pascalCase}}{{feature_name}}{{/pascalCase}}LocalDataSource {
  static const String _cacheKey = '{{#snakeCase}}{{feature_name}}{{/snakeCase}}_cache';
  static const String _cacheListKey = '{{#snakeCase}}{{feature_name}}{{/snakeCase}}_list_cache';

  final ILocalStoreService _localStoreService;

  {{#pascalCase}}{{feature_name}}{{/pascalCase}}LocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model>> getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}s() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(List<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model> models) async {
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
  Future<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model?> getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Model model) async {
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
  Future<void> deleteCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCached{{#pascalCase}}{{entity_name}}{{/pascalCase}}s();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cache{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(updatedList);
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
{{/has_local_cache}}
