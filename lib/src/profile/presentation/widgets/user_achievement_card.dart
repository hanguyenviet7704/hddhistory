part of '../../profile.dart';

class UserAchievementCard extends StatelessWidget {
  const UserAchievementCard({
    super.key,
    required this.achievement,
  });

  final AchievenmentResponseEntity achievement;

  @override
  Widget build(BuildContext context) {
    final int totalCourses = achievement.totalCourse;
    final int completedCourses = achievement.completedCourse;
    final int unlockedCourses = _countUnlockedCourses(achievement.courses);
    final bool useUnlockedLabel = completedCourses == 0 && unlockedCourses > 0;

    final String subtitle = useUnlockedLabel
        ? '$unlockedCourses of $totalCourses unlocked'
        : '$completedCourses of $totalCourses completed';

    final bool useLargeLayout = achievement.courses.length <= 2;
    final double itemWidth = useLargeLayout ? 137.w : 90.w;
    final TextStyle itemTitleStyle = useLargeLayout
        ? AppStyle.text12.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.5,
          )
        : AppStyle.text10.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.75,
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppCustomColor.backgroundGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault,
            blurRadius: 4.r,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAchievementHeader(
            title: achievement.skillsetTitle.text,
            subtitle: subtitle,
          ),
          SizedBox(height: 12.h),
          _UserAchievementCourseRow(
            courses: achievement.courses,
            itemWidth: itemWidth,
            itemTitleStyle: itemTitleStyle,
          ),
        ],
      ),
    );
  }

  int _countUnlockedCourses(List<CourseLevelProgressEntity> courses) {
    return courses.where((course) => course.completedKeypoints > 0 || course.isCompleted).length;
  }
}

class _UserAchievementHeader extends StatelessWidget {
  const _UserAchievementHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: AppStyle.text14.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w700,
            height: 1.75,
          ),
        ),
        AppText(
          subtitle,
          style: AppStyle.text10.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w600,
            height: 1.75,
          ),
        ),
      ],
    );
  }
}

class _UserAchievementCourseRow extends StatelessWidget {
  const _UserAchievementCourseRow({
    required this.courses,
    required this.itemWidth,
    required this.itemTitleStyle,
  });

  final List<CourseLevelProgressEntity> courses;
  final double itemWidth;
  final TextStyle itemTitleStyle;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 146.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            courses.length,
            (index) => Padding(
              padding: EdgeInsets.only(right: index == courses.length - 1 ? 0 : 24.w),
              child: UserAchievementCourseItem(
                course: courses[index],
                itemWidth: itemWidth,
                titleStyle: itemTitleStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
