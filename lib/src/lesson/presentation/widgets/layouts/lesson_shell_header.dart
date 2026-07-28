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
        width: 36.w,
        height: 36.w,
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            width: 20.w,
            height: 20.w,
            // Bare on the background (the close button sits directly on the
            // Scaffold, above any content card) — swap to light ink over a
            // dark custom bg.
            colorFilter: ColorFilter.mode(
              studyThemeOnBg(context, AppCustomColor.textQuaternary),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
