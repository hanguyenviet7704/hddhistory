part of '../../course.dart';

class CourseRoadmapPage extends StatefulWidget {
  const CourseRoadmapPage({super.key});

  @override
  State<CourseRoadmapPage> createState() => _CourseRoadmapPageState();
}

class _CourseRoadmapPageState extends State<CourseRoadmapPage> {
  bool _hasTrackedForVisibility = false;
  String _lastTrackedCourseId = '';
  String _lastLoadedProgressCourseId = '';

  /// Roadmap-source values that mean the user opened this roadmap FROM Explore
  /// (the course grid, "My courses", "View more", or search). Only these show a
  /// back button. Other sources (Courses tab default, Home cards) show none.
  static const _kExploreSources = {
    'course_selection',
    'my_courses',
    'skillset_courses',
    'search',
  };

  /// Returns to wherever the user opened this roadmap from.
  /// CourseCubit/PageCubit aren't provided above the roadmap tree, so resolve
  /// them from DI (see [TopProgressBar]).
  void _backFromRoadmap(BuildContext context, String source) {
    // "View more" opened the full one-skillset grid (SkillsetCoursesRoute, a
    // child of the roadmap route) — go back to that exact page.
    if (source == 'skillset_courses') {
      final skillsetId = AppDI.injector.get<HomeCubit>().state.currentSkillset.id;
      if (skillsetId.isNotEmpty) {
        SkillsetCoursesRoute(skillsetId: skillsetId).go(context);
        context.read<PageCubit>().setCurrentRouteName(RouteNamed.skillsetCourses);
        return;
      }
    }
    // Grid / My courses / search live on the Explore tab — return to it at the
    // current skillset (mirrors the header dropdown's navigation).
    final skillsetIndex =
        AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
    AppDI.injector.get<CourseCubit>()
      ..setAllCourseSource('roadmap_back')
      ..jumpToSkillset(skillsetIndex);
    context.read<PageCubit>().setCurrentIndex(3);
    CourseRoute(selectedTabIndex: skillsetIndex).go(context);
  }

  void _trackRoadmapQuickLearningClick() {
    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final courseId = roadmapState.roadmap.courseId;
    if (courseId.isEmpty) return;
    final trackingData = CourseTrackingData.fromCourseId(context, courseId);
    if (trackingData == null) return;
    final hasProgress = roadmapState.roadmap.levels.any((level) => level.hasRoadmapProgress);
    final actionType = hasProgress ? 'continue_learning' : 'start_lesson';
    AppService.instance.appTrackingService.trackRoadmapQuickLearningClick(
      trackingData,
      actionType: actionType,
    );
  }

  void _trackRoadmapScrView() {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final courseId = roadmapState.roadmap.courseId;
    if (courseId.isEmpty) return;
    if (_hasTrackedForVisibility && _lastTrackedCourseId == courseId) return;
    final trackingData = CourseTrackingData.fromCourseId(context, courseId);
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoadmapScrView(
      trackingData,
      roadmapSource: roadmapState.roadmapSource,
    );
    _lastTrackedCourseId = courseId;
    _hasTrackedForVisibility = true;
  }

