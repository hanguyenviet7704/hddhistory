part of '../../../profile.dart';

class UserAchievementCourseItem extends StatelessWidget {
  final CourseLevelProgressEntity course;
  final TextStyle titleStyle;

  const UserAchievementCourseItem({
    super.key,
    required this.course,
    required this.titleStyle,
  });

  void _onTap(BuildContext context) {
    context.read<AchievenmentProgressCubit>().loadCourseLevelProgress(course.courseId);
    UserAchievementBottomSheet.show(
      context,
      courseId: course.courseId,
      initialLevel: course.level,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UserAchievementBadge(course: course),
          16.verticalSpace,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                course.title,
                maxLines: 2,
                width: 100.w,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              if (!course.hideProgress) ...[
                8.verticalSpace,
                UserAchievementProgressBar(progress: course.progress),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAchievementBadge extends StatelessWidget {
  final CourseLevelProgressEntity course;

  const _UserAchievementBadge({required this.course});

  @override
  Widget build(BuildContext context) {
    final double width = 64.w;
    final double height = 80.h;

    if (course.badgeUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppCustomColor.borderSecondary,
          borderRadius: BorderRadius.circular(12.r),
        ),
      );
    }

    return CacheNetworkGraphic(
      url: course.badgeUrl,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
