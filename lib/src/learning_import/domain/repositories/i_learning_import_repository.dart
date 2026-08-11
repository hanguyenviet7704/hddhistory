part of '../../learning_import.dart';

/// What to import. A plain params class rather than freezed — it never crosses
/// the wire and never lands in state, so a generated `copyWith`/`toJson` would
/// be dead code.
class CreateLearningImportParams {
  /// R2 object key of an already-uploaded PDF. Mutually exclusive with [url].
  final String? fileKey;
  final String? fileName;

  /// YouTube link. Mutually exclusive with [fileKey].
  final String? url;

  /// Language the lesson is written in, whatever language the source is in.
  final String outputLocale;

  const CreateLearningImportParams({
    required this.outputLocale,
    this.fileKey,
    this.fileName,
    this.url,
  });

  bool get isPdf => fileKey != null && fileKey!.isNotEmpty;
}

class UpdateLessonProgressParams {
  final String lessonId;

  /// Which keypoint the reader was in — where opening the lesson resumes.
  final int stopAtKeypointIndex;

  /// How far into that keypoint, as a card index RELATIVE to it.
  final int stopAtSectionIndex;

  const UpdateLessonProgressParams({
    required this.lessonId,
    required this.stopAtKeypointIndex,
    required this.stopAtSectionIndex,
  });
}

abstract class ILearningImportRepository {
  /// Starts a run and returns the job to poll. Fails with the server's reason
  /// when a gate rejects it — not premium, out of credits, or another import
  /// already in flight.
  TaskEither<AppException, LearningImportJobEntity> createImport(
    CreateLearningImportParams params,
  );

  TaskEither<AppException, LearningImportJobEntity> getJob(String jobId);

  TaskEither<AppException, ImportQuotaEntity> getQuota();

  TaskEither<AppException, BasePageBreak<UserLessonEntity>> getUserLessons({
    required int page,
    required int take,
  });

  /// One lesson INCLUDING its sections — the list endpoint omits the body.
  TaskEither<AppException, UserLessonEntity> getUserLesson(String id);

  TaskEither<AppException, Unit> updateProgress(
    UpdateLessonProgressParams params,
  );

  TaskEither<AppException, Unit> deleteUserLesson(String id);
}
