part of '../../week_recap.dart';

@lazySingleton
class GetCurrentWeekRecapUseCase {
  final IWeekRecapRepository _repository;

  GetCurrentWeekRecapUseCase(this._repository);

  TaskEither<AppException, CurrentWeekRecapEntity> call({required int tzOffset}) {
    return _repository.getCurrent(tzOffset: tzOffset);
  }
}
