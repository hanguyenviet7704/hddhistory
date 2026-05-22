part of '../../daily_warm_up.dart';

@lazySingleton
class GetDailyWarmUpUseCase implements BaseUseCase<String, DailyWarmUpEntity> {
  final IDailyWarmUpRepository _repository;

  GetDailyWarmUpUseCase(this._repository);

  @override
  TaskEither<AppException, DailyWarmUpEntity> call(String params) {
    return _repository.getDailyWarmUp(params);
  }
}

