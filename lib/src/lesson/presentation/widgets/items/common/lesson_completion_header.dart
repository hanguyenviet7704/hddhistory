part of '../../../../lesson.dart';

class LessonCompletionHeader extends StatelessWidget {
  const LessonCompletionHeader({
    super.key,
    this.title = 'Maintaining Appropriate Eye Contact',
    this.subtitle = 'Building Nonverbal Presence',
    this.margin = EdgeInsets.zero,
  });

  final String title;
  final String subtitle;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: AppCustomColor.successGreen,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_rounded,
              size: 16.sp,
              color: Colors.white,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  subtitle.toUpperCase(),
                  maxLines: 1,
                  style: AppStyle.text10.copyWith(
                    color: AppCustomColor.textTertiary,
                    height: 1.75,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                2.verticalSpace,
                AppText(
                  title,
                  maxLines: 2,
                  style: AppStyle.textBold14.copyWith(
                    color: AppCustomColor.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
