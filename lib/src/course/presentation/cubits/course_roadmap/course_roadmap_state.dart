part of '../../../course.dart';

enum CourseRoadmapStatus { initial, loading, success, failure }

@freezed
abstract class CourseRoadmapState with _$CourseRoadmapState {
  const factory CourseRoadmapState({
    @Default(CourseRoadmapStatus.initial) CourseRoadmapStatus status,
    @Default(BasePageBreak<CourseEntity>()) BasePageBreak<CourseEntity> pageData,
    @Default(RoadmapEntity()) RoadmapEntity roadmap,
    CourseEntity? selectedItem,
    String? errorMessage,
  }) = _CourseRoadmapState;

  factory CourseRoadmapState.initial() => CourseRoadmapState();

  factory CourseRoadmapState.fromJson(Map<String, dynamic> json) => _$CourseRoadmapStateFromJson(json);
}

extension CourseStateExtension on CourseRoadmapState {
  int get totalLessons => roadmap.lessonList.length;
  int get completedLessons => roadmap.lessonList.where((r) => r.process == ProcessEnum.done).length;
  double get progress {
    if (totalLessons == 0) return 0;
    if (completedLessons >= totalLessons) return 1;
    return completedLessons / totalLessons;
  }
}
