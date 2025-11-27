part of '../../roleplay.dart';

@freezed
abstract class RoleplayFeedbackEntity with _$RoleplayFeedbackEntity {
  const factory RoleplayFeedbackEntity({
    @Default('') String feedbackText,
    @Default(0) double timeGpt,
  }) = _RoleplayFeedbackEntity;

  factory RoleplayFeedbackEntity.fromJson(Map<String, dynamic> json) => _$RoleplayFeedbackEntityFromJson(json);
}
