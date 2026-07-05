part of '../../../course.dart';

class CourseRoadmapContent extends StatefulWidget {
  const CourseRoadmapContent({super.key});

  @override
  State<CourseRoadmapContent> createState() => _CourseRoadmapContentState();
}

class _CourseRoadmapContentState extends State<CourseRoadmapContent> {
  bool _isUserScrolling = false;

  Future<void> _refreshRoadmapAndProgress() async {
    final roadmapCubit = context.read<CourseRoadmapCubit>();
    await roadmapCubit.loadRoadmap();
    final courseId = roadmapCubit.state.roadmap.courseId;
    if (!mounted) return;
    if (courseId.isNotEmpty) {
      await context.read<ProgressCubit>().loadAllUserProgresss(courseId: courseId, silent: true);
    }
  }

  void _showSubmitFailure() {
    if (!mounted) return;
    context.showDSnackBar(
      message: context.l10n.courseroadmap.additionalContentRequestSubmitFailure,
      type: MessageType.error,
    );
  }

  Future<bool> _submitAdditionalContentRequest({
    required CourseLevel level,
    required bool requested,
    String requestText = '',
  }) async {
    final success = await context.read<ProgressCubit>().submitCompletedLevelAdditionalContentRequest(
      level: level,
      requested: requested,
      requestText: requestText,
    );
    if (!success) _showSubmitFailure();
    return success;
  }

  void _showRequestPopup(CourseLevel level) {
    CompletedLevelAdditionalContentRequestPopup.show(
      context,
      onSubmit: (requestText) => _submitAdditionalContentRequest(
        level: level,
        requested: true,
        requestText: requestText,
      ),
    );
  }

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
        onRefresh: _refreshRoadmapAndProgress,
        child: BlocBuilder<CourseRoadmapCubit, CourseRoadmapState>(
          builder: (context, roadmapState) {
            final roadmap = roadmapState.roadmap;
            if (roadmap.levels.isEmpty) {
              final loadFailed = roadmapState.status == CourseRoadmapStatus.failure && roadmap.courseId.isNotEmpty;
              // A bare Center isn't scrollable, so RefreshIndicator could never
              // be triggered from the empty/failed state — wrap in an
              // always-scrollable view so pull-to-refresh works here too.
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: loadFailed
                        ? CourseRoadmapLoadFailureState(
                            onRetry: () => context.read<CourseRoadmapCubit>().loadRoadmap(),
                          )
                        : const CourseEmptyState(),
                  ),
                ),
              );
            }
            final paywallConfig = AppService.instance.remoteConfigService.paywallConfig;
            final isPremium = context.read<ProfileCubit>().state.user.isPremium;
            final lockedLessonKeys = roadmap.lockedLessonKeys(paywallConfig, isPremium: isPremium);
            return BlocBuilder<ProgressCubit, ProgressState>(
              // The roadmap list only reads userCourseProgress + the
              // additional-content submit flag. Without buildWhen the whole
              // ListView.separated rebuilds on every unrelated progress change
              // (lesson/keypoint/exercise results, status flips, etc.).
              buildWhen: (previous, current) =>
                  previous.userCourseProgress != current.userCourseProgress ||
                  previous.isSubmittingCompletedLevelAdditionalContentRequest != current.isSubmittingCompletedLevelAdditionalContentRequest,
              builder: (context, progressState) {
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) => _handleScrollNotification(notification, roadmap),
                  child: ListView.separated(
                    // Bottom padding so the last card scrolls clear of the
                    // floating "Start lesson" CTA (which sits above the nav bar).
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 180.h),
                    separatorBuilder: (context, index) => 20.verticalSpace,
                    itemCount: roadmap.levels.length,
                    itemBuilder: (context, index) {
                      final level = roadmap.levels[index];
                      return CourseLevelContent(
                        roadmapLevel: level,
                        enableSequentialUnlock: roadmap.levelSequentialUnlockFlags.elementAt(index),
                        lockedLessonKeys: lockedLessonKeys,
                        additionalContentRequestStatus: roadmap.additionalContentRequestStateFor(
                          level: level.level,
                          userProgress: progressState.userCourseProgress,
                        ),
                        isSubmittingAdditionalContentRequest: progressState.isSubmittingCompletedLevelAdditionalContentRequest,
                        onNoAdditionalContentRequest: () => _submitAdditionalContentRequest(
                          level: level.level,
                          requested: false,
                        ),
                        onYesAdditionalContentRequest: () => _showRequestPopup(level.level),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
