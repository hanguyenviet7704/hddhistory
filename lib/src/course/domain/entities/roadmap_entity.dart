part of '../../course.dart';

@freezed
abstract class ContentExperimentEntity with _$ContentExperimentEntity {
  const factory ContentExperimentEntity({
    @Default('') String key,
    @Default('') String arm,
  }) = _ContentExperimentEntity;

  factory ContentExperimentEntity.fromJson(Map<String, dynamic> json) =>
      _$ContentExperimentEntityFromJson(json);
}

@freezed
abstract class RoadmapEntity with _$RoadmapEntity {
  const factory RoadmapEntity({
    @Default('') String id,
    @Default('') String courseId,
    @Default([]) List<RoadmapLevelEntity> levels,

    /// The course blurb for the roadmap header. Carried on the roadmap because
    /// the course LIST payload deliberately omits `description` (5 languages,
    /// ~30% of /categories, and no list surface renders it).
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseDescription,

    /// Nhánh A/B nội dung của người này ở khoá này. App PHẢI đóng dấu `key` và
    /// `arm` lên event học tập — không có nó thì bảng kết quả toàn số 0 và
    /// trông y như "hai bản không khác gì nhau".
    ContentExperimentEntity? contentExperiment,
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

  /// Course-wide totals for the roadmap header (design `3 · Learning` → Course
  /// detail). The per-level figures on [RoadmapLevelEntity] answer a different
  /// question — the header speaks for the whole course, and a course can hold
  /// more than one level.
  int get totalLessonCount => levels.fold<int>(0, (sum, level) => sum + level.totalLessons);

  int get completedLessonCount => levels.fold<int>(0, (sum, level) => sum + level.completedLessons);

  double get courseProgress {
    final total = totalLessonCount;
    if (total == 0) return 0;
    return (completedLessonCount / total).clamp(0.0, 1.0);
  }

  /// Minutes of unfinished material.
  ///
  /// Counts what is LEFT rather than the course total: the header sits above a
  /// roadmap the reader is part-way down, and "48 min left" is the number that
  /// tells them whether to start now.
  ///
  /// Sums [LessonEntity.roadmapMinutes] — the KEYPOINT's estimate — because a
  /// roadmap row is a keypoint and that is the field content fills. Summing the
  /// lesson-level estimate reads zero on every course.
  int get minutesLeft => flatLessons.where((lesson) => lesson.roadmapProgress != ProcessEnum.done).fold<int>(0, (sum, lesson) => sum + lesson.roadmapMinutes);

  /// Whether the estimate is worth printing. A finished course legitimately has
  /// zero left, and a course whose lessons carry no estimate also sums to zero
  /// — neither should render "0 min left", so the header drops the whole clause.
  bool get hasMinutesLeft => minutesLeft > 0;

  int lockedLessonStartIndex(PaywallConfigEntity config) {
    if (!config.enableLessonLock) return -1;
    if (config.lessonLock < 0) return -1;
    final totalLessons = flatLessons.length;
    if (totalLessons == 0) return -1;
    if (config.lessonLock >= totalLessons) return -1;
    return config.lessonLock;
  }

  /// A premium user is never locked out of any lesson, regardless of the
  /// remote-config lock index — this must be checked here, at the single
  /// source both the roadmap list's lock badge and the tap-to-open gate read
  /// from, so the two can't disagree (previously only the tap gate checked
  /// premium, in RoadmapNodeActionHelper._handlePaywall, leaving the visual
  /// badge showing "locked" on lessons a premium user could already open).
  Set<String> lockedLessonKeys(PaywallConfigEntity config, {bool isPremium = false}) {
    if (isPremium) return {};
    final startIndex = lockedLessonStartIndex(config);
    if (startIndex < 0) return {};
    final lessons = flatLessons;
    if (startIndex >= lessons.length) return {};
    return lessons.skip(startIndex).map((lesson) => lesson.roadmapKey).where((key) => key.isNotEmpty).toSet();
  }

  bool isLessonLocked(LessonEntity lesson, PaywallConfigEntity config, {bool isPremium = false}) {
    final key = lesson.roadmapKey;
    if (key.isEmpty) return false;
    return lockedLessonKeys(config, isPremium: isPremium).contains(key);
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

  bool get isAllCurrentRoadmapContentCompleted {
    if (levels.isEmpty) return false;
    return levels.every((level) => level.isRoadmapCompleted);
  }

  RoadmapLevelEntity? get latestCompletedRoadmapLevel {
    for (int i = levels.length - 1; i >= 0; i--) {
      final level = levels[i];
      if (level.isRoadmapCompleted) return level;
    }
    return null;
  }

  CompletedLevelAdditionalContentRequestPromptStatus additionalContentRequestStateFor({
    required CourseLevel level,
    required UserProgressEntity userProgress,
  }) {
    if (level == CourseLevel.unknown) return CompletedLevelAdditionalContentRequestPromptStatus.hidden;
    if (!isAllCurrentRoadmapContentCompleted) return CompletedLevelAdditionalContentRequestPromptStatus.hidden;
    if (latestCompletedRoadmapLevel?.level != level) return CompletedLevelAdditionalContentRequestPromptStatus.hidden;
    if (courseId.isNotEmpty && userProgress.courseId != courseId) {
      return CompletedLevelAdditionalContentRequestPromptStatus.hidden;
    }

    final completedLevel = userProgress.completedLevelFor(level);
    final request = completedLevel?.additionalContentRequest;
    if (request == null) return CompletedLevelAdditionalContentRequestPromptStatus.available;
    return request.requested ? CompletedLevelAdditionalContentRequestPromptStatus.requested : CompletedLevelAdditionalContentRequestPromptStatus.hidden;
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

enum CompletedLevelAdditionalContentRequestPromptStatus {
  hidden,
  available,
  requested;

  bool get isVisible => this != hidden;
  bool get isRequested => this == requested;
}
