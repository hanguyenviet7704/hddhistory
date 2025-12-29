part of '../../../profile.dart';

class UserAchievementDetailCard extends StatelessWidget {
  final CourseLevelProgressEntity course;

  const UserAchievementDetailCard({
    super.key,
    required this.course,
  });

  String get title {
    final String courseTitle = course.courseTitle.text.trim();
    if (courseTitle.isNotEmpty) return courseTitle;
    return course.titleBadge.text.trim();
  }

  String get levelNumber => course.level.number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _UserAchievementDetailHeader(
            levelLabel: context.text.setting.achievementsLevelLabel(level: levelNumber),
            title: title,
          ),
          24.verticalSpace,
          _UserAchievementDetailBadge(course: course),
          24.verticalSpace,
          _UserAchievementDetailProgress(
            label: context.text.setting.achievementsCompleteCourseAtLevel(level: levelNumber),
            progress: course.progress,
            percent: course.progressPercent,
          ),
        ],
      ),
    );
  }
}

class _UserAchievementDetailHeader extends StatelessWidget {
  const _UserAchievementDetailHeader({
    required this.levelLabel,
    required this.title,
  });

  final String levelLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          levelLabel,
          textAlign: TextAlign.center,
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w600,
            height: 1.75,
          ),
        ),
        AppText(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppStyle.text24.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _UserAchievementDetailBadge extends StatelessWidget {
  const _UserAchievementDetailBadge({required this.course});

  final CourseLevelProgressEntity course;

  String get _badgeUrl {
    if (course.isCompleted) return course.lightBadge.trim();
    if (course.darkBadge.trim().isNotEmpty) return course.darkBadge.trim();
    return course.lightBadge.trim();
  }

  @override
  Widget build(BuildContext context) {
    final double width = 120.w;
    final double height = 150.h;

    if (_badgeUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppCustomColor.borderSecondary,
          borderRadius: BorderRadius.circular(16.r),
        ),
      );
    }

    return CacheNetworkGraphic(
      url: _badgeUrl,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

class _UserAchievementDetailProgress extends StatelessWidget {
  const _UserAchievementDetailProgress({
    required this.label,
    required this.progress,
    required this.percent,
  });

  final String label;
  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          label,
          textAlign: TextAlign.center,
          style: AppStyle.text16.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        8.verticalSpace,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAchievementProgressBar(
              progress: progress,
              width: 90.w,
              height: 8.h,
            ),
            12.horizontalSpace,
            AppText(
              '$percent%',
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textTertiary,
                fontWeight: FontWeight.w700,
                height: 1.75,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
