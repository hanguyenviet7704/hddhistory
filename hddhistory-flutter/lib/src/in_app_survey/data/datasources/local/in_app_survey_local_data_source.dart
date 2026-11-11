part of '../../../in_app_survey.dart';

abstract class InAppSurveyLocalDataSource {
  Future<InAppSurveyConfigModel?> getCachedInAppSurveyConfig();
  Future<void> cacheInAppSurveyConfig(InAppSurveyConfigModel model);
  Future<void> clearCache();
}

@LazySingleton(as: InAppSurveyLocalDataSource)
class InAppSurveyLocalDataSourceImpl implements InAppSurveyLocalDataSource {
  static const String _cacheKey = 'in_app_survey_config_cache';

  final ILocalStoreService _localStoreService;

  InAppSurveyLocalDataSourceImpl(this._localStoreService);

  @override
  Future<InAppSurveyConfigModel?> getCachedInAppSurveyConfig() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;
      return InAppSurveyConfigModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheInAppSurveyConfig(InAppSurveyConfigModel model) async {
    try {
      await _localStoreService.setMap(key: _cacheKey, value: model.toJson());
    } catch (e) {
      LogDev.error('Error caching in app survey config: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheKey);
    } catch (e) {
      LogDev.error('Error clearing in app survey config cache: $e');
    }
  }
}

