part of '../../study_theme.dart';

/// The circular "Change background" affordance (design item 2). 42px on Home
/// (inline in the greeting header), 46px as a floating button on Course/Learn.
/// Opens the [ChangeBackgroundSheet].
class ChangeBackgroundButton extends StatelessWidget {
  final double size;

  /// Analytics origin for the theme flow ('home' / 'roadmap' / 'keypoint').
  /// Threaded into theme_change_click and the opened sheet.
  final String source;

  /// Glyph size as a fraction of [size]. The floating variants keep the original
  /// half-size glyph; Home's 28px header button needs a proportionally larger
  /// one (19/28) or the icon disappears inside the circle.
  final double iconRatio;

  const ChangeBackgroundButton({super.key, this.size = 42, this.source = 'home', this.iconRatio = 0.5});

  /// Design `cb-theme-icon` — a small "image / theme" glyph. Stroke uses the
  /// brand colour for now; theme-adaptive tinting (light icon on dark
  /// backgrounds) lands with the glass/overlay pass.
  static const String _iconSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="4" width="13" height="6" rx="1.6" stroke="#554FF0" stroke-width="1.6"/><path d="M16 7h3.2a1.5 1.5 0 0 1 1.5 1.5v2A1.5 1.5 0 0 1 19.2 12H12a1.5 1.5 0 0 0-1.5 1.5V15" stroke="#554FF0" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/><rect x="8.4" y="15" width="4.2" height="5" rx="1.3" stroke="#554FF0" stroke-width="1.6"/></svg>''';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.studyTheme.changeBackground,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          StudyThemeTracking.track(TrackingKey.themeChangeClick, parameters: {'source': source});
          ChangeBackgroundSheet.show(context, source: source);
        },
        child: Container(
          width: size.r,
          height: size.r,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7FA),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0x2E252525), blurRadius: 16.r, offset: Offset(0, 6.h)),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          ),
          alignment: Alignment.center,
          child: SvgPicture.string(_iconSvg, width: (size * iconRatio).r, height: (size * iconRatio).r),
        ),
      ),
    );
  }
}
