part of '../../daily_warm_up.dart';

@lazySingleton
class GetDailyWarmUpUseCase implements BaseUseCase<Unit, DailyWarmUpEntity> {
  final IDailyWarmUpRepository _repository;

  GetDailyWarmUpUseCase(this._repository);

  @override
  TaskEither<AppException, DailyWarmUpEntity> call(Unit _) {
    return _repository.getDailyWarmUp();
  }
}
