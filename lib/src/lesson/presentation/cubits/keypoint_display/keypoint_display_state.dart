part of '../../../lesson.dart';

/// Reading font offered by the Keypoint "Text display" sheet. Limited to
/// families actually bundled with the app (see pubspec `flutter.fonts`) — no
/// new font assets are added for this feature.
enum ReadingFontFamily {
  /// The app's stock sans-serif (Mulish).
  defaultFamily,

  /// A serif face — platform serif (iOS "Georgia" / Android generic "serif"
  /// via [KeypointDisplayStateX.fontFamilyFallback]); no bundled asset needed.
  serif,

  /// A monospace face (iOS "Courier New" / Android generic "monospace").
  courier,
}

@freezed
abstract class KeypointDisplayState with _$KeypointDisplayState {
  const factory KeypointDisplayState({
    /// Multiplier applied on top of the base reading size (~16px). Stepped by
    /// [KeypointDisplayCubit.fontScaleStep] via the Text display sheet's A−/A+
    /// controls.
    @Default(1.0) double fontScale,

    /// Reading font family, applied only to theory/reading content — never to
    /// chrome/UI text.
    @Default(ReadingFontFamily.defaultFamily) ReadingFontFamily fontFamily,
  }) = _KeypointDisplayState;

  factory KeypointDisplayState.initial() => const KeypointDisplayState();

  factory KeypointDisplayState.fromJson(Map<String, dynamic> json) => _$KeypointDisplayStateFromJson(json);
}

extension KeypointDisplayStateX on KeypointDisplayState {
  /// Primary Flutter font family for the current [fontFamily] choice.
  String get fontFamilyName => switch (fontFamily) {
        ReadingFontFamily.defaultFamily => AppFont.mulish,
        ReadingFontFamily.serif => 'Georgia',
        ReadingFontFamily.courier => 'Courier New',
      };

  /// Cross-platform generic fallback so serif/monospace still resolve where the
  /// iOS family names ('Georgia'/'Courier New') are absent (e.g. Android).
  List<String>? get fontFamilyFallback => switch (fontFamily) {
        ReadingFontFamily.defaultFamily => null,
        ReadingFontFamily.serif => const ['serif'],
        ReadingFontFamily.courier => const ['monospace'],
      };

  /// Rounded reading font size in px, for display in the Text display sheet
  /// (design shows a plain integer, e.g. "16").
  int get displayFontSizePx => (KeypointDisplayCubit.baseFontSizePx * fontScale).round();

  bool get canDecreaseFontScale => fontScale > KeypointDisplayCubit.minFontScale + 0.001;

  bool get canIncreaseFontScale => fontScale < KeypointDisplayCubit.maxFontScale - 0.001;
}
