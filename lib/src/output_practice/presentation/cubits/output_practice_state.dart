part of '../../output_practice.dart';

enum OutputPracticeStatus { initial, loading, success, failure }

@freezed
abstract class OutputPracticeState with _$OutputPracticeState {
  const factory OutputPracticeState({
    @Default(OutputPracticeStatus.initial) OutputPracticeStatus status,
    @Default(BasePageBreak<OutputPracticeMessageEntity>()) BasePageBreak<OutputPracticeMessageEntity> messagesPageData,
    OutputPracticeConversationEntity? conversation,
    String? errorMessage,
  }) = _OutputPracticeState;

  factory OutputPracticeState.initial() => const OutputPracticeState();

  factory OutputPracticeState.fromJson(Map<String, dynamic> json) => _$OutputPracticeStateFromJson(json);
}
