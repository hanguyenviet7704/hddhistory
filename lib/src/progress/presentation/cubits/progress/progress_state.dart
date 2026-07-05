part of '../../../progress.dart';

enum ProgressStatus { initial, loading, success, failure }

@freezed
abstract class ProgressState with _$ProgressState {
  const factory ProgressState({
    @Default(ProgressStatus.initial) ProgressStatus status,
    @Default(BasePageBreak<CourseEntity>()) BasePageBreak<CourseEntity> myCoursesPageData,
    @Default(UserProgressEntity()) UserProgressEntity userCourseProgress,
    @Default(LessonResultEntity()) LessonResultEntity currentLessonResult,
    @Default(KeypointResultEntity()) KeypointResultEntity currentKeypointResult,
    @Default(ExerciseResultEntity()) ExerciseResultEntity currentExerciseResult,
    @Default(false) bool isSubmittingCompletedLevelAdditionalContentRequest,
    String? errorMessage,
  }) = _ProgressState;

  factory ProgressState.initial() => ProgressState();

  factory ProgressState.fromJson(Map<String, dynamic> json) => _$ProgressStateFromJson(json);
}

extension ProgressStateExtension on ProgressState {
  // List<UserProgressEntity> get userProgresses => userProgressData.items;
  List<UserProgressEntity> get userProgresses => [];
  List<CourseEntity> get myCourses => myCoursesPageData.items;
}

/// True when the "my courses" (Continue learning) list should be (re)fetched
/// by a page that needs it: no courses loaded and no load currently running.
/// Note: a genuinely-empty "my courses" list (a user who hasn't started any
/// course yet) looks identical to a failed/never-run load, so it will
/// refetch on every Home entry — the same accepted trade-off as
/// [shouldSelfHealHomeData]. Kept as a pure function so the self-heal
/// trigger is unit-testable.
bool shouldEnsureMyCoursesReload(ProgressState state) => state.myCourses.isEmpty && state.status != ProgressStatus.loading;
