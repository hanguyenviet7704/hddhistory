part of '../../../course.dart';

class CourseRoadmapContent extends StatefulWidget {
  const CourseRoadmapContent({super.key});

  @override
  State<CourseRoadmapContent> createState() => _CourseRoadmapContentState();
}

class _CourseRoadmapContentState extends State<CourseRoadmapContent> {
  bool _isUserScrolling = false;
  // Anchors the "PHẦN" node (session) that holds the in-progress lesson, so we
  // can scroll it into view. A "PHẦN" is a node WITHIN a level (a level can hold
  // several), so we scroll to the node, not the level.
  final GlobalKey _currentLessonKey = GlobalKey();
  // Auto-scroll to the in-progress lesson every time the roadmap is ENTERED
  // (Course-tab tap, opened from Home, first mount) — not once-per-course: this
  // page is a kept-alive shell branch, so a once-per-course flag would never
  // re-fire on re-entry. Set when entry is requested but the roadmap hasn't
  // loaded yet (e.g. opened from Home for a new course); the load listener then
  // performs it. Progress ticks / pull-to-refresh (no entry) never scroll.
  bool _pendingAutoScroll = true;

  /// Request an auto-scroll on entering the roadmap: do it now if the roadmap is
  /// already loaded (tab re-entry), else defer to the load listener.
  void _requestAutoScrollToCurrentLesson(RoadmapEntity roadmap) {
    _pendingAutoScroll = true;
    if (roadmap.levels.isNotEmpty) _performAutoScrollToCurrentLesson(roadmap);
  }

  /// Scroll so the in-progress lesson's "PHẦN" node sits near the top. No-op
  /// while levels are loading, or for a not-started course (no in-progress
  /// lesson → leave the list at the top, per design).
  void _performAutoScrollToCurrentLesson(RoadmapEntity roadmap) {
    if (roadmap.levels.isEmpty) return;
    _pendingAutoScroll = false;
    // Not-started course → no in-progress lesson → leave the list at the top.
    if (roadmap.lastInProgressLesson == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _currentLessonKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.12,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

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
      child: MultiBlocListener(
        listeners: [
          // Entering the roadmap (tab tap / opened from Home) → jump to the
          // lesson in progress. Fires on the route-name transition only.
          BlocListener<PageCubit, PageState>(
            listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName && current.currentRouteName == RouteNamed.courseRoadmap,
            listener: (context, _) => _requestAutoScrollToCurrentLesson(context.read<CourseRoadmapCubit>().state.roadmap),
          ),
          // Roadmap finished loading / switched course while an entry scroll is
          // pending (e.g. opened from Home before levels arrived) → do it now.
          BlocListener<CourseRoadmapCubit, CourseRoadmapState>(
            listenWhen: (previous, current) => (previous.roadmap.levels.isEmpty && current.roadmap.levels.isNotEmpty) || previous.roadmap.courseId != current.roadmap.courseId,
            listener: (context, state) {
              if (_pendingAutoScroll) _performAutoScrollToCurrentLesson(state.roadmap);
            },
          ),
        ],
        child: RefreshIndicator(
          onRefresh: _refreshRoadmapAndProgress,
          child: BlocBuilder<CourseRoadmapCubit, CourseRoadmapState>(
            // This builder only reads roadmap + status (see body below) — the
            // inner ProgressCubit BlocBuilder just below already has its own
            // correctly-scoped buildWhen. CourseRoadmapCubit is high-frequency,
            // so without this the whole branch (including the ListView.separated)
            // re-evaluates on every emission.
            buildWhen: (previous, current) => previous.roadmap != current.roadmap || previous.status != current.status,
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
                      // floating "Start lesson" CTA (which sits above the nav
                      // bar). Derived from the nav bar's ACTUAL height (varies
                      // with the device's safe-area inset) instead of a flat
                      // guess, or it falls short on devices with a taller inset.
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, floatingNavBarHeight(context) + 60.h),
                      separatorBuilder: (context, index) => 20.verticalSpace,
                      itemCount: roadmap.levels.length,
                      itemBuilder: (context, index) {
                        final level = roadmap.levels[index];
                        return CourseLevelContent(
                          roadmapLevel: level,
                          // Anchor + target for auto-scroll: the level holding
                          // the in-progress lesson keys its matching "PHẦN" node
                          // with [_currentLessonKey] (null lesson = not started).
                          currentLesson: roadmap.lastInProgressLesson,
                          currentLessonKey: _currentLessonKey,
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
      ),
    );
  }
}
