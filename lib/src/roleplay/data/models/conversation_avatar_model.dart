part of '../../roleplay.dart';

@freezed
abstract class ConversationAvatarModel with _$ConversationAvatarModel {
  const factory ConversationAvatarModel({
    @Default('') String name,
    @Default('') String url,
  }) = _ConversationAvatarModel;

  factory ConversationAvatarModel.fromJson(Map<String, dynamic> json) => _$ConversationAvatarModelFromJson(json);
}

extension ConversationAvatarModelExtension on ConversationAvatarModel {
  ConversationAvatarEntity toEntity() => ConversationAvatarEntity(
    name: name,
    url: url,
  );
}