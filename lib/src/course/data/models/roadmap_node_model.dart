part of '../../course.dart';

@freezed
abstract class RoadmapNodeModel with _$RoadmapNodeModel {
  const factory RoadmapNodeModel({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String roleplayId,
    @Default([]) List<String> lessonIds,
    @Default('') String outputId,
    @Default(LessonModel()) LessonModel roleplay,
    @Default([]) List<LessonModel> lessons,
    @Default(LessonModel()) LessonModel output,
  }) = _RoadmapNodeModel;

  factory RoadmapNodeModel.fromJson(Map<String, dynamic> json) => _$RoadmapNodeModelFromJson(json);
}

extension RoadmapNodeModelExtension on RoadmapNodeModel {
  RoadmapNodeEntity toEntity() => RoadmapNodeEntity(
    id: id,
    title: title,
    description: description,
    roleplayId: roleplayId,
    lessonIds: lessonIds,
    outputId: outputId,
    roleplay: roleplay.toEntity(),
    lessons: lessons.map((model) => model.toEntity()).toList(),
    output: output.toEntity(),
  );
}
