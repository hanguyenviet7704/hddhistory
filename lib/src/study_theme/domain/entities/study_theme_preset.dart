part of '../../study_theme.dart';

/// How a study-background preset is rendered.
/// - [defaultMode]: the app's stock light background (no personalization).
/// - [color]: a solid colour or gradient.
/// - [image]: a static photo (bundled asset, remote url, or user upload).
/// - [video]: a looping video ("live"); may also carry ambient [audioAsset].
enum StudyThemeMode { defaultMode, color, image, video }

/// One selectable study background. Mirrors the design's `cbPresets` schema so
/// the official catalogue (shipped by lynci later) maps 1:1 onto it.
@freezed
abstract class StudyThemePreset with _$StudyThemePreset {
  const factory StudyThemePreset({
    required String id,
    required StudyThemeMode mode,

    /// Group heading in the picker sheet (e.g. "Solid & Gradient", "Nature").
    required String category,
    required String name,

    /// Colours for [StudyThemeMode.color] (1 = solid, 2+ = top→bottom gradient).
    @Default(<Color>[]) List<Color> gradient,

    /// Asset path (or remote url) for [StudyThemeMode.image].
    String? imageAsset,

    /// Looping video asset/url for [StudyThemeMode.video].
    String? videoAsset,

    /// Ambient audio asset/url played while a live preset is active.
    String? audioAsset,

    /// Optional poster used as the sheet thumbnail for video presets.
    String? thumbAsset,

    /// Readability overlay painted over the applied background (NOT the sheet
    /// thumbnail, which always shows the true colour). Editor-tuned per preset;
    /// null means no overlay.
    Color? overlay,

    /// Whether the background reads as dark (drives glass-card + icon tinting).
    @Default(false) bool isDark,
  }) = _StudyThemePreset;
}

extension StudyThemePresetX on StudyThemePreset {
  /// A non-default preset — the user has picked a custom background. Screens
  /// only go transparent (to reveal the study background) when this is true, so
  /// the stock "Default" look of every screen is preserved otherwise (mirrors
  /// the design's `cb-custom` toggle).
  bool get isCustom => mode != StudyThemeMode.defaultMode;

  /// Only default/solid/gradient presets survive an app restart — image and
  /// video (and user uploads) are intentionally not persisted, mirroring the
  /// design's `_cbPersist` (`mode !== 'image' && mode !== 'video'`).
  bool get isPersistable => mode == StudyThemeMode.defaultMode || mode == StudyThemeMode.color;

  /// A "live" preset animates (looping video) and optionally plays audio.
  bool get isLive => mode == StudyThemeMode.video;

  bool get hasAudio => (audioAsset ?? '').trim().isNotEmpty;
}
