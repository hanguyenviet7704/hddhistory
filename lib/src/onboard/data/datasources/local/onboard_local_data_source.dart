part of '../../../onboard.dart';

abstract class OnboardLocalDataSource {
  /// Get cached onboard by id
  Future<OnboardModel?> getCachedOnboard(String id);

  /// Cache onboard
  Future<void> cacheOnboard(OnboardModel model);
}

@LazySingleton(as: OnboardLocalDataSource)
class OnboardLocalDataSourceImpl implements OnboardLocalDataSource {
  static const String _cacheKey = 'onboard_cache';

  final ILocalStoreService _localStoreService;

  OnboardLocalDataSourceImpl(this._localStoreService);

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
}
