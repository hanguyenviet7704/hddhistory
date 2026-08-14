part of '../../home.dart';

/// One slide of the Home carousel, as the server decided this reader should see
/// it. No targeting fields: the filtering already happened server-side, which is
/// what makes the dots honest — one dot per slide the app was actually given.
@freezed
abstract class HomeBannerSlideEntity with _$HomeBannerSlideEntity {
  const factory HomeBannerSlideEntity({
    @Default('') String imageUrl,
    @Default('') String linkUrl,

    /// Identity of this slide's creative, echoed back to
    /// impression/click tracking. Empty for the legacy single-banner
    /// fallback (see [HomeBannerEntityX.effectiveSlides]) and for a server
    /// older than the field — [HomeCubit] skips tracking in that case.
    @Default('') String campaignKey,
  }) = _HomeBannerSlideEntity;

  factory HomeBannerSlideEntity.fromJson(Map<String, dynamic> json) => _$HomeBannerSlideEntityFromJson(json);
}

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

    /// The carousel for this reader, in display order. Empty from an API older
    /// than the carousel — see [HomeBannerEntityX.effectiveSlides].
    @Default(<HomeBannerSlideEntity>[]) List<HomeBannerSlideEntity> slides,
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
  bool get isVisible => (visible ?? enabled) && effectiveSlides.isNotEmpty;

  /// What the carousel actually renders.
  ///
  /// Falls back to the single-banner fields when [slides] is empty, so a build
  /// of this app running against an API that predates the carousel still shows
  /// the one banner instead of collapsing the slot. The mirror on the server
  /// covers the opposite skew (old app, new API), and between them the rollout
  /// order stops being load-bearing.
  ///
  /// Slides with no image are dropped — the server already does this, so this is
  /// belt and braces for the legacy path.
  List<HomeBannerSlideEntity> get effectiveSlides {
    final resolved = slides.isNotEmpty ? slides : [HomeBannerSlideEntity(imageUrl: imageUrl, linkUrl: linkUrl)];

    return resolved.where((slide) => slide.imageUrl.isNotEmpty).toList();
  }
}
