part of '../../roleplay.dart';

@freezed
abstract class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    @Default(ConversationAvatarModel()) ConversationAvatarModel avatar,
    @Default(SectionConversationPosition.left) SectionConversationPosition position,
    @Default('') String backgroundColor,
    @Default('') String textColor,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default('') String audio,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) => _$ConversationModelFromJson(json);
}

extension ConversationModelExtension on ConversationModel {
  ConversationEntity toEntity() => ConversationEntity(
    avatar: avatar.toEntity(),
    position: position,
    backgroundColor: backgroundColor,
    textColor: textColor,
    content: content,
    audio: audio,
  );
}

enum SectionConversationPosition {
  @JsonValue('left')
  left,
  @JsonValue('right')
  right,
}
