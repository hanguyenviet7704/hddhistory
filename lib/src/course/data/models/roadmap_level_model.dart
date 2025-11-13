part of '../../course.dart';

@freezed
abstract class RoadmapLevelModel with _$RoadmapLevelModel {
  const factory RoadmapLevelModel({
    @Default(0) int id,
    @Default(CourseLevel.level1) CourseLevel level,
    @Default([]) List<RoadmapNodeModel> nodes,
    @Default([]) List<LessonModel> lessonList,
  }) = _RoadmapLevelModel;

  factory RoadmapLevelModel.fromJson(Map<String, dynamic> json) => _$RoadmapLevelModelFromJson(json);
}

enum CourseLevel {
  @JsonValue('level 1')
  level1,
  @JsonValue('level 2')
  level2,
}

extension RoadmapLevelModelExtension on RoadmapLevelModel {
  RoadmapLevelEntity toEntity() => RoadmapLevelEntity(
    id: id,
    level: level,
    nodes: nodes.map((model) => model.toEntity()).toList(),
    lessonList: lessonList.map((model) => model.toEntity()).toList(),
  );
}
