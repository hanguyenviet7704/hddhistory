part of '../../home.dart';

@freezed
abstract class HomeBannerModel with _$HomeBannerModel {
  const factory HomeBannerModel({
    @Default(false) bool enabled,
    @Default('') String imageUrl,
    @Default('') String linkUrl,
    @Default(<String>[]) List<String> countries,
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
      );
}
