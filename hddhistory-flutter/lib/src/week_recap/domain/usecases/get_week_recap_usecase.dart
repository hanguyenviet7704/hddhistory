part of '../../week_recap.dart';

@lazySingleton
class GetWeekRecapUseCase {
  final IWeekRecapRepository _repository;

  GetWeekRecapUseCase(this._repository);

  TaskEither<AppException, WeekRecapEntity> call(String id) => _repository.getById(id);
}
