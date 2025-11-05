part of '../../../course.dart';

class CourseCard extends StatelessWidget {
  final CourseEntity course;
  final bool showProgress;
  final int? completedLessons;
  final int? totalLessons;
  final bool isSelected;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.showProgress = false,
    this.completedLessons,
    this.totalLessons,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(8.w),
        child: Row(
          children: [
            // Course image
            DCachedImage(
              url: course.image,
              width: 80.w,
              height: 80.w,
              borderRadius: BorderRadius.circular(12.r),
            ),
            16.horizontalSpace,
            // Course info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    course.title.text,
                    style: AppStyle.text16.copyWith(
                      color: AppCustomColor.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  8.verticalSpace,
                  if (showProgress && completedLessons != null && totalLessons != null)
                    _buildProgressView()
                  else
                    _buildLessonCountView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressView() {
    final progress = totalLessons! > 0 ? completedLessons! / totalLessons! : 0.0;

    return Row(
      children: [
        // Progress bar
        Container(
          width: 60.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: AppCustomColor.greyE3,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppCustomColor.black0D,
                borderRadius: BorderRadius.circular(18.r),
              ),
            ),
          ),
        ),
        6.horizontalSpace,
        AppText(
          '$completedLessons/$totalLessons Lessons',
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCountView() {
    return Row(
      children: [
        Icon(
          Icons.description_outlined,
          size: 16.w,
          color: AppCustomColor.textTertiary,
        ),
        8.horizontalSpace,
        AppText(
          '${course.numberOfLesson} lessons',
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
