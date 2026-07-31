part of '../../onboard_v2.dart';

/// Resolves the icon to render for an onboarding path row / path-map node.
///
/// Preference order: [iconUrl] (network, admin-uploaded override) >
/// [iconKey] (mapped to the bundled asset the app already ships) > a neutral
/// bundled default. Both API-sourced paths and the offline enum fallback
/// (see [OnboardV2PathResolver]) share this single resolution codepath so
/// path-selection and the path-map screen render identically regardless of
/// where the content came from.
abstract final class OnboardV2IconResolver {
  static final Map<String, ({AssetGenImage enabled, AssetGenImage disabled})> _assetsByIconKey = {
    'ic_heart': (enabled: AppAsset.icons.app.icHeart, disabled: AppAsset.icons.app.icHeartDisable),
    'ic_compass': (enabled: AppAsset.icons.app.icCompass, disabled: AppAsset.icons.app.icCompassDisable),
    'ic_direct_hit': (enabled: AppAsset.icons.app.icDirectHit, disabled: AppAsset.icons.app.icDirectHitDisable),
    'ic_speech_ballon': (enabled: AppAsset.icons.app.icSpeechBallon, disabled: AppAsset.icons.app.icSpeechBallonDisable),
    'ic_book': (enabled: AppAsset.icons.app.icBook, disabled: AppAsset.icons.app.icBookDisable),
    'ic_world_map': (enabled: AppAsset.icons.app.icWorldMap, disabled: AppAsset.icons.app.icWorldMapDisable),
  };

  /// The `onboarding-config` admin seeds path `iconKey`s as `cat_*` (the
  /// Figma path illustrations) — a single bundled SVG per path, with no
  /// separate selected/unselected artwork. Rendered via [CacheNetworkGraphic]
  /// (not [DCachedImage] directly), which picks the SVG renderer by the
  /// `.svg` file extension — see the call sites in
  /// `onboard_v2_selectable_option_row.dart` / `onboard_v2_path_map_node.dart`.
  static final Map<String, String> _svgAssetsByIconKey = {
    'cat_feel': AppAsset.svg.app.catFeel,
    'cat_think': AppAsset.svg.app.catThink,
    'cat_work': AppAsset.svg.app.catWork,
    'cat_connect': AppAsset.svg.app.catConnect,
    'cat_learn': AppAsset.svg.app.catLearn,
    'cat_explore': AppAsset.svg.app.catExplore,
  };

  /// The bundled `iconKey` the legacy [OnboardingPath] enum has always
  /// rendered — seeds the offline fallback path entity so it resolves to the
  /// exact same asset the app shipped before this change.
  static String iconKeyForLegacyPath(OnboardingPath path) => switch (path) {
    OnboardingPath.feelBetter => 'ic_heart',
    OnboardingPath.thinkBetter => 'ic_compass',
    OnboardingPath.workBetter => 'ic_direct_hit',
    OnboardingPath.connectBetter => 'ic_speech_ballon',
    OnboardingPath.learnBetter => 'ic_book',
    OnboardingPath.exploreBetter => 'ic_world_map',
  };

  /// Returns a path suitable for [DCachedImage] (network url or bundled
  /// asset path).
  static String resolve({required String iconUrl, required String iconKey, required bool selected}) {
    final url = iconUrl.trim();
    if (url.isNotEmpty) return url;

    final key = iconKey.trim();
    final asset = _assetsByIconKey[key];
    if (asset != null) return (selected ? asset.enabled : asset.disabled).path;

    final svgAsset = _svgAssetsByIconKey[key];
    if (svgAsset != null) return svgAsset;

    // Neutral default for an unrecognised iconKey (should not happen once
    // admin content is seeded from the bundled iconKey list).
    return AppAsset.icons.app.icTag.path;
  }
}
