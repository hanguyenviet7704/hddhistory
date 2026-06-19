part of '../../lesson.dart';

@lazySingleton
class ReportIssueUseCase implements BaseUseCase<IssueReportEntity, Unit> {
  final ILessonRepository _repository;

  ReportIssueUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(IssueReportEntity params) {
    return _repository.reportIssue(params);
  }
}
