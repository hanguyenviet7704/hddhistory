part of '../../course.dart';

@freezed
abstract class RoadmapEntity with _$RoadmapEntity {
  const factory RoadmapEntity({
    @Default('') String id,
    @Default('') String courseId,
    @Default([]) List<RoadmapLevelEntity> levels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoadmapEntity;

  factory RoadmapEntity.fromJson(Map<String, dynamic> json) => _$RoadmapEntityFromJson(json);
}

extension RoadmapEntityExtension on RoadmapEntity {
  List<LessonEntity> get displayLessons {
    if (levels.isEmpty) return [];
    final levelFlags = levelSequentialUnlockFlags;
    final displayLessons = <LessonEntity>[];
    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      final level = levels[levelIndex];
      final enableSequentialUnlock = levelIndex < levelFlags.length ? levelFlags[levelIndex] : false;
      final nodeFlags = enableSequentialUnlock ? level.sequentialUnlockFlags : List<bool>.filled(level.nodes.length, false);
      for (var nodeIndex = 0; nodeIndex < level.nodes.length; nodeIndex++) {
        final node = level.nodes[nodeIndex];
        final enableNodeUnlock = nodeIndex < nodeFlags.length ? nodeFlags[nodeIndex] : false;
        final items = node.lessonsList.applySequentialUnlock(enableAutoUnlock: enableNodeUnlock);
        displayLessons.addAll(items);
      }
    }
    return displayLessons;
  }

  LessonEntity? get lastInProgressLesson {
    final display = displayLessons;
    for (var i = display.length - 1; i >= 0; i--) {
      final lesson = display[i];
      if (lesson.roadmapProgress == ProcessEnum.inProgress) return lesson;
    }
    return null;
  }

  MapEntry<LessonEntity, CourseLevel> autoSelectedLesson({required CourseLevel fallbackLevel}) {
    if (levels.isEmpty) return MapEntry(LessonEntity(), fallbackLevel);
    final display = displayLessons;
    if (display.isEmpty) return MapEntry(LessonEntity(), fallbackLevel);

    final hasProgress = display.any((lesson) => lesson.roadmapProgress != ProcessEnum.notStarted);
    LessonEntity selectedLesson;
    if (!hasProgress) {
      selectedLesson = display.first;
    } else {
      final inProgressLessons = display.where((lesson) => lesson.roadmapProgress == ProcessEnum.inProgress).toList();
      if (inProgressLessons.isNotEmpty) {
        selectedLesson = inProgressLessons.last;
      } else {
        selectedLesson = display.lastWhere(
          (lesson) => lesson.roadmapProgress != ProcessEnum.notStarted,
          orElse: () => display.first,
        );
      }
    }

    CourseLevel selectedLevel = fallbackLevel;
    for (final level in levels) {
      if (level.roadmapLessonsList.any((lesson) => lesson.isSameLesson(selectedLesson))) {
        selectedLevel = level.level;
        break;
      }
    }

    return MapEntry(selectedLesson, selectedLevel);
  }

  int get lastCompletedLevelIndex {
    for (int i = levels.length - 1; i >= 0; i--) {
      if (levels.elementAt(i).isCompleted) return i + 1;
    }
    return -1;
  }

  bool usingAppProgressLessons(int levelIndex) {
    if (levelIndex == 0) return true;
    if (lastCompletedLevelIndex == -1) return false;
    return levelIndex <= lastCompletedLevelIndex;
  }

  List<bool> get levelSequentialUnlockFlags {
    bool previousLevelsCompleted = true;
    return levels.map((level) {
      final enableSequentialUnlock = level.hasRoadmapProgress || previousLevelsCompleted;
      previousLevelsCompleted = previousLevelsCompleted && level.isRoadmapCompleted;
      return enableSequentialUnlock;
    }).toList();
  }

  int get totalLessons => levels.fold(0, (sum, level) => sum + level.totalLessons);

  int lockedLessonStartIndexForLevel({
    required PaywallConfigEntity paywallConfig,
    required int levelIndex,
  }) {
    if (levelIndex < 0 || levelIndex >= levels.length) return -1;
    if (!paywallConfig.enableLessonLock) return -1;

    final totalLessonsInLevel = levels[levelIndex].totalLessons;
    int lessonOffset = 0;
    for (int i = 0; i < levelIndex; i++) {
      lessonOffset += levels[i].totalLessons;
    }

    if (paywallConfig.lessonLock <= lessonOffset) return 0;
    if (paywallConfig.lessonLock >= lessonOffset + totalLessonsInLevel) return -1;
    return paywallConfig.lessonLock - lessonOffset;
  }
}
