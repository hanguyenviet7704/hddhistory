part of '../../../course.dart';

/// Maximum number of courses shown per skillset section in the Explore view.
/// A "View more" button is shown when a skillset has more courses than this.
const int _kMaxCoursesPerSection = 5;

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
/// Order: New (not coming-soon) → In Progress → Not Started → Coming Soon.
/// Progress is resolved via [progressById] (see [resolveCourseProgress]).
List<CourseEntity> sortCoursesForExplore(
  List<CourseEntity> courses, [
  Map<String, CourseEntity> progressById = const {},
]) {
  int priority(CourseEntity c) {
    if (c.isNewNow) return 0;
    final p = resolveCourseProgress(c, progressById);
    if (p.passed > 0 && p.passed < p.total) {
      return 1; // In Progress
    }
    if (c.isComingSoonNow) return 3; // Coming Soon last
    return 2; // Not Started
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

  @override
  void initState() {
    super.initState();
    _courseCubit = context.read<CourseCubit>();
    _positionsListener.itemPositions.addListener(_onPositionsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackAllCourseScrView());
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  void _trackAllCourseScrView() {
    if (!mounted) return;
    final source = _courseCubit.state.allCourseSource;
    AppService.instance.appTrackingService.trackCourseSelectAllCourseView(source: source);
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
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) => prev.skillsets != curr.skillsets || prev.selectedCourseIndex != curr.selectedCourseIndex,
      builder: (context, homeState) {
        final skillsets = homeState.skillsets;
        if (skillsets.isEmpty) {
          return const CourseEmptyState();
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
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 24.h,
              childAspectRatio: 0.75,
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
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 80.h),
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
      _showComingSoonSheet(context, course);
      return;
    }

    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }

    AppService.instance.appTrackingService.trackCourseSelectCourseClick(
      skillset,
      course,
      source: 'all_course',
    );

    final isFirstTimeUserChooseCourse = context.read<UserCubit>().state.isFirstTimeUserChooseCourse;
    if (isFirstTimeUserChooseCourse && kDebugMode) {
      AppService.instance.appTrackingService.trackCourseSelectFirstCourseClick(skillset, course);
      CourseIntroPopup.show(
        context,
        course: course,
        onClose: () => _handleCourseTap(context, skillset, course, index),
      );
      return;
    }

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
    context.read<PageCubit>().setCurrentIndex(1);
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
      context.read<PageCubit>().setCurrentIndex(1);
    }
  }

  _CourseProgressInfo _myCourseProgress(CourseEntity course) {
    if (course.numberOfLessonPassed <= 0) return const _CourseProgressInfo();
    return _CourseProgressInfo(
      showProgress: true,
      completedLessons: course.numberOfLessonPassed,
      totalLessons: course.numberOfLesson,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

void _showComingSoonSheet(BuildContext context, CourseEntity course) {
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
          style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
        ),
        12.verticalSpace,
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 24.h,
          childAspectRatio: 0.75,
          children: gridChildren,
        ),
        if (showBottomSpacing) 24.verticalSpace,
      ],
    );
  }

  _CourseProgressInfo _progressInfoFor(
    CourseEntity course,
    Map<String, CourseEntity> progressById,
  ) {
    final p = resolveCourseProgress(course, progressById);
    if (p.passed <= 0) return const _CourseProgressInfo();
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
        onTap: () => SkillsetCoursesRoute(skillsetId: skillset.id).push(context),
        child: Container(
          // Figma node 10907:22199 — soft brand card: background/brand-2
          // (#E0DEFD), 2px border/brand (#C7C5FA), 12px radius.
          decoration: BoxDecoration(
            border: Border.all(color: AppCustomColor.brandPrimary200, width: 2),
            borderRadius: BorderRadius.circular(12.r),
            color: const Color(0xFFE0DEFD),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
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
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: isSelected
                    ? Border.all(color: AppCustomColor.brandPrimary, width: 2)
                    : null,
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
                  ],
                ),
              ),
            ),
            12.verticalSpace,
            AppText(
              course.title.text,
              style: AppStyle.textBold14.copyWith(
                color: AppCustomColor.textPrimary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    if (course.isComingSoonNow) {
      return _WhiteGridBadge(
        icon: Icon(Icons.access_time_filled_rounded, size: 20.w, color: AppCustomColor.brandPrimary),
        label: context.l10n.allcourse.comingSoonLabel,
        textColor: AppCustomColor.brandPrimary,
      );
    }

    // New course (green sparkle + green text).
    if (course.isNewNow) {
      return _WhiteGridBadge(
        icon: Icon(Icons.auto_awesome_rounded, size: 20.w, color: _kBadgeGreen),
        label: context.l10n.allcourse.newCourseLabel,
        textColor: _kBadgeGreen,
      );
    }

    final completed = completedLessons ?? 0;
    final total = totalLessons ?? course.numberOfLesson;

    // State 5 — Complete (green check circle + green text).
    if (total > 0 && completed >= total) {
      return _WhiteGridBadge(
        icon: Icon(Icons.check_circle_rounded, size: 20.w, color: _kBadgeGreen),
        label: context.l10n.allcourse.progressCompleted,
        textColor: _kBadgeGreen,
      );
    }

    // In progress — "{n}% complete" (ring + brand text).
    if (completed > 0 && total > 0) {
      final pct = (completed / total * 100).round();
      return _WhiteGridBadge(
        icon: SizedBox(
          width: 20.w,
          height: 20.w,
          child: CircularProgressIndicator(
            value: completed / total,
            strokeWidth: 2,
            backgroundColor: AppCustomColor.borderSecondary,
            valueColor: AlwaysStoppedAnimation(AppCustomColor.brandPrimary),
          ),
        ),
        label: context.l10n.allcourse.progressPercent(percent: pct),
        textColor: AppCustomColor.brandPrimary,
      );
    }

    // Not started — lesson count (solid book + text/tertiary #5F6F86).
    // The Figma icon (node 10840-20060) is a filled book (#95A7C2) with a
    // white line; rendered with its baked colors (no srcIn) so the line shows.
    if (course.numberOfLesson > 0) {
      return _WhiteGridBadge(
        icon: SvgPicture.asset(
          AppAsset.svg.app.icBookSolid,
          width: 20.w,
          height: 20.w,
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
