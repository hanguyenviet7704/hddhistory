part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeConversationEntity with _$OutputPracticeConversationEntity {
  const factory OutputPracticeConversationEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OutputPracticeConversationEntity;

  factory OutputPracticeConversationEntity.fromJson(Map<String, dynamic> json) => _$OutputPracticeConversationEntityFromJson(json);
}

