part of '../../library.dart';

/// Shell branch index of the Library tab (see `ScaffoldLayout._tabToBranch`).
const int kLibraryBranchIndex = 5;


/// Slot width of a card in the "In progress" carousel, as a fraction of the
/// screen (design: a 322-wide card on a 390 frame, so the next one peeks in).
const double _kLibraryCarouselViewportFraction = 0.9;

/// The Library tab (design `5b · Library`): what you are part-way through, a
/// way into the full history, and the shelf of lessons you made yourself.
///
/// It took over the Profile tab's slot in the bottom bar. Profile is still its
/// own shell branch, reached from the Home header avatar.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureData();
    });
  }

  /// Self-heal on entry, the same shape as `HabitPage`/`HomeCubit`: the
  /// StatefulShellRoute keeps this page alive, so initState fires only on the
  /// very first open — every later visit comes through the PageCubit listener
  /// in [build].
  void _ensureData() {
    unawaited(context.read<ProgressCubit>().ensureLibraryCoursesLoaded());
    // Only when the shelf has never been loaded: the My Creations row shows how
    // many lessons are on it, and the shelf screen refetches for itself.
    final lessons = context.read<UserLessonCubit>();
    if (lessons.state.status == UserLessonStatus.initial) {
      unawaited(lessons.loadLessons());
    }
    // The id sets, which every bookmark elsewhere in the app reads — this is
    // the cheapest place to warm them.
    unawaited(context.read<SavedCubit>().ensureIdsLoaded());
    // And the lists themselves: the two Saved shelves are strips of real cards
    // now, not rows with a count, so ids alone no longer render them. `ensure`
    // rather than `load`, so flicking between tabs costs nothing.
    unawaited(context.read<SavedCubit>().ensureCoursesLoaded());
    unawaited(context.read<SavedCubit>().ensureCardsLoaded());
    // The week-recap banner and its "Sổ tay" row read this. `ensure` rather than
    // `load`: the popup host on the shell asks for the same thing at startup,
    // and `ensure` refreshes only once its copy has gone stale — a tab flick
    // costs nothing, while a return after real work picks the new week up.
    unawaited(AppDI.injector.get<WeekRecapCubit>().ensureCurrentLoaded());
    // The archive itself, for the "Sổ hành trình" strip — the banner above it
    // only ever needed the count.
    final weekRecap = AppDI.injector.get<WeekRecapCubit>();
    if (weekRecap.state.archiveStatus == WeekRecapStatus.initial) {
      unawaited(weekRecap.loadArchive());
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ProgressCubit>().loadLibraryCourses(isInit: true),
      context.read<UserLessonCubit>().loadLessons(),
      context.read<SavedCubit>().loadIds(),
    ]);
  }

  /// Opens a course's roadmap, mirroring Home's "Jump back in" card: select the
  /// skillset + course, then `.go()` the roadmap branch and re-anchor the route
  /// name (a `.go()` into an already-built branch fires no didPush, so the
  /// observer would otherwise leave the nav state on this tab).
  void _openCourse(CourseEntity course) {
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }
    final resolved = course.withSkillset;
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(kRoadmapSourceLibrary);
    AppDI.injector.get<HomeCubit>()
      ..selectSkillset(resolved.skillset)
      ..selectCourse(resolved);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }

  void _openHistory() {
    AppHaptic.select();
    const LibraryHistoryRoute().push(context);
  }

  void _openMyCreations() {
    AppHaptic.select();
    const MyLessonsRoute().push(context);
  }

  void _openSavedCourses() {
    AppHaptic.select();
    const SavedCoursesRoute().push(context);
  }

  void _openSavedCards() {
    AppHaptic.select();
    const SavedCardsRoute().push(context);
  }

  void _openNotebook() {
    AppHaptic.select();
    const WeekRecapArchiveRoute().push(context);
  }

  /// Empty state → the Explore grid, same jump the Habit tab's empty state makes.
  void _openExplore() {
    AppHaptic.select();
    context.read<PageCubit>().setCurrentIndex(3);
    CourseRoute().go(context);
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.course);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;

    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex == kLibraryBranchIndex) _ensureData();
      },
      child: Scaffold(
        // Transparent only when a custom study background is active.
        backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _LibraryHeader(title: l10n.title)),
              const SliverToBoxAdapter(child: WeekRecapBanner()),
              SliverToBoxAdapter(
                child: _LibrarySectionHeader(
                  title: l10n.inProgressSection,
                  trailingLabel: l10n.myHistoryLink,
                  onTrailingTap: _openHistory,
                ),
              ),
              SliverToBoxAdapter(
                child: _LibraryInProgressStrip(
                  onOpenCourse: _openCourse,
                  onExplore: _openExplore,
                ),
              ),
              // Four shelves, each showing what is actually on it rather than
              // a row saying how many things are (design note 2026-09-04).
              // Each hides itself while empty, so a new reader gets a short
              // page instead of four "nothing here yet" panels.
              SliverToBoxAdapter(child: LibraryMyCreationsStrip(onSeeAll: _openMyCreations)),
              SliverToBoxAdapter(
                child: LibrarySavedCoursesStrip(
                  onSeeAll: _openSavedCourses,
                  onOpenCourse: _openCourse,
                ),
              ),
              SliverToBoxAdapter(child: LibrarySavedCardsStrip(onSeeAll: _openSavedCards)),
              SliverToBoxAdapter(child: LibraryNotebookStrip(onSeeAll: _openNotebook)),
              SliverToBoxAdapter(
                child: SizedBox(height: floatingNavBarHeight(context) + 20.h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky-feeling page title (design: 26/700, 58 from the top of the frame).
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, MediaQuery.paddingOf(context).top + 14.h, 24.w, 12.h),
      child: AppText(
        title,
        style: TextStyle(
          fontFamily: AppFont.mulish,
          fontSize: 26.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: studyThemeOnBg(context, AppCustomColor.textPrimary),
        ),
      ),
    );
  }
}

