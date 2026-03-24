part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeAiReplyOptionEntity with _$OutputPracticeAiReplyOptionEntity {
  const factory OutputPracticeAiReplyOptionEntity({
    @Default(0) int value,
    @Default('') String label,
    @Default('') String description,
  }) = _OutputPracticeAiReplyOptionEntity;

  factory OutputPracticeAiReplyOptionEntity.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeAiReplyOptionEntityFromJson(json);
}
