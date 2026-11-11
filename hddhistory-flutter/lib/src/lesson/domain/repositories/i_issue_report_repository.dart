part of '../../lesson.dart';

abstract class IIssueReportRepository {
  TaskEither<AppException, Unit> submitIssueReport(IssueReportEntity entity);
}
