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

    List<LessonEntity> newLessonList = [...lessonList];

    for (int i = 1; i < newLessonList.length; i++) {
      final previousLesson = newLessonList.elementAt(i - 1);
      final currentLesson = newLessonList.elementAt(i);

      if (previousLesson.progess == ProcessEnum.done && currentLesson.progess == ProcessEnum.notStarted) {
        lesson = currentLesson.copyWith(progess: ProcessEnum.inProgress);
        newLessonList = [...newLessonList.sublist(0, i), lesson, ...newLessonList.sublist(i + 1)];
        break;
      }
    }
    return newLessonList;
  }
}
