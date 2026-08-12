part of '../../learning_import.dart';

/// Where the user's material came from.
enum ImportSourceTypeEntity {
  @JsonValue('pdf')
  pdf,
  @JsonValue('youtube')
  youtube,
  @JsonValue('unknown')
  unknown,
}

/// State of one import run.
///
/// [interrupted] is derived server-side from a stale heartbeat, never stored:
/// the process running the job died (a deploy, a crash) and nothing was left to
/// write a final status. It is a retryable state, not a failure — the attempt
/// did not consume one of the user's monthly credits.
enum ImportJobStatusEntity {
  @JsonValue('queued')
  queued,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('interrupted')
  interrupted,
  @JsonValue('unknown')
  unknown,
}

/// Which step a running job is on — the only honest progress signal we have for
/// a job that takes minutes, so the waiting screen names the step instead of
/// animating a bar that means nothing.
enum ImportJobStageEntity {
  @JsonValue('fetching')
  fetching,
  @JsonValue('generating')
  generating,
  @JsonValue('validating')
  validating,
  @JsonValue('saving')
  saving,

  /// Narration, which the server now runs BEFORE it reports the job complete —
  /// so "your lesson is ready" means readable and listenable. It has its own
  /// deadline server-side: past it the job completes anyway and the audio
  /// lands late.
  @JsonValue('dubbing')
  dubbing,
  @JsonValue('unknown')
  unknown,
}

@freezed
abstract class LearningImportJobEntity with _$LearningImportJobEntity {
  const factory LearningImportJobEntity({
    @Default('') String id,
    @Default(ImportJobStatusEntity.unknown) ImportJobStatusEntity status,
    ImportJobStageEntity? stage,
    @Default(0) int percent,
    @Default(ImportSourceTypeEntity.unknown) ImportSourceTypeEntity sourceType,

    /// Filename or video title — what the waiting screen and the history row
    /// show so the user knows which import they are looking at.
    @Default('') String sourceLabel,
    @Default('') String outputLocale,

    /// Set once the lesson exists. This is what the waiting screen navigates to.
    String? userLessonId,

    /// Machine-readable failure cause. The app renders its own sentence from
    /// this rather than showing a server message, so the wording stays
    /// localized and stays ours.
    String? errorCode,
  }) = _LearningImportJobEntity;
}

extension LearningImportJobEntityX on LearningImportJobEntity {
  bool get isRunning =>
      status == ImportJobStatusEntity.queued ||
      status == ImportJobStatusEntity.processing;

  bool get isDone => status == ImportJobStatusEntity.completed;

  /// Failed for any reason, including the process dying. [ImportJobStatusEntity.interrupted]
  /// is grouped here because both end the wait — they differ only in the
  /// sentence shown and whether retrying is worth suggesting.
  bool get isFailed =>
      status == ImportJobStatusEntity.failed ||
      status == ImportJobStatusEntity.interrupted;
}
