part of '../../../course.dart';

class LessonListHeader extends StatelessWidget {
  final LessonEntity lesson;

  const LessonListHeader({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "LESSON" label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            36.horizontalSpace,
            AppText(
              context.l10n.allcourse.lessonLabel,
              style: AppStyle.text12.copyWith(
                color: AppCustomColor.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36.w,
                height: 36.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 24.sp,
                    color: AppCustomColor.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Lesson title
        AppText(
          lesson.title.text,
          maxLines: 3,
          textAlign: TextAlign.center,
          style: AppStyle.text24.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        8.verticalSpace,

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
              8.horizontalSpace,
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
    );
  }
}
