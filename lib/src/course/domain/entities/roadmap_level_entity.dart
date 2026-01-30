part of '../../course.dart';

@freezed
abstract class RoadmapLevelEntity with _$RoadmapLevelEntity {
  const factory RoadmapLevelEntity({
    @Default(0) int id,
    @Default(CourseLevel.level1) CourseLevel level,
    @Default('') String lightBadge,
    @Default('') String darkBadge,
    @Default(BaseMultiLanguage()) BaseMultiLanguage titleBadge,
    @Default([]) List<String> keypointIds,
    @Default([]) List<RoadmapNodeEntity> nodes,
    @Default([]) List<LessonEntity> lessonList,
  }) = _RoadmapLevelEntity;

  factory RoadmapLevelEntity.fromJson(Map<String, dynamic> json) => _$RoadmapLevelEntityFromJson(json);
}

extension RoadmapLevelEntityExtension on RoadmapLevelEntity {
  List<LessonEntity> get roadmapLessonsList => [
    ...nodes.expand((node) => node.lessonsList),
  ];

  int get totalLessons => lessonList.length;
  int get completedLessons => lessonList.where((r) => r.progess == ProcessEnum.done).length;
  double get progress {
    if (totalLessons == 0) return 0;
    if (completedLessons >= totalLessons) return 1;
    return completedLessons / totalLessons;
  }

  bool get isCompleted => completedLessons >= totalLessons;

  bool get hasRoadmapProgress =>
      roadmapLessonsList.any((lesson) => lesson.roadmapProgress != ProcessEnum.notStarted);

  bool get isRoadmapCompleted =>
      roadmapLessonsList.isNotEmpty &&
      roadmapLessonsList.every((lesson) => lesson.roadmapProgress == ProcessEnum.done);

  List<bool> get sequentialUnlockFlags {
    bool previousNodesCompleted = true;
    return nodes.map((node) {
      final items = node.lessonsList;
      final nodeHasProgress = items.any((lesson) => lesson.roadmapProgress != ProcessEnum.notStarted);
      final nodeItemsCompleted = items.isNotEmpty &&
          items.every((lesson) => lesson.roadmapProgress == ProcessEnum.done);
      final enableSequentialUnlock = nodeHasProgress || previousNodesCompleted;
      previousNodesCompleted = previousNodesCompleted && nodeItemsCompleted;
      return enableSequentialUnlock;
    }).toList();
  }

  List<LessonEntity> appProgressLessons(bool usingAppProgressLessons) {
    if (!usingAppProgressLessons) return lessonList;
    if (lessonList.isEmpty) return [];
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
