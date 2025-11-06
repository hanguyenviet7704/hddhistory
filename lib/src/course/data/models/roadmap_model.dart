part of '../../course.dart';

@freezed
abstract class RoadmapModel with _$RoadmapModel {
  const factory RoadmapModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String courseId,
    @Default([]) List<RoadmapNodeModel> node,
    @Default([]) List<LessonModel> lessonList,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoadmapModel;

  factory RoadmapModel.fromJson(Map<String, dynamic> json) => _$RoadmapModelFromJson(json);
}

extension RoadmapModelExtension on RoadmapModel {
  RoadmapEntity toEntity() => RoadmapEntity(
    id: id,
    courseId: courseId,
    node: node.map((model) => model.toEntity()).toList(),
    lessonList: lessonList.map((model) => model.toEntity()).toList(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
