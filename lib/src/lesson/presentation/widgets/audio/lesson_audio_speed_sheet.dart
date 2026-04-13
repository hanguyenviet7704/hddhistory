part of '../../../lesson.dart';

Future<void> showLessonAudioSpeedSheet(
  BuildContext context, {
  required double initialSpeed,
  required ValueChanged<double> onSpeedChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppCustomColor.scrimOverlay,
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
          return SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppCustomColor.backgroundWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                context.l10n.lesson.audioSpeedTitle,
                                style: AppStyle.text18.copyWith(
                                  color: const Color(0xFF0D121C),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.back(),
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
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
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
                                    color: const Color(0xFF554FF0),
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
                                      onTap: () => updateSpeed(setState, speed),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF0D121C) : const Color(0xFFEEF2F6),
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        alignment: Alignment.center,
                                        child: AppText(
                                          label,
                                          style: (isSelected ? AppStyle.textBold14 : AppStyle.text14).copyWith(
                                            color: isSelected ? Colors.white : const Color(0xFF364152),
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48.r,
        height: 48.r,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F6),
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: const Color(0xFF0D121C),
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
