part of '../../../learning_streak.dart';

abstract class LearningStreakLocalDataSource {
  Future<UserLearningStreakModel?> getCachedUserLearningStreak(String userId);

  Future<void> cacheUserLearningStreak(String userId, UserLearningStreakModel model);

  Future<void> clearCache({String? userId});
}

@LazySingleton(as: LearningStreakLocalDataSource)
class LearningStreakLocalDataSourceImpl implements LearningStreakLocalDataSource {
  static const String _cacheKeyPrefix = 'learning_streak_cache';
  static const String _legacyCacheKey = 'learning_streak_cache';
  static const String _cachedUserIdsKey = 'learning_streak_cached_user_ids';

  final ILocalStoreService _localStoreService;

  LearningStreakLocalDataSourceImpl(this._localStoreService);

  @override
  Future<UserLearningStreakModel?> getCachedUserLearningStreak(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId.isEmpty) {
      await _purgeLegacyCacheIfNeeded();
      return null;
    }
    final userCacheKey = _cacheKeyForUser(normalizedUserId);

    try {
      final cachedData = await _localStoreService.getMap(key: userCacheKey);
      if (cachedData.isNotEmpty) {
        return UserLearningStreakModel.fromJson(cachedData).sanitized();
      }

      await _purgeLegacyCacheIfNeeded();
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserLearningStreak(String userId, UserLearningStreakModel model) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId.isEmpty) return;
    final cacheKey = _cacheKeyForUser(normalizedUserId);

    try {
      final sanitizedModel = model.sanitized();
      await _localStoreService.setMap(
        key: cacheKey,
        value: sanitizedModel.toJson(),
      );
      final cachedIds = await _localStoreService.getList<String>(key: _cachedUserIdsKey);
      if (!cachedIds.contains(normalizedUserId)) {
        cachedIds.add(normalizedUserId);
        await _localStoreService.setList<String>(key: _cachedUserIdsKey, value: cachedIds);
      }
    } catch (e) {
      //
    }
  }

  @override
  Future<void> clearCache({String? userId}) async {
    try {
      if (userId != null) {
        final normalizedUserId = _normalizeUserId(userId);
        if (normalizedUserId.isEmpty) return;
        await _localStoreService.remove(key: _cacheKeyForUser(normalizedUserId));
        final cachedIds = await _localStoreService.getList<String>(key: _cachedUserIdsKey);
        final updatedIds = cachedIds.where((id) => id != normalizedUserId).toList();
        await _localStoreService.setList<String>(key: _cachedUserIdsKey, value: updatedIds);
        return;
      }

      final cachedIds = await _localStoreService.getList<String>(key: _cachedUserIdsKey);
      for (final id in cachedIds) {
        await _localStoreService.remove(key: _cacheKeyForUser(id));
      }
      await _localStoreService.remove(key: _cachedUserIdsKey);
      await _localStoreService.remove(key: _legacyCacheKey);
    } catch (e) {
      //
    }
  }

  String _cacheKeyForUser(String userId) => '${_cacheKeyPrefix}_$userId';

  String _normalizeUserId(String userId) {
    return userId.trim();
  }

  Future<void> _purgeLegacyCacheIfNeeded() async {
    final legacyData = await _localStoreService.getMap(key: _legacyCacheKey);
    if (legacyData.isNotEmpty) {
      await _localStoreService.remove(key: _legacyCacheKey);
    }
  }
}
