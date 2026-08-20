part of '../../study_journal.dart';

@lazySingleton
class GetStudyJournalMonthUseCase {
  final IStudyJournalRepository _repository;

  GetStudyJournalMonthUseCase(this._repository);

  TaskEither<AppException, StudyJournalMonthEntity> call({
    required DateTime month,
    required int tzOffset,
  }) {
    return _repository.getMonth(month: month, tzOffset: tzOffset);
  }
}
