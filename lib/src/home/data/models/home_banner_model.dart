part of '../../home.dart';

@freezed
abstract class HomeBannerModel with _$HomeBannerModel {
  const factory HomeBannerModel({
    @Default(false) bool enabled,
    @Default('') String imageUrl,
    @Default('') String linkUrl,
  }) = _HomeBannerModel;

  factory HomeBannerModel.fromJson(Map<String, dynamic> json) => _$HomeBannerModelFromJson(json);
}

extension HomeBannerModelX on HomeBannerModel {
  HomeBannerEntity toEntity() => HomeBannerEntity(
        enabled: enabled,
        imageUrl: imageUrl,
        linkUrl: linkUrl,
      );
}
