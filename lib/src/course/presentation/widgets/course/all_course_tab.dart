part of '../../../course.dart';

class AllCourseTab extends StatefulWidget {
  final int initialCategoryIndex;

  const AllCourseTab({
    super.key,
    required this.initialCategoryIndex,
  });

  @override
  State<AllCourseTab> createState() => _AllCourseTabState();
}

class _AllCourseTabState extends State<AllCourseTab> with AutomaticKeepAliveClientMixin {
  final ItemScrollController _sectionScrollController = ItemScrollController();
  final ItemPositionsListener _sectionPositionsListener = ItemPositionsListener.create();
  final ItemScrollController _categoryScrollController = ItemScrollController();

  int _activeCategoryIndex = 0;
  bool _didInitialScroll = false;
  bool _isProgrammaticScroll = false;
  int? _programmaticTargetIndex;
  int _scrollToken = 0;

  @override
  void initState() {
    super.initState();
    _activeCategoryIndex = widget.initialCategoryIndex;
    _sectionPositionsListener.itemPositions.addListener(_handleSectionPositionsChanged);
  }

  @override
  void dispose() {
    _sectionPositionsListener.itemPositions.removeListener(_handleSectionPositionsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        final skillsets = homeState.skillsets;
        if (skillsets.isEmpty) {
          return const CourseEmptyState();
        }

        _initScrollIfNeeded(skillsets.length);
        final progressState = context.watch<ProgressCubit>().state;

        return Column(
          children: [
            CourseCategoryBar(
              skillsets: skillsets,
              activeCategoryIndex: _activeCategoryIndex,
              onCategoryTap: _onCategoryTap,
              categoryScrollController: _categoryScrollController,
            ),
            12.verticalSpace,
            Expanded(
              child: ScrollablePositionedList.builder(
                itemCount: skillsets.length,
                itemScrollController: _sectionScrollController,
                itemPositionsListener: _sectionPositionsListener,
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                itemBuilder: (context, index) {
                  final skillset = skillsets[index];
                  return _CourseSection(
                    skillset: skillset,
                    progressState: progressState,
                    isSelected: (courseId) => homeState.isSelectedCourse(courseId),
                    onTapCourse: (course, courseIndex) => _onTapCourse(context, skillset, course, courseIndex),
                    showBottomSpacing: index < skillsets.length - 1,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _initScrollIfNeeded(int totalSections) {
    if (_didInitialScroll || totalSections == 0) return;

    _didInitialScroll = true;
    final clampedIndex = widget.initialCategoryIndex.clamp(0, totalSections - 1);
    _activeCategoryIndex = clampedIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection(clampedIndex, jump: true);
      _scrollCategoryTo(clampedIndex);
    });
  }

  void _onCategoryTap(int index) {
    setState(() => _activeCategoryIndex = index);
    _scrollCategoryTo(index);
    _scrollToSection(index);
  }

  void _scrollToSection(int index, {bool jump = false}) {
    if (!_sectionScrollController.isAttached) return;

    if (jump) {
      _sectionScrollController.jumpTo(index: index, alignment: 0);
      return;
    }

    _markProgrammaticScroll(index);
    _sectionScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  void _scrollCategoryTo(int index) {
    if (!_categoryScrollController.isAttached) return;

    _categoryScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  void _handleSectionPositionsChanged() {
    final positions = _sectionPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int? bestIndex;
    double bestVisibility = 0;

    for (final position in positions) {
      final visibility = _visibleFraction(position);
      if (visibility > bestVisibility) {
        bestVisibility = visibility;
        bestIndex = position.index;
      }
    }

    if (_isProgrammaticScroll) {
      if (_programmaticTargetIndex == null || bestIndex != _programmaticTargetIndex) {
        return;
      }
      _isProgrammaticScroll = false;
      _programmaticTargetIndex = null;
    }

    if (bestIndex != null && bestIndex != _activeCategoryIndex) {
      setState(() => _activeCategoryIndex = bestIndex!);
      _scrollCategoryTo(bestIndex);
    }
  }

  double _visibleFraction(ItemPosition position) {
    final visibleStart = math.max(0.0, position.itemLeadingEdge);
    final visibleEnd = math.min(1.0, position.itemTrailingEdge);
    final visible = visibleEnd - visibleStart;
    return visible > 0 ? visible : 0;
  }

  void _markProgrammaticScroll(int index) {
    _isProgrammaticScroll = true;
    _programmaticTargetIndex = index;
    _scrollToken += 1;
    final currentToken = _scrollToken;

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (_scrollToken != currentToken) return;
      _isProgrammaticScroll = false;
      _programmaticTargetIndex = null;
    });
  }

  void _onTapCourse(
    BuildContext context,
    SkillsetEntity skillset,
    CourseEntity course,
    int index,
  ) {
    final isFirstTimeUserChooseCourse = context.read<UserCubit>().state.isFirstTimeUserChooseCourse;
    if (isFirstTimeUserChooseCourse) {
      CourseIntroPopup.show(context, onClose: () => _handleCourseTap(context, skillset, course, index));
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
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }

    context.read<HomeCubit>()
      ..selectSkillset(skillset)
      ..selectCourseIndex(index);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentIndex(1);
  }

  @override
  bool get wantKeepAlive => true;
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
    final courses = skillset.courses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          skillset.title.text.toUpperCase(),
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w600,
            height: 1.75,
          ),
        ),
        8.verticalSpace,
        ...List.generate(courses.length, (index) {
          final course = courses[index];
          final progressInfo = _progressInfoFor(progressState, course);
          return Padding(
            padding: EdgeInsets.only(bottom: index < courses.length - 1 ? 8.h : 0),
            child: CourseCard(
              course: course,
              showProgress: progressInfo.showProgress,
              completedLessons: progressInfo.completedLessons,
              totalLessons: progressInfo.totalLessons,
              isSelected: isSelected(course.id),
              onTap: () => onTapCourse(course, index),
            ),
          );
        }),
        if (showBottomSpacing) 16.verticalSpace,
      ],
    );
  }

  _CourseProgressInfo _progressInfoFor(ProgressState progressState, CourseEntity course) {
    final userProgress = progressState.userProgresses.firstWhereOrNull(
      (progress) => progress.courseId == course.id,
    );

    if (userProgress == null || userProgress.lessonsResult.isEmpty) {
      return const _CourseProgressInfo();
    }

    final completedLessons = userProgress.lessonsResult.where((result) => result.passed).length;
    if (completedLessons == 0) {
      return const _CourseProgressInfo();
    }

    return _CourseProgressInfo(
      showProgress: true,
      completedLessons: completedLessons,
      totalLessons: course.numberOfLesson,
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
