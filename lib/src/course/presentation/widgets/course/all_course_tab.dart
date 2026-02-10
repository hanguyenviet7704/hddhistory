part of '../../../course.dart';

class AllCourseTab extends StatefulWidget {
  final int initialCategoryIndex;
  final bool isVisible;

  const AllCourseTab({
    super.key,
    required this.initialCategoryIndex,
    required this.isVisible,
  });

  @override
  State<AllCourseTab> createState() => _AllCourseTabState();
}

class _AllCourseTabState extends State<AllCourseTab> with AutomaticKeepAliveClientMixin {
  late final AllCourseTabController _controller;
  bool _wasVisible = false;
  bool _isUserScrolling = false;
  int? _scrollStartCategoryIndex;

  @override
  void initState() {
    super.initState();
    _controller = AllCourseTabController(
      initialCategoryIndex: widget.initialCategoryIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AllCourseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible && !widget.isVisible) {
      _wasVisible = false;
    }
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

        _controller.ensureInitialized(skillsets.length);
        _trackAllCourseScrViewIfNeeded();
        final progressState = context.watch<ProgressCubit>().state;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                CourseCategoryBar(
                  skillsets: skillsets,
                  activeCategoryIndex: _controller.activeCategoryIndex,
                  onCategoryTap: (index) => _handleCategoryTap(skillsets, index),
                  categoryScrollController: _controller.categoryScrollController,
                  onCategorySlide: _handleCategorySlide,
                ),
                12.verticalSpace,
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleListScrollNotification,
                    child: ScrollablePositionedList.builder(
                      itemCount: skillsets.length,
                      itemScrollController: _controller.sectionScrollController,
                      itemPositionsListener: _controller.sectionPositionsListener,
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
                ),
              ],
            );
          },
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
    if (isFirstTimeUserChooseCourse) {
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

  void _trackAllCourseScrViewIfNeeded() {
    if (!widget.isVisible || _wasVisible) return;
    final source = context.read<CourseCubit>().state.allCourseSource;
    AppService.instance.appTrackingService.trackCourseSelectAllCourseView(source: source);
    _wasVisible = true;
  }

  void _handleCategoryTap(List<SkillsetEntity> skillsets, int index) {
    final currentIndex = _controller.activeCategoryIndex;
    if (index != currentIndex) {
      final skillset = skillsets.skillsetFromIndex(index);
      if (skillset != null && skillset.id.isNotEmpty) {
        AppService.instance.appTrackingService.trackCourseSelectCategoryClick(
          skillset,
          isRightDirection: index > currentIndex,
        );
      }
    }
    _controller.onCategoryTap(index);
  }

  void _handleCategorySlide() {
    if (!widget.isVisible) return;
    AppService.instance.appTrackingService.trackCourseSelectCategorySlide();
  }

  bool _handleListScrollNotification(ScrollNotification notification) {
    if (!widget.isVisible || notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      _isUserScrolling = true;
      _scrollStartCategoryIndex = _controller.activeCategoryIndex;
    } else if (notification is ScrollEndNotification) {
      _trackAllCourseScroll();
    }
    return false;
  }

  void _trackAllCourseScroll() {
    if (!_isUserScrolling) return;
    final startIndex = _scrollStartCategoryIndex;
    if (startIndex == null) {
      _resetScrollTracking();
      return;
    }
    final isSameCategory = startIndex == _controller.activeCategoryIndex;
    AppService.instance.appTrackingService.trackCourseSelectAllCourseScroll(isSameCategory: isSameCategory);
    _resetScrollTracking();
  }

  void _resetScrollTracking() {
    _isUserScrolling = false;
    _scrollStartCategoryIndex = null;
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
