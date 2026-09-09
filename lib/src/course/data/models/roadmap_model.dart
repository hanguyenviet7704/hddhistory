part of '../../course.dart';

/// Nhánh A/B nội dung mà server đã chia cho người này ở khoá này. `null` khi
/// khoá không nằm trong đợt nào, hoặc người này bị loại khỏi đợt (khách không
/// có id ổn định, hoặc đã học khoá này từ trước khi đợt mở).
@freezed
abstract class ContentExperimentModel with _$ContentExperimentModel {
  const factory ContentExperimentModel({
    @Default('') String key,
    @Default('') String arm,
  }) = _ContentExperimentModel;

  factory ContentExperimentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentExperimentModelFromJson(json);
}

extension ContentExperimentModelExtension on ContentExperimentModel {
  ContentExperimentEntity toEntity() =>
      ContentExperimentEntity(key: key, arm: arm);
}

@freezed
abstract class RoadmapModel with _$RoadmapModel {
  const factory RoadmapModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String courseId,
    @Default([]) List<RoadmapLevelModel> levels,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseDescription,
    ContentExperimentModel? contentExperiment,
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
    contentExperiment: contentExperiment?.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
