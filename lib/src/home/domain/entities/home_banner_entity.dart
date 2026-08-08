part of '../../home.dart';

@freezed
abstract class HomeBannerEntity with _$HomeBannerEntity {
  const factory HomeBannerEntity({
    @Default(false) bool enabled,
    @Default('') String imageUrl,
    @Default('') String linkUrl,
  }) = _HomeBannerEntity;

  factory HomeBannerEntity.fromJson(Map<String, dynamic> json) => _$HomeBannerEntityFromJson(json);
}

extension HomeBannerEntityX on HomeBannerEntity {
  /// The admin-configured banner may exist but be turned off, or be enabled
  /// with no image yet uploaded — either way there's nothing to render, so
  /// Home collapses the section to zero height instead of showing a broken
  /// or empty card.
  bool get isVisible => enabled && imageUrl.isNotEmpty;
}
