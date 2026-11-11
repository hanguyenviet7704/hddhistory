part of '../../home.dart';

@freezed
abstract class HomePopupModel with _$HomePopupModel {
  const factory HomePopupModel({
    @Default(false) bool enabled,
    @Default('') String imageUrl,
    @Default('') String linkUrl,
    @Default('') String campaignKey,
    // NULLABLE on purpose: "the server did not send this" must stay
    // distinguishable from "the server said hide" — see
    // [HomePopupEntityX.isVisible], which refuses to show anything on silence.
    bool? visible,
  }) = _HomePopupModel;

  factory HomePopupModel.fromJson(Map<String, dynamic> json) => _$HomePopupModelFromJson(json);
}

extension HomePopupModelX on HomePopupModel {
  HomePopupEntity toEntity() => HomePopupEntity(
        enabled: enabled,
        imageUrl: imageUrl,
        linkUrl: linkUrl,
        campaignKey: campaignKey,
        visible: visible,
      );
}

/// Reply to the tap. Only interesting for logging: the app has already closed the
/// popup and opened the link by the time this lands.
@freezed
abstract class HomePopupClickResultModel with _$HomePopupClickResultModel {
  const factory HomePopupClickResultModel({
    @Default(false) bool recorded,
  }) = _HomePopupClickResultModel;

  factory HomePopupClickResultModel.fromJson(Map<String, dynamic> json) => _$HomePopupClickResultModelFromJson(json);
}
