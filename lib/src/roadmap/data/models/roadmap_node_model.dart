part of '../../roadmap.dart';

@freezed
abstract class RoadmapNodeModel with _$RoadmapNodeModel {
  const factory RoadmapNodeModel({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String entranceId,
    @Default([]) List<String> lessonIds,
    @Default('') String outputId,
    @Default(LessonModel()) LessonModel entrance,
    @Default([]) List<LessonModel> lessons,
    @Default(LessonModel()) LessonModel output,
  }) = _RoadmapNodeModel;

  factory RoadmapNodeModel.fromJson(Map<String, dynamic> json) => _$RoadmapNodeModelFromJson(json);
}