part of '../../../lesson.dart';

class LessonShellHeader extends StatelessWidget {
  const LessonShellHeader({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.showModeToggle,
    required this.canSwitchModes,
    this.trailing,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode> onModeSelected;
  final VoidCallback onClose;
  final bool showModeToggle;
  final bool canSwitchModes;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        height: 36.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: _LessonShellIconButton(
                key: const ValueKey('lesson-shell-close-button'),
                onTap: onClose,
                assetPath: AppAsset.svg.app.icClose,
              ),
            ),
            if (showModeToggle)
              LessonModeToggle(
                selectedMode: selectedMode,
                onModeSelected: canSwitchModes ? onModeSelected : null,
              ),
            if (trailing != null)
              Positioned(
                right: 0,
                child: trailing!,
              ),
          ],
        ),
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
