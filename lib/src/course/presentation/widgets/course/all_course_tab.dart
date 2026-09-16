part of '../../../course.dart';

/// Corner radius of a cover tile. 18 in the redesign, up from 12 — the softer
/// corner is what makes a borderless tile still read as a card.
double get _kCoverRadius => 18.r;

/// Gap between the cover and the title, and between title and author.
double get _kCoverToTitleGap => 8.h;
double get _kTitleToAuthorGap => 6.h;

/// The title reserves exactly two lines (13 × 1.35) so every card is the same
/// height — rows align and the gap between them is uniform regardless of title
/// length.
double get _kCourseTitleHeight => (13 * 1.35 * 2).sp;

/// One author line under the title (icon 12 / text 11.5 with 1.4 leading).
/// Reserved on every card — even author-less ones — so grid rows stay aligned.
double get _kCourseAuthorHeight => (11.5 * 1.4).sp;

/// Height of everything BELOW the cover. The cover itself is square and sized
/// from the column width, so a cell's total height is this plus that width —
/// which is why the grid lays cells out by natural height rather than by a
/// fixed extent.
double get _kCourseCaptionHeight => _kCoverToTitleGap + _kCourseTitleHeight + _kTitleToAuthorGap + _kCourseAuthorHeight;

/// Inter-row / inter-column gaps for the course grids (redesign redline:
/// `gap: 20px 14px`).
double get _kCourseGridRowGap => 20.h;
double get _kCourseGridColGap => 14.w;

/// Height of one cell in a two-column grid [gridWidth] wide.
///
/// Has to be measured rather than fixed: the cover is SQUARE, so its height is
/// the column width, which depends on the device. `childAspectRatio` cannot
/// express this either — the caption below the cover is a fixed number of lines,
/// so the cell's ratio changes with screen width.
double courseGridCellExtent(double gridWidth) => (gridWidth - _kCourseGridColGap) / 2 + _kCourseCaptionHeight;

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
  final total = withProgress.numberOfLesson > 0 ? withProgress.numberOfLesson : course.numberOfLesson;
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

/// The Explore tab's scrolling body.
///
/// Every strip and its ORDER comes from `GET /courses-explore` — the tab walks
/// the list it is handed and draws each section by its `type`. It used to build
/// one section per skillset from `HomeCubit`, which is why a scrollspy
/// (`ScrollablePositionedList`, an active-chip index, a scroll nonce) lived
/// here; with the skillset sections gone there is nothing to spy on, and a
/// plain list is the whole of it. Browsing a whole skillset now happens through
/// the topic chips, which open its full list directly.
class AllCourseTab extends StatefulWidget {
  const AllCourseTab({super.key});

  @override
  State<AllCourseTab> createState() => _AllCourseTabState();
}

class _AllCourseTabState extends State<AllCourseTab> with AutomaticKeepAliveClientMixin {
  late final CourseCubit _courseCubit;

  /// Guards explore_scr_view to once per Explore-tab visit — the tab is kept
  /// alive (AutomaticKeepAliveClientMixin), so initState fires only on the very
  /// first open. Reset when the tab stops being the current route (see the
  /// PageCubit listener in build) so each re-entry logs a fresh view.
  bool _scrViewLogged = false;