/// Section title with a brand-coloured link on the right (design: 20/700 + 15/700).
class _LibrarySectionHeader extends StatelessWidget {
  const _LibrarySectionHeader({
    required this.title,
    required this.trailingLabel,
    required this.onTrailingTap,
  });

  final String title;
  final String trailingLabel;
  final VoidCallback onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Only 2 of the design's 14 vertical padding lives on the row: the rest
      // comes from the "My history" link's own 12, which it needs as tap target
      // (see below). Same total height, one big hit region instead of a 13pt one.
      padding: EdgeInsets.fromLTRB(24.w, 2.h, 24.w, 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: AppText(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // 15.5/700/-0.1, the one heading size every tab now shares
               // (design note 2026-09-04: "chú ý cỡ chữ title các thành phần").
               // At 20 these read as five page titles stacked down one screen.
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontSize: 15.5.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
            ),
          ),
          8.horizontalSpace,
          Semantics(
            button: true,
            label: trailingLabel,
            child: GestureDetector(
              key: const Key('library-my-history-link'),
              behavior: HitTestBehavior.opaque,
              onTap: onTrailingTap,
              // Padding, not bare text: the label alone is ~13pt tall, well under
              // the 44 minimum tap target, and it sits in the far-right corner
              // where a thumb is least accurate. It is inside the opaque hit
              // region, and the row gave up the matching amount of its own
              // padding — so the link grew a hit box without moving.
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.h),
                child: AppText(
                  trailingLabel,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    // Brand link sits directly on the (possibly dark) study
                    // background — lift it there so it stays legible.
                    color: studyThemeAccentOnBg(context, AppCustomColor.brandPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "In progress" carousel, with the cold-load / failed / empty branches the
/// design doesn't draw but the screen still has to answer for.
class _LibraryInProgressStrip extends StatefulWidget {
  const _LibraryInProgressStrip({required this.onOpenCourse, required this.onExplore});

  final void Function(CourseEntity course) onOpenCourse;
  final VoidCallback onExplore;

  @override
  State<_LibraryInProgressStrip> createState() => _LibraryInProgressStripState();
}

class _LibraryInProgressStripState extends State<_LibraryInProgressStrip> {
  /// Owned by the State, not rebuilt in `build`: a controller created inline is
  /// never disposed and throws away the reader's scroll position on every
  /// rebuild — and this widget rebuilds on every progress emit.
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _kLibraryCarouselViewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, ProgressState>(
      buildWhen: (previous, current) => previous.libraryPageData != current.libraryPageData || previous.libraryStatus != current.libraryStatus,
      builder: (context, state) {
        if (state.isLibraryInitialLoading) {
          return SizedBox(
            height: _kLibraryCardHeight.h,
            child: const Center(child: CircularProgressIndicator(color: AppCustomColor.brandPrimary)),
          );
        }

        if (state.isLibraryFailure) {
          return LibraryInlineError(
            message: state.libraryErrorMessage,
            onRetry: () => context.read<ProgressCubit>().loadLibraryCourses(isInit: true),
          );
        }

        final courses = state.libraryInProgressCourses;
        if (courses.isEmpty) return _LibraryInProgressEmpty(onExplore: widget.onExplore);

        // A PageView, not a horizontal ListView with PageScrollPhysics: that
        // physics snaps by VIEWPORT width, so a 322-wide card would jump a whole
        // screen per fling. `viewportFraction` is what makes a card come to rest
        // aligned with the next one peeking in, exactly as Home's "Jump back in"
        // strip does it (see `_JumpBackInSection`).
        return SizedBox(
          height: _kLibraryCardHeight.h,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: EdgeInsets.only(left: 24.w, right: 10.w),
                child: LibraryCourseCard(
                  course: course,
                  showContinueAffordance: true,
                  onTap: () => widget.onOpenCourse(course),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Nothing started yet — say so and offer the one thing that fixes it.
class _LibraryInProgressEmpty extends StatelessWidget {
  const _LibraryInProgressEmpty({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.library;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
        decoration: BoxDecoration(
          color: studyThemeCardColor(context),
          border: Border.all(color: _kLibraryCardBorder, width: 1.5),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              l10n.emptyInProgressTitle,
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                // Inside a card → dark ink, never studyThemeOnBg.
                color: AppCustomColor.textPrimary,
              ),
            ),
            4.verticalSpace,
            AppText(
              l10n.emptyInProgressBody,
              style: AppStyle.text13.copyWith(
                fontWeight: FontWeight.w500,
                color: studyThemeCardMuted(context, _kLibraryMutedText),
              ),
            ),
            12.verticalSpace,
            Semantics(
              button: true,
              label: l10n.emptyInProgressCta,
              child: GestureDetector(
                key: const Key('library-empty-explore-button'),
                behavior: HitTestBehavior.opaque,
                onTap: onExplore,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    color: AppCustomColor.brandPrimary,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: AppText(
                    l10n.emptyInProgressCta,
                    style: AppStyle.textBold12.copyWith(
                      fontSize: 13.sp,
                      color: AppCustomColor.backgroundWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
