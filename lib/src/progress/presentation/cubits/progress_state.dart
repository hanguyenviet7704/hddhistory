part of '../../progress.dart';

enum ProgressStatus { initial, loading, success, failure }

@freezed
abstract class ProgressState with _$ProgressState {
  const factory ProgressState({
    @Default(ProgressStatus.initial) ProgressStatus status,
    @Default(BasePageBreak<UserProgressEntity>()) BasePageBreak<UserProgressEntity> pageData,
    @Default(BasePageBreak<CourseEntity>()) BasePageBreak<CourseEntity> myCoursesPageData,
    UserProgressEntity? selectedLesson,
    UserProgressEntity? selectedKeypoint,
    UserProgressEntity? selectedExercise,
    String? errorMessage,
  }) = _ProgressState;

  factory ProgressState.initial() => ProgressState();

  factory ProgressState.fromJson(Map<String, dynamic> json) => _$ProgressStateFromJson(json);
}

extension ProgressStateExtension on ProgressState {
  List<UserProgressEntity> get userProgresses => pageData.items;
  List<CourseEntity> get myCourses => myCoursesPageData.items;
}