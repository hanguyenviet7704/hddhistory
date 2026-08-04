part of '../../../course.dart';

/// Maximum number of courses shown per skillset section in the Explore view.
/// A "View more" button is shown when a skillset has more courses than this.
const int _kMaxCoursesPerSection = 5;

/// Course-card thumbnail height (square-ish hero image).
double get _kCourseThumbHeight => 160.w;

/// Title always reserves exactly two lines (Body/Default/Bold 14 × line-height
/// 1.4) so every card is the same height — rows align and the gap between rows
/// is uniform regardless of title length.
double get _kCourseTitleHeight => (14 * 1.4 * 2).sp;

/// One author line under the title (icon 12 / text 11.5 with 1.4 leading).
/// Reserved on every card — even author-less ones — so grid rows stay aligned.
double get _kCourseAuthorHeight => (11.5 * 1.4).sp;

/// Exact height of a [_CourseGridCard] = thumbnail + 12 gap + 2-line title
/// + 4 gap + author line. Used as the grid cell extent so there is NO leftover
/// slack and the visible row gap equals exactly the configured spacing.
double get _kCourseCardExtent =>
    _kCourseThumbHeight + 12.h + _kCourseTitleHeight + 4.h + _kCourseAuthorHeight;

/// Inter-row / inter-column gaps for the course grids (Figma redline).
double get _kCourseGridRowGap => 24.h; // Spacing/600 (vertical)
double get _kCourseGridColGap => 20.w; // horizontal rhythm (matches page margin)

/// Resolves the lesson-progress numbers for [course].
///
/// The skillset list endpoint (HomeCubit.skillsets) returns courses WITHOUT
/// per-user progress (`numberOfLessonPassed` is always 0). The user's actual
/// progress lives in ProgressCubit.myCourses — the same source Home's
/// "Continue learning" reads. So we prefer the matching entry from
/// [progressById] (keyed by course id) and fall back to the course itself.
({int passed, int total}) resolveCourseProgress(
  CourseEntity course, [
  Map<String, CourseEntity> progressById = const {},
]) {
  final withProgress = progressById[course.id] ?? course;
  final passed = withProgress.numberOfLessonPassed;
  final total = withProgress.numberOfLesson > 0
      ? withProgress.numberOfLesson
      : course.numberOfLesson;
  return (passed: passed, total: total);
}

/// Builds the `courseId → course-with-progress` lookup from the ProgressCubit's
/// "my courses" list (which carries `numberOfLessonPassed`).
Map<String, CourseEntity> progressLookup(ProgressState progressState) => {
      for (final c in progressState.myCourses) c.id: c,
    };

/// Sorts [courses] for display in the Explore screen.
///
/// Order: Coming Soon → New → In Progress → Not Started.
/// Progress is resolved via [progressById] (see [resolveCourseProgress]).
List<CourseEntity> sortCoursesForExplore(
  List<CourseEntity> courses, [
  Map<String, CourseEntity> progressById = const {},
]) {
  int priority(CourseEntity c) {
    if (c.isComingSoonNow) return 0; // Coming soon featured first (Figma)
    if (c.isNewNow) return 1;
    final p = resolveCourseProgress(c, progressById);
    if (p.passed > 0 && p.passed < p.total) {
      return 2; // In Progress
    }
    return 3; // Not Started
  }

  return [...courses]..sort((a, b) => priority(a).compareTo(priority(b)));
}

class AllCourseTab extends StatefulWidget {
  const AllCourseTab({super.key});

  @override
  State<AllCourseTab> createState() => _AllCourseTabState();
}

class _AllCourseTabState extends State<AllCourseTab> with AutomaticKeepAliveClientMixin {
  late final CourseCubit _courseCubit;

  /// Owned per widget instance — an [ItemScrollController] can only attach to one
  /// list at a time, so it must NOT live on the (singleton) cubit, or two live
  /// Explore lists (e.g. the kept-alive tab plus a pushed one) would collide and
  /// crash. Chip-tap scrolls are requested via the cubit's scroll nonce instead.
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();

  /// Scrollspy stays disarmed (no chip highlighted) until the user physically
  /// scrolls, so a fresh entry shows the "out menu" state. Re-armed to false on
  /// every reset to all.
  bool _spyArmed = false;

