part of '../../../daily_warm_up.dart';

abstract class DailyWarmUpLocalDataSource {
  Future<DailyWarmUpModel?> getCachedDailyWarmUp();
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model);
  Future<String> getShownDate(String userId);
  Future<void> markShownDate(String userId, String date);
  Future<String> getOnboardingCompletedDate(String userId);
  Future<void> markOnboardingCompletedDateIfAbsent(String userId, String date);
  Future<void> clearCache();
}

@LazySingleton(as: DailyWarmUpLocalDataSource)
class DailyWarmUpLocalDataSourceImpl implements DailyWarmUpLocalDataSource {
  static const String _cacheKey = 'daily_warm_up_cache';
  static const String _shownDateKeyPrefix = 'daily_warm_up_shown_date';
  static const String _onboardingCompletedDateKeyPrefix = 'daily_warm_up_onboarding_completed_date';

  final ILocalStoreService _localStoreService;

  DailyWarmUpLocalDataSourceImpl(this._localStoreService);

  @override
  Future<DailyWarmUpModel?> getCachedDailyWarmUp() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;
      return DailyWarmUpModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model) async {
    try {
      await _localStoreService.setMap(key: _cacheKey, value: model.toJson());
    } catch (e) {
      LogDev.error('Error caching daily warm up: $e');
    }
  }

  @override
  Future<String> getShownDate(String userId) async {
    try {
      return await _localStoreService.getString(key: _shownDateKey(userId));
    } catch (_) {
      return '';
    }
  }

  @override
  Future<void> markShownDate(String userId, String date) async {
    final normalizedDate = date.trim();
    if (normalizedDate.isEmpty) return;

    try {
      await _localStoreService.setString(key: _shownDateKey(userId), value: normalizedDate);
    } catch (e) {
      LogDev.error('Error marking daily warm up shown date: $e');
    }
  }

  @override
  Future<String> getOnboardingCompletedDate(String userId) async {
    try {
      return await _localStoreService.getString(key: _onboardingCompletedDateKey(userId));
    } catch (_) {
      return '';
    }
  }

  @override
  Future<void> markOnboardingCompletedDateIfAbsent(String userId, String date) async {
    final normalizedDate = date.trim();
    if (normalizedDate.isEmpty) return;

    try {
      final existingDate = await getOnboardingCompletedDate(userId);
      if (existingDate.trim().isNotEmpty) return;
      await _localStoreService.setString(key: _onboardingCompletedDateKey(userId), value: normalizedDate);
    } catch (e) {
      LogDev.error('Error marking daily warm up onboarding completed date: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheKey);
    } catch (e) {
      LogDev.error('Error clearing daily warm up cache: $e');
    }
  }

  String _shownDateKey(String userId) {
    return '${_shownDateKeyPrefix}_${_normalizedUserId(userId)}';
  }

  String _onboardingCompletedDateKey(String userId) {
    return '${_onboardingCompletedDateKeyPrefix}_${_normalizedUserId(userId)}';
  }

  String _normalizedUserId(String userId) {
    return userId.trim().isEmpty ? 'anonymous' : userId.trim();
  }
}
