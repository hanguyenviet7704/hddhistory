part of '../../study_theme.dart';

/// Wire shape of one `/study-themes` catalogue item (DB-managed background
/// preset). Colours travel as hex strings (`gradient`: `#RRGGBB`, `overlay`:
/// 8-digit `#RRGGBBAA`) and are parsed into [Color] by [toEntity].
@freezed
abstract class StudyThemePresetModel with _$StudyThemePresetModel {
  const factory StudyThemePresetModel({
    @Default('') String key,
    @Default(StudyThemeMode.defaultMode) StudyThemeMode mode,
    @Default('') String category,
    @Default('') String name,
    @Default(<String>[]) List<String> gradient,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    String? thumbUrl,
    String? overlay,
    @Default(false) bool isDark,
    @Default(0) int order,
  }) = _StudyThemePresetModel;

  factory StudyThemePresetModel.fromJson(Map<String, dynamic> json) => _$StudyThemePresetModelFromJson(json);
}

extension StudyThemePresetModelX on StudyThemePresetModel {
  StudyThemePreset toEntity() => StudyThemePreset(
    id: key,
    mode: mode,
    category: category,
    name: name,
    gradient: gradient.map(_studyThemeColorFromHex).whereType<Color>().toList(),
    imageUrl: imageUrl,
    videoUrl: videoUrl,
    audioUrl: audioUrl,
    thumbUrl: thumbUrl,
    overlay: _studyThemeColorFromHex(overlay),
    isDark: isDark,
  );
}

/// Parses `#RGB` / `#RRGGBB` / `#RRGGBBAA` (server sends alpha LAST, unlike
/// Flutter's `Color` which wants it first) into a [Color]. Returns null for
/// any null/blank/malformed input so a bad value degrades to "no colour"
/// instead of crashing the sheet render.
Color? _studyThemeColorFromHex(String? value) {
  if (value == null) return null;
  var hex = value.trim();
  if (hex.isEmpty) return null;
  if (hex.startsWith('#')) hex = hex.substring(1);

  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }

  if (hex.length == 6) {
    hex = 'FF$hex'; // opaque
  } else if (hex.length == 8) {
    // Input is RRGGBBAA -> Color wants AARRGGBB.
    hex = '${hex.substring(6, 8)}${hex.substring(0, 6)}';
  } else {
    return null;
  }

  final value32 = int.tryParse(hex, radix: 16);
  return value32 == null ? null : Color(value32);
}
