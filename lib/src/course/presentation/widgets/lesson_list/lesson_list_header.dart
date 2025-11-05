part of '../../../course.dart';

class LessonListHeader extends StatelessWidget {
  final LessonEntity lesson;

  const LessonListHeader({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppCustomColor.borderDefault,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "LESSON" label
          AppText(
            'LESSON',
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),

          // Lesson title
          AppText(
            lesson.title.text,
            style: AppStyle.text24.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),

          // Duration badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundBrand,
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16.sp,
                  color: AppCustomColor.brandPrimary,
                ),
                SizedBox(width: 8.w),
                AppText(
                  lesson.estimateCompleTime.text,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.brandPrimary,
                    fontWeight: FontWeight.w600,
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
