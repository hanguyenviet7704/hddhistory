part of '../../home.dart';

/// Reply to a fire-and-forget tracking call (banner impression, banner click,
/// popup impression). Only interesting for logging — the app has already
/// acted (painted the slide, opened the link) by the time this lands. Shares
/// its shape with [HomePopupClickResultModel], which plays the same role for
/// the popup's pre-existing click endpoint.
@freezed
abstract class HomeTrackingResultModel with _$HomeTrackingResultModel {
  const factory HomeTrackingResultModel({
    @Default(false) bool recorded,
  }) = _HomeTrackingResultModel;

  factory HomeTrackingResultModel.fromJson(Map<String, dynamic> json) => _$HomeTrackingResultModelFromJson(json);
}
