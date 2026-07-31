part of '../study_theme.dart';

/// A titled group of presets in the picker sheet (design: heading + 3-col grid).
class PresetGroup {
  final String category;
  final List<StudyThemePreset> items;
  const PresetGroup(this.category, this.items);
}

/// Structural presets only. The picker's background CATALOGUE is fetched from
/// the DB ([GetStudyThemesUseCase] → `/study-themes`) — there is deliberately NO
/// bundled fallback catalogue anymore, so the admin/API is the single source of
/// truth (the sheet shows a loading state until it arrives, then the live list).
///
/// Only two synthetic presets ship in the binary: [defaultPreset] (the "no
/// custom background" / reset option and the initial applied preset) and
/// [uploadPreset] (the user's own picked image). Neither is catalogue content.
abstract class PresetCatalog {
  const PresetCatalog._();

  static const StudyThemePreset defaultPreset = StudyThemePreset(
    id: 'default',
    mode: StudyThemeMode.defaultMode,
    category: 'Default',
    name: 'Default',
    gradient: [Color(0xFFEFEEF9), Color(0xFFE6EBDE)],
  );

  /// Synthetic preset for a user-uploaded image. The picked file itself lives
  /// on [StudyThemeState.uploadedFile] (never persisted as catalogue content);
  /// this only carries the mode + a dark readability overlay (~18%).
  static const StudyThemePreset uploadPreset = StudyThemePreset(
    id: 'upload',
    mode: StudyThemeMode.image,
    category: '',
    name: 'Custom',
    overlay: Color(0x2E000000), // black ~18%
    isDark: true,
  );

  /// Resolves the two structural presets by id (used by the legacy-format
  /// persistence path). Real catalogue presets are resolved from the loaded
  /// remote catalogue, not here.
  static StudyThemePreset? byId(String? id) {
    if (id == defaultPreset.id) return defaultPreset;
    if (id == uploadPreset.id) return uploadPreset;
    return null;
  }

  /// Groups any preset list by [StudyThemePreset.category], preserving
  /// first-seen order. Drives the picker sheet's grouped grid over
  /// [StudyThemeState.catalog] (the remote catalogue).
  static List<PresetGroup> groupByCategory(List<StudyThemePreset> source) {
    final order = <String>[];
    final byCategory = <String, List<StudyThemePreset>>{};
    for (final p in source) {
      final list = byCategory.putIfAbsent(p.category, () {
        order.add(p.category);
        return <StudyThemePreset>[];
      });
      list.add(p);
    }
    return [for (final c in order) PresetGroup(c, byCategory[c]!)];
  }
}
