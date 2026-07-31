part of '../../course.dart';

/// "My course" library screen — reached from Profile → "Khóa học của tôi"
/// (design 6 · Profile → MeUp App master, "CHANGE COURSE" screen).
///
/// Skillset chip row (scrolls to a section) + the user's ENROLLED courses
/// grouped by skillset as row cards (thumbnail + title + progress, check on the
/// active course), and a pinned "Explore more courses" CTA back to Explore.
/// Distinct from [ChangeCoursePage] (the flat switcher): tapping a card opens
/// that course's roadmap.
///
/// Pushed on the ROOT navigator from Profile (see `_openMyCourses`), so it sits
/// above the shell — into-shell actions pop this page first, then drive
/// go_router on the global shell context.
class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  /// Root-pushes this page over the current tab with the cubits it reads.
  /// Shared by Profile's Library row (`_openMyCourses`) and the course
  /// roadmap's back button (when the user drilled in from here) so both open
  /// it identically.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
            BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
            BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
          ],
          child: const MyCoursesPage(),
        ),
      ),
    );
  }

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  int _selectedChip = 0;

  // Compact header: shorter than Material's default kToolbarHeight (56) so the
  // category chips sit higher, closer to the title. Used for BOTH the AppBar's
  // toolbarHeight and the body's top clearance under the transparent,
  // body-behind app bar — keep them equal or a gap/overlap reappears.
  static const double _kHeaderToolbarHeight = 44;

  @override
  void initState() {
    super.initState();
    // First-frame view hook (spec mycourse_scr_view).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppService.instance.appTrackingService.trackMycourseScrView();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _sectionKey(String skillsetId) => _sectionKeys.putIfAbsent(skillsetId, () => GlobalKey());

  void _onChipTap(int index, List<SkillsetEntity> sections) {
    AppService.instance.appTrackingService.trackProfileMycourseCatClick(sections[index].title.text);
    setState(() => _selectedChip = index);
    final ctx = _sectionKeys[sections[index].id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, alignment: 0.02, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('my-courses-page'),
      // Transparent only when a custom study background is active.
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
      // Let the custom study background (painted in the body) run edge-to-edge
      // behind the transparent app bar; on the default theme the white scaffold
      // shows through so the header still reads as a white bar.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: _kHeaderToolbarHeight.h,
        leading: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: IconButton(
            onPressed: () {
              AppHaptic.select();
              AppService.instance.appTrackingService.trackMycourseBackClick();
              context.back();
            },
            constraints: BoxConstraints(minWidth: 44.w, minHeight: _kHeaderToolbarHeight.h),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: studyThemeOnBg(context, AppCustomColor.textPrimary), size: 20.w),
          ),
        ),
        title: AppText(
          context.l10n.allcourse.allcourseMyCourse,
          style: AppStyle.textBold18.copyWith(color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
        ),
      ),
      body: ThemedBackground(
        child: BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (prev, curr) => prev.skillsets != curr.skillsets || prev.status != curr.status,
          builder: (context, homeState) {
            final progressState = context.watch<ProgressCubit>().state;
            final progressById = progressLookup(progressState);

            // Only skillsets the user is enrolled in (≥1 course in their progress).
            final sections = homeState.skillsets.where((s) => s.courses.any((c) => progressById.containsKey(c.id))).toList();

            // Only block with a full spinner on a genuine cold load — don't
            // replace an already-loaded list with a spinner when Home refreshes.
            if ((homeState.status == HomeStatus.initial || homeState.status == HomeStatus.loading) &&
                homeState.skillsets.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppCustomColor.brandPrimary));
            }

            if (sections.isEmpty) {
              return _MyCoursesEmpty(onExplore: () => _exploreMore(context));
            }

            final selected = _selectedChip.clamp(0, sections.length - 1);

            return Column(
              children: [
                // Clear the transparent app bar (extendBodyBehindAppBar) so the
                // chips sit directly below the (now compact) header while the
                // study bg fills behind it. Must match the AppBar's
                // toolbarHeight above, or a gap/overlap reappears.
                SizedBox(height: MediaQuery.paddingOf(context).top + _kHeaderToolbarHeight.h),
                _MyCourseChipBar(
                  skillsets: sections,
                  selectedIndex: selected,
                  onTap: (i) => _onChipTap(i, sections),
                ),
                14.verticalSpace,
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 16.h),
                    children: [
                      for (var i = 0; i < sections.length; i++)
                        KeyedSubtree(
                          key: _sectionKey(sections[i].id),
                          child: _MyCourseSection(
                            skillset: sections[i],
                            progressState: progressState,
                            onTapCourse: (skillset, course) => _openCourseRoadmap(context, skillset, course),
                            showBottomSpacing: i < sections.length - 1,
                          ),
                        ),
                    ],
                  ),
                ),
                // Pinned bottom CTA (design: sticky bottom).
                Container(
                  color: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
                  padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h + MediaQuery.paddingOf(context).bottom),
                  child: _ExploreMoreCoursesButton(onTap: () => _exploreMore(context)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Pops this root-pushed page, then jumps the shell to the course roadmap.
  void _openCourseRoadmap(BuildContext context, SkillsetEntity skillset, CourseEntity course) {
    AppService.instance.appTrackingService.trackProfileMycourseItemClick(course.title.text);
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }
    final index = skillset.courses.indexWhere((c) => c.id == course.id);
    Navigator.of(context, rootNavigator: true).pop();
    final shellContext = AppConfig.instance.context;
    if (shellContext == null) return;
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource('my_courses');
    AppDI.injector.get<HomeCubit>()
      ..selectSkillset(skillset)
      ..selectCourseIndex(index >= 0 ? index : 0);
    CourseRoadmapRoute().go(shellContext);
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }

  /// Pops this page, then jumps the shell to the Explore tab at the current
  /// skillset (mirrors CourseRoadmapPage._backFromRoadmap / SkillsetCourses).
  void _exploreMore(BuildContext context) {
    AppService.instance.appTrackingService.trackProfileMycourseExplore();
    Navigator.of(context, rootNavigator: true).pop();
    final shellContext = AppConfig.instance.context;
    if (shellContext == null) return;
    final skillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
    AppDI.injector.get<CourseCubit>()
      ..setAllCourseSource('my_courses_explore_more')
      ..jumpToSkillset(skillsetIndex);
    AppDI.injector.get<PageCubit>().setCurrentIndex(3);
    CourseRoute(selectedTabIndex: skillsetIndex).go(shellContext);
  }
}

