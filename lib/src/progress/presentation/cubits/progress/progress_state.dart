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