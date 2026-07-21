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
    StudyThemePreset(
      id: 'rose',
      mode: StudyThemeMode.color,
      category: 'Solid & Gradient',
      name: 'Rose',
      gradient: [Color(0xFFFDE6F0), Color(0xFFF6C9DE)],
    ),
    StudyThemePreset(
      id: 'sky',
      mode: StudyThemeMode.color,
      category: 'Solid & Gradient',
      name: 'Sky',
      gradient: [Color(0xFFE3F0FF), Color(0xFFC7DDFB)],
    ),
    StudyThemePreset(
      id: 'sand',
      mode: StudyThemeMode.color,
      category: 'Solid & Gradient',
      name: 'Sand',
      gradient: [Color(0xFFFBF3E2), Color(0xFFEFE0C4)],
    ),
    StudyThemePreset(
      id: 'plum',
      mode: StudyThemeMode.color,
      category: 'Solid & Gradient',
      name: 'Plum',
      gradient: [Color(0xFF3A2C57), Color(0xFF241735)],
      isDark: true,
    ),

    // Nature — bundled sample photos (design assets/bg/*). A dark readability
    // overlay is applied while the app content is still dark-on-light; the
    // glass-card + light-text pass (Phase 2) refines contrast further.
    StudyThemePreset(
      id: 'ocean',
      mode: StudyThemeMode.image,
      category: 'Nature',
      name: 'Ocean',
      imageAsset: 'assets/bg/ocean-photo.jpg',
      overlay: Color(0x59000000),
      isDark: true,
    ),
    StudyThemePreset(
      id: 'sunset',
      mode: StudyThemeMode.image,
      category: 'Nature',
      name: 'Sunset',
      imageAsset: 'assets/bg/ocean-sunset.jpg',
      overlay: Color(0x59000000),
      isDark: true,
    ),
    StudyThemePreset(
      id: 'rain',
      mode: StudyThemeMode.image,
      category: 'Nature',
      name: 'Rain',
      imageAsset: 'assets/bg/rain-photo.jpg',
      overlay: Color(0x59000000),
      isDark: true,
    ),

    // Live — a looping muted video (+ optional ambient audio), design item 5.
    // Ships a bundled sample clip so the mode is demoable offline; production
    // Live presets instead carry an R2 videoUrl/audioUrl from the DB catalogue
    // (the layer prefers *Asset, then falls back to *Url). Like image/upload it
    // is NOT persisted across restarts (isPersistable = default/color only).
    StudyThemePreset(
      id: 'live-meadow',
      mode: StudyThemeMode.video,
      category: 'Live',
      name: 'Meadow',
      videoAsset: 'assets/bg/live-bee.mp4',
      audioAsset: 'assets/bg/live-ambient.mp3',
      thumbAsset: 'assets/bg/rain-photo.jpg', // poster (no frame-grab tool bundled)
      overlay: Color(0x4D000000),
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
  static List<PresetGroup> get groups => groupByCategory(presets);

  /// Groups any preset list by [StudyThemePreset.category], preserving
  /// first-seen order. Shared by [groups] (the bundled fallback) and the
  /// picker sheet (grouping [StudyThemeState.catalog], which may be the
  /// remote catalogue) so both render identically.
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
