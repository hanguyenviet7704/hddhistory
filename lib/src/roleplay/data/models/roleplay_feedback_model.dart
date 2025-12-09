part of '../../roleplay.dart';

@freezed
abstract class RoleplayFeedbackModel with _$RoleplayFeedbackModel {
  const factory RoleplayFeedbackModel({
    @Default('') @JsonKey(name: 'feedback_text') String feedbackText,
    @Default(0) @JsonKey(name: 'time_gpt') double timeGpt,
  }) = _RoleplayFeedbackModel;

  factory RoleplayFeedbackModel.fromJson(Map<String, dynamic> json) => _$RoleplayFeedbackModelFromJson(json);
}

extension RoleplayFeedbackModelExtension on RoleplayFeedbackModel {
  RoleplayFeedbackEntity toEntity() => RoleplayFeedbackEntity(
    timeGpt: timeGpt,
    feedbackText: feedbackText,
  );
}