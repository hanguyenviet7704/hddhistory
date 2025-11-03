part of '../../roadmap.dart';

@freezed
abstract class RoadmapEntity with _$RoadmapEntity {
  const factory RoadmapEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoadmapEntity;

  factory RoadmapEntity.fromJson(Map<String, dynamic> json) => _$RoadmapEntityFromJson(json);
}
