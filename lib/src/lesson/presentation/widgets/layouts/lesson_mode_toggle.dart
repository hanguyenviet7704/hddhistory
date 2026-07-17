part of '../../../lesson.dart';

class LessonModeToggle extends StatelessWidget {
  const LessonModeToggle({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode>? onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onModeSelected == null ? 0.6 : 1,
      child: Container(
        height: 36.h,
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary700.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.borderDefault,
              blurRadius: 4.r,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LessonModeToggleTab(
              key: const ValueKey('lesson-mode-read-tab'),
              label: context.l10n.lesson.audioReadLabel,
              iconAsset: AppAsset.svg.app.icMenu,
              isSelected: selectedMode.isRead,
              onTap: onModeSelected == null
                  ? null
                  : () {
                      AppHaptic.select();
                      onModeSelected!(LessonEntryMode.read);
                    },
            ),
            SizedBox(width: 4.w),
            _LessonModeToggleTab(
              key: const ValueKey('lesson-mode-audio-tab'),
              label: context.l10n.lesson.audioListenLabel,
              iconAsset: AppAsset.svg.app.icMusicNote,
              isSelected: selectedMode.isAudio,
              onTap: onModeSelected == null
                  ? null
                  : () {
                      AppHaptic.select();
                      onModeSelected!(LessonEntryMode.audio);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonModeToggleTab extends StatelessWidget {
  const _LessonModeToggleTab({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? AppCustomColor.textBrand : AppCustomColor.textQuaternary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32.h,
        padding: EdgeInsets.only(left: 12.w, right: isSelected ? 16.w : 12.w),
        decoration: BoxDecoration(
          color: isSelected ? AppCustomColor.backgroundWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 20.w,
              height: 20.w,
              colorFilter: ColorFilter.mode(
                foregroundColor,
                BlendMode.srcIn,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8.w),
              AppText(
                label,
                style: AppStyle.textBold14.copyWith(
                  color: foregroundColor,
                  height: 1.75,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
