part of '../../learning_import.dart';

enum LearningImportStatus { initial, loading, success, failure }

/// Drives the import sheet and the waiting screen.
///
/// One cubit covers both because they are one flow: the sheet's Confirm button
/// creates the job the waiting screen then polls, and a failure at either end
/// shows the same sentence in the same place.
@freezed
abstract class LearningImportState with _$LearningImportState {
  const factory LearningImportState({
    @Default(LearningImportStatus.initial) LearningImportStatus status,
    @Default(ImportQuotaEntity()) ImportQuotaEntity quota,

    /// The run being watched. Null before Confirm is pressed.
    LearningImportJobEntity? job,

    /// True while the picked PDF is going to R2 — a distinct step from
    /// generation, and slow enough on a big file to deserve its own label.
    @Default(false) bool uploading,

    /// Machine-readable failure cause, from either the create call or the job.
    /// The UI turns this into a localized sentence; see [learningImportErrorText].
    String? errorCode,
    String? errorMessage,
  }) = _LearningImportState;

  factory LearningImportState.initial() => const LearningImportState();
}

extension LearningImportStateX on LearningImportState {
  bool get isBusy =>
      uploading ||
      status == LearningImportStatus.loading ||
      (job?.isRunning ?? false);

  bool get isFinished => job?.isDone ?? false;

  String? get finishedLessonId => job?.userLessonId;
}
