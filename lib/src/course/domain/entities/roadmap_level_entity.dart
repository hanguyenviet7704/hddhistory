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

  List<LessonEntity> resolvedRoadmapLessons({bool enableSequentialUnlock = true}) {
    final nodeFlags = enableSequentialUnlock ? sequentialUnlockFlags : List<bool>.filled(nodes.length, false);
    final resolvedLessons = <LessonEntity>[];

    for (int i = 0; i < nodes.length; i++) {
      final enableNodeUnlock = i < nodeFlags.length ? nodeFlags[i] : false;
      resolvedLessons.addAll(
        nodes[i].lessonsList.applySequentialUnlock(enableAutoUnlock: enableNodeUnlock),
      );
    }

    return resolvedLessons;
  }

  int get totalLessons => nodes.expand((node) => node.lessonsList).length;
  int get completedLessons => resolvedRoadmapLessons().where((lesson) => lesson.roadmapProgress == ProcessEnum.done).length;
  double get progress {
    if (totalLessons == 0) return 0;
    if (completedLessons >= totalLessons) return 1;
    return completedLessons / totalLessons;
  }

  bool get isCompleted => completedLessons >= totalLessons;

  bool get hasRoadmapProgress => roadmapLessonsList.any((lesson) => lesson.roadmapProgress != ProcessEnum.notStarted);

  bool get isRoadmapCompleted {
    final blockingLessons = roadmapLessonsList.where((lesson) => lesson.type.blocksRoadmap).toList();
    if (blockingLessons.isEmpty) return roadmapLessonsList.isNotEmpty;
    return blockingLessons.every((lesson) => lesson.roadmapProgress == ProcessEnum.done);
  }

  List<bool> get sequentialUnlockFlags {
    bool previousNodesCompleted = true;
    return nodes.map((node) {
      final items = node.lessonsList;
      final blockingItems = items.where((lesson) => lesson.type.blocksRoadmap).toList();
      final nodeHasProgress = blockingItems.any((lesson) => lesson.roadmapProgress != ProcessEnum.notStarted);
      final nodeItemsCompleted = blockingItems.isEmpty || blockingItems.every((lesson) => lesson.roadmapProgress == ProcessEnum.done);
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
