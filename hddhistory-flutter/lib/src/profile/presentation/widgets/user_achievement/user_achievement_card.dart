part of '../../../profile.dart';

class UserAchievementCard extends StatelessWidget {
  final AchievenmentResponseEntity achievement;

  const UserAchievementCard({
    super.key,
    required this.achievement,
  });

  int get totalCourses => achievement.totalCourse;
  int get completedCourses => achievement.completedCourse;

  String subtitle(BuildContext context) => context.l10n.setting.achievementsCompletedCount(
    completed: completedCourses,
    total: totalCourses,
  );

  @override
  Widget build(BuildContext context) {
    if (totalCourses == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _UserAchievementHeader(
          title: achievement.categoryTitle.text,
          subtitle: subtitle(context),
        ),
        12.verticalSpace,
        _UserAchievementCourseRow(
          courses: achievement.courses,
          categoryId: achievement.categoryId,
          categoryName: achievement.categoryTitle.en.isNotEmpty ? achievement.categoryTitle.en : achievement.categoryTitle.text,
          itemTitleStyle: AppStyle.text12.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.75,
          ),
        ),
      ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.textBold16.copyWith(
              color: AppCustomColor.textPrimary,
              height: 1.5,
            ),
          ),
        ),
        AppText(
          subtitle,
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textTertiary,
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
  final String categoryId;
  final String categoryName;

  const _UserAchievementCourseRow({
    required this.courses,
    required this.itemTitleStyle,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return _UserAchievementCourseRowBody(
      courses: courses,
      categoryId: categoryId,
      categoryName: categoryName,
      itemTitleStyle: itemTitleStyle,
    );
  }
}

class _UserAchievementCourseRowBody extends StatefulWidget {
  final List<CourseLevelProgressEntity> courses;
  final TextStyle itemTitleStyle;
  final String categoryId;
  final String categoryName;

  const _UserAchievementCourseRowBody({
    required this.courses,
    required this.itemTitleStyle,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<_UserAchievementCourseRowBody> createState() => _UserAchievementCourseRowBodyState();
}

class _UserAchievementCourseRowBodyState extends State<_UserAchievementCourseRowBody> {
  bool _hasTrackedSlide = false;

  String _resolveCourseName(CourseLevelProgressEntity course) {
    final String name = course.courseTitle.en.trim();
    if (name.isNotEmpty) return name;
    return course.title;
  }

  CourseTrackingData _buildTrackingData(CourseLevelProgressEntity course) {
    return CourseTrackingData.fromTrackingValues(
      categoryId: widget.categoryId,
      categoryName: widget.categoryName,
      courseId: course.courseId,
      courseName: _resolveCourseName(course),
    );
  }

  bool _handleScroll(ScrollNotification notification) {
    if (_hasTrackedSlide) return false;
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (notification is ScrollUpdateNotification && notification.metrics.pixels != notification.metrics.minScrollExtent) {
      if (widget.courses.isEmpty) return false;
      AppService.instance.appTrackingService.trackSettingBadgeSlide(_buildTrackingData(widget.courses.first));
      _hasTrackedSlide = true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(right: 20.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            widget.courses.length,
            (index) => Padding(
              padding: EdgeInsets.only(right: index == widget.courses.length - 1 ? 0 : 8.w),
              child: UserAchievementCourseItem(
                course: widget.courses[index],
                titleStyle: widget.itemTitleStyle,
                categoryId: widget.categoryId,
                categoryName: widget.categoryName,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
