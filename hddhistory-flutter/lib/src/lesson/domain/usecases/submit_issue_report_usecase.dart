part of '../../lesson.dart';

@lazySingleton
class SubmitIssueReportUseCase implements BaseUseCase<IssueReportEntity, Unit> {
  final IIssueReportRepository _repository;

  SubmitIssueReportUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(IssueReportEntity params) {
    return _repository.submitIssueReport(params);
  }
}
