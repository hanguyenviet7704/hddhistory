part of '../../course.dart';

@freezed
abstract class RoadmapNodeEntity with _$RoadmapNodeEntity {
  const factory RoadmapNodeEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String roleplayId,
    @Default([]) List<String> lessonIds,
    @Default('') String outputId,
    @Default(LessonEntity()) LessonEntity roleplay,
    @Default([]) List<LessonEntity> lessons,
    @Default(LessonEntity()) LessonEntity output,
  }) = _RoadmapNodeEntity;

  factory RoadmapNodeEntity.fromJson(Map<String, dynamic> json) => _$RoadmapNodeEntityFromJson(json);
}

extension RoadmapNodeEntityExtension on RoadmapNodeEntity {
  int get totalLessons => lessons.length;
  int get completedLessons => lessons.where((r) => r.progess == ProcessEnum.done).length;
  double get progress {
    if (totalLessons == 0) return 0;
    if (completedLessons >= totalLessons) return 1;
    return completedLessons / totalLessons;
  }

  bool get isCompleted => completedLessons >= totalLessons;

  List<LessonEntity> get lessonsList => [roleplay, ...lessons, output];

  LessonEntity resolveRoleplay(List<LessonEntity> levelLessons) {
    if (roleplay.id.isNotEmpty) return roleplay;
    return _resolveLessonById(levelLessons, roleplayId);
  }

  LessonEntity resolveOutput(List<LessonEntity> levelLessons) {
    if (output.id.isNotEmpty) return output;
    return _resolveLessonById(levelLessons, outputId);
  }

  List<LessonEntity> resolveLessons(List<LessonEntity> levelLessons) {
    if (lessonIds.isNotEmpty) {
      return lessonIds.map((id) => _resolveLessonById(levelLessons, id)).where((lesson) => lesson.id.isNotEmpty).toList();
    }
    return lessons;
  }

  List<LessonEntity> flattenKeypoints(List<LessonEntity> resolvedLessons) {
    final List<LessonEntity> flattened = [];
    for (final lesson in resolvedLessons) {
      if (lesson.keypoints.isNotEmpty) {
        flattened.add(lesson);
        continue;
      }
      
      for (final keypoint in lesson.keypoints) {
        flattened.add(
          lesson.copyWith(
            id: lesson.id,
            title: keypoint.title,
            description: keypoint.description,
            estimateCompleTime: keypoint.estimateCompleTime,
            progess: keypoint.progess,
            type: LessonType.lesson,
            keypoints: [],
          ),
        );
      }
    }
    return flattened;
  }

  List<LessonEntity> timelineItems(List<LessonEntity> levelLessons) {
    final roleplayLesson = resolveRoleplay(levelLessons);
    final outputLesson = resolveOutput(levelLessons);
    final flattenedLessons = flattenKeypoints(resolveLessons(levelLessons));

    return [
      if (roleplayLesson.id.isNotEmpty) roleplayLesson,
      ...flattenedLessons,
      if (outputLesson.id.isNotEmpty) outputLesson,
    ];
  }

  LessonEntity _resolveLessonById(List<LessonEntity> levelLessons, String lessonId) {
    if (lessonId.isEmpty) return const LessonEntity();
    return levelLessons.firstWhere(
      (lesson) => lesson.id == lessonId,
      orElse: () => const LessonEntity(),
    );
  }
}
