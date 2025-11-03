part of '../../../onboard.dart';

abstract class OnboardLocalDataSource {
  /// Get cached onboards
  Future<List<OnboardModel>> getCachedOnboards();

  /// Cache onboards
  Future<void> cacheOnboards(List<OnboardModel> models);

  /// Get cached onboard by id
  Future<OnboardModel?> getCachedOnboard(String id);

  /// Cache onboard
  Future<void> cacheOnboard(OnboardModel model);

  /// Delete cached onboard
  Future<void> deleteCachedOnboard(String id);

  /// Clear cache
  Future<void> clearCache();
}

@LazySingleton(as: OnboardLocalDataSource)
class OnboardLocalDataSourceImpl implements OnboardLocalDataSource {
  static const String _cacheKey = 'onboard_cache';
  static const String _cacheListKey = 'onboard_list_cache';

  final ILocalStoreService _localStoreService;

  OnboardLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<OnboardModel>> getCachedOnboards() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => OnboardModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheOnboards(List<OnboardModel> models) async {
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
  Future<OnboardModel?> getCachedOnboard(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return OnboardModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheOnboard(OnboardModel model) async {
    try {
      final cacheKey = '${_cacheKey}_${model.hashCode}';
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> deleteCachedOnboard(String id) async {
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
