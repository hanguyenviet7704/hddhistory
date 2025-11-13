part of '../../course.dart';

@freezed
abstract class RoadmapLevelEntity with _$RoadmapLevelEntity {
  const factory RoadmapLevelEntity({
    @Default(0) int id,
    @Default(CourseLevel.level1) CourseLevel level,
    @Default([]) List<RoadmapNodeEntity> nodes,
    @Default([]) List<LessonEntity> lessonList,
  }) = _RoadmapLevelEntity;

  factory RoadmapLevelEntity.fromJson(Map<String, dynamic> json) => _$RoadmapLevelEntityFromJson(json);
}

extension RoadmapLevelEntityExtension on RoadmapLevelEntity {
  int get totalLessons => lessonList.length;
  int get completedLessons => lessonList.where((r) => r.progess == ProcessEnum.done).length;
  double get progress {
    if (totalLessons == 0) return 0;
    if (completedLessons >= totalLessons) return 1;
    return completedLessons / totalLessons;
  }
}