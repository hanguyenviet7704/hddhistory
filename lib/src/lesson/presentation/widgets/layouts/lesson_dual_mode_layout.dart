part of '../../../lesson.dart';

class LessonDualModeLayout extends StatelessWidget {
  const LessonDualModeLayout({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.readBody,
    required this.audioBody,
    required this.isLoading,
    this.bottom,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode> onModeSelected;
  final VoidCallback onClose;
  final Widget readBody;
  final Widget audioBody;
  final Widget? bottom;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final activeBody = selectedMode.isAudio ? audioBody : readBody;

    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafePage(
        child: Unfocused(
          child: Column(
            children: [
              8.verticalSpace,
              _LessonDualModeHeader(
                selectedMode: selectedMode,
                onClose: onClose,
                onModeSelected: onModeSelected,
                canSwitchModes: !isLoading,
              ),
              20.verticalSpace,
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey(selectedMode),
                          child: activeBody,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BlocSelector<LessonCubit, LessonState, bool>(
                        selector: (state) => state.isBottomButtonVisible,
                        builder: (context, isVisible) {
                          if (selectedMode.isAudio || bottom == null) {
                            return const SizedBox.shrink();
                          }
                          return _AnimatedLessonBottomBar(
                            isVisible: isVisible,
                            child: bottom!,
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !isLoading,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isLoading ? const _LessonLoadingOverlay() : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonDualModeHeader extends StatelessWidget {
  const _LessonDualModeHeader({
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.canSwitchModes,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode> onModeSelected;
  final VoidCallback onClose;
  final bool canSwitchModes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20.w,
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: Center(
                  child: SvgPicture.asset(
                    AppAsset.svg.app.icClose,
                    width: 20.w,
                    height: 20.w,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFAAB8CD),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _LessonModeToggle(
            selectedMode: selectedMode,
            onModeSelected: canSwitchModes ? onModeSelected : null,
          ),
        ],
      ),
    );
  }
}

class _LessonModeToggle extends StatelessWidget {
  const _LessonModeToggle({
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
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F6),
          borderRadius: BorderRadius.circular(160.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LessonModeTab(
              label: context.l10n.lesson.audioReadLabel,
              iconAsset: AppAsset.svg.app.icMenu,
              isSelected: selectedMode.isRead,
              onTap: onModeSelected == null ? null : () => onModeSelected!(LessonEntryMode.read),
            ),
            SizedBox(width: 3.w),
            _LessonModeTab(
              label: context.l10n.lesson.audioListenLabel,
              iconAsset: AppAsset.svg.app.icMusicNote,
              isSelected: selectedMode.isAudio,
              onTap: onModeSelected == null ? null : () => onModeSelected!(LessonEntryMode.audio),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonModeTab extends StatelessWidget {
  const _LessonModeTab({
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
    final foregroundColor = isSelected ? const Color(0xFF0D121C) : const Color(0xFFAAB8CD);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30.h,
        padding: EdgeInsets.only(left: 12.w, right: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppCustomColor.backgroundWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(160.r),
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
            SizedBox(width: 8.w),
            AppText(
              label,
              style: (isSelected ? AppStyle.textBold14 : AppStyle.text14).copyWith(
                color: foregroundColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
