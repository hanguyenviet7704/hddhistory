part of '../../../lesson.dart';

class LessonShellHeader extends StatelessWidget {
  const LessonShellHeader({
    super.key,
    required this.onClose,
    this.trailing,
  });

  final VoidCallback onClose;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Two bands, per the design (`11 · Keypoint.dc.html`): the controls sit on
    // their own row — close pinned left, narration + overflow menu pinned right
    // with the space between them empty — and the progress pips get a row of
    // their own underneath, inset further (36 vs 18) so the bar reads as a
    // measure of the whole screen rather than as another header control.
    //
    // They shared one row before, which made the pip bar's width a function of
    // how many buttons were showing and pushed it off-centre.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Row(
            children: [
              _LessonShellIconButton(
                key: const ValueKey('lesson-shell-close-button'),
                onTap: onClose,
                assetPath: AppAsset.svg.app.icKpClose,
              ),
              const Spacer(),
              const KeypointNarrationToggle(),
              // "Change theme" lives inside the top-right overflow menu
              // ([LessonHeaderMenu], passed in as [trailing]) alongside "Text
              // display", "Speed", and "Report a problem" — no Read/Listen mode
              // toggle anymore (the unified screen has only one mode).
              if (trailing != null) ...[
                8.horizontalSpace,
                trailing!,
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 36.w, right: 36.w, top: 6.h),
          child: const KeypointProgressPipBar(),
        ),
      ],
    );
  }
}

class _LessonShellIconButton extends StatelessWidget {
  const _LessonShellIconButton({
    super.key,
    required this.assetPath,
    required this.onTap,
  });

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        // Slightly larger than the circle so the tap target stays comfortable
        // without changing the header's spacing.
        width: 36.w,
        height: 36.w,
        child: Center(
          child: KeypointHeaderButtonChrome(
            child: SvgPicture.asset(
              assetPath,
              width: 20.w,
              height: 20.w,
              colorFilter: const ColorFilter.mode(
                KeypointHeaderChrome.icon,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The keypoint header's chrome tokens, taken from the design's own `light`
/// treatment (`11 · Keypoint.dc.html`).
///
/// The design defines three treatments (`scrim` / `light` / `outline`) and picks
/// `light` by default, with the comment "Header chrome is theme-independent —
/// same on every theme". So these do NOT flip with the study background: they
/// used to, which is why the pips came out white-on-dark instead of the design's
/// indigo-on-white.
abstract final class KeypointHeaderChrome {
  /// `btn: rgba(255,255,255,.9)`
  static final Color buttonBg = AppCustomColor.backgroundWhite.withValues(alpha: 0.9);

  /// `icon: #0D121C`
  static const Color icon = Color(0xFF0D121C);

  /// `audioOn: #554FF0`
  static const Color audioOn = Color(0xFF554FF0);

  /// `audioOff: #9AA4B2`
  static const Color audioOff = Color(0xFF9AA4B2);

  /// `pipTrack: rgba(255,255,255,.9)`
  static final Color pipTrack = AppCustomColor.backgroundWhite.withValues(alpha: 0.9);

  /// `pipFill: #554FF0`
  static const Color pipFill = Color(0xFF554FF0);
}

/// Round chrome behind a keypoint header control — the design's 34pt circle at
/// `rgba(255,255,255,.9)`.
///
/// Shared by all three header controls (close, narration, overflow menu) rather
/// than repeated in each: they were drifting already — close and menu had no
/// circle at all and drew their icon in a pale grey that a photo background
/// swallowed, while narration had its own copy at a different opacity.
///
/// The design pairs the circle with `backdrop-filter: blur(6px)`. That is
/// deliberately not reproduced: `ThemedGlassCard` dropped its own BackdropFilter
/// because the blur haloed edges over a photo, and a 34pt circle would show the
/// same rim. The flat translucent fill covers the icon just as well.
class KeypointHeaderButtonChrome extends StatelessWidget {
  const KeypointHeaderButtonChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: KeypointHeaderChrome.buttonBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
