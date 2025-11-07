part of '../../roleplay.dart';

@freezed
abstract class ConversationEntity with _$ConversationEntity {
  const factory ConversationEntity({
    @Default('') String name,
    @Default('') String avartar,
    @Default(SectionConversationPosition.left) SectionConversationPosition position,
    @Default('') String bubbleColor,
    @Default('') String textColor,
    @Default('') String content,
    @Default('') String audio,
  }) = _ConversationEntity;

  factory ConversationEntity.fromJson(Map<String, dynamic> json) => _$ConversationEntityFromJson(json);
}
