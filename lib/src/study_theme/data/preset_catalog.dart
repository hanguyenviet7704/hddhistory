part of '../study_theme.dart';

/// A titled group of presets in the picker sheet (design: heading + 3-col grid).
class PresetGroup {
  final String category;
  final List<StudyThemePreset> items;
  const PresetGroup(this.category, this.items);
}

/// SAMPLE study-background catalogue. Values mirror the design's `cbPresets`;
/// the official list/groups/live entries arrive from lynci later and slot in
/// here without touching any consumer (all UI reads [presets] / [groups]).
///
/// Phase 1 ships the Default + "Solid & Gradient" groups (no bundled assets
/// needed). Nature (image) and Live (video + audio) groups are added in a
/// later phase together with their assets.
abstract class PresetCatalog {
  const PresetCatalog._();

  static const StudyThemePreset defaultPreset = StudyThemePreset(
    id: 'default',
    mode: StudyThemeMode.defaultMode,
    category: 'Default',
    name: 'Default',
    gradient: [Color(0xFFEFEEF9), Color(0xFFE6EBDE)],
  );

  static const List<StudyThemePreset> presets = [
    defaultPreset,
    StudyThemePreset(
      id: 'lavender',
      mode: StudyThemeMode.color,
      category: 'Solid & Gradient',
      name: 'Lavender',
      gradient: [Color(0xFFEDE9FF), Color(0xFFD5D2F7)],
    ),
    StudyThemePreset(
      id: 'peach',
      mode: StudyThemeMode.color,
      category: 'Solid & Gradient',
      name: 'Peach',
      gradient: [Color(0xFFFFE7D6), Color(0xFFFCD1C0)],
    ),
    StudyThemePreset(
      id: 'mint',
      mode: StudyThemeMode.color,
      category: 'Solid & Gradient',
      name: 'Mint',
      gradient: [Color(0xFFDCF6EC), Color(0xFFC3EBDD)],
    ),
    StudyThemePreset(
      id: 'midnight',
      mode: StudyThemeMode.color,
      category: 'Solid & Gradient',
      name: 'Midnight',
      gradient: [Color(0xFF20244A), Color(0xFF141733)],
      isDark: true,
    ),
  ];

  /// Synthetic preset for a user-uploaded image. The picked file itself lives
  /// on [StudyThemeState.uploadedFile] (never persisted); this only carries the
  /// mode + a dark readability overlay (~18%, design item 4).
  static const StudyThemePreset uploadPreset = StudyThemePreset(
    id: 'upload',
    mode: StudyThemeMode.image,
    category: '',
    name: 'Custom',
    overlay: Color(0x2E000000), // black ~18%
    isDark: true,
  );

  static StudyThemePreset? byId(String? id) {
    if (id == null) return null;
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Presets grouped by [StudyThemePreset.category], preserving first-seen
  /// order. Drives the sheet's grouped grid (design `cbGroups`).
  static List<PresetGroup> get groups {
    final order = <String>[];
    final byCategory = <String, List<StudyThemePreset>>{};
    for (final p in presets) {
      final list = byCategory.putIfAbsent(p.category, () {
        order.add(p.category);
        return <StudyThemePreset>[];
      });
      list.add(p);
    }
    return [for (final c in order) PresetGroup(c, byCategory[c]!)];
  }
}