  /// Guards explore_scr_view to once per Explore-tab visit — the tab is kept
  /// alive (AutomaticKeepAliveClientMixin), so initState fires only on the very
  /// first open. Reset when the tab stops being the current route (see the
  /// PageCubit listener in build) so each re-entry logs a fresh view.
  bool _scrViewLogged = false;

  @override
  void initState() {
    super.initState();
    _courseCubit = context.read<CourseCubit>();
    _positionsListener.itemPositions.addListener(_onPositionsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _logScrViewIfActive());
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  /// Logs explore_scr_view once per Explore-tab visit: source (remapped to the
  /// spec set nav_explore/home_explore/my_course from the entry point's
  /// allCourseSource) + the active skill_id. No-op unless Explore is the
  /// current route.
  void _logScrViewIfActive() {
    if (!mounted) return;
    // Explore is shell branch index 3 (ScaffoldLayout._tabToBranch). Keying on
    // the branch index (not currentRouteName) fires reliably for BOTH a
    // bottom-nav tap AND a Home→Explore .go(), which only setCurrentIndex(3)
    // without ever setting a route name.
    if (context.read<PageCubit>().state.currentIndex != 3) return;
    if (_scrViewLogged) return;
    _scrViewLogged = true;
    final source = _courseCubit.state.allCourseSource;
    final skillId = context.read<HomeCubit>().state.currentSkillset.id;
    ExploreTracking.track(
      TrackingKey.exploreScrView,
      parameters: {
        'source': ExploreTracking.remapScrViewSource(source),
        'skill_id': skillId,
      },
    );
    // Reset so a later plain bottom-nav entry (which sets no source) reports
    // nav_explore instead of reusing the previous entry's source.
    _courseCubit.setAllCourseSource('nav_explore');
  }

  /// Highlights the chip of the section currently at the TOP of the viewport
  /// (the section whose header has most recently scrolled up to the top), so
  /// at the very top the first section is active. Picks the visible section
  /// with the greatest leading edge still at/above [_kSpyTopThreshold];
  /// falls back to the topmost visible section.
  static const double _kSpyTopThreshold = 0.15;

  void _onPositionsChanged() {
    if (!_spyArmed || !mounted) return;
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final aboveTop = positions.where((p) => p.itemLeadingEdge <= _kSpyTopThreshold).toList();
    final active = aboveTop.isNotEmpty
        ? aboveTop.reduce((a, b) => a.itemLeadingEdge >= b.itemLeadingEdge ? a : b)
        : positions.reduce((a, b) => a.itemLeadingEdge <= b.itemLeadingEdge ? a : b);
    _courseCubit.onActiveSectionChanged(active.index);
  }

  /// Handles a scroll request from the cubit (chip tap, reset, or deep-link),
  /// signalled by a bumped [CourseState.exploreScrollNonce].
  void _handleScrollRequest(CourseState state, int skillsetCount) {
    if (state.activeSkillsetIndex < 0) {
      // Reset to "out menu": disarm scrollspy and return to the top.
      _spyArmed = false;
    }
    if (!_scrollController.isAttached || skillsetCount == 0) return;
    final target = state.activeSkillsetIndex.clamp(0, skillsetCount - 1);
    _scrollController.scrollTo(
      index: target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<PageCubit, PageState>(
      // Fire explore_scr_view on every entry to the Explore tab, not just the
      // first build — the tab is kept alive so initState won't re-run.
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex == 3) {
          _logScrViewIfActive();
        } else {
          _scrViewLogged = false;
        }
      },
      child: BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) => prev.skillsets != curr.skillsets || prev.selectedCourseIndex != curr.selectedCourseIndex || prev.status != curr.status,
      builder: (context, homeState) {
        final skillsets = homeState.skillsets;
        if (skillsets.isEmpty) {
          // Cold load (first open, no cached skillsets yet): show a grid
          // skeleton instead of the "nothing to see" empty state, which is
          // reserved for a confirmed-empty catalog (status == success).
          final isColdLoading = homeState.status == HomeStatus.loading || homeState.status == HomeStatus.initial;
          return isColdLoading ? const _CourseGridSkeleton() : const CourseEmptyState();
        }
        final progressState = context.watch<ProgressCubit>().state;
        final exploreMode = context.select<CourseCubit, CourseExploreMode>(
          (c) => c.state.exploreMode,
        );

        // "My courses" — a flat grid of the user's enrolled courses.
        if (exploreMode == CourseExploreMode.myCourses) {
          final myCourses = progressState.myCourses;
          if (myCourses.isEmpty) {
            return const CourseEmptyState();
          }
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: _kCourseGridColGap,
              mainAxisSpacing: _kCourseGridRowGap,
              // Exact card height (no slack) so the row gap is exactly 24.
              mainAxisExtent: _kCourseCardExtent,
            ),
            itemCount: myCourses.length,
            itemBuilder: (context, index) {
              final course = myCourses[index];
              final info = _myCourseProgress(course);
              return _CourseGridCard(
                key: ValueKey(course.id),
                course: course,
                completedLessons: info.completedLessons,
                totalLessons: info.totalLessons,
                isSelected: homeState.isSelectedCourse(course.id),
                onTap: () => _onTapMyCourse(context, skillsets, course),
              );
            },
          );
        }

