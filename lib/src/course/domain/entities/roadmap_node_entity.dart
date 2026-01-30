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

  List<LessonEntity> get lessonsList => [
    roleplay,
    ...lessons.expand((lesson) => lesson.lessonsPerKeypoint),
    output,
  ];
}
