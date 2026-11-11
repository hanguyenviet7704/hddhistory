part of '../../study_journal.dart';

@lazySingleton
class GetStudyJournalDayUseCase {
  final IStudyJournalRepository _repository;

  GetStudyJournalDayUseCase(this._repository);

  TaskEither<AppException, StudyJournalDayDetailEntity> call({
    required DateTime day,
    required int tzOffset,
  }) {
    return _repository.getDay(day: day, tzOffset: tzOffset);
  }
}
