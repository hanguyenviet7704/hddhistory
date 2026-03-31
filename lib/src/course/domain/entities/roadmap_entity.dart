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
  List<LessonEntity> get flatLessons {
    if (levels.isEmpty) return [];
    final lessons = <LessonEntity>[];
    for (final level in levels) {
      for (final node in level.nodes) {
        lessons.addAll(node.lessonsList);
      }
    }
    return lessons;
  }

  int lockedLessonStartIndex(PaywallConfigEntity config) {
    if (!config.enableLessonLock) return -1;
    if (config.lessonLock < 0) return -1;
    final totalLessons = flatLessons.length;
    if (totalLessons == 0) return -1;
    if (config.lessonLock >= totalLessons) return -1;
    return config.lessonLock;
  }

  Set<String> lockedLessonKeys(PaywallConfigEntity config) {
    final startIndex = lockedLessonStartIndex(config);
    if (startIndex < 0) return {};
    final lessons = flatLessons;
    if (startIndex >= lessons.length) return {};
    return lessons.skip(startIndex).map((lesson) => lesson.roadmapKey).where((key) => key.isNotEmpty).toSet();
  }

  bool isLessonLocked(LessonEntity lesson, PaywallConfigEntity config) {
    final key = lesson.roadmapKey;
    if (key.isEmpty) return false;
    return lockedLessonKeys(config).contains(key);
  }

  List<LessonEntity> get displayLessons {
    if (levels.isEmpty) return [];
    final levelFlags = levelSequentialUnlockFlags;
    final displayLessons = <LessonEntity>[];
    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      final level = levels[levelIndex];
      final enableSequentialUnlock = levelIndex < levelFlags.length ? levelFlags[levelIndex] : false;
      displayLessons.addAll(
        level.resolvedRoadmapLessons(enableSequentialUnlock: enableSequentialUnlock),
      );
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

  LessonEntity nextLessonAfter(LessonEntity current, {bool lessonOnly = true}) {
    if (current.id.isEmpty) return LessonEntity();
    final lessons = displayLessons;
    if (lessons.isEmpty) return LessonEntity();

    final currentIndex = lessons.indexWhere((lesson) => lesson.isSameLesson(current));
    if (currentIndex == -1) return LessonEntity();

    for (int i = currentIndex + 1; i < lessons.length; i++) {
      final next = lessons[i];
      if (!lessonOnly || next.type == LessonType.lesson) {
        return next;
      }
    }

    return LessonEntity();
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
    if (paywallConfig.lessonLock < 0) return -1;

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
