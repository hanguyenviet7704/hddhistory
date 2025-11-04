part of '../../../course.dart';

enum CourseLessonStatus { initial, loading, success, failure }

@freezed
abstract class CourseLessonState with _$CourseLessonState {
  const factory CourseLessonState({
    @Default(CourseLessonStatus.initial) CourseLessonStatus status,
    @Default(BasePageBreak<LessonEntity>()) BasePageBreak<LessonEntity> pageData,
    LessonEntity? selectedLesson,
    String? errorMessage,
  }) = _CourseLessonState;

  factory CourseLessonState.initial() => CourseLessonState();

  factory CourseLessonState.fromJson(Map<String, dynamic> json) => _$CourseLessonStateFromJson(json);
}

