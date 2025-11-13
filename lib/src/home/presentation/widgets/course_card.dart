part of '../../home.dart';

class CourseCardWidget extends StatelessWidget {
  final CourseEntity course;

  const CourseCardWidget({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<HomeCubit>()
          ..selectSkillset(course.skillset)
          ..selectCourse(course);
        CourseRoadmapRoute().go(context);
        context.read<PageCubit>().setCurrentIndex(1);
      },
      child: Container(
        width: 256.w,
        margin: EdgeInsets.only(right: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppCustomColor.borderSecondary,
            width: 2.w,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Course image
                DCachedImage(
                  url: course.image,
                  width: 50.w,
                  height: 50.w,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                12.horizontalSpace,
                // Course info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        course.skillset.title.text,
                        style: AppStyle.textBold12.copyWith(color: AppCustomColor.brandPrimary),
                        maxLines: 1,
                      ),
                      // Course description
                      AppText(
                        course.title.text,
                        style: AppStyle.textBold14.copyWith(color: AppCustomColor.textSecondary),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (kDebugMode) ...[
              12.verticalSpace,
              LinearPercentIndicator(
                animation: true,
                animationDuration: 500,
                animateFromLastPercent: true,
                lineHeight: 10.h,
                percent: 0.5,
                backgroundColor: const Color(0xFFE3E8EF), // Neutral/200
                progressColor: const Color(0xFF0D121C), // Brand/Brand/Primary/300
                barRadius: Radius.circular(30.r),
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
