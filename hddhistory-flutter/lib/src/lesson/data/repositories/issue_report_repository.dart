part of '../../lesson.dart';

@LazySingleton(as: IIssueReportRepository)
class IssueReportRepository with RestfulRequestHandlerMixin implements IIssueReportRepository {
  final IssueReportApi _api;

  IssueReportRepository(this._api);

  @override
  TaskEither<AppException, Unit> submitIssueReport(IssueReportEntity entity) {
    return executeApiAction(
      apiCall: () async {
        await _api.submitReport(_toJson(entity));
      },
    );
  }

  Map<String, dynamic> _toJson(IssueReportEntity entity) => {
    'lessonId': entity.lessonId,
    if (entity.keypointId.isNotEmpty) 'keypointId': entity.keypointId,
    'reasons': entity.reasons.map((r) => r.apiValue).toList(),
    if (entity.comment.trim().isNotEmpty) 'comment': entity.comment.trim(),
  };
}
