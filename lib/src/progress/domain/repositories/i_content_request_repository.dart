part of '../../progress.dart';

abstract class IContentRequestRepository {
  TaskEither<AppException, UserProgressEntity> createCompletedLevelAdditionalContentRequest(
    Map<String, dynamic> body,
  );
}
