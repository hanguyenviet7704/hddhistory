part of '../../home.dart';

/// Admin-configured promo popup on Home: one image, tappable, that stops coming
/// back once this reader has tapped it.
///
/// The server owns every part of that decision — kill switch, market targeting,
/// and whether this user already tapped THIS campaign — and answers with
/// [visible]. Nothing here re-derives it.
@freezed
abstract class HomePopupEntity with _$HomePopupEntity {
  const factory HomePopupEntity({
    @Default(false) bool enabled,
    @Default('') String imageUrl,
    @Default('') String linkUrl,

    /// Identity of the creative, echoed back when the reader taps so the server
    /// records the campaign they actually saw. Empty when nothing is configured.
    @Default('') String campaignKey,

    /// The server's decision for THIS reader. Nullable so "an API that predates
    /// the popup said nothing" stays distinguishable from "the server said hide";
    /// [isVisible] treats a silent API as nothing to show, which is the safe
    /// direction for a modal that interrupts.
    bool? visible,
  }) = _HomePopupEntity;

  factory HomePopupEntity.fromJson(Map<String, dynamic> json) => _$HomePopupEntityFromJson(json);
}

extension HomePopupEntityX on HomePopupEntity {
  /// Whether Home should raise the popup.
  ///
  /// Deliberately stricter than the banner's equivalent: the banner falls back to
  /// `enabled` when `visible` is null, because a banner that shows when it should
  /// not is a wasted slot. This one interrupts the reader and, worse, an app
  /// talking to an API without the click endpoint could not retire it — so
  /// silence means do not show.
  ///
  /// The image and key checks are not paranoia: an image-less popup is a blank
  /// modal, and without a key the tap could not be recorded, so it would come
  /// back forever.
  bool get isVisible => (visible ?? false) && imageUrl.isNotEmpty && campaignKey.isNotEmpty;
}
