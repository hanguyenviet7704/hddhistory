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
      final data = await _localStoreService.getMap(key: '${_cacheKey}_data');
      if (data.isEmpty) return null;

      return OnboardModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheOnboard(OnboardModel model) async {
    try {
      await _localStoreService.setMap(
        key: '${_cacheKey}_data',
        value: model.toJson(),
      );
    } catch (_) {}
  }
}
