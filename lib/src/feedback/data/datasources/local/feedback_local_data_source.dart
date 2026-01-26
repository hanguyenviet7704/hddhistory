part of '../../../feedback.dart';

abstract class FeedbackLocalDataSource {
  Future<UserFeedbackModel?> getCachedUserFeedback();
  Future<void> cacheUserFeedback(UserFeedbackModel model);
  Future<void> clearCache();
}

@LazySingleton(as: FeedbackLocalDataSource)
class FeedbackLocalDataSourceImpl implements FeedbackLocalDataSource {
  static const String _cacheKey = 'user_feedback_cache';

  final ILocalStoreService _localStoreService;

  FeedbackLocalDataSourceImpl(this._localStoreService);

  @override
  Future<UserFeedbackModel?> getCachedUserFeedback() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;
      return UserFeedbackModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserFeedback(UserFeedbackModel model) async {
    try {
      await _localStoreService.setMap(
        key: _cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheKey);
    } catch (e) {
    }
  }
}

