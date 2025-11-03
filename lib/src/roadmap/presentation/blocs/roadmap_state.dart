part of '../../roadmap.dart';

enum RoadmapStatus { initial, loading, success, failure }

@freezed
abstract class RoadmapState with _$RoadmapState {
  const factory RoadmapState({
    @Default(RoadmapStatus.initial) RoadmapStatus status,
    @Default(BasePageBreak<RoadmapEntity>()) BasePageBreak<RoadmapEntity> pageData,
    RoadmapEntity? selectedItem,
    String? errorMessage,
  }) = _RoadmapState;

  factory RoadmapState.initial() => RoadmapState();

  factory RoadmapState.fromJson(Map<String, dynamic> json) => _$RoadmapStateFromJson(json);
}
