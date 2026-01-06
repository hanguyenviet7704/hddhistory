part of '../../../course.dart';

enum CourseRoadmapStatus { initial, loading, success, failure }

@freezed
abstract class CourseRoadmapState with _$CourseRoadmapState {
  const factory CourseRoadmapState({
    @Default(CourseRoadmapStatus.initial) CourseRoadmapStatus status,
    @Default(RoadmapEntity()) RoadmapEntity roadmap,
    @Default(CourseLevelProgressEntity()) CourseLevelProgressEntity currentLevelProgress,
    @Default(CourseLevel.level1) CourseLevel currentCourseLevel,
    @Default(LessonEntity()) LessonEntity currentLesson,
    String? errorMessage,
  }) = _CourseRoadmapState;

  factory CourseRoadmapState.initial() => CourseRoadmapState();

  factory CourseRoadmapState.fromJson(Map<String, dynamic> json) => _$CourseRoadmapStateFromJson(json);
}

extension CourseRoadmapStateExtension on CourseRoadmapState {
  bool get isCompleted => roadmap.levels.every((level) => level.isCompleted);
  RoadmapLevelEntity get currentLevelOpen => roadmap.levels.firstWhere((level) => !level.isCompleted);
  RoadmapLevelEntity get currentLevel => roadmap.levels.firstWhere((level) => level.level == currentCourseLevel);
  List<LessonEntity> get currentLevelLessons => currentLevel.lessonList.where((lesson) => lesson.type == LessonType.lesson).toList();
  bool get isLastLessonInLevel {
    if (currentLevelLessons.isEmpty) return false;
    return currentLevelLessons.last.id == currentLesson.id;
  }
}