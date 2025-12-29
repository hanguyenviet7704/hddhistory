part of '../../profile.dart';

class UserAchievementCourseItem extends StatelessWidget {
  const UserAchievementCourseItem({
    super.key,
    required this.course,
    required this.itemWidth,
    required this.titleStyle,
  });

  final CourseLevelProgressEntity course;
  final double itemWidth;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    final String title = _resolveTitle();
    final bool showProgress = course.totalKeypoints > 0;

    return SizedBox(
      width: itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UserAchievementBadge(course: course),
          SizedBox(height: 16.h),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              if (showProgress) ...[
                SizedBox(height: 8.h),
                UserAchievementProgressBar(progress: _progress),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _resolveTitle() {
    final String courseTitle = course.courseTitle.text.trim();
    if (courseTitle.isNotEmpty) return courseTitle;
    return course.titleBadge.text.trim();
  }

  double get _progress {
    if (course.totalKeypoints <= 0) return 0;
    return course.completedKeypoints / course.totalKeypoints;
  }
}

class _UserAchievementBadge extends StatelessWidget {
  const _UserAchievementBadge({required this.course});

  final CourseLevelProgressEntity course;

  @override
  Widget build(BuildContext context) {
    final double width = 64.w;
    final double height = 80.h;
    final String badgeUrl = _resolveBadgeUrl();

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

    final bool showOverlay = !course.isCompleted && course.darkBadge.isEmpty;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CacheNetworkGraphic(
            url: badgeUrl,
            width: width,
            height: height,
            fit: BoxFit.contain,
          ),
          if (showOverlay)
            Container(
              color: AppCustomColor.backgroundWhite.op(0.8),
            ),
        ],
      ),
    );
  }

  String _resolveBadgeUrl() {
    if (course.isCompleted) {
      return course.lightBadge.trim();
    }
    if (course.darkBadge.trim().isNotEmpty) {
      return course.darkBadge.trim();
    }
    return course.lightBadge.trim();
  }
}
