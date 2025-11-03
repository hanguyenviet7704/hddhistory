part of '../../roadmap.dart';

@freezed
abstract class RoadmapModel with _$RoadmapModel {
  const factory RoadmapModel({
    required String id,
    required String courseId,
    required List<RoadmapNodeModel> node,
    required List<LessonModel> lessonList,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RoadmapModel;

  factory RoadmapModel.fromJson(Map<String, dynamic> json) => _$RoadmapModelFromJson(json);
}

extension RoadmapModelExtension on RoadmapModel {
  RoadmapEntity toEntity() => RoadmapEntity(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
