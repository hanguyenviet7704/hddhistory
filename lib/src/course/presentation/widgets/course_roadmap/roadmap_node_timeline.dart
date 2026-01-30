part of '../../../course.dart';

class _RoadmapNodeTimeline extends StatelessWidget {
  final List<LessonEntity> items;
  final List<LessonEntity> levelLessons;
  final int lockedLessonStartIndex;
  final CourseLevel courseLevel;
  final LessonEntity roleplay;

  const _RoadmapNodeTimeline({
    required this.items,
    required this.levelLessons,
    required this.lockedLessonStartIndex,
    required this.courseLevel,
    required this.roleplay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        return _RoadmapTimelineItem(
          lesson: items[index],
          isFirst: index == 0,
          isLast: index == items.length - 1,
          levelLessons: levelLessons,
          lockedLessonStartIndex: lockedLessonStartIndex,
          courseLevel: courseLevel,
          roleplay: roleplay,
        );
      }),
    );
  }
}

class _RoadmapTimelineItem extends StatelessWidget {
  final LessonEntity lesson;
  final bool isFirst;
  final bool isLast;
  final List<LessonEntity> levelLessons;
  final int lockedLessonStartIndex;
  final CourseLevel courseLevel;
  final LessonEntity roleplay;

  const _RoadmapTimelineItem({
    required this.lesson,
    required this.isFirst,
    required this.isLast,
    required this.levelLessons,
    required this.lockedLessonStartIndex,
    required this.courseLevel,
    required this.roleplay,
  });

  bool get _isLocked {
    final flatIndex = levelLessons.indexWhere((l) => l.id == lesson.id);
    return flatIndex >= 0 && flatIndex >= lockedLessonStartIndex;
  }

  String get _defaultIconAsset {
    if (lesson.type == LessonType.roleplay) return AppAsset.svg.app.icSend;
    if (lesson.type == LessonType.lesson) return AppAsset.svg.app.icBook;
    return AppAsset.svg.app.icAim;
  }

  String? get _iconUrl {
    if (lesson.icon.url.isNotEmpty) return lesson.icon.url;
    if (lesson.lightIcon.url.isNotEmpty) return lesson.lightIcon.url;
    return null;
  }

  Widget _buildIndicator(BuildContext context, bool isLocked) {
    final iconUrl = _iconUrl;
    return Container(
      padding: EdgeInsets.all(13.5.w),
      decoration: BoxDecoration(
        color: isLocked ? AppCustomColor.neutral100 : AppCustomColor.brandPrimary50,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: iconUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: iconUrl,
                  width: 28.w,
                  height: 28.w,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => SvgPicture.asset(
                    _defaultIconAsset,
                    width: 24.w,
                    height: 24.w,
                    colorFilter: ColorFilter.mode(
                      isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  errorWidget: (context, url, error) => SvgPicture.asset(
                    _defaultIconAsset,
                    width: 24.w,
                    height: 24.w,
                    colorFilter: ColorFilter.mode(
                      isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              )
            : SvgPicture.asset(
                _defaultIconAsset,
                width: 28.w,
                height: 28.w,
                colorFilter: ColorFilter.mode(
                  isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                  BlendMode.srcIn,
                ),
              ),
      ),
    );
  }

  void _onRoleplayTap(BuildContext context, bool isLocked) {
    if (isLocked) return;
    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackRoadmapItemClick(
        trackingData,
        itemType: 'roadmap_roleplay_item',
      );
    }
    context.read<CourseLessonCubit>()
      ..reset()
      ..loadLesson(lesson.id);
    LessonListRoute().go(context);
    context.read<CourseRoadmapCubit>()
      ..setCurrentCourseLevel(courseLevel)
      ..setCurrentLesson(lesson);
  }

  Widget _buildContent(BuildContext context, bool isLocked) {
    if (lesson.type == LessonType.roleplay) {
      return RoadmapRoleplayCard(
        lesson: lesson,
        isLocked: isLocked,
        onTap: () => _onRoleplayTap(context, isLocked),
      );
    }

    return LessonKeypointCard(
      courseLevel: courseLevel,
      premiumLesson: isLocked,
      lesson: lesson,
      lessonRolePlay: roleplay,
      onOverrideTap: lesson.type == LessonType.lesson
          ? () => RoadmapDetailPopup.show(
              context,
              lesson: lesson,
              courseLevel: courseLevel,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _isLocked;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        alignment: TimelineAlign.start,
        indicatorStyle: IndicatorStyle(
          width: 54.w,
          height: 54.w,
          padding: EdgeInsets.zero,
          indicator: _buildIndicator(context, isLocked),
        ),
        beforeLineStyle: const LineStyle(
          color: AppCustomColor.borderSecondary,
          thickness: 2.0,
          dotted: true,
          dotRadius: 2.0,
          dotSpacing: 6.0,
        ),
        afterLineStyle: const LineStyle(
          color: AppCustomColor.borderSecondary,
          thickness: 2.0,
          dotted: true,
          dotRadius: 2.0,
          dotSpacing: 6.0,
        ),
        endChild: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: _buildContent(context, isLocked),
        ),
      ),
    );
  }
}
