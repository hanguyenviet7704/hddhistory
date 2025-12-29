part of '../../../course.dart';

enum CourseRoadmapStatus { initial, loading, success, failure }

@freezed
abstract class CourseRoadmapState with _$CourseRoadmapState {
  const factory CourseRoadmapState({
    @Default(CourseRoadmapStatus.initial) CourseRoadmapStatus status,
    @Default(RoadmapEntity()) RoadmapEntity roadmap,
    @Default(CourseLevelProgressEntity()) CourseLevelProgressEntity currentLevelProgress,
    String? errorMessage,
  }) = _CourseRoadmapState;

  factory CourseRoadmapState.initial() => CourseRoadmapState();

  factory CourseRoadmapState.fromJson(Map<String, dynamic> json) => _$CourseRoadmapStateFromJson(json);
}

extension CourseRoadmapStateExtension on CourseRoadmapState {
  bool get isCompleted => roadmap.levels.every((level) => level.isCompleted);
  RoadmapLevelEntity get currentLevel => roadmap.levels.firstWhere((level) => !level.isCompleted);
}