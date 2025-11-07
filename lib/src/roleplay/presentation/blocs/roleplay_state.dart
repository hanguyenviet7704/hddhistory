part of '../../roleplay.dart';

enum RoleplayStatus { initial, loading, success, failure }

@freezed
abstract class RoleplayState with _$RoleplayState {
  const factory RoleplayState({
    @Default(RoleplayStatus.initial) RoleplayStatus status,
    @Default(BasePageBreak<SectionEntity>()) BasePageBreak<SectionEntity> pageData,
    SectionEntity? selectedItem,
    String? errorMessage,
  }) = _RoleplayState;

  factory RoleplayState.initial() => RoleplayState();

  factory RoleplayState.fromJson(Map<String, dynamic> json) => _$RoleplayStateFromJson(json);
}
