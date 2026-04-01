part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeConversationUsageEntity with _$OutputPracticeConversationUsageEntity {
  const factory OutputPracticeConversationUsageEntity({
    @Default(0) int remainingInThisMonth,
    @Default(0) int monthlyLimit,
  }) = _OutputPracticeConversationUsageEntity;

  factory OutputPracticeConversationUsageEntity.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeConversationUsageEntityFromJson(json);
}

extension OutputPracticeConversationUsageEntityX on OutputPracticeConversationUsageEntity {
  bool get hasReachedLimit => remainingInThisMonth <= 0 && monthlyLimit > 0;
}
