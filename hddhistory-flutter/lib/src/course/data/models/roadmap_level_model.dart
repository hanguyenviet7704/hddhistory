part of '../../course.dart';

@freezed
abstract class RoadmapLevelModel with _$RoadmapLevelModel {
  const factory RoadmapLevelModel({
    @Default(0) int id,
    @JsonKey(unknownEnumValue: CourseLevel.unknown) @Default(CourseLevel.level1) CourseLevel level,
    @Default('') String lightBadge,
    @Default('') String darkBadge,
    @Default(BaseMultiLanguage()) BaseMultiLanguage titleBadge,
    @Default([]) List<String> keypointIds,
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
  @JsonValue('unknown')
  unknown;

  String get name => switch (this) {
    level1 => 'Level 1',
    level2 => 'Level 2',
    unknown => 'Unknown',
  };

  String get number => name.split(' ').last;
}

extension RoadmapLevelModelExtension on RoadmapLevelModel {
  RoadmapLevelEntity toEntity() => RoadmapLevelEntity(
    id: id,
    level: level,
    lightBadge: lightBadge,
    darkBadge: darkBadge,
    titleBadge: titleBadge,
    keypointIds: keypointIds,
    nodes: nodes.map((model) => model.toEntity()).toList(),
    lessonList: lessonList.map((model) => model.toEntity()).toList(),
  );
}
