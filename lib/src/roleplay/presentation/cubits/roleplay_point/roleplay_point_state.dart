part of '../../../roleplay.dart';

enum RoleplayPointStatus { initial, loading, success, failure }

@freezed
sealed class RoleplayPointEntity with _$RoleplayPointEntity {
  const factory RoleplayPointEntity({
    @Default(KeypointEntity()) KeypointEntity keypoint,
    @Default(0) int point,
  }) = _RoleplayPointEntity;

  factory RoleplayPointEntity.fromJson(Map<String, dynamic> json) => _$RoleplayPointEntityFromJson(json);
}

@freezed
abstract class RoleplayPointState with _$RoleplayPointState {
  const factory RoleplayPointState({
    @Default(RoleplayPointStatus.initial) RoleplayPointStatus status,
    @Default([]) List<RoleplayPointEntity> points,
  }) = _RoleplayPointState;

  factory RoleplayPointState.initial() => RoleplayPointState(points: []);

  factory RoleplayPointState.fromJson(Map<String, dynamic> json) => _$RoleplayPointStateFromJson(json);
}



