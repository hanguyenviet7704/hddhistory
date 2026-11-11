part of '../../study_theme.dart';

/// How a study-background preset is rendered.
/// - [defaultMode]: the app's stock light background (no personalization).
/// - [color]: a solid colour or gradient.
/// - [image]: a static photo (bundled asset, remote url, or user upload).
/// - [video]: a looping video ("live"); may also carry ambient [audioAsset].
///
/// `@JsonValue`s mirror the `mode` string the `/study-themes` catalogue
/// endpoint sends (see [StudyThemePresetModel]).
enum StudyThemeMode {
  @JsonValue('default')
  defaultMode,
  @JsonValue('color')
  color,
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
}

/// One selectable study background. Mirrors the design's `cbPresets` schema so
/// the official catalogue (served by the `/study-themes` endpoint, see
/// [StudyThemePresetModel]) maps 1:1 onto it. Bundled presets ([PresetCatalog])
/// only ever populate the `*Asset` fields; server-sourced presets only ever
/// populate the `*Url` fields — a single preset never mixes the two.
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

    /// Bundled asset path for [StudyThemeMode.image] (offline fallback catalogue).
    String? imageAsset,

    /// Looping video asset for [StudyThemeMode.video] (offline fallback catalogue).
    String? videoAsset,

    /// Ambient audio asset played while a bundled live preset is active.
    String? audioAsset,

    /// Optional poster used as the sheet thumbnail for a bundled video preset.
    String? thumbAsset,

    /// Remote photo url for [StudyThemeMode.image] (DB-managed catalogue).
    String? imageUrl,

    /// Remote looping video url for [StudyThemeMode.video] (DB-managed catalogue).
    String? videoUrl,

    /// Remote ambient audio url played while a DB-managed live preset is active.
    String? audioUrl,

    /// Remote poster used as the sheet thumbnail for a DB-managed preset.
    String? thumbUrl,

    /// Readability overlay painted over the applied background (NOT the sheet
    /// thumbnail, which always shows the true colour). Editor-tuned per preset;
    /// null means no overlay.
    Color? overlay,

    /// Whether the background reads as dark (drives glass-card + icon tinting).
    @Default(false) bool isDark,

    /// Premium-only preset: shown behind the paywall (locked) in the in-app
    /// picker, and hidden entirely from the onboarding theme step.
    @Default(false) bool isPremium,
  }) = _StudyThemePreset;
}

extension StudyThemePresetX on StudyThemePreset {
  /// A non-default preset — the user has picked a custom background. Screens
  /// only go transparent (to reveal the study background) when this is true, so
  /// the stock "Default" look of every screen is preserved otherwise (mirrors
  /// the design's `cb-custom` toggle).
  bool get isCustom => mode != StudyThemeMode.defaultMode;

  /// True for CATALOGUE presets (default / colour / image / live) — they persist
  /// across a restart as a tiny id pointer, re-resolved from the catalogue on
  /// next launch. The user UPLOAD (id `upload`) is excluded here only because it
  /// can't be pointed at by id; it still survives a restart via its own stored
  /// file copy + overlay (see the cubit's `toJson`/`fromJson`).
  bool get isPersistable => id != 'upload';

  /// A "live" preset animates (looping video) and optionally plays audio.
  bool get isLive => mode == StudyThemeMode.video;

  bool get hasAudio => (audioAsset ?? audioUrl ?? '').trim().isNotEmpty;
}
