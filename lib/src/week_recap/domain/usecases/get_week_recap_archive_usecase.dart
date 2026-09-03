part of '../../week_recap.dart';

@lazySingleton
class GetWeekRecapArchiveUseCase {
  final IWeekRecapRepository _repository;

  GetWeekRecapArchiveUseCase(this._repository);

  TaskEither<AppException, BasePageBreak<WeekRecapSummaryEntity>> call({
    required int page,
    int take = 20,
  }) {
    return _repository.getArchive(page: page, take: take);
  }
}
