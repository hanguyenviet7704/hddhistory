part of '../../roleplay.dart';

@freezed
abstract class ConversationAvatarEntity with _$ConversationAvatarEntity {
  const factory ConversationAvatarEntity({
    @Default('') String id,
    @Default('') String name,
    @Default('') String url,
    @Default('') String thumbnailUrl,
  }) = _ConversationAvatarEntity;

  factory ConversationAvatarEntity.fromJson(Map<String, dynamic> json) => _$ConversationAvatarEntityFromJson(json);
}

extension ConversationAvatarEntityExtension on ConversationAvatarEntity {
  /// Preferred image for list/grid/card/avatar thumbnails: the lightweight
  /// [thumbnailUrl] (small WebP) when available, else the full [url].
  String get displayImage => thumbnailUrl.isNotEmpty ? thumbnailUrl : url;
}
