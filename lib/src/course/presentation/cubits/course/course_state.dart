part of '../../../course.dart';

enum CourseStatus { initial, loading, success, failure }

@freezed
abstract class CourseState with _$CourseState {
  const factory CourseState({
    @Default(CourseStatus.initial) CourseStatus status,
    @Default(BasePageBreak<CourseEntity>()) BasePageBreak<CourseEntity> pageData,
    @Default(RoadmapEntity()) RoadmapEntity roadmap,
    CourseEntity? selectedItem,
    String? errorMessage,
  }) = _CourseState;

  factory CourseState.initial() => CourseState();

  factory CourseState.fromJson(Map<String, dynamic> json) => _$CourseStateFromJson(json);
}

extension CourseStateExtension on CourseState {
  int get totalLessons => roadmap.lessonList.length;
  int get completedLessons => roadmap.lessonList.where((r) => r.process == ProcessEnum.done).length;
  double get progress => completedLessons / totalLessons;
}