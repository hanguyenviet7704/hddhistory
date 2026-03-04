part of '../../../learning_streak.dart';

abstract class LearningStreakLocalDataSource {
  Future<UserLearningStreakModel?> getCachedUserLearningStreak();

  Future<void> cacheUserLearningStreak(UserLearningStreakModel model);

  Future<void> clearCache();
}

@LazySingleton(as: LearningStreakLocalDataSource)
class LearningStreakLocalDataSourceImpl implements LearningStreakLocalDataSource {
  static const String _cacheKey = 'learning_streak_cache';

  final ILocalStoreService _localStoreService;

  LearningStreakLocalDataSourceImpl(this._localStoreService);

  @override
  Future<UserLearningStreakModel?> getCachedUserLearningStreak() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;

      return UserLearningStreakModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserLearningStreak(UserLearningStreakModel model) async {
    try {
      await _localStoreService.setMap(
        key: _cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      //
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheKey);
    } catch (e) {
      //
    }
  }
}

