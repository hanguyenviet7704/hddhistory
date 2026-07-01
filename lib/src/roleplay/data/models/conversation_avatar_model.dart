part of '../../roleplay.dart';

@freezed
abstract class ConversationAvatarModel with _$ConversationAvatarModel {
  const factory ConversationAvatarModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String name,
    @Default('') String url,
    @Default('') String thumbnailUrl,
  }) = _ConversationAvatarModel;

  factory ConversationAvatarModel.fromJson(Map<String, dynamic> json) => _$ConversationAvatarModelFromJson(json);
}

extension ConversationAvatarModelExtension on ConversationAvatarModel {
  ConversationAvatarEntity toEntity() => ConversationAvatarEntity(
    id: id,
    name: name,
    url: url,
    thumbnailUrl: thumbnailUrl,
  );
}
