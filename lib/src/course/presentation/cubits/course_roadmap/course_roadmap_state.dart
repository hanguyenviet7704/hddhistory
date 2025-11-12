part of '../../../course.dart';

enum CourseRoadmapStatus { initial, loading, success, failure }

@freezed
abstract class CourseRoadmapState with _$CourseRoadmapState {
  const factory CourseRoadmapState({
    @Default(CourseRoadmapStatus.initial) CourseRoadmapStatus status,
    @Default(RoadmapEntity()) RoadmapEntity roadmap,
    String? errorMessage,
  }) = _CourseRoadmapState;

  factory CourseRoadmapState.initial() => CourseRoadmapState();

  factory CourseRoadmapState.fromJson(Map<String, dynamic> json) => _$CourseRoadmapStateFromJson(json);
}

extension CourseStateExtension on CourseRoadmapState {
  List<LessonEntity> get allLessons => roadmap.levels.expand((level) => level.lessonList).toList();
  int get totalLessons => allLessons.length;
  int get completedLessons => allLessons.where((r) => r.progess == ProcessEnum.done).length;
  double get progress {
    if (totalLessons == 0) return 0;
    if (completedLessons >= totalLessons) return 1;
    return completedLessons / totalLessons;
  }
}
