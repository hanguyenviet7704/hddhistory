part of '../../roleplay.dart';

@freezed
abstract class ConversationAvatarEntity with _$ConversationAvatarEntity {
  const factory ConversationAvatarEntity({
    @Default('') String name,
    @Default('') String url,
  }) = _ConversationAvatarEntity;

  factory ConversationAvatarEntity.fromJson(Map<String, dynamic> json) => _$ConversationAvatarEntityFromJson(json);
}
