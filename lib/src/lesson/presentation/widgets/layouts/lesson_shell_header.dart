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
    // Design puts everything on ONE row: close · progress pips (flexible) ·
    // narration toggle · overflow menu. The pips are not a separate band
    // below the header, and the audio control is not a floating button.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        children: [
          _LessonShellIconButton(
            key: const ValueKey('lesson-shell-close-button'),
            onTap: onClose,
            assetPath: AppAsset.svg.app.icClose,
          ),
          12.horizontalSpace,
          const Expanded(child: KeypointProgressPipBar()),
          12.horizontalSpace,
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
              colorFilter: ColorFilter.mode(
                studyThemeOnBg(context, AppCustomColor.textPrimary),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round translucent chrome behind a keypoint header control — the design's 34pt
/// circle at `rgba(255,255,255,.9)`, flipping to a dark circle over a dark study
/// background so the icon inside stays legible either way.
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
    final isDarkBg = studyThemeIsDarkBg(context);

    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: isDarkBg ? const Color(0xFF12141C).withValues(alpha: 0.52) : AppCustomColor.backgroundWhite.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
