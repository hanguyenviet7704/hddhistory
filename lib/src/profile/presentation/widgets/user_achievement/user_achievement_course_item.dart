part of '../../../profile.dart';

class UserAchievementCourseItem extends StatelessWidget {
  const UserAchievementCourseItem({
    super.key,
    required this.course,
    required this.titleStyle,
  });

  final CourseLevelProgressEntity course;
  final TextStyle titleStyle;

  String get _title {
    final String courseTitle = course.courseTitle.text.trim();
    if (courseTitle.isNotEmpty) return courseTitle;
    return course.titleBadge.text.trim();
  }

  double get _progress {
    if (course.totalKeypoints <= 0) return 0;
    return course.completedKeypoints / course.totalKeypoints;
  }

  @override
  Widget build(BuildContext context) {
    final bool showProgress = course.totalKeypoints > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UserAchievementBadge(course: course),
        16.verticalSpace,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              _title,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
            if (showProgress) ...[
              8.verticalSpace,
              UserAchievementProgressBar(progress: _progress),
            ],
          ],
        ),
      ],
    );
  }
}

class _UserAchievementBadge extends StatelessWidget {
  final CourseLevelProgressEntity course;

  const _UserAchievementBadge({required this.course});

  String get badgeUrl {
    if (course.isCompleted) {
      return course.lightBadge.trim();
    }
    if (course.darkBadge.trim().isNotEmpty) {
      return course.darkBadge.trim();
    }
    return course.lightBadge.trim();
  }

  @override
  Widget build(BuildContext context) {
    final double width = 64.w;
    final double height = 80.h;

    if (badgeUrl.isEmpty) {
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
      url: badgeUrl,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
