part of '../../home.dart';

@freezed
abstract class HomeBannerSlideModel with _$HomeBannerSlideModel {
  const factory HomeBannerSlideModel({
    @Default('') String imageUrl,
    @Default('') String linkUrl,
    // 16-hex content hash of the creative, used to key impression/click
    // tracking. Defaults to '' for a server predating this field, which
    // tracking treats as "skip" rather than firing with a blank key.
    @Default('') String campaignKey,
  }) = _HomeBannerSlideModel;

  factory HomeBannerSlideModel.fromJson(Map<String, dynamic> json) => _$HomeBannerSlideModelFromJson(json);
}

extension HomeBannerSlideModelX on HomeBannerSlideModel {
  HomeBannerSlideEntity toEntity() => HomeBannerSlideEntity(imageUrl: imageUrl, linkUrl: linkUrl, campaignKey: campaignKey);
}

@freezed
abstract class HomeBannerModel with _$HomeBannerModel {
  const factory HomeBannerModel({
    @Default(false) bool enabled,
    @Default('') String imageUrl,
    @Default('') String linkUrl,
    @Default(<String>[]) List<String> countries,
    // The carousel, already filtered to this viewer's markets and in display
    // order. Empty from an API that predates it — see
    // [HomeBannerEntityX.effectiveSlides], which then falls back to the single
    // banner so the rollout order is not load-bearing in either direction.
    @Default(<HomeBannerSlideModel>[]) List<HomeBannerSlideModel> slides,
    // NULLABLE on purpose, so "the server did not send this" is distinguishable
    // from "the server said hide". An API that predates country targeting sends
    // nothing here; defaulting that to false would blank every banner in the
    // wild the moment this app shipped, and make the rollout order load-bearing.
    bool? visible,
  }) = _HomeBannerModel;

  factory HomeBannerModel.fromJson(Map<String, dynamic> json) => _$HomeBannerModelFromJson(json);
}

extension HomeBannerModelX on HomeBannerModel {
  HomeBannerEntity toEntity() => HomeBannerEntity(
        enabled: enabled,
        imageUrl: imageUrl,
        linkUrl: linkUrl,
        countries: countries,
        visible: visible,
        slides: slides.map((slide) => slide.toEntity()).toList(),
      );
}
