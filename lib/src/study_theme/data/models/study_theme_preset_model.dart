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
    @Default(false) bool isPremium,
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
    isPremium: isPremium,
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

/// Serialises a [Color] to `#RRGGBBAA` (alpha LAST) — the inverse of
/// [_studyThemeColorFromHex]. Used to persist a user-upload background's
/// readability overlay across app restarts. Returns null for a null colour.
String? _studyThemeColorToHex(Color? color) {
  if (color == null) return null;
  int channel(double v) => (v * 255.0).round().clamp(0, 255);
  String hex2(int v) => v.toRadixString(16).padLeft(2, '0');
  return '#${hex2(channel(color.r))}${hex2(channel(color.g))}${hex2(channel(color.b))}${hex2(channel(color.a))}';
}