        // "All courses" — every skillset stacked as a scrollspy section.
        final initialIndex = _courseCubit.state.activeSkillsetIndex
            .clamp(0, skillsets.length - 1);
        return BlocListener<CourseCubit, CourseState>(
          // A bumped nonce is a scroll request (chip tap / reset / deep-link).
          listenWhen: (prev, curr) => prev.exploreScrollNonce != curr.exploreScrollNonce,
          listener: (_, state) => _handleScrollRequest(state, skillsets.length),
          child: NotificationListener<ScrollNotification>(
            // Arm the scrollspy on the first user-initiated drag (programmatic
            // scrolls have no dragDetails), so chips don't light on entry.
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _spyArmed = true;
              }
              return false;
            },
            child: ScrollablePositionedList.builder(
              itemScrollController: _scrollController,
              itemPositionsListener: _positionsListener,
              initialScrollIndex: initialIndex,
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
              itemCount: skillsets.length,
              itemBuilder: (context, index) {
                final skillset = skillsets[index];
                return _CourseSection(
                  skillset: skillset,
                  progressState: progressState,
                  isSelected: (courseId) => homeState.isSelectedCourse(courseId),
                  onTapCourse: (course, courseIndex) =>
                      _onTapCourse(context, skillset, course, courseIndex),
                  showBottomSpacing: index < skillsets.length - 1,
                );
              },
            ),
          ),
        );
      },
      ),
    );
  }

  void _onTapCourse(
    BuildContext context,
    SkillsetEntity skillset,
    CourseEntity course,
    int index,
  ) {
    // Coming-soon courses show an informational bottom sheet instead of navigating.
    if (course.isComingSoonNow) {
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
        'source': 'nav_explore',
      },
    );

    _handleCourseTap(context, skillset, course, index);
  }

  void _handleCourseTap(
    BuildContext context,
    SkillsetEntity skillset,
    CourseEntity course,
    int index,
  ) {
    context.read<CourseRoadmapCubit>().setRoadmapSource('course_selection');
    context.read<HomeCubit>()
      ..selectSkillset(skillset)
      ..selectCourseIndex(index);
    CourseRoadmapRoute().go(context);
    // Set the route name explicitly (not just the index): .go() to the roadmap
    // branch root doesn't re-fire the observer, so otherwise currentRouteName
    // stays non-primary and the bottom nav (the only exit) stays hidden.
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }

  /// Handle a tap from the "My courses" grid. Resolves the owning skillset so
  /// the normal selection flow runs; falls back to opening the roadmap by id.
  void _onTapMyCourse(
    BuildContext context,
    List<SkillsetEntity> skillsets,
    CourseEntity course,
  ) {
    for (final skillset in skillsets) {
      final index = skillset.courses.indexWhere((c) => c.id == course.id);
      if (index >= 0) {
        _onTapCourse(context, skillset, course, index);
        return;
      }
    }

    if (course.isComingSoonNow) {
      _showComingSoonSheet(context, course);
      return;
    }
    if (context.read<HomeCubit>().trySelectCourseFromCourseId(course.id)) {
      context.read<CourseRoadmapCubit>().setRoadmapSource('my_courses');
      CourseRoadmapRoute().go(context);
      context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
    }
  }

  _CourseProgressInfo _myCourseProgress(CourseEntity course) {
    // Every "my course" is enrolled — always show its %, even at 0%.
    return _CourseProgressInfo(
      showProgress: true,
      completedLessons: course.numberOfLessonPassed,
      totalLessons: course.numberOfLesson,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

void _showComingSoonSheet(BuildContext context, CourseEntity course, {SkillsetEntity? skillset}) {
  ExploreTracking.track(
    TrackingKey.courseComingsoonView,
    parameters: {
      if (skillset != null) ...ExploreTracking.skillsetParams(skillset),
      ...ExploreTracking.courseParams(course),
    },
  );
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppCustomColor.backgroundWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              course.title.text,
              style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
              textAlign: TextAlign.center,
            ),
            16.verticalSpace,
            AppText(
              l10n.allcourse.comingSoonDescription,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
              textAlign: TextAlign.center,
            ),
            24.verticalSpace,
            AppButton.primary(
              fullWidthBtn: true,
              // Pop via the sheet's own context so we close exactly this
              // bottom-sheet route — using rootNavigator popped the wrong
              // navigator (the shell/page beneath), blanking the screen.
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: AppText(
                l10n.allcourse.comingSoonGotIt,
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CourseSection extends StatelessWidget {
  final SkillsetEntity skillset;
  final ProgressState progressState;
  final bool Function(String courseId) isSelected;
  final void Function(CourseEntity course, int courseIndex) onTapCourse;
  final bool showBottomSpacing;

  const _CourseSection({
    required this.skillset,
    required this.progressState,
    required this.isSelected,
    required this.onTapCourse,
    required this.showBottomSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final progressById = progressLookup(progressState);
    final sorted = sortCoursesForExplore(skillset.courses, progressById);
    final displayed = sorted.take(_kMaxCoursesPerSection).toList();
    final hasMore = sorted.length > _kMaxCoursesPerSection;

    // Build the grid children: course cards + optional view-more slot.
    final gridChildren = <Widget>[
      ...displayed.map((course) {
        final originalIndex = skillset.courses.indexWhere((c) => c.id == course.id);
        final progressInfo = _progressInfoFor(course, progressById);
        return _CourseGridCard(
          key: ValueKey(course.id),
          course: course,
          completedLessons: progressInfo.completedLessons,
          totalLessons: progressInfo.totalLessons,
          isSelected: isSelected(course.id),
          onTap: () => onTapCourse(course, originalIndex >= 0 ? originalIndex : displayed.indexOf(course)),
        );
      }),
      if (hasMore) _ViewMoreGridCard(skillset: skillset),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          skillset.title.text,
          style: AppStyle.textBold18.copyWith(color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
        ),
        12.verticalSpace,
        // Manual 2-column grid (not GridView.count): cells size to their own
        // height so there is no aspect-ratio slack — the vertical gap is exactly
        // _kCourseGridRowGap (Figma Spacing/600 = 24).
        _buildGrid(gridChildren),
        if (showBottomSpacing) 24.verticalSpace,
      ],
    );
  }

  /// Lays [cells] out in a 2-column grid using plain Rows so each cell keeps its
  /// natural height. Columns are [_kCourseGridColGap] apart, rows
  /// [_kCourseGridRowGap] apart — no GridView aspect-ratio slack.
  Widget _buildGrid(List<Widget> cells) {
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: _kCourseGridRowGap));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cells[i]),
            SizedBox(width: _kCourseGridColGap),
            Expanded(
              child: i + 1 < cells.length ? cells[i + 1] : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
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
}

/// Grid-slot card for "View more" — occupies one cell in the 2-column grid,
/// matching the dimensions of [_CourseGridCard].
class _ViewMoreGridCard extends StatelessWidget {
  const _ViewMoreGridCard({required this.skillset});

  final SkillsetEntity skillset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${context.l10n.allcourse.viewMore} ${skillset.title.text}',
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          ExploreTracking.track(
            TrackingKey.exploreCatViewmore,
            parameters: ExploreTracking.skillsetParams(skillset),
          );
          SkillsetCoursesRoute(skillsetId: skillset.id).push(context);
        },
        // Align the card to the top of the cell and size it to the same height
        // as a course thumbnail (160.w), so it sits as a square card in the
        // thumbnail row instead of stretching down the whole cell. Matches the
        // Figma layout (node 10907:22199).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 160.w,
              alignment: Alignment.center,
              // Figma node 10907:22199 — soft brand card: background/brand-2
              // (#E0DEFD), 2px border/brand (#C7C5FA), 12px radius.
              decoration: BoxDecoration(
                border: Border.all(color: AppCustomColor.brandPrimary200, width: 2),
                borderRadius: BorderRadius.circular(12.r),
                color: const Color(0xFFE0DEFD),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Both lines share Body/Small/SemiB — Mulish SemiBold 12/1.75,
                  // brand/primary-text (#362F82), centered.
                  AppText(
                    context.l10n.allcourse.viewMore,
                    style: AppStyle.text12.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.75,
                      color: AppCustomColor.brandPrimary700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  AppText(
                    skillset.title.text,
                    style: AppStyle.text12.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.75,
                      color: AppCustomColor.brandPrimary700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cold-load placeholder for the Explore grid (first open, no cached
/// skillsets yet). A static, non-interactive 2-column grid of dummy
/// [_CourseGridCard]s wrapped in Skeletonizer, which auto-generates bone
/// shapes matching the real card layout (thumbnail + 2-line title). Swapped
/// out for the real grid the instant skillsets arrive.
class _CourseGridSkeleton extends StatelessWidget {
  const _CourseGridSkeleton();

  static const int _kSkeletonCardCount = 6;
  static const CourseEntity _kSkeletonCourse = CourseEntity(
    id: 'skeleton',
    title: BaseMultiLanguage(en: 'Course title placeholder'),
  );

  @override
  Widget build(BuildContext context) {
    return sk.Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: _kCourseGridColGap,
          mainAxisSpacing: _kCourseGridRowGap,
          mainAxisExtent: _kCourseCardExtent,
        ),
        itemCount: _kSkeletonCardCount,
        itemBuilder: (context, index) => _CourseGridCard(
          course: _kSkeletonCourse,
          onTap: () {},
        ),
      ),
    );
  }
}

/// Vertical grid card shared between [AllCourseTab] and [SkillsetCoursesPage].
/// Displays a fixed-height thumbnail with badge overlay, then title below.
class _CourseGridCard extends StatelessWidget {
  const _CourseGridCard({
    super.key,
    required this.course,
    this.completedLessons,
    this.totalLessons,
    this.isSelected = false,
    required this.onTap,
  });

  final CourseEntity course;
  final int? completedLessons;
  final int? totalLessons;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: course.title.text,
      button: true,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                // Light hairline border so each card reads as separated from the
                // background, matching the design; brand border when selected.
                border: isSelected
                    ? Border.all(color: AppCustomColor.brandPrimary, width: 2)
                    : Border.all(color: AppCustomColor.borderSecondary, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CacheNetworkGraphic(
                      url: course.image,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _GridCourseBadge(
                        course: course,
                        completedLessons: completedLessons,
                        totalLessons: totalLessons,
                      ),
                    ),
                    if ((course.viewCount ?? 0) > 0)
                      Positioned(
                        right: 9.r,
                        bottom: 9.r,
                        child: CourseViewsChip(count: course.viewCount!),
                      ),
                  ],
                ),
              ),
            ),
            12.verticalSpace,
            // Fixed 2-line height so every card is the same height.
            SizedBox(
              height: _kCourseTitleHeight,
              width: double.infinity,
              child: AppText(
                course.title.text,
                style: AppStyle.textBold14.copyWith(
                  color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            4.verticalSpace,
            // Fixed-height author slot (kept even when blank) so grid rows
            // stay aligned — same trick as the 2-line title above.
            SizedBox(
              height: _kCourseAuthorHeight,
              width: double.infinity,
              child: (course.author?.trim() ?? '').isEmpty
                  ? null
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: CourseAuthorLine(
                        author: course.author!.trim(),
                        color: studyThemeOnBg(context, kCourseMetaAuthorColor),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White-background badge shown at the top-left of the grid card thumbnail.
/// Priority: comingSoon > isNew > in-progress percent > lesson count > nothing.
class _GridCourseBadge extends StatelessWidget {
  const _GridCourseBadge({
    required this.course,
    this.completedLessons,
    this.totalLessons,
  });

  final CourseEntity course;
  final int? completedLessons;
  final int? totalLessons;

  @override
  Widget build(BuildContext context) {
    // State 4 — Coming soon (filled purple clock + brand text).
    // A coming-soon course is never enrolled, so it wins over everything.
    if (course.isComingSoonNow) {
      return _WhiteGridBadge(
        icon: Icon(Icons.access_time_filled_rounded, size: 20.w, color: AppCustomColor.brandPrimary),
        label: context.l10n.allcourse.comingSoonLabel,
        textColor: AppCustomColor.brandPrimary,
      );
    }

    final completed = completedLessons ?? 0;
    final total = totalLessons ?? course.numberOfLesson;
    // A non-null [completedLessons] means the user is enrolled (the course is in
    // their progress list). Enrolled courses always show their saved progress —
    // even at 0% — matching Home's "Tiếp tục khoá học" card. Progress takes
    // priority over the "New course" badge so it never hides real progress.
    final isEnrolled = completedLessons != null && total > 0;

    if (isEnrolled) {
      // State 5 — Complete (green check circle + green text).
      if (completed >= total) {
        return _WhiteGridBadge(
          icon: Icon(Icons.check_circle_rounded, size: 20.w, color: _kBadgeGreen),
          label: context.l10n.allcourse.progressCompleted,
          textColor: _kBadgeGreen,
        );
      }

      // In progress — "{n}% complete" (ring + brand text). 0% shows an empty
      // ring, same as Home.
      final pct = (completed / total * 100).round();
      return _WhiteGridBadge(
        // Keep the 20px slot so the badge height matches the other states, but
        // render a smaller ring inside it — the full-slot ring read as too big
        // next to the label.
        icon: SizedBox(
          width: 20.w,
          height: 20.w,
          child: Center(
            child: SizedBox(
              width: 15.w,
              height: 15.w,
              child: CircularProgressIndicator(
                value: completed / total,
                strokeWidth: 2,
                backgroundColor: AppCustomColor.borderSecondary,
                valueColor: AlwaysStoppedAnimation(AppCustomColor.brandPrimary),
              ),
            ),
          ),
        ),
        label: context.l10n.allcourse.progressPercent(percent: pct),
        textColor: AppCustomColor.brandPrimary,
      );
    }

    // New course (green sparkle + green text) — only for not-enrolled courses.
    if (course.isNewNow) {
      return _WhiteGridBadge(
        icon: Icon(Icons.auto_awesome_rounded, size: 20.w, color: _kBadgeGreen),
        label: context.l10n.allcourse.newCourseLabel,
        textColor: _kBadgeGreen,
      );
    }

    // Not started — lesson count (solid book + text/tertiary #5F6F86).
    // The Figma icon (node 10840-20060) is a filled book (#95A7C2) with a
    // white line; rendered with its baked colors (no srcIn) so the line shows.
    if (course.numberOfLesson > 0) {
      return _WhiteGridBadge(
        // Figma node 10840-20060: the book glyph is ~13×14 centred inside a
        // 20px icon slot. The solid book SVG fills its viewBox edge-to-edge (no
        // built-in padding like Material icons), so render it at 14px inside a
        // 20px box — keeps the badge height aligned with the other states while
        // the visible book matches the design.
        icon: SizedBox(
          width: 20.w,
          height: 20.w,
          child: Center(
            child: SvgPicture.asset(
              AppAsset.svg.app.icBookSolid,
              width: 14.w,
              height: 14.w,
            ),
          ),
        ),
        label: context.l10n.allcourse.lessonsCount(count: course.numberOfLesson),
        textColor: AppCustomColor.streakTextMuted,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Brand/secondary/700 green used by the "New course" and "Complete" badges
/// (Figma course-card state set, node 10840-20051).
const Color _kBadgeGreen = Color(0xFF2B604E);

class _WhiteGridBadge extends StatelessWidget {
  const _WhiteGridBadge({
    this.icon,
    required this.label,
    required this.textColor,
  });

  final Widget? icon;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 6.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(12.r),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            4.horizontalSpace,
          ],
          AppText(
            label,
            style: AppStyle.textBold12.copyWith(
              color: textColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseProgressInfo {
  final bool showProgress;
  final int? completedLessons;
  final int? totalLessons;

  const _CourseProgressInfo({
    this.showProgress = false,
    this.completedLessons,
    this.totalLessons,
  });
}
