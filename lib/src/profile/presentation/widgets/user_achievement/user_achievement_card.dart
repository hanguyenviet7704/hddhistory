part of '../../../profile.dart';

class UserAchievementCard extends StatelessWidget {
  final AchievenmentResponseEntity achievement;

  const UserAchievementCard({
    super.key,
    required this.achievement,
  });

  int get totalCourses => achievement.totalCourse;
  int get completedCourses => achievement.completedCourse;

  String subtitle(BuildContext context) => context.text.setting.achievementsCompletedCount(
    completed: completedCourses,
    total: totalCourses,
  );

  @override
  Widget build(BuildContext context) {
    if (totalCourses == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      margin: EdgeInsets.only(bottom: 16.h),
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
            subtitle: subtitle(context),
          ),
          12.verticalSpace,
          _UserAchievementCourseRow(
            courses: achievement.courses,
            itemTitleStyle: AppStyle.text10.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
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
  final List<CourseLevelProgressEntity> courses;
  final TextStyle itemTitleStyle;

  const _UserAchievementCourseRow({
    required this.courses,
    required this.itemTitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          courses.length,
          (index) => Padding(
            padding: EdgeInsets.only(right: index == courses.length - 1 ? 0 : 24.w),
            child: UserAchievementCourseItem(
              course: courses[index],
              titleStyle: itemTitleStyle,
            ),
          ),
        ),
      ),
    );
  }
}
