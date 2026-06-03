part of '../../../lesson.dart';

class LessonAudioSpeedPill extends StatelessWidget {
  const LessonAudioSpeedPill({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            label,
            style: AppStyle.textBold14.copyWith(
              color: AppCustomColor.textBrand,
              height: 1.75,
            ),
          ),
        ),
      ),
    );
  }
}
