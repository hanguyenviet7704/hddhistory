part of '../../../lesson.dart';

/// Persisted reading-display preferences for the Keypoint theory content
/// (font size + font family), driven by the "Text display" sheet reachable
/// from the keypoint header's overflow menu ([LessonHeaderMenu], read mode
/// only). Provided app-wide (see [AppProviders]) since it's a lightweight
/// settings cubit read from a leaf widget deep in the theory render tree
/// ([DocumentContentWidget]) without needing a route-scoped provider.
@lazySingleton
class KeypointDisplayCubit extends HydratedCubit<KeypointDisplayState> {
  KeypointDisplayCubit() : super(KeypointDisplayState.initial());

  /// Base reading font size (px) the scale multiplies against — matches the
  /// theory body's stock `text18`/`textBold18` reading size closely enough
  /// for the sheet's "16" display value while keeping the control's math
  /// simple (see design: "display px = round(base*scale)").
  static const double baseFontSizePx = 16;

  static const double fontScaleStep = 0.1;

  // Design calls for "~0.85-1.4"; 0.8 keeps every step (0.1 increments from
  // the 1.0 default) landing on a clean value instead of overshooting past an
  // odd floor, while still reading as "~0.85" in practice (the 0.9 -> 0.8
  // step clamps up to 0.85, so 0.85 is still reachable, just not a middle
  // step).
  static const double minFontScale = 0.85;
  static const double maxFontScale = 1.4;

  void increaseFontScale() => _applyFontScale(state.fontScale + fontScaleStep);

  void decreaseFontScale() => _applyFontScale(state.fontScale - fontScaleStep);

  void setFontFamily(ReadingFontFamily family) {
    if (state.fontFamily == family) return;
    emit(state.copyWith(fontFamily: family));
  }

  void _applyFontScale(double next) {
    final clamped = double.parse(next.clamp(minFontScale, maxFontScale).toStringAsFixed(2));
    if (clamped == state.fontScale) return;
    emit(state.copyWith(fontScale: clamped));
  }

  @override
  KeypointDisplayState? fromJson(Map<String, dynamic> json) {
    try {
      return KeypointDisplayState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(KeypointDisplayState state) => state.toJson();
}
