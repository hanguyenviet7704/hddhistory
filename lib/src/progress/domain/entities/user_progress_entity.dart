part of '../../progress.dart';

@freezed
abstract class UserProgressEntity with _$UserProgressEntity {
  const factory UserProgressEntity({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String courseId,
    @Default([]) List<LessonResultEntity> lessonsResult,
    @Default([]) List<CompletedLevelEntity> completedLevels,
  }) = _UserProgressEntity;

  factory UserProgressEntity.fromJson(Map<String, dynamic> json) => _$UserProgressEntityFromJson(json);
}

extension UserProgressEntityCompletedLevelRequestExtension on UserProgressEntity {
  CompletedLevelEntity? completedLevelFor(CourseLevel level) {
    for (final completedLevel in completedLevels) {
      if (completedLevel.level == level) return completedLevel;
    }
    return null;
  }

  UserProgressEntity withCompletedLevelAdditionalContentRequest({
    required CourseLevel level,
    required bool requested,
    required String requestText,
    required String fallbackUserId,
    required String fallbackCourseId,
    DateTime? submittedAt,
  }) {
    final resolvedSubmittedAt = submittedAt ?? DateTime.now();
    final request = CompletedLevelAdditionalContentRequestEntity(
      requested: requested,
      requestText: requestText,
      submittedAt: resolvedSubmittedAt,
    );
    final existingIndex = completedLevels.indexWhere((completedLevel) => completedLevel.level == level);
    final nextCompletedLevels = [...completedLevels];
    if (existingIndex == -1) {
      nextCompletedLevels.add(
        CompletedLevelEntity(
          level: level,
          completedAt: resolvedSubmittedAt,
          additionalContentRequest: request,
        ),
      );
    } else {
      nextCompletedLevels[existingIndex] = nextCompletedLevels[existingIndex].copyWith(
        additionalContentRequest: request,
      );
    }

    return copyWith(
      userId: userId.isNotEmpty ? userId : fallbackUserId,
      courseId: courseId.isNotEmpty ? courseId : fallbackCourseId,
      completedLevels: nextCompletedLevels,
    );
  }
}
