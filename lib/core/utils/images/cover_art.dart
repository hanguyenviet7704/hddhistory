part of '../utils.dart';

/// A course or keypoint cover: the real artwork when there is one, a generated
/// stand-in when there isn't.
///
/// The stand-in exists because content lands before its art does — a course row
/// imported without a cover, a keypoint whose image has not been uploaded yet.
/// Left to [CacheNetworkGraphic] those render as nothing at all, which reads as
/// a broken screen rather than as missing art.
///
/// **Derived from the id, never from a random number.** Two draws of the same
/// entity must produce the same tile: a `Random()` here would repaint on every
/// scroll and rebuild, and a grid that reshuffles itself while you look at it is
/// worse than one with holes in it. The seed also means the same course keeps
/// its colour across sessions and devices, so it stays recognisable.
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.url,
    required this.seed,
    this.label = '',
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  /// The real artwork. Empty means there is none yet.
  final String url;

  /// What the stand-in is derived from — an entity id. Must be stable for the
  /// lifetime of the entity; a title would change the tile on every edit.
  final String seed;

  /// Used for the stand-in's initial. Optional: a blank one just omits it.
  final String label;

  final BorderRadiusGeometry? borderRadius;
  final BoxFit fit;

  /// Cover palettes, each a pair the app already uses elsewhere. Deliberately
  /// muted: a stand-in must not out-shout the real covers beside it in a grid.
  static const List<List<Color>> _palettes = [
    [Color(0xFF6C63FF), Color(0xFF554FF0)],
    [Color(0xFF3AA07E), Color(0xFF2F8468)],
    [Color(0xFFE0A32E), Color(0xFFC9862B)],
    [Color(0xFF4C8DD8), Color(0xFF3A6FB5)],
    [Color(0xFFB85C9E), Color(0xFF954A80)],
    [Color(0xFF5B8C51), Color(0xFF46703F)],
    [Color(0xFFD1685A), Color(0xFFAE5348)],
    [Color(0xFF5E6AD2), Color(0xFF4A55AC)],
  ];

  @override
  Widget build(BuildContext context) {
    if (url.trim().isNotEmpty) {
      return CacheNetworkGraphic(url: url, fit: fit, borderRadius: borderRadius);
    }

    final palette = _palettes[_hash(seed) % _palettes.length];
    final initial = _initialOf(label);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A soft off-centre highlight so the tile reads as artwork rather
            // than as a flat colour swatch — which is what an empty state looks
            // like, and this is not one.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.6),
                  radius: 1.1,
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            if (initial.isNotEmpty)
              Center(
                child: AppText(
                  initial,
                  style: AppStyle.textBold24.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 34.sp,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// First letter of the first word that has one.
  ///
  /// Skips leading punctuation and digits so a title like `"1. Mở đầu"` shows
  /// `M` rather than `1` — the number is the position, not the subject.
  static String _initialOf(String value) {
    for (final rune in value.trim().runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r'[\p{L}]', unicode: true).hasMatch(char)) {
        return char.toUpperCase();
      }
    }

    return '';
  }

  /// FNV-1a. Chosen over [String.hashCode] because that one is randomly seeded
  /// per isolate in Dart — the same course would get a different colour after
  /// every app restart, which is exactly the flicker this class exists to avoid.
  static int _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }

    return hash;
  }
}
