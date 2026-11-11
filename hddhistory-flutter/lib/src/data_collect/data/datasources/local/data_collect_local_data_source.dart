part of '../../../data_collect.dart';

abstract class DataCollectLocalDataSource {
  /// Get cached user_collect_datas
  Future<List<UserCollectDataModel>> getCachedUserCollectDatas();

  /// Cache user_collect_datas
  Future<void> cacheUserCollectDatas(List<UserCollectDataModel> models);

  /// Get cached user_collect_data by id
  Future<UserCollectDataModel?> getCachedUserCollectData(String id);

  /// Cache user_collect_data
  Future<void> cacheUserCollectData(UserCollectDataModel model);

  /// Delete cached user_collect_data
  Future<void> deleteCachedUserCollectData(String id);

  /// Clear cache
  Future<void> clearCache();
}

@LazySingleton(as: DataCollectLocalDataSource)
class DataCollectLocalDataSourceImpl implements DataCollectLocalDataSource {
  static const String _cacheKey = 'data_collect_cache';
  static const String _cacheListKey = 'data_collect_list_cache';

  final ILocalStoreService _localStoreService;

  DataCollectLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<UserCollectDataModel>> getCachedUserCollectDatas() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => UserCollectDataModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheUserCollectDatas(List<UserCollectDataModel> models) async {
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
  Future<UserCollectDataModel?> getCachedUserCollectData(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return UserCollectDataModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserCollectData(UserCollectDataModel model) async {
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
  Future<void> deleteCachedUserCollectData(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
      // Note: Individual item caches would need to be tracked separately
      // or you can implement a prefix-based clear in LocalStoreService
    } catch (e) {
      // Handle error silently or log
    }
  }
}
