part of '../../../progress.dart';

enum ProgressStatus { initial, loading, success, failure }

@freezed
abstract class ProgressState with _$ProgressState {
  const factory ProgressState({
    @Default(ProgressStatus.initial) ProgressStatus status,
    @Default(BasePageBreak<CourseEntity>()) BasePageBreak<CourseEntity> myCoursesPageData,

    /// EVERY enrolled course, paginated — the Library tab's own list.
    ///
    /// Deliberately separate from [myCoursesPageData]: that one is loaded with
    /// `recent: true`, which the API caps at 3 rows, and Home's "Jump back in"
    /// strip is built from exactly those 3. Pointing the Library at the same
    /// field would silently change what Home shows.
    @Default(BasePageBreak<CourseEntity>()) BasePageBreak<CourseEntity> libraryPageData,

    /// Load state for [libraryPageData] alone. The Library list must not share
    /// [status]: the two lists are fetched independently, and a shared status
    /// makes each loader's in-flight guard swallow the other's request.
    @Default(ProgressStatus.initial) ProgressStatus libraryStatus,
    String? libraryErrorMessage,
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

  /// Every enrolled course, newest-touched first (the API orders by the
  /// progress row's `updatedAt`).
  List<CourseEntity> get libraryCourses => libraryPageData.items;

  /// Still something left to do. A course with no lessons at all counts as in
  /// progress rather than finished — 0/0 is "nothing to show yet", and calling
  /// it Completed would be a lie the reader can see through.
  List<CourseEntity> get libraryInProgressCourses =>
      libraryCourses.where((c) => c.numberOfLesson <= 0 || c.numberOfLessonPassed < c.numberOfLesson).toList();

  /// Every item done.
  List<CourseEntity> get libraryFinishedCourses =>
      libraryCourses.where((c) => c.numberOfLesson > 0 && c.numberOfLessonPassed >= c.numberOfLesson).toList();

  bool get isLibraryLoading => libraryStatus == ProgressStatus.loading;

  /// Cold load: a spinner is only honest while there is nothing to show yet.
  bool get isLibraryInitialLoading => isLibraryLoading && libraryCourses.isEmpty;

  bool get isLibraryFailure => libraryStatus == ProgressStatus.failure && libraryCourses.isEmpty;
}

/// True when the "my courses" (Continue learning) list should be (re)fetched
/// by a page that needs it: no courses loaded and no load currently running.
/// Note: a genuinely-empty "my courses" list (a user who hasn't started any
/// course yet) looks identical to a failed/never-run load, so it will
/// refetch on every Home entry — the same accepted trade-off as
/// [shouldSelfHealHomeData]. Kept as a pure function so the self-heal
/// trigger is unit-testable.
bool shouldEnsureMyCoursesReload(ProgressState state) => state.myCourses.isEmpty && state.status != ProgressStatus.loading;
