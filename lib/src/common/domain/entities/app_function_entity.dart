part of '../../common.dart';

@freezed
abstract class AppFunctionEntity with _$AppFunctionEntity {
  const factory AppFunctionEntity({
    @Default(false) bool iap,
    @Default(false) bool roadmap,
    @Default(false) bool showFeedback,
  }) = _AppFunctionEntity;

  factory AppFunctionEntity.fromJson(Map<String, dynamic> json) => _$AppFunctionEntityFromJson(json);
}
