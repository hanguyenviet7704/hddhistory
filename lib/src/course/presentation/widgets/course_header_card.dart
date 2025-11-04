part of '../../course.dart';

class CourseHeaderCard extends StatelessWidget {
  final CourseEntity course;
  final int completedLessons;
  final int totalLessons;

  const CourseHeaderCard({
    super.key,
    required this.course,
    required this.completedLessons,
    required this.totalLessons,
  });

  String _getLevelText() {
    switch (course.level) {
      case CourseLevel.level1:
        return 'Level 1';
      case CourseLevel.level2:
        return 'Level 2';
    }
  }

  double get _progressPercent {
    if (totalLessons == 0) return 0;
    return completedLessons / totalLessons;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault,
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course title
          AppText(
            course.title.text,
            style: AppStyle.text24.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          8.verticalSpace,
          // Course description
          if (course.description.en.isNotEmpty)
            AppText(
              course.description.text,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (course.description.en.isNotEmpty) 12.verticalSpace,
          // Level indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppCustomColor.greyE3,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: AppText(
              _getLevelText(),
              style: AppStyle.text12.copyWith(
                fontWeight: FontWeight.w500,
                color: AppCustomColor.textSecondary,
              ),
              maxLines: 1,
            ),
          ),
          16.verticalSpace,
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: _progressPercent,
                    backgroundColor: AppCustomColor.borderSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppCustomColor.black0D,
                    ),
                    minHeight: 9.h,
                  ),
                ),
              ),
              12.horizontalSpace,
              // Lesson count
              AppText(
                '$completedLessons/$totalLessons Lessons',
                style: AppStyle.text14.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppCustomColor.textPrimary,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
