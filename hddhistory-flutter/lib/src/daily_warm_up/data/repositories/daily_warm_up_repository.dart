part of '../../daily_warm_up.dart';

@LazySingleton(as: IDailyWarmUpRepository)
class DailyWarmUpRepository with RestfulRequestHandlerMixin implements IDailyWarmUpRepository {
  final DailyWarmUpApi _api;
  final DailyWarmUpLocalDataSource _localDataSource;

  DailyWarmUpRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, DailyWarmUpEntity> getDailyWarmUp() {
    return callApiWithTransform<DailyWarmUpModel, DailyWarmUpEntity>(
      apiCall: () => _api.getDailyWarmUp(),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheDailyWarmUp(data ?? DailyWarmUpModel()),
      defaultValue: DailyWarmUpEntity(),
      enableErrorMessages: false,
    );
  }
}
