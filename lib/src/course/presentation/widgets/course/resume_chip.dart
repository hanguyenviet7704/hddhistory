part of '../../../course.dart';

/// Rendered height of [ResumeChipHost]'s card: a 32 cover plus its 6/6 padding.
///
/// Public because the shell has to reserve it: the Coach bubble sits ABOVE the
/// chip, so when the chip appears the bubble has to move up by exactly this
/// much or the two overlap.
const double kResumeChipHeight = 44;

/// Gap between the nav bar and the chip, and between the chip and whatever
/// stacks on top of it.
const double kResumeChipGap = 10;

/// The course the "keep going" chip points at, or null when there is nothing to
/// resume.
///
/// `myCourses` arrives ordered last-studied-first, so the first entry that is
/// started but unfinished IS the course they were last in the middle of. A
/// finished course is not something to continue, and one never opened is not
/// something to *resume*.
CourseEntity? resumeCourseFor(ProgressState state) {
  for (final course in state.myCourses) {
    final total = course.numberOfLesson;
    final passed = course.numberOfLessonPassed;
    if (total > 0 && passed > 0 && passed < total) return course;
  }
  return null;
}

/// Whether the chip is on screen right now.
///
/// Lives here rather than inside the widget because the shell needs the same
/// answer to place the Coach bubble above it. Two copies of this predicate
/// would drift, and the symptom would be the bubble sitting on the chip.
bool shouldShowResumeChip(PageState pageState, ProgressState progressState) {
  // Nav bar hidden (a lesson, a roleplay, search) → nothing floats above it.
  if (!pageState.isPrimaryRoute) return false;
  // The roadmap IS the destination, and Confession is a place to be left alone
  // in (owner) — the WHOLE branch, not just its hub: a reader opening a room
  // (`communityTopic`, which keeps the nav pill) is still in Confession, and
  // that is where most of the time in there is spent.
  //
  // `lessonReader` is the GENERATED lesson's roadmap — the counterpart of
  // `courseRoadmap`, down to its own floating "continue" CTA sitting at
  // `floatingNavBarHeight + 8`, which is exactly where the chip lands. Same
  // screen, same reason, same answer.
  if (pageState.currentRouteName == RouteNamed.courseRoadmap) return false;
  if (pageState.currentRouteName == RouteNamed.lessonReader) return false;
  if (communityRouteNames.contains(pageState.currentRouteName)) return false;
  return resumeCourseFor(progressState) != null;
}

/// Vertical space a primary tab must leave below its LAST row, on top of
/// whatever it already reserves for the nav bar, so the chip never sits on top
/// of that row.
///
/// Zero when the chip is not on screen, so a tab that adds this unconditionally
/// still ends flush with the nav bar on the days there is nothing to resume.
/// Mirrors [coachBubbleClearance] — same problem, same shape, and for the same
/// reason: the space the floating thing occupies and the space pages reserve
/// for it must come from one place or they drift, and the symptom is a row you
/// can see but cannot read (owner, 2026-09-16: "chip đang chèn lên phần tác giả
/// của khoá học").
///
/// Watches both cubits, so a tab repaints its padding the moment the chip
/// appears or goes away.
double resumeChipClearance(BuildContext context) {
  final pageState = context.watch<PageCubit>().state;
  final progressState = context.watch<ProgressCubit>().state;
  if (!shouldShowResumeChip(pageState, progressState)) return 0;

  return (kResumeChipHeight + kResumeChipGap).h;
}

/// "Tiếp tục học" — a one-tap way back into the course you were last in the
/// middle of, riding just above the floating nav bar on every tab that has one.
class ResumeChipHost extends StatefulWidget {
  /// Bottom of the chip, already clear of the floating nav bar.
  final double bottomInset;

  const ResumeChipHost({super.key, required this.bottomInset});

  @override
  State<ResumeChipHost> createState() => _ResumeChipHostState();
}

