part of '../../../lesson.dart';

const _lessonAudioSpeedSheetSurfaceKey = ValueKey('lesson-audio-speed-sheet-surface');

Future<void> showLessonAudioSpeedSheet(
  BuildContext context, {
  required double initialSpeed,
  required ValueChanged<double> onSpeedChanged,
}) {
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppCustomColor.scrimOverlay,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26.r))),
    builder: (context) {
      double selectedSpeed = initialSpeed;

      void updateSpeed(StateSetter setState, double nextSpeed) {
        final normalizedSpeed = nextSpeed.clamp(
          LessonAudioStateX.supportedSpeeds.first,
          LessonAudioStateX.supportedSpeeds.last,
        );
        if (selectedSpeed == normalizedSpeed) return;
        setState(() => selectedSpeed = normalizedSpeed);
        onSpeedChanged(normalizedSpeed);
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: _lessonAudioSpeedSheetSurfaceKey,
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset + 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 14.h, bottom: 4.h),
                        child: Center(
                          child: Container(
                            width: 40.w,
                            height: 5.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDADCE4),
                              borderRadius: BorderRadius.circular(99.r),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                context.l10n.lesson.audioSpeedTitle,
                                style: AppStyle.text18.copyWith(
                                  color: AppCustomColor.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                AppHaptic.select();
                                context.back();
                              },
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
                                      Color(0xFF7F8EA4),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LessonAudioSpeedAdjustButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    final currentIndex = LessonAudioStateX.supportedSpeeds.indexOf(selectedSpeed);
                                    if (currentIndex <= 0) return;
                                    updateSpeed(setState, LessonAudioStateX.supportedSpeeds[currentIndex - 1]);
                                  },
                                ),
                                SizedBox(width: 32.w),
                                AppText(
                                  _lessonAudioSpeedTitle(selectedSpeed),
                                  style: AppStyle.textBold32.copyWith(
                                    color: AppCustomColor.brandPrimary,
                                  ),
                                ),
                                SizedBox(width: 32.w),
                                _LessonAudioSpeedAdjustButton(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    final currentIndex = LessonAudioStateX.supportedSpeeds.indexOf(selectedSpeed);
                                    if (currentIndex == -1 || currentIndex >= LessonAudioStateX.supportedSpeeds.length - 1) return;
                                    updateSpeed(setState, LessonAudioStateX.supportedSpeeds[currentIndex + 1]);
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Row(
                              children: LessonAudioStateX.supportedSpeeds.map((speed) {
                                final isSelected = selectedSpeed == speed;
                                final label = speed == 1.0 ? context.l10n.lesson.audioSpeedNormal : _lessonAudioSpeedLabel(speed);

                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                                    child: GestureDetector(
                                      onTap: () {
                                        AppHaptic.select();
                                        updateSpeed(setState, speed);
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        height: 48.h,
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.inputFill,
                                          borderRadius: BorderRadius.circular(13.r),
                                        ),
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                                        child: AppText(
                                          label,
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          // "Bình thường" is wider than the "x"
                                          // labels; shrink to fit the equal-width
                                          // pill on one line instead of wrapping
                                          // (which overflowed the fixed height).
                                          enableFitScaleDown: true,
                                          style: (isSelected ? AppStyle.textBold14 : AppStyle.text14).copyWith(
                                            color: isSelected ? Colors.white : AppCustomColor.textSecondary,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _LessonAudioSpeedAdjustButton extends StatelessWidget {
  const _LessonAudioSpeedAdjustButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52.r,
        height: 52.r,
        decoration: BoxDecoration(
          color: AppCustomColor.inputFill,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: AppCustomColor.textPrimary,
          size: 20.sp,
        ),
      ),
    );
  }
}

String _lessonAudioSpeedLabel(double speed) {
  final normalized = speed.toStringAsFixed(speed.truncateToDouble() == speed ? 0 : 2);
  return '${normalized.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}x';
}

String _lessonAudioSpeedTitle(double speed) {
  if (speed == 1.0) return '1.0x';
  return _lessonAudioSpeedLabel(speed);
}
