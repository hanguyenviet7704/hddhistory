part of '../../roleplay.dart';

@freezed
abstract class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    @Default('') String name,
    @Default('') String avartar,
    @Default(SectionConversationPosition.left) SectionConversationPosition position,
    @Default('') String backgroundColor,
    @Default('') String textColor,
    @Default('') String content,
    @Default('') String audio,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) => _$ConversationModelFromJson(json);
}

extension ConversationModelExtension on ConversationModel {
  ConversationEntity toEntity() => ConversationEntity(
    name: name,
    avartar: avartar,
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
