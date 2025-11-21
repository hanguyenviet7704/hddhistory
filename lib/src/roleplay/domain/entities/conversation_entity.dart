part of '../../roleplay.dart';

@freezed
abstract class ConversationEntity with _$ConversationEntity {
  const factory ConversationEntity({
    @Default(ConversationAvatarEntity()) ConversationAvatarEntity avatar,
    @Default(SectionConversationPosition.left) SectionConversationPosition position,
    @Default('') String backgroundColor,
    @Default('') String textColor,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default(BaseMultiLanguage()) BaseMultiLanguage audio,
  }) = _ConversationEntity;

  factory ConversationEntity.fromJson(Map<String, dynamic> json) => _$ConversationEntityFromJson(json);
}
