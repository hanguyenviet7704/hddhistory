part of '../../course.dart';

@freezed
abstract class RoadmapModel with _$RoadmapModel {
  const factory RoadmapModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String courseId,
    @Default([]) List<RoadmapLevelModel> levels,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseDescription,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoadmapModel;

  factory RoadmapModel.fromJson(Map<String, dynamic> json) => _$RoadmapModelFromJson(json);
}

extension RoadmapModelExtension on RoadmapModel {
  RoadmapEntity toEntity() => RoadmapEntity(
    id: id,
    courseId: courseId,
    levels: levels.map((model) => model.toEntity()).toList(),
    courseDescription: courseDescription,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
