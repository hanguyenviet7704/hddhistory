part of '../../home.dart';

@freezed
abstract class HomeBannerEntity with _$HomeBannerEntity {
  const factory HomeBannerEntity({
    @Default(false) bool enabled,
    @Default('') String imageUrl,
    @Default('') String linkUrl,

    /// ISO-3166 alpha-2 allow-list the banner is targeted at. Empty means
    /// everywhere. Carried for completeness — the app never evaluates it,
    /// because only the server can see the caller's IP country.
    @Default(<String>[]) List<String> countries,

    /// The server's decision for THIS caller, already accounting for [enabled]
    /// and the country targeting.
    ///
    /// Null means the API is older than country targeting and said nothing —
    /// see [isVisible], which falls back to [enabled] then.
    bool? visible,
  }) = _HomeBannerEntity;

  factory HomeBannerEntity.fromJson(Map<String, dynamic> json) => _$HomeBannerEntityFromJson(json);
}

extension HomeBannerEntityX on HomeBannerEntity {
  /// Whether Home should render the slot at all.
  ///
  /// Prefers [visible] over [enabled]: a banner can be switched on globally and
  /// still not be meant for this reader, and only the server can tell — it is
  /// the only side that sees the caller's IP country. Evaluating [enabled] here
  /// would show a Vietnam-only campaign to everyone.
  ///
  /// Falls back to [enabled] when [visible] is null, which is what an API older
  /// than country targeting sends. That keeps this app working against either
  /// version and takes the rollout order off the critical path.
  ///
  /// The image check stays: a banner can be live with nothing uploaded yet, and
  /// Home collapses the section rather than render an empty card.
  bool get isVisible => (visible ?? enabled) && imageUrl.isNotEmpty;
}
