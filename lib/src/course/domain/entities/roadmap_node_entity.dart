part of '../../course.dart';

@freezed
abstract class RoadmapNodeEntity with _$RoadmapNodeEntity {
  const factory RoadmapNodeEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String roleplayId,
    @Default([]) List<String> lessonIds,
    @Default('') String outputId,
    @Default(LessonEntity()) LessonEntity roleplay,
    @Default([]) List<LessonEntity> lessons,
    @Default(LessonEntity()) LessonEntity output,
  }) = _RoadmapNodeEntity;

  factory RoadmapNodeEntity.fromJson(Map<String, dynamic> json) => _$RoadmapNodeEntityFromJson(json);
}

