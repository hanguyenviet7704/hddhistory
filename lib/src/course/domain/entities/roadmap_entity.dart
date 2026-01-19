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

  int get totalLessons => levels.fold(0, (sum, level) => sum + level.totalLessons);
}
