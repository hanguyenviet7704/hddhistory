part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeConversationUsageModel with _$OutputPracticeConversationUsageModel {
  const factory OutputPracticeConversationUsageModel({
    @Default(0) int remainingInThisMonth,
    @Default(0) int monthlyLimit,
  }) = _OutputPracticeConversationUsageModel;

  factory OutputPracticeConversationUsageModel.fromJson(Map<String, dynamic> json) => _$OutputPracticeConversationUsageModelFromJson(json);
}

extension OutputPracticeConversationUsageModelExtension on OutputPracticeConversationUsageModel {
  OutputPracticeConversationUsageEntity toEntity() => OutputPracticeConversationUsageEntity(
    remainingInThisMonth: remainingInThisMonth,
    monthlyLimit: monthlyLimit,
  );
}