  @override
  void initState() {
    super.initState();
    _courseCubit = context.read<CourseCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _logScrViewIfActive());
  }

  /// Logs explore_scr_view once per Explore-tab visit: source (remapped to the
  /// spec set nav_explore/home_explore/my_course from the entry point's
  /// allCourseSource). No-op unless Explore is the current route.
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
    ExploreTracking.track(
      TrackingKey.exploreScrView,
      parameters: {'source': ExploreTracking.remapScrViewSource(source)},
    );
    // Reset so a later plain bottom-nav entry (which sets no source) reports
    // nav_explore instead of reusing the previous entry's source.
    _courseCubit.setAllCourseSource('nav_explore');
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
          // Re-entry is where a failed first load gets a second chance: the tab
          // is kept alive, so initState does not run again. No-op when the
          // sections are already there.
          unawaited(context.read<ExploreCubit>().ensureExploreDataLoaded());
        } else {
          _scrViewLogged = false;
        }
      },
      child: BlocBuilder<ExploreCubit, ExploreState>(
        builder: (context, state) {
          final sections = state.sections;

          if (sections.isEmpty) {
            // Cold load: a skeleton, not the "nothing to see" empty state,
            // which is reserved for a catalogue that really is empty.
            if (state.status == ExploreStatus.loading || state.status == ExploreStatus.initial) {
              return const _CourseGridSkeleton();
            }
            if (state.status == ExploreStatus.failure) {
              return _ExploreLoadFailed(
                onRetry: () => context.read<ExploreCubit>().refresh(),
              );
            }
            return const CourseEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ExploreCubit>().refresh(),
            child: ListView.builder(
              // No horizontal padding here: each section pays its own, so its
              // strip can run to the screen edge instead of stopping 20 short
              // and reading as a clipped list.
              // + the resume chip: it floats over this list's last row, and
              // that row is a course card whose author line was landing under
              // it (owner, 2026-09-16).
              padding: EdgeInsets.only(bottom: 80.h + resumeChipClearance(context)),
              itemCount: sections.length + _kHeaderRows,
              itemBuilder: (context, index) {
                // The search field and the import board ride at the top of the
                // list so the whole page scrolls as one.
                if (index < _kHeaderRows) {
                  return Column(
                    children: [
                      const CourseHeader(),
                      12.verticalSpace,
                    ],
                  );
                }

                final section = sections[index - _kHeaderRows];
                return Padding(
                  padding: EdgeInsets.only(bottom: 22.h),
                  child: _ExploreSection(
                    section: section,
                    onTapCourse: (course) => _onTapExploreCourse(context, course, section),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Row 0 of the list is the header (search + the import board), which scrolls
  /// away with the sections rather than sitting pinned above them — the design
  /// scrolls the whole page (owner, 2026-09-05).
  static const int _kHeaderRows = 1;

  /// Opens a course tapped anywhere on the tab.
  ///
  /// A course arrives here without a skillset — a collection is a hand-picked
  /// list that crosses skillsets — so the owning one is resolved from the
  /// catalogue, which is what the roadmap's selection flow needs.
  void _onTapExploreCourse(
    BuildContext context,
    CourseEntity course,
    ExploreSectionEntity section,
  ) {
    if (course.isComingSoonNow) {
      _showComingSoonSheet(context, course);
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
        ...ExploreTracking.sectionParams(section),
        ...ExploreTracking.courseParams(course),
        'course_state': ExploreTracking.courseState(course, passed: progress.passed, total: progress.total),
        'source': 'nav_explore',
      },
    );

    final skillsets = context.read<HomeCubit>().state.skillsets;
    for (final skillset in skillsets) {
      final index = skillset.courses.indexWhere((c) => c.id == course.id);
      if (index >= 0) {
        _handleCourseTap(context, skillset, course, index);
        return;
      }
    }

    // Not in the cached catalogue (a course published since the skillsets were
    // fetched). Fall back to selecting it by id rather than swallowing the tap.
    if (context.read<HomeCubit>().trySelectCourseFromCourseId(course.id)) {
      context.read<CourseRoadmapCubit>().setRoadmapSource('course_selection');
      CourseRoadmapRoute().go(context);
      context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
    }
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

/// Draws one section by its type. A kind this build does not know about is
/// dropped in the repository, so anything arriving here is drawable.
class _ExploreSection extends StatelessWidget {
  const _ExploreSection({required this.section, required this.onTapCourse});

  final ExploreSectionEntity section;
  final void Function(CourseEntity course) onTapCourse;

  @override
  Widget build(BuildContext context) {
    switch (section.type) {
      case ExploreSectionType.curated:
        return _CollectionSection(section: section, onTapCourse: onTapCourse);
      case ExploreSectionType.weeklyTop:
        return _WeeklyTopSection(section: section, onTapCourse: onTapCourse);
      case ExploreSectionType.becauseYou:
        return _BecauseYouSection(section: section, onTapCourse: onTapCourse);
      case ExploreSectionType.topicChips:
        return const _TopicChipsSection();
      case ExploreSectionType.unknown:
        return const SizedBox.shrink();
    }
  }
}

/// A heading over a horizontal strip of covers — the shape every editor-curated
/// collection takes, with a chevron into the same courses as a grid.
class _CollectionSection extends StatelessWidget {
  const _CollectionSection({required this.section, required this.onTapCourse});

  final ExploreSectionEntity section;
  final void Function(CourseEntity course) onTapCourse;

  /// Card width in the strip (design `width:126px`). The cover is square, so
  /// this is its height too.
  static const double _cardWidth = 126;

  @override
  Widget build(BuildContext context) {
    final progressById = progressLookup(context.watch<ProgressCubit>().state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Expanded(
                child: AppText(
                  section.title.text,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                  ),
                ),
              ),
              10.horizontalSpace,
              Semantics(
                button: true,
                label: '${context.l10n.allcourse.viewMore} ${section.title.text}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptic.select();
                    CollectionCoursesRoute(collectionId: section.id).push(context);
                  },
                  // 28 square so the tap target is not just the glyph, pulled 6
                  // right so the arrow lines up with the page margin.
                  child: Transform.translate(
                    offset: Offset(6.w, 0),
                    child: SizedBox(
                      width: 28.w,
                      height: 28.w,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 24.w,
                        color: studyThemeAccentOnBg(context, AppCustomColor.brandPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        10.verticalSpace,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 2.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < section.courses.length; i++) ...[
                if (i > 0) 12.horizontalSpace,
                SizedBox(
                  width: _cardWidth.w,
                  child: Builder(
                    builder: (context) {
                      final course = section.courses[i];
                      final info = _progressInfoFor(course, progressById);
                      return _CourseGridCard(
                        key: ValueKey('${section.id}-${course.id}'),
                        course: course,
                        completedLessons: info.completedLessons,
                        totalLessons: info.totalLessons,
                        onTap: () => onTapCourse(course),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
}

/// "Được học nhiều nhất" — one card at a time, swiped sideways, with the three
/// ranks shown as dots.
///
/// A pager rather than a strip because each entry carries a description: the
/// reason a course is popular is the point of the section, and three
/// descriptions side by side in a scroller would each be three words wide.
class _WeeklyTopSection extends StatefulWidget {
  const _WeeklyTopSection({required this.section, required this.onTapCourse});

  final ExploreSectionEntity section;
  final void Function(CourseEntity course) onTapCourse;

  @override
  State<_WeeklyTopSection> createState() => _WeeklyTopSectionState();
}

class _WeeklyTopSectionState extends State<_WeeklyTopSection> {
  final ScrollController _controller = ScrollController();

  /// Width of one page, learned from layout. Needed to turn a scroll offset
  /// into a page number for the dots.
  double _pageWidth = 1;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted || _pageWidth <= 0) return;
    final page = (_controller.offset / _pageWidth).round();
    if (page != _page) setState(() => _page = page);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = widget.section.courses;
    if (courses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0xFFEBE9F9), width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F3FE), Color(0xFFFBF7F4)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        context.l10n.allcourse.exploreWeeklyEyebrow,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8A88A8),
                        ),
                      ),
                      2.verticalSpace,
                      AppText(
                        context.l10n.allcourse.exploreWeeklyTitle,
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          color: AppCustomColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (courses.length > 1) _WeeklyDots(count: courses.length, active: _page),
              ],
            ),
            14.verticalSpace,
            // A snapping horizontal scroller, not a PageView: a PageView cannot
            // size itself to its children, so it needs a fixed height — and any
            // height big enough for the longest description leaves a slab of
            // dead white under the short ones (owner: "spacing đang hơi dày").
            // This sizes to the tallest card instead, which is also what the
            // design's scroll-snap row does.
            LayoutBuilder(
              builder: (context, constraints) {
                _pageWidth = constraints.maxWidth;
                return SingleChildScrollView(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  physics: const PageScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final course in courses)
                        SizedBox(
                          width: constraints.maxWidth,
                          child: _WeeklyTopCard(
                            course: course,
                            onTap: () => widget.onTapCourse(course),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyDots extends StatelessWidget {
  const _WeeklyDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) 5.horizontalSpace,
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: (i == active ? 22 : 6).w,
            height: 6.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99.r),
              color: i == active ? AppCustomColor.textPrimary : const Color(0xFFD9DEE7),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeeklyTopCard extends StatelessWidget {
  const _WeeklyTopCard({required this.course, required this.onTap});

  final CourseEntity course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final learners = course.learnerCount;
    final author = course.author ?? '';
    final meta = [
      if (author.isNotEmpty) author,
      if (learners != null && learners > 0) context.l10n.allcourse.exploreLearnerCount(count: learners),
    ].join(' · ');

    return Semantics(
      label: course.title.text,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: SizedBox(
                    width: 60.w,
                    height: 60.w,
                    child: CoverArt(url: course.image, seed: course.id, label: course.title.text),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        course.title.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.28,
                          color: AppCustomColor.textPrimary,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        4.verticalSpace,
                        AppText(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFont.mulish,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C8AA4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            12.verticalSpace,
            Container(height: 1, color: const Color(0x22554FF0)),
            12.verticalSpace,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '“',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 26.sp,
                    height: 0.9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0x38554FF0),
                  ),
                ),
                9.horizontalSpace,
                Expanded(
                  child: AppText(
                    course.description.text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.55,
                      color: const Color(0xFF4A4A73),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Tìm kiếm theo chủ đề" — the skillset catalogue as chips, two rows of three.
///
/// Reads `HomeCubit` rather than the Explore payload: the catalogue is already
/// loaded for Home and the roadmap, and asking the server for it again on every
/// Explore open would be bytes spent on data the app is holding.
class _TopicChipsSection extends StatelessWidget {
  const _TopicChipsSection();

  @override
  Widget build(BuildContext context) {
    final skillsets = context.watch<HomeCubit>().state.skillsets;
    if (skillsets.isEmpty) return const SizedBox.shrink();

    // Two rows that scroll sideways together, as designed — NOT a Wrap. A Wrap
    // looks identical against the design's short mock labels and then collapses
    // into one chip per line against the real ones ("Hiệu suất & Thói quen",
    // "Giao tiếp hiệu quả"): two of those exceed the screen width, so every chip
    // gets a line of its own and the row reads as a vertical list.
    final half = (skillsets.length / 2).ceil();
    final rows = [skillsets.take(half).toList(), skillsets.skip(half).toList()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: AppText(
            context.l10n.allcourse.exploreTopicsTitle,
            maxLines: 2,
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: studyThemeOnBg(context, AppCustomColor.textPrimary),
            ),
          ),
        ),
        10.verticalSpace,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int r = 0; r < rows.length; r++) ...[
                if (r > 0) 8.verticalSpace,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < rows[r].length; i++) ...[
                      if (i > 0) 8.horizontalSpace,
                      _TopicChip(skillset: rows[r][i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.skillset});

  final SkillsetEntity skillset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: skillset.title.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          ExploreTracking.track(
            TrackingKey.exploreCatViewmore,
            parameters: ExploreTracking.skillsetParams(skillset),
          );
          SkillsetCoursesRoute(skillsetId: skillset.id).push(context);
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(10.w, 7.h, 15.w, 7.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(99.r),
            border: Border.all(color: const Color(0xFFEEF0F6), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (skillset.image.isNotEmpty) ...[
                ClipOval(
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    // ClipOval on the image itself, not a circular Container
                    // around it: at this size a shape+clipBehavior container
                    // leaks the artwork's corners as four pale wedges.
                    child: CoverArt(url: skillset.image, seed: skillset.id, label: skillset.title.text),
                  ),
                ),
                8.horizontalSpace,
              ],
              // No width cap: the strip scrolls sideways, so a long topic name
              // widens the row instead of being squeezed or wrapped. maxLines 1
              // keeps every chip the same height whatever the name.
              AppText(
                skillset.title.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3A4250),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Vì bạn đã học X" — a tinted panel naming the course just finished, with
/// three suggestions from the same skillset stacked under it.
///
/// Stacked rows rather than the horizontal strip the collections use: this is a
/// short, reasoned list ("because of that, these three"), and a sideways
/// scroller would hide two of the three behind a gesture.
class _BecauseYouSection extends StatelessWidget {
  const _BecauseYouSection({required this.section, required this.onTapCourse});

  final ExploreSectionEntity section;
  final void Function(CourseEntity course) onTapCourse;

  @override
  Widget build(BuildContext context) {
    final source = section.sourceCourse;
    if (source == null || section.courses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: const Color(0xFFECEEF6), width: 1.5),
        ),
        padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 6.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        context.l10n.allcourse.exploreBecauseYouTitle.toUpperCase(),
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.85,
                          color: AppCustomColor.brandPrimary,
                        ),
                      ),
                      3.verticalSpace,
                      AppText(
                        source.title.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: AppCustomColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                10.horizontalSpace,
                ClipRRect(
                  borderRadius: BorderRadius.circular(11.r),
                  child: SizedBox(
                    width: 36.w,
                    height: 36.w,
                    child: CoverArt(url: source.image, seed: source.id, label: source.title.text),
                  ),
                ),
              ],
            ),
            10.verticalSpace,
            for (final course in section.courses) _BecauseYouRow(course: course, onTap: () => onTapCourse(course)),
          ],
        ),
      ),
    );
  }
}

class _BecauseYouRow extends StatelessWidget {
  const _BecauseYouRow({required this.course, required this.onTap});

  final CourseEntity course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final author = course.author ?? '';

    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          // A rule on TOP of every row, the first one included — that is what
          // separates the list from the "because you finished X" header above
          // it, so the panel reads as one thing rather than two stacked blocks.
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE6E9F1))),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13.r),
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: CoverArt(url: course.image, seed: course.id, label: course.title.text),
                ),
              ),
              11.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      course.title.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFont.mulish,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: AppCustomColor.textPrimary,
                      ),
                    ),
                    if (author.isNotEmpty) ...[
                      2.verticalSpace,
                      AppText(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFont.mulish,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C8AA4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the tab has nothing to draw AND the fetch failed — distinct from
/// an empty catalogue, which is a different message and has no retry.
class _ExploreLoadFailed extends StatelessWidget {
  const _ExploreLoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              context.l10n.allcourse.exploreLoadFailed,
              maxLines: 100,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
            ),
            16.verticalSpace,
            AppButton.primary(
              onPressed: onRetry,
              child: AppText(
                context.l10n.allcourse.exploreRetry,
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      child: LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: _kCourseGridColGap,
            mainAxisSpacing: _kCourseGridRowGap,
            mainAxisExtent: courseGridCellExtent(constraints.maxWidth - 40.w),
          ),
          itemCount: _kSkeletonCardCount,
          itemBuilder: (context, index) => _CourseGridCard(
            course: _kSkeletonCourse,
            onTap: () {},
          ),
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
    required this.onTap,
  });

  final CourseEntity course;
  final int? completedLessons;
  final int? totalLessons;
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
            // Square, borderless, no shadow — the redesign lets the artwork be
            // the card.
            AspectRatio(
              aspectRatio: 1,
              child: SizedBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_kCoverRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverArt(
                        url: course.image,
                        seed: course.id,
                        label: course.title.text,
                      ),
                      Positioned(
                        top: 10.r,
                        left: 10.r,
                        child: _GridCourseBadge(
                          course: course,
                          completedLessons: completedLessons,
                          totalLessons: totalLessons,
                        ),
                      ),
                      if ((course.displayViewCount ?? 0) > 0)
                        Positioned(
                          right: 9.r,
                          bottom: 9.r,
                          child: CourseViewsChip(count: course.displayViewCount!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: _kCoverToTitleGap),
            // Fixed 2-line height so every card is the same height.
            SizedBox(
              height: _kCourseTitleHeight,
              width: double.infinity,
              child: AppText(
                course.title.text,
                style: AppStyle.text13.copyWith(
                  color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: _kTitleToAuthorGap),
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
        icon: Icon(Icons.access_time_filled_rounded, size: 14.w, color: AppCustomColor.brandPrimary),
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
          icon: Icon(Icons.check_circle_rounded, size: 14.w, color: _kBadgeGreen),
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
          width: 14.w,
          height: 14.w,
          child: Center(
            child: SizedBox(
              width: 12.w,
              height: 12.w,
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
        icon: Icon(Icons.auto_awesome_rounded, size: 14.w, color: _kBadgeGreen),
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
          width: 14.w,
          height: 14.w,
          child: Center(
            child: SvgPicture.asset(
              AppAsset.svg.app.icBookSolid,
              width: 12.w,
              height: 12.w,
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
    // A free-floating pill inset from the corner, not the corner tab it used to
    // be: the redesign detaches the badge from the cover's edge so the artwork
    // reads whole behind it.
    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 4.h, 9.w, 4.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(99.r),
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
            style: AppStyle.text10.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
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
