part of '../../home.dart';

class CourseCardWidget extends StatelessWidget {
  final UserProgressEntity courseProgress;
  final CourseEntity? course;
  final VoidCallback? onTap;

  const CourseCardWidget({
    super.key,
    required this.courseProgress,
    this.course,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 256.w,
        height: 102.h,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: AppCustomColor.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Course image
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: AppCustomColor.greyF5,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: course?.image.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          course!.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: AppCustomColor.grey9A,
                              size: 24.w,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.book,
                        color: AppCustomColor.grey9A,
                        size: 24.w,
                      ),
              ),
              12.horizontalSpace,
              // Course info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course title
                    AppText(
                      course?.title.text ?? 'Course',
                      style: AppStyle.textBold14.copyWith(
                        color: AppCustomColor.black36,
                      ),
                      maxLines: 1,
                    ),
                    4.verticalSpace,
                    // Course description
                    AppText(
                      course?.description.text ?? 'Course description',
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.grey69,
                      ),
                      maxLines: 2,
                    ),
                    const Spacer(),
                    // Progress bar
                    Container(
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: AppCustomColor.greyF5,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _calculateProgress(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppCustomColor.green61,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
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

  double _calculateProgress() {
    if (courseProgress.lessonsResult.isEmpty) return 0.0;

    final passedLessons = courseProgress.lessonsResult.where((lesson) => lesson.passed).length;

    return passedLessons / courseProgress.lessonsResult.length;
  }
}