/// Horizontal skillset chips (icon + label) — tapping scrolls to that section.
class _MyCourseChipBar extends StatelessWidget {
  const _MyCourseChipBar({
    required this.skillsets,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<SkillsetEntity> skillsets;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        itemCount: skillsets.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final skillset = skillsets[index];
          final selected = index == selectedIndex;
          return Semantics(
            button: true,
            selected: selected,
            label: skillset.title.text,
            child: GestureDetector(
              onTap: () {
                AppHaptic.select();
                onTap(index);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: selected ? AppCustomColor.brandPrimary : AppCustomColor.brandPrimary50,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (skillset.image.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: CacheNetworkGraphic(url: skillset.image, width: 20.w, height: 20.w, fit: BoxFit.cover),
                      ),
                      8.horizontalSpace,
                    ],
                    AppText(
                      skillset.title.text,
                      style: AppStyle.textBold14.copyWith(
                        color: selected ? AppCustomColor.textWhite : AppCustomColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One skillset's enrolled courses: header + column of [_MyCourseRow]s.
class _MyCourseSection extends StatelessWidget {
  const _MyCourseSection({
    required this.skillset,
    required this.progressState,
    required this.onTapCourse,
    required this.showBottomSpacing,
  });

  final SkillsetEntity skillset;
  final ProgressState progressState;
  final void Function(SkillsetEntity skillset, CourseEntity course) onTapCourse;
  final bool showBottomSpacing;

  @override
  Widget build(BuildContext context) {
    final progressById = progressLookup(progressState);
    final enrolled = sortCoursesForExplore(
      skillset.courses.where((c) => progressById.containsKey(c.id)).toList(),
      progressById,
    );
    final currentCourseId = context.read<HomeCubit>().state.currentCourse.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bare section header sitting directly on the (possibly custom)
        // background — the enrolled-course rows below stay opaque cards.
        AppText(
          skillset.title.text,
          style: AppStyle.textBold18.copyWith(color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
        ),
        14.verticalSpace,
        for (var i = 0; i < enrolled.length; i++) ...[
          if (i > 0) 14.verticalSpace,
          _MyCourseRow(
            course: enrolled[i],
            // Progress comes from myCourses (numberOfLessonPassed) via
            // [resolveCourseProgress] — the same source the Explore grid % reads.
            // NOT ProgressCubit.userProgresses (only loaded for the open course),
            // which is why the row must not use _CourseProgressChip here.
            completedLessons: resolveCourseProgress(enrolled[i], progressById).passed,
            totalLessons: resolveCourseProgress(enrolled[i], progressById).total,
            isSelected: enrolled[i].id == currentCourseId,
            onTap: () => onTapCourse(skillset, enrolled[i]),
          ),
        ],
        if (showBottomSpacing) 26.verticalSpace,
      ],
    );
  }
}

/// Design's course row card: 78px rounded thumbnail + title + progress status
/// (reusing [_CourseProgressChip]), with a 26px brand check at the top-right of
/// the currently-active course.
class _MyCourseRow extends StatelessWidget {
  const _MyCourseRow({
    required this.course,
    required this.completedLessons,
    required this.totalLessons,
    required this.isSelected,
    required this.onTap,
  });

  final CourseEntity course;
  final int completedLessons;
  final int totalLessons;
  final bool isSelected;
  final VoidCallback onTap;

  /// Design status line: green check + "Completed" when done, otherwise a ring +
  /// "N% complete" — always a percentage for an enrolled course, even at 0%.
  Widget _statusLine(BuildContext context) {
    final total = totalLessons;
    final passed = completedLessons;
    final isDone = total > 0 && passed >= total;
    final pct = total > 0 ? (passed / total * 100).round() : 0;

    final Widget icon = isDone
        ? Icon(Icons.check_circle_rounded, size: 16.w, color: _kBadgeGreen)
        : SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              value: total > 0 ? passed / total : 0,
              strokeWidth: 2.5.w,
              backgroundColor: AppCustomColor.borderDefault,
              color: AppCustomColor.brandPrimary,
            ),
          );
    final color = isDone ? _kBadgeGreen : AppCustomColor.brandPrimary;
    final label = isDone ? context.l10n.allcourse.progressCompleted : context.l10n.allcourse.progressPercent(percent: pct);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        7.horizontalSpace,
        Flexible(
          child: AppText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.textBold12.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: course.title.text,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isSelected ? AppCustomColor.brandPrimary50 : AppCustomColor.backgroundWhite,
            border: Border.all(
              color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.r),
                    child: CacheNetworkGraphic(url: course.image, width: 78.w, height: 78.w, fit: BoxFit.cover),
                  ),
                  14.horizontalSpace,
                  Expanded(
                    child: Padding(
                      // Keep text clear of the top-right check.
                      padding: EdgeInsets.only(right: isSelected ? 20.w : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            course.title.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary, height: 1.35),
                          ),
                          8.verticalSpace,
                          _statusLine(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: const BoxDecoration(color: AppCustomColor.brandPrimary, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, color: AppCustomColor.textWhite, size: 15.w),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft full-width CTA to the Explore tab — matches the design's pale
/// "Explore more courses" pill (very light lavender fill, hairline border).
class _ExploreMoreCoursesButton extends StatelessWidget {
  const _ExploreMoreCoursesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.allcourse.exploreMoreCourses;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          width: double.infinity,
          height: 54.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary50,
            border: Border.all(color: AppCustomColor.brandPrimary100, width: 1.5),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                label,
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.brandPrimary),
              ),
              6.horizontalSpace,
              Icon(Icons.arrow_forward_rounded, size: 18.w, color: AppCustomColor.brandPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the user has no enrolled courses yet — nudges them to Explore.
class _MyCoursesEmpty extends StatelessWidget {
  const _MyCoursesEmpty({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CourseEmptyState(),
            24.verticalSpace,
            _ExploreMoreCoursesButton(onTap: onExplore),
          ],
        ),
      ),
    );
  }
}
