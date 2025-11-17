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

  bool get isCompleted => completedLessons >= totalLessons;

  List<LessonEntity> appProgressLessons(bool usingAppProgressLessons) {
    if (!usingAppProgressLessons) return lessonList;
    LessonEntity lesson = lessonList.elementAt(0);
    if (lesson.progess == ProcessEnum.notStarted) {
      lesson = lesson.copyWith(progess: ProcessEnum.inProgress);
      return [lesson, ...lessonList.sublist(1)];
    }

    /// Check previous lesson is completed, current lesson will be in progress
    for (int i = 1; i < lessonList.length; i++) {
      if (lessonList.elementAt(i - 1).progess != ProcessEnum.done) continue;
      lesson = lessonList.elementAt(i).copyWith(progess: ProcessEnum.inProgress);
      return [...lessonList.sublist(0, i), lesson, ...lessonList.sublist(i + 1)];
    }
    return lessonList;
  }
}