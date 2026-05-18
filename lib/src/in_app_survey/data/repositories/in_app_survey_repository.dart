part of '../../in_app_survey.dart';

@LazySingleton(as: IInAppSurveyRepository)
class InAppSurveyRepository with RestfulRequestHandlerMixin implements IInAppSurveyRepository {
  final InAppSurveyApi _api;
  final InAppSurveyLocalDataSource _localDataSource;

  InAppSurveyRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, InAppSurveyConfigEntity> getInAppSurveyConfig() {
    return callApiWithTransform<InAppSurveyConfigModel, InAppSurveyConfigEntity>(
      apiCall: () => _api.getInAppSurveyConfig(),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheInAppSurveyConfig(data ?? InAppSurveyConfigModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedInAppSurveyConfig();
        return cachedModel?.toEntity();
      },
      defaultValue: InAppSurveyConfigEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> createInAppSurveyResponse(InAppSurveyResponseEntity entity) {
    return executeApiAction(
      apiCall: () => _api.createInAppSurveyResponse(_responseEntityToJson(entity)),
    );
  }

  Map<String, dynamic> _responseEntityToJson(InAppSurveyResponseEntity entity) {
    return {
      'configKey': entity.configKey,
      'branchId': entity.branchId,
      'closedAnswerIds': entity.closedAnswerIds,
      'openAnswer': entity.openAnswer,
    };
  }
}

