part of '../../achievenment.dart';

@LazySingleton(as: IAchievenmentRepository)
class AchievenmentRepository with RestfulRequestHandlerMixin implements IAchievenmentRepository {
  final AchievenmentApi _api;
  final AchievenmentLocalDataSource _localDataSource;

  AchievenmentRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, AchievenmentResponseEntity> getAchievenmentResponse(String id) {
    return callApiWithTransform<AchievenmentResponseModel, AchievenmentResponseEntity>(
      apiCall: () => _api.getAchievenmentResponse(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheAchievenmentResponse(data ?? AchievenmentResponseModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedAchievenmentResponse(id);
        return cachedModel?.toEntity();
      },
      defaultValue: AchievenmentResponseEntity(),
    );
  }
}