  void _loadProgressForRoadmap(String courseId, {bool force = false}) {
    if (courseId.isEmpty) return;
    if (!force && _lastLoadedProgressCourseId == courseId) return;
    _lastLoadedProgressCourseId = courseId;
    unawaited(context.read<ProgressCubit>().loadAllUserProgresss(courseId: courseId, silent: true));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<PageCubit>().state.currentRouteName == RouteNamed.courseRoadmap) {
        _trackRoadmapScrView();
        _loadProgressForRoadmap(context.read<CourseRoadmapCubit>().state.roadmap.courseId);
      }
    });
  }

  void _tryShowRoleplayIncompleteFeedback(FeedbackState state) {
    final pendingEntry = state.pendingFeedbackIncompletePrompt;
    if (pendingEntry == null) return;
    if (state.status != FeedbackStatus.success) return;
    if (pendingEntry == FeedbackEntry.roleplay && state.userFeedback.userHasRoleplayFeedbackIncomplete) {
      context.read<FeedbackCubit>().clearIncompleteFeedbackPrompt();
      return;
    }
    if (pendingEntry == FeedbackEntry.keypoint && state.userFeedback.userHasKeypointFeedbackIncomplete) {
      context.read<FeedbackCubit>().clearIncompleteFeedbackPrompt();
      return;
    }

    final courseId = state.activeCourseId;
    final lessonId = state.activeLessonId;
    final keypointId = state.activeKeypointId;
    if (courseId.isEmpty && lessonId.isEmpty && keypointId.isEmpty) {
      context.read<FeedbackCubit>().clearIncompleteFeedbackPrompt();
      return;
    }

    context.read<FeedbackCubit>().clearIncompleteFeedbackPrompt();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
      FeedbackIncompleteLessonPopup.show(
        context,
        entry: pendingEntry,
        courseId: courseId,
        lessonId: lessonId,
        keypointId: keypointId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PageCubit, PageState>(
          listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName,
          listener: (context, state) {
            if (state.currentRouteName == RouteNamed.courseRoadmap) {
              _trackRoadmapScrView();
              return;
            }
            _hasTrackedForVisibility = false;
          },
        ),
        BlocListener<CourseRoadmapCubit, CourseRoadmapState>(
          listenWhen: (previous, current) => previous.roadmap.courseId != current.roadmap.courseId,
          listener: (context, state) {
            _hasTrackedForVisibility = false;
            _trackRoadmapScrView();
            _loadProgressForRoadmap(state.roadmap.courseId);
          },
        ),
        BlocListener<FeedbackCubit, FeedbackState>(
          listenWhen: (previous, current) => previous.pendingFeedbackIncompletePrompt != current.pendingFeedbackIncompletePrompt || previous.status != current.status,
          listener: (context, state) {
            _tryShowRoleplayIncompleteFeedback(state);
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundWhite,
        body: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
          selector: (state) => state.status == CourseRoadmapStatus.loading && state.roadmap.levels.isEmpty,
          builder: (context, isLoading) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppCustomColor.brandPrimary,
                ),
              );
            }
            return SafeBody(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Header: centered skillset dropdown, plus a back arrow on
                      // the left ONLY when the roadmap was opened from Explore
                      // (grid / My courses / View more / search) — tapping it
                      // returns to that Explore screen. Reached "naturally"
                      // (Courses tab, Home cards) → no back button.
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const TopProgressBar(),
                          BlocSelector<CourseRoadmapCubit, CourseRoadmapState, String>(
                            selector: (state) => state.roadmapSource,
                            builder: (context, source) {
                              if (!_kExploreSources.contains(source)) {
                                return const SizedBox.shrink();
                              }
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Semantics(
                                  button: true,
                                  label: 'Back',
                                  child: IconButton(
                                    key: const Key('roadmap-back-to-explore'),
                                    padding: EdgeInsets.only(left: 12.w),
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 20.w,
                                      color: AppCustomColor.textPrimary,
                                    ),
                                    onPressed: () => _backFromRoadmap(context, source),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      CourseRoadmapContent(),
                    ],
                  ),
                  // Sticky "Start lesson" CTA floating above the bottom nav bar.
                  // (A centerDocked FAB would dock at the screen bottom and sit
                  // behind the floating nav overlay, hiding it.)
                  //
                  // Decorative white fade behind the CTA — IgnorePointer so it
                  // never blocks taps on the lesson nodes beneath it.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 200.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppCustomColor.backgroundWhite.withValues(alpha: 0),
                              AppCustomColor.backgroundWhite,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20.w,
                    right: 20.w,
                    // Sit above the floating nav bar (≈110.h tall incl. safe area).
                    bottom: 120.h,
                    child: Center(
                      child: CourseRoadmapFloatingButton(
                        onPressed: () {
                          // Empty "My Course" state (no roadmap yet): the CTA
                          // can't start a lesson, so send the user to Explore to
                          // pick a course — mirrors the TopProgressBar dropdown.
                          final hasRoadmap = context
                              .read<CourseRoadmapCubit>()
                              .state
                              .roadmap
                              .levels
                              .isNotEmpty;
                          if (!hasRoadmap) {
                            final skillsetIndex = AppDI.injector
                                .get<HomeCubit>()
                                .state
                                .selectedSkillsetIndex;
                            AppDI.injector.get<CourseCubit>()
                              ..setAllCourseSource('my_course_empty')
                              ..jumpToSkillset(skillsetIndex);
                            context.read<PageCubit>().setCurrentIndex(3);
                            CourseRoute(selectedTabIndex: skillsetIndex)
                                .go(context);
                            return;
                          }
                          _trackRoadmapQuickLearningClick();
                          RoadmapNodeActionHelper.startLastInProgressAction(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
