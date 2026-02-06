part of '../../../course.dart';

class CourseRoadmapContent extends StatefulWidget {
  const CourseRoadmapContent({super.key});

  @override
  State<CourseRoadmapContent> createState() => _CourseRoadmapContentState();
}

class _CourseRoadmapContentState extends State<CourseRoadmapContent> {
  bool _isUserScrolling = false;

  bool _handleScrollNotification(
    ScrollNotification notification,
    RoadmapEntity roadmap,
  ) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      _isUserScrolling = true;
      return false;
    }
    if (notification is ScrollEndNotification) {
      if (!_isUserScrolling) return false;
      _isUserScrolling = false;
      final trackingData = CourseTrackingData.fromCourseId(context, roadmap.courseId);
      if (trackingData == null) return false;
      AppService.instance.appTrackingService.trackRoadmapItemScroll(trackingData);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async => context.read<CourseRoadmapCubit>().loadRoadmap(),
        child: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, RoadmapEntity>(
          selector: (state) => state.roadmap,
          builder: (context, roadmap) {
            if (roadmap.levels.isEmpty) return const CourseEmptyState();
            final paywallConfig = AppService.instance.remoteConfigService.paywallConfig;
            final lockedLessonKeys = roadmap.lockedLessonKeys(paywallConfig);
            return NotificationListener<ScrollNotification>(
              onNotification: (notification) => _handleScrollNotification(notification, roadmap),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                separatorBuilder: (context, index) => 20.verticalSpace,
                itemCount: roadmap.levels.length,
                itemBuilder: (context, index) {
                  return CourseLevelContent(
                    roadmapLevel: roadmap.levels[index],
                    enableSequentialUnlock: roadmap.levelSequentialUnlockFlags.elementAt(index),
                    lockedLessonKeys: lockedLessonKeys,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
