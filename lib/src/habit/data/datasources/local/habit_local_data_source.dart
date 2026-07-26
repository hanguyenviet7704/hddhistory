part of '../../../habit.dart';

/// Local cache for the combined Habit-tab bootstrap payload
/// (`GET /user-habits/screen`). Lets [HabitCubit.load] render the last-known
/// habits/summary/slot-cap instantly (cache-first), then refresh from network
/// in the background. Mirrors [AchievenmentProgressLocalDataSource].
abstract class HabitLocalDataSource {
  Future<HabitScreenModel?> getCachedHabitScreen();
  Future<void> cacheHabitScreen(HabitScreenModel model);
  Future<void> clearCache();
}

@LazySingleton(as: HabitLocalDataSource)
class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  static const String _cacheKey = 'habit_screen_cache';

  final ILocalStoreService _localStoreService;

  HabitLocalDataSourceImpl(this._localStoreService);

  @override
  Future<HabitScreenModel?> getCachedHabitScreen() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;
      return HabitScreenModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheHabitScreen(HabitScreenModel model) async {
    try {
      await _localStoreService.setMap(key: _cacheKey, value: model.toJson());
    } catch (e) {
      LogDev.error('Error caching habit screen: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheKey);
    } catch (e) {
      LogDev.error('Error clearing habit screen cache: $e');
    }
  }
}
