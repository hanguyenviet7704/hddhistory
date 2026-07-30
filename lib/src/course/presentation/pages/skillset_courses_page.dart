part of '../../course.dart';

class SkillsetCoursesPage extends StatefulWidget {
  const SkillsetCoursesPage({
    super.key,
    required this.skillsetId,
  });

  final String skillsetId;

  @override
  State<SkillsetCoursesPage> createState() => _SkillsetCoursesPageState();
}

class _SkillsetCoursesPageState extends State<SkillsetCoursesPage> {
  /// This is a non-primary detail route, so the shell's floating nav must stay
  /// hidden while it's shown. The nav is gated on [PageStateX.isPrimaryRoute];
  /// entering via Explore's `.push` (or a back-navigation that pops an overlay /
  /// returns from the roadmap) can leave/reset currentRouteName on a PRIMARY
  /// name, un-hiding the nav over this page — so assert our own name on mount
  /// and reclaim it whenever a primary name lands while we're on screen.
  ///
  /// Only claim while this page is actually FOREGROUND: this page lingers on its
  /// branch navigator after the user opens a course (a branch switch, not a
  /// pop), so it stays `isCurrent` even while backgrounded. go_router wraps the
  /// inactive branch in `TickerMode(enabled: false)`, so a false there means
  /// we're backgrounded and must NOT steal the visible branch's route name.
  void _ensureRouteName() {
    if (!mounted) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.skillsetCourses);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureRouteName();
      _trackCatlistScrView();
    });
  }

  /// Fires the category-list view event once per page mount (initState postFrame
  /// runs a single time), so it never double-counts on rebuilds. Guards the
  /// empty-skillset fallback (skillset not yet resolved from the id).
  void _trackCatlistScrView() {
    if (!mounted) return;
    final skillset = AppDI.injector.get<HomeCubit>().state.skillsets.firstWhere(
          (s) => s.id == widget.skillsetId,
          orElse: () => const SkillsetEntity(),
        );
    if (skillset.id.isEmpty) return;
    ExploreTracking.track(
      TrackingKey.exploreCatlistScrView,
      parameters: ExploreTracking.skillsetParams(skillset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      bloc: AppDI.injector.get<PageCubit>(),
      listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName && current.isPrimaryRoute,
      listener: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRouteName());
      },
      child: BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (prev, curr) => prev.skillsets != curr.skillsets,
        builder: (context, homeState) {
          final skillset = homeState.skillsets.firstWhere(
            (s) => s.id == widget.skillsetId,
            orElse: () => const SkillsetEntity(),
          );

          // Progress (numberOfLessonPassed) lives in ProgressCubit.myCourses, not
          // in the skillset list — merge it in by course id.
          final progressById = progressLookup(context.watch<ProgressCubit>().state);
          final sorted = sortCoursesForExplore(skillset.courses, progressById);

          return Scaffold(
            key: const Key('skillset-courses-page'),
            // Transparent only when a custom study background is active.
            backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
            // The header floats over the background instead of sitting on an
            // opaque white bar, so the study background runs to the very top of
            // the screen. The grid below re-adds the header's height as padding.
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              // Material 3 would otherwise tint the bar once content scrolls
              // under it, bringing the white band back mid-scroll.
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              centerTitle: true,
              leading: Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: IconButton(
                  onPressed: () {
                    AppHaptic.select();
                    ExploreTracking.track(
                      TrackingKey.exploreCatlistBackClick,
                      parameters: ExploreTracking.skillsetParams(skillset),
                    );
                    _backToExplore(context);
                  },
                  constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.w),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    // Lifted to a light ink on a dark study background — the bar
                    // is transparent now, so the slate default could land on a
                    // dark photo.
                    color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                    size: 20.w,
                  ),
                ),
              ),
              title: AppText(
                skillset.title.text,
                style: AppStyle.textBold20.copyWith(color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
              ),
            ),
            body: ThemedBackground(
              child: sorted.isEmpty
                  ? const CourseEmptyState()
                  : GridView.builder(
                      key: const Key('skillset-courses-grid'),
                      // Generous bottom slack: with the exact (no-slack) cell
                      // extent, Android font metrics can run a few px taller than
                      // the reserved title box, and 24 left the last row's title
                      // clipped at max scroll. 48 + the safe-area inset keeps the
                      // final row fully scrollable clear of the system nav bar.
                      // Top inset replaces what the opaque AppBar used to
                      // occupy: status bar + toolbar, now that the body runs
                      // behind both.
                      //
                      // viewPadding, NOT padding: Scaffold hands the body a
                      // MediaQuery with the top padding already removed (the
                      // AppBar is deemed to have consumed it), so `padding.top`
                      // reads 0 here and the first row would sit on the title.
                      // viewPadding survives that removal.
                      padding: EdgeInsets.fromLTRB(
                        20.w,
                        MediaQuery.viewPaddingOf(context).top + kToolbarHeight + 8.h,
                        20.w,
                        48.h + MediaQuery.paddingOf(context).bottom,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: _kCourseGridColGap,
                        mainAxisSpacing: _kCourseGridRowGap,
                        // Exact card height (no slack) so the row gap is exactly 24.
                        mainAxisExtent: _kCourseCardExtent,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final course = sorted[index];
                        final progressInfo = _progressInfoFor(course, progressById);
                        return _CourseGridCard(
                          key: ValueKey(course.id),
                          course: course,
                          completedLessons: progressInfo.completedLessons,
                          totalLessons: progressInfo.totalLessons,
                          onTap: () => _handleCourseTap(context, skillset, course),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  _CourseProgressInfo _progressInfoFor(
    CourseEntity course,
    Map<String, CourseEntity> progressById,
  ) {
    // Only enrolled courses (present in the user's progress list) show a
    // percentage — even at 0% — matching Home. Others show the lesson count.
    if (!progressById.containsKey(course.id)) return const _CourseProgressInfo();
    final p = resolveCourseProgress(course, progressById);
    return _CourseProgressInfo(
      showProgress: true,
      completedLessons: p.passed,
      totalLessons: p.total,
    );
  }

  /// This "View more" grid is a drill-down FROM the Explore tab, so back always
  /// returns to Explore (branch 3) at the current skillset — NOT `context.back()`.
  ///
  /// `SkillsetCoursesRoute` is a CHILD of `CourseRoadmapRoute` (Course branch),
  /// and the roadmap's own back button reaches this page via a sibling `.go()`.
  /// A plain pop would therefore land back on the roadmap, and the roadmap's
  /// back would re-open this grid — an infinite ping-pong. Jumping straight to
  /// the Explore branch (mirrors CourseRoadmapPage._backFromRoadmap) breaks it.
  void _backToExplore(BuildContext context) {
    final skillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
    AppDI.injector.get<CourseCubit>()
      ..setAllCourseSource('skillset_courses_back')
      ..jumpToSkillset(skillsetIndex);
    context.read<PageCubit>().setCurrentIndex(3);
    CourseRoute(selectedTabIndex: skillsetIndex).go(context);
  }

  void _handleCourseTap(BuildContext context, SkillsetEntity skillset, CourseEntity course) {
    if (course.status == CoursePublishStatus.comingSoon) {
      _showComingSoonSheet(context, course, skillset: skillset);
      return;
    }
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }
    final progress = resolveCourseProgress(
      course,
      progressLookup(context.read<ProgressCubit>().state),
    );
    ExploreTracking.track(
      TrackingKey.exploreCourseClick,
      parameters: {
        ...ExploreTracking.skillsetParams(skillset),
        ...ExploreTracking.courseParams(course),
        'course_state': ExploreTracking.courseState(course, passed: progress.passed, total: progress.total),
        'source': 'skill_list',
      },
    );
    context.read<CourseRoadmapCubit>().setRoadmapSource('skillset_courses');
    context.read<HomeCubit>()
      ..selectSkillset(skillset)
      ..selectCourse(course);
    CourseRoadmapRoute().go(context);
    // .go() to the roadmap branch root from another branch does NOT re-fire the
    // route observer, so currentRouteName would stay on this detail page
    // (skillsetCourses → not a primary route) and the bottom nav — the only way
    // back out of the roadmap — would stay hidden. Set the route name explicitly
    // (this also lights the Course tab). Mirrors keypoint_complete_page.
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }
}
