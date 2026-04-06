part of '../../course.dart';

@freezed
abstract class RoadmapNodeEntity with _$RoadmapNodeEntity {
  const factory RoadmapNodeEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String openingVideoId,
    @Default('') String roleplayId,
    @Default([]) List<String> lessonIds,
    @Default('') String outputId,
    @Default('') String closingVideoId,
    @Default(LessonEntity()) LessonEntity openingVideo,
    @Default(LessonEntity()) LessonEntity roleplay,
    @Default([]) List<LessonEntity> lessons,
    @Default(LessonEntity()) LessonEntity output,
    @Default(LessonEntity()) LessonEntity closingVideo,
  }) = _RoadmapNodeEntity;

  factory RoadmapNodeEntity.fromJson(Map<String, dynamic> json) => _$RoadmapNodeEntityFromJson(json);
}

extension RoadmapNodeEntityExtension on RoadmapNodeEntity {
  List<LessonEntity> get lessonsList => [
    if (openingVideo.id.isNotEmpty) openingVideo,
    if (roleplay.id.isNotEmpty) roleplay,
    ...lessons.expand((lesson) => lesson.lessonsPerKeypoint),
    if (output.id.isNotEmpty) output,
    if (closingVideo.id.isNotEmpty) closingVideo,
  ];

  int get totalLessons => lessons.length;
  int get completedLessons => lessons.where((r) => r.progess == ProcessEnum.done).length;
  double get progress {
    if (totalLessons == 0) return 0;
    if (completedLessons >= totalLessons) return 1;
    return completedLessons / totalLessons;
  }

  bool get isCompleted => completedLessons >= totalLessons;
}