class _ResumeChipHostState extends State<ResumeChipHost> {
  @override
  void initState() {
    super.initState();
    // Home loads `myCourses`, but the chip shows on tabs a reader can land on
    // without ever passing through Home (a deep link into Library, a cold start
    // that restores Explore). No-op when the list is already there.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(AppDI.injector.get<ProgressCubit>().ensureMyCoursesLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageState = context.watch<PageCubit>().state;
    final progressState = context.watch<ProgressCubit>().state;
    if (!shouldShowResumeChip(pageState, progressState)) {
      return const SizedBox.shrink();
    }

    final course = resumeCourseFor(progressState)!;

    return Positioned(
      left: 8.w,
      right: 8.w,
      bottom: widget.bottomInset,
      child: _ResumeChip(
        course: course,
        onTap: () => _openRoadmap(context, course),
      ),
    );
  }

  void _openRoadmap(BuildContext context, CourseEntity course) {
    AppHaptic.select();
    ExploreTracking.track(
      TrackingKey.resumeChipClick,
      parameters: ExploreTracking.courseParams(course),
    );

    final homeCubit = AppDI.injector.get<HomeCubit>();
    // Select the course the same way every other entry point does, so the
    // roadmap opens on it and its own "Tiếp tục học" CTA lands on the right
    // lesson. Falling back to selection by id covers a course that is not in
    // the cached category catalogue.
    for (final category in homeCubit.state.categories) {
      final index = category.courses.indexWhere((c) => c.id == course.id);
      if (index >= 0) {
        homeCubit
          ..selectCategory(category)
          ..selectCourseIndex(index);
        _goToRoadmap(context);
        return;
      }
    }
    if (homeCubit.trySelectCourseFromCourseId(course.id)) _goToRoadmap(context);
  }


  /// The roadmap source for the tab the chip was tapped on.
  ///
  /// The roadmap decides BOTH whether to draw a back button and where that
  /// button goes from this string — an unregistered source strands the reader
  /// on a roadmap with no way out, which is exactly what happened the first
  /// time this shipped a bare 'resume_chip'. One source per tab means back
  /// returns to the tab they were standing on, with no new return path to
  /// write.
  String _roadmapSource() {
    switch (AppDI.injector.get<PageCubit>().state.currentIndex) {
      case 3:
        return kRoadmapSourceResumeChipExplore;
      case kLibraryBranchIndex:
        return kRoadmapSourceResumeChipLibrary;
      default:
        // Home, and anything unexpected: Home is the one tab every reader can
        // always get back out of.
        return kRoadmapSourceResumeChipHome;
    }
  }

  void _goToRoadmap(BuildContext context) {
    // From DI, not `context.read`: the chip lives on the SHELL, above every
    // route, and CourseRoadmapCubit is provided per route — reading it from
    // this context throws ProviderNotFound the moment the chip is tapped. Same
    // reason top_progress_bar.dart resolves its cubits this way. Both are
    // singletons, so it is the same instance the roadmap will use.
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(_roadmapSource());
    CourseRoadmapRoute().go(context);
    // Set the route name explicitly: `.go()` to a branch root fires no didPush,
    // so the observer never sets it and the nav guard stays out of step.
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }
}

class _ResumeChip extends StatelessWidget {
  const _ResumeChip({required this.course, required this.onTap});

  final CourseEntity course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${context.l10n.allcourse.resumeChipLabel}: ${course.title.text}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: kResumeChipHeight.h,
          padding: EdgeInsets.fromLTRB(7.w, 6.h, 12.w, 6.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFEDEFF6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x29141828),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11.r),
                child: SizedBox(
                  width: 32.w,
                  height: 32.w,
                  child: CoverArt(url: course.image, seed: course.id, label: course.title.text),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      context.l10n.allcourse.resumeChipLabel.toUpperCase(),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppFont.mulish,
                        fontSize: 7.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppCustomColor.brandPrimary,
                      ),
                    ),
                    2.verticalSpace,
                    AppText(
                      course.title.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFont.mulish,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: const Color(0xFF3A4250),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.w,
                color: AppCustomColor.brandPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
