part of '../../../course.dart';

class AllCourseTab extends StatefulWidget {
  const AllCourseTab({super.key});

  @override
  State<AllCourseTab> createState() => _AllCourseTabState();
}

class _AllCourseTabState extends State<AllCourseTab> with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackAllCourseScrView());
  }

  void _trackAllCourseScrView() {
    if (!mounted) return;
    final source = context.read<CourseCubit>().state.allCourseSource;
    AppService.instance.appTrackingService.trackCourseSelectAllCourseView(source: source);
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
        final selectedCategoryIndex = context.watch<CourseCubit>().state.selectedCategoryIndex;

        // Filter skillsets based on selected category. -1 means show all.
        final visibleSkillsets = selectedCategoryIndex < 0
            ? skillsets
            : skillsets.length > selectedCategoryIndex
                ? [skillsets[selectedCategoryIndex]]
                : <SkillsetEntity>[];

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
          itemCount: visibleSkillsets.length,
          itemBuilder: (context, index) {
            final skillset = visibleSkillsets[index];
            return _CourseSection(
              skillset: skillset,
              progressState: progressState,
              isSelected: (courseId) => homeState.isSelectedCourse(courseId),
              onTapCourse: (course, courseIndex) =>
                  _onTapCourse(context, skillset, course, courseIndex),
              showBottomSpacing: index < visibleSkillsets.length - 1,
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
